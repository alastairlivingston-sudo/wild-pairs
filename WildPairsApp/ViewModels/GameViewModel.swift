import SwiftUI
import UIKit
import WildPairsCore

// Thin SwiftUI binding over the platform-agnostic GamePresenter. It owns no game logic:
// it forwards intents, republishes the derived GameViewState, schedules AI turns with a
// think-delay, and plays effects (haptics / VoiceOver). All decisions live in WildPairsCore.

@MainActor
final class GameViewModel: ObservableObject {

    @Published private(set) var viewState: GameViewState
    /// A transient line for the illegal-move tooltip; cleared after a short delay.
    @Published var lastInvalidHint: String?
    /// Seconds left on the round-wide fallback timer; nil when not running (e.g. paused,
    /// round not in `.playing`, or the rule profile disables it). Drives the countdown UI.
    @Published private(set) var roundTimeRemaining: TimeInterval?
    /// Seconds left on the local player's per-move timer; nil when it isn't their turn.
    @Published private(set) var moveTimeRemaining: TimeInterval?
    /// The AI seat currently in its "thinking" delay, if any — drives the thinking
    /// indicator (ux-spec.md §10 "Game table — AI turn (thinking indicator)").
    @Published private(set) var thinkingPlayerID: UUID?

    private let presenter: GamePresenter
    private let settings: AppSettings
    private let haptics: HapticEngine
    private let sound: SoundCoordinator
    private let onRoundEnd: (_ localTeamWon: Bool, _ difficulty: Difficulty, _ turns: Int) -> Void

    private var aiTask: Task<Void, Never>?
    private var roundTimerTask: Task<Void, Never>?
    private var moveTimerTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?
    private var roundDeadline: Date?
    private var moveDeadline: Date?
    private var turnsThisRound = 0
    private var roundResultRecorded = false

    init(
        presenter: GamePresenter,
        settings: AppSettings,
        onRoundEnd: @escaping (Bool, Difficulty, Int) -> Void = { _, _, _ in }
    ) {
        self.presenter = presenter
        self.settings = settings
        self.haptics = HapticEngine(settings: settings)
        self.sound = SoundCoordinator(settings: settings)
        self.onRoundEnd = onRoundEnd
        self.viewState = presenter.viewState
        scheduleAITurnsIfNeeded()
        scheduleRoundTimerIfNeeded()
        scheduleMoveTimerIfNeeded()
    }

    convenience init(
        config: GameConfig,
        settings: AppSettings,
        persistence: PersistenceService = PersistenceService(),
        onRoundEnd: @escaping (Bool, Difficulty, Int) -> Void = { _, _, _ in }
    ) {
        self.init(presenter: GamePresenter(config: config, persistence: persistence),
                  settings: settings, onRoundEnd: onRoundEnd)
    }

    var localPlayerID: UUID { presenter.localPlayerID }
    var roundTimeLimit: TimeInterval { presenter.state.ruleProfile.roundTimeLimitSeconds }
    var moveTimeLimit: TimeInterval { presenter.state.ruleProfile.moveTimeLimitSeconds }
    var thinkingDifficulty: Difficulty? {
        thinkingPlayerID.flatMap { id in presenter.state.players.first { $0.id == id }?.difficulty }
    }

    // MARK: Local intents

    func play(_ card: CardViewModel) {
        guard card.isPlayable else {
            haptics.illegalCard()
            lastInvalidHint = GameViewState.matchHint(state: presenter.state)
            clearHintSoon()
            return
        }
        apply { presenter.play(card.card) }
    }

    func drawCard()                       { apply { presenter.draw() } }
    func chooseColour(_ c: CardColour)     { apply { presenter.chooseColour(c) } }
    func chooseTarget(_ id: UUID)          { apply { presenter.chooseTarget(id) } }
    func passTeamCard(_ card: Card?)       { apply { presenter.passTeamCard(card) } }
    func callSolo()                        { haptics.soloCall(); sound.play(.soloCall); apply { presenter.callSolo() } }
    func callOut(_ id: UUID)               { apply { presenter.callOut(id) } }

    func beginNextRound() {
        turnsThisRound = 0
        roundResultRecorded = false
        apply { presenter.beginNewRound() }
    }

    // MARK: Lifecycle

