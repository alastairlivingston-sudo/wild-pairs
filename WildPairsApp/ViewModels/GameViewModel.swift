import SwiftUI
import WildPairsCore

// Thin SwiftUI binding over the platform-agnostic GamePresenter. It owns no game logic:
// it forwards intents, republishes the derived GameViewState, schedules AI turns with a
// think-delay, and plays effects (haptics / VoiceOver). All decisions live in WildPairsCore.

@MainActor
final class GameViewModel: ObservableObject {

    @Published private(set) var viewState: GameViewState
    /// A transient line for the illegal-move tooltip; cleared after a short delay.
    @Published var lastInvalidHint: String?

    private let presenter: GamePresenter
    private let settings: AppSettings
    private let haptics: HapticEngine
    private let onRoundEnd: (_ localTeamWon: Bool, _ difficulty: Difficulty, _ turns: Int) -> Void

    private var aiTask: Task<Void, Never>?
    private var roundTimerTask: Task<Void, Never>?
    private var moveTimerTask: Task<Void, Never>?
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
    func callSolo()                        { haptics.soloCall(); apply { presenter.callSolo() } }
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
        scheduleAITurnsIfNeeded()
        scheduleRoundTimerIfNeeded()
        scheduleMoveTimerIfNeeded()
    }

    private func scheduleAITurnsIfNeeded() {
        aiTask?.cancel()
        guard presenter.nextAutomaticAction() != nil else { return }
        aiTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.presenter.nextAutomaticAction() != nil {
                let delay = self.thinkDelay()
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                if Task.isCancelled { return }
                guard let effects = self.presenter.advanceAutomatic() else { break }
                self.turnsThisRound += 1
                self.handle(effects)
                self.viewState = self.presenter.viewState
                self.checkRoundEnd()
            }
            self.scheduleMoveTimerIfNeeded()
        }
    }

    /// Round-wide wall-clock fallback (`RuleProfile.roundTimeLimitSeconds`): if nobody empties
    /// their hand before this fires, the engine decides the round by lowest score.
    private func scheduleRoundTimerIfNeeded() {
        roundTimerTask?.cancel()
        guard presenter.state.phase == .playing else { return }
        let seconds = presenter.state.ruleProfile.roundTimeLimitSeconds
        guard seconds > 0 else { return }
        roundTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let effects = self.presenter.roundTimerExpired()
            self.handle(effects)
            self.viewState = self.presenter.viewState
            self.checkRoundEnd()
        }
    }

    /// Per-move wall-clock fallback (`RuleProfile.moveTimeLimitSeconds`) for the local human
    /// only — forces a random legal move if they haven't acted in time.
    private func scheduleMoveTimerIfNeeded() {
        moveTimerTask?.cancel()
        guard presenter.state.phase == .playing,
              presenter.state.pendingDecision == nil,
              presenter.state.currentPlayer?.id == localPlayerID else { return }
        let seconds = presenter.state.ruleProfile.moveTimeLimitSeconds
        guard seconds > 0 else { return }
        moveTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let effects = self.presenter.forceTimedOutMove(for: self.localPlayerID)
            self.turnsThisRound += 1
            self.handle(effects)
            self.viewState = self.presenter.viewState
            self.checkRoundEnd()
            self.scheduleAITurnsIfNeeded()
            self.scheduleMoveTimerIfNeeded()
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
            case .animateCardPlay:               haptics.cardPlay()
            case .animateCardDraw(let to, _):    if to == localPlayerID { haptics.cardDrawn() }
            case .announceSolo:                  break
            case .soloCallMissed:                haptics.drawPenalty()
            case .playRoundEnd(let team):        announceRoundEnd(team)
            case .playGameEnd(let team):         announceRoundEnd(team)
            default:                             break
            }
        }
    }

    private func announceRoundEnd(_ team: TeamID) {
        let localTeam = presenter.state.players.first { $0.id == localPlayerID }?.teamID
        if team == localTeam { haptics.roundWin() } else { haptics.roundLoss() }
    }

    private func clearHintSoon() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self?.lastInvalidHint = nil
        }
    }
}