    func pause() {
        aiTask?.cancel()
        roundTimerTask?.cancel()
        moveTimerTask?.cancel()
        tickTask?.cancel()
        tickTask = nil
        roundDeadline = nil
        moveDeadline = nil
        roundTimeRemaining = nil
        moveTimeRemaining = nil
        thinkingPlayerID = nil
    }
    func resume() {
        scheduleAITurnsIfNeeded()
        scheduleRoundTimerIfNeeded()
        scheduleMoveTimerIfNeeded()
    }

    // MARK: Internals

    private func apply(_ action: () -> [GameEffect]) {
        let effects = action()
        turnsThisRound += 1
        handle(effects)
        viewState = presenter.viewState
        checkRoundEnd()
        enforceTurnCapIfNeeded()
        scheduleAITurnsIfNeeded()
        scheduleRoundTimerIfNeeded()
        scheduleMoveTimerIfNeeded()
    }

    /// Defensive turn cap (game-rules.md §Error Handling, playtest-review.md G4): the pure
    /// engine can't loop on its own (every action makes progress), so `GameSimulator`'s
    /// 300-turn cap is a belt-and-suspenders safety net rather than expected behaviour — but
    /// the ViewModel should enforce `RuleProfile.maxTurnsPerRound` too, in case something
    /// upstream (a future house rule, a bug) causes a round to run unexpectedly long. Reuses
    /// the round timer's existing lowest-score-wins fallback rather than inventing a new one.
    private func enforceTurnCapIfNeeded() {
        guard presenter.state.phase == .playing,
              turnsThisRound >= presenter.state.ruleProfile.maxTurnsPerRound else { return }
        let effects = presenter.roundTimerExpired()
        roundDeadline = nil
        handle(effects)
        viewState = presenter.viewState
        checkRoundEnd()
    }

    private func scheduleAITurnsIfNeeded() {
        aiTask?.cancel()
        guard presenter.nextAutomaticAction() != nil else { return }
        aiTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.presenter.nextAutomaticAction() != nil {
                self.thinkingPlayerID = self.presenter.state.currentPlayer?.id
                let delay = self.thinkDelay()
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                self.thinkingPlayerID = nil
                if Task.isCancelled { return }
                guard let effects = self.presenter.advanceAutomatic() else { break }
                self.turnsThisRound += 1
                self.handle(effects)
                self.viewState = self.presenter.viewState
                self.checkRoundEnd()
                self.enforceTurnCapIfNeeded()
            }
            self.scheduleMoveTimerIfNeeded()
        }
    }

    /// Round-wide wall-clock fallback (`RuleProfile.roundTimeLimitSeconds`): if nobody empties
    /// their hand before this fires, the engine decides the round by lowest score.
    private func scheduleRoundTimerIfNeeded() {
        roundTimerTask?.cancel()
        roundDeadline = nil
        guard presenter.state.phase == .playing else { return }
        let seconds = presenter.state.ruleProfile.roundTimeLimitSeconds
        guard seconds > 0 else { return }
        roundDeadline = Date().addingTimeInterval(seconds)
        startTickingIfNeeded()
        roundTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let effects = self.presenter.roundTimerExpired()
            self.roundDeadline = nil
            self.handle(effects)
            self.viewState = self.presenter.viewState
            self.checkRoundEnd()
        }
    }

    /// Per-move wall-clock fallback (`RuleProfile.moveTimeLimitSeconds`) for the local human
    /// only — forces a random legal move if they haven't acted in time.
    private func scheduleMoveTimerIfNeeded() {
        moveTimerTask?.cancel()
        moveDeadline = nil
        guard presenter.state.phase == .playing,
              presenter.state.pendingDecision == nil,
              presenter.state.currentPlayer?.id == localPlayerID else { return }
        let seconds = presenter.state.ruleProfile.moveTimeLimitSeconds
        guard seconds > 0 else { return }
        moveDeadline = Date().addingTimeInterval(seconds)
        startTickingIfNeeded()
        moveTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let effects = self.presenter.forceTimedOutMove(for: self.localPlayerID)
            self.moveDeadline = nil
            self.turnsThisRound += 1
            self.handle(effects)
            self.viewState = self.presenter.viewState
            self.checkRoundEnd()
            self.enforceTurnCapIfNeeded()
            self.scheduleAITurnsIfNeeded()
            self.scheduleMoveTimerIfNeeded()
        }
    }

    /// Republishes `roundTimeRemaining`/`moveTimeRemaining` a few times a second so the
    /// countdown UI animates smoothly; stops itself once both deadlines clear.
    private func startTickingIfNeeded() {
        guard tickTask == nil else { return }
        tickTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                self.roundTimeRemaining = self.roundDeadline.map { max(0, $0.timeIntervalSinceNow) }
                self.moveTimeRemaining = self.moveDeadline.map { max(0, $0.timeIntervalSinceNow) }
                if self.roundDeadline == nil && self.moveDeadline == nil {
                    self.tickTask = nil
                    return
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private func thinkDelay() -> TimeInterval {
        switch settings.userSettings.animationSpeed {
        case .off:  return 0
        case .fast: return 0.1
        case .normal:
            let difficulty = presenter.state.currentPlayer?.difficulty ?? .easy
            return AIPlayer.thinkDelay(for: difficulty)
        }
    }

    private func checkRoundEnd() {
        guard !roundResultRecorded,
              presenter.state.phase != .playing,
              let winner = presenter.state.winState?.winningTeam else { return }
        roundResultRecorded = true
        let localTeam = presenter.state.players.first { $0.id == localPlayerID }?.teamID
        let difficulty = presenter.state.players.first { $0.role == .ai }?.difficulty ?? .easy
        onRoundEnd(winner == localTeam, difficulty, turnsThisRound)
    }

    private func handle(_ effects: [GameEffect]) {
        for effect in effects {
            switch effect {
            case .animateCardPlay(let card, _):
                haptics.cardPlay()
                sound.play(soundEffect(forCardPlay: card))
            case .animateCardDraw(let to, _):
                if to == localPlayerID { haptics.cardDrawn() }
                sound.play(.cardDraw)
            case .animateCardShuffle:            sound.play(.cardShuffle)
            case .animateHandSwap:               sound.play(.swapHands)
            case .announceSolo(let name):
                announce(soloAnnouncement(for: name))
            case .soloCallMissed(let name, let penalty):
                haptics.drawPenalty()
                sound.play(.soloMissed)
                announce(soloMissedAnnouncement(for: name, penaltyCards: penalty))
            case .playRoundEnd(let team):
                announceRoundEnd(team, sound: .roundWin, isGameEnd: false)
            case .playGameEnd(let team):
                announceRoundEnd(team, sound: .gameWin, isGameEnd: true)
            case .accessibilityAnnounce(let message):
                announce(message)
            default:
                break
            }
        }
    }

    /// Posts a VoiceOver live-region announcement without moving the accessibility cursor
    /// (accessibility-plan.md §2 — Solo!/round-end events must announce automatically).
    private func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func relation(toPlayerNamed name: String) -> String {
        guard let player = presenter.state.players.first(where: { $0.name == name }) else { return name }
        if player.id == localPlayerID { return "you" }
        let localTeam = presenter.state.players.first { $0.id == localPlayerID }?.teamID
        return player.teamID == localTeam ? "partner" : name
    }

    private func soloAnnouncement(for name: String) -> String {
        switch relation(toPlayerNamed: name) {
        case "you":     return "Solo called! You have one card remaining."
        case "partner": return "Your partner called Solo! They have one card remaining."
        default:        return "\(name) called Solo! They have one card remaining."
        }
    }

    private func soloMissedAnnouncement(for name: String, penaltyCards: Int) -> String {
        if relation(toPlayerNamed: name) == "you" {
            return "You forgot to call Solo! — \(penaltyCards) penalty cards drawn."
        }
        return "\(name) forgot to call Solo! — drew \(penaltyCards) penalty cards."
    }

    private func soundEffect(forCardPlay card: Card) -> SoundEffect {
        switch card.type {
        case .skip, .skipTwo:                 return .skipPlayed
        case .reverse:                        return .reversePlayed
        case .drawTwo:                        return .drawTwoPlayed
        case .drawFour, .changeColour:        return .wildPlayed
        case .number, .discardAll, .targetedDraw, .forcedSwap, .teamPlay:
            return .cardPlay
        }
    }

    private func announceRoundEnd(_ team: TeamID, sound winSound: SoundEffect, isGameEnd: Bool) {
        let localTeam = presenter.state.players.first { $0.id == localPlayerID }?.teamID
        if team == localTeam {
            haptics.roundWin()
            sound.play(winSound)
            announce(isGameEnd ? "Your team wins the game!" : "Your team wins this round.")
        } else {
            haptics.roundLoss()
            announce(isGameEnd ? "Opponents win the game." : "Opponents win this round.")
        }
    }

    private func clearHintSoon() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self?.lastInvalidHint = nil
        }
    }
}
