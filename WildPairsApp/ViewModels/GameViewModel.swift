import SwiftUI
import UIKit
import WildPairsCore
import os

// Thin SwiftUI binding over the platform-agnostic GamePresenter. It owns no game logic:
// it forwards intents, republishes the derived GameViewState, schedules AI turns with a
// think-delay, and plays effects (haptics / VoiceOver). All decisions live in WildPairsCore.

/// A transient, seat-level feedback cue (Phase 17 C3) so play is legible: which seat just got
/// skipped, and how many cards a seat was just made to draw. `token` makes each emission
/// distinct so the UI re-triggers even for a repeat of the same kind on the same seat.
enum SeatCueKind: Equatable {
    case skipped
    case drew(Int)
}

struct SeatCueEvent: Equatable {
    let seatIDs: [UUID]
    let kind: SeatCueKind
    let token: Int
}

/// A played card in flight from the acting seat to the discard pile (Phase 17 Stage 3.1), so
/// every play — not just the local hand's — is *seen* travelling across the table. `token`
/// keeps repeat plays of the same card by the same seat distinct.
struct CardFlightEvent: Equatable {
    let card: Card
    let fromSeatID: UUID
    let token: Int
}

/// A draw in flight from the draw pile to a seat's hand (Phase 17 Stage 3.5). `count` card-
/// backs fly, staggered, so a big penalty pickup visibly takes longer than a single draw.
struct DrawFlightEvent: Equatable {
    let toSeatID: UUID
    let count: Int
    let token: Int
}

/// One-shot presentation event for a successful missed-Solo catch. This is deliberately not
/// game state: the engine remains authoritative for the penalty draw; the UI only needs a stable
/// seat ID and token so it can place the "+2 caught" stamp on the correct seat once.
struct SoloPenaltyEvent: Equatable {
    let seatID: UUID
    let count: Int
    let token: Int
}

/// What one finished round means for the local statistics.
struct RoundResult {
    let localTeamWon: Bool
    let difficulty: Difficulty
    let turns: Int
    /// Raw card points the round awarded, before the difficulty multiplier.
    let roundPoints: Int
    let multiplier: Int
}

@MainActor
final class GameViewModel: ObservableObject {

    @Published private(set) var viewState: GameViewState
    /// Pass-and-play (Phase 15): the human seat the game is waiting on when it is not the
    /// one currently shown. Non-nil drives the "pass the device" overlay; `confirmHandoff()`
    /// flips the displayed perspective. Always nil in single-human games.
    @Published private(set) var pendingHandoffSeat: PlayerSeatViewState?
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
    /// The latest transient seat cue (skip / forced draw) — the table shows it briefly on the
    /// affected seat so a skip or penalty is *seen*, not just inferred (Phase 17 C3).
    @Published private(set) var seatCue: SeatCueEvent?
    private var seatCueToken = 0
    /// The most recent played-card flight (Phase 17 Stage 3.1) — the table launches a ghost
    /// card from the acting seat to the discard when this changes.
    @Published private(set) var cardFlight: CardFlightEvent?
    private var cardFlightToken = 0
    /// The most recent draw flight (Phase 17 Stage 3.5) — the table launches `count` card-backs
    /// from the draw pile to the target seat when this changes.
    @Published private(set) var drawFlight: DrawFlightEvent?
    private var drawFlightToken = 0
    /// The most recent successful missed-Solo catch, used only for a transient seat stamp.
    @Published private(set) var soloPenalty: SoloPenaltyEvent?
    private var soloPenaltyToken = 0
    /// `GameEffect.soloCallMissed` carries a display name rather than an ID. Remember the target
    /// while the synchronous call-out action is handled so the UI never has to match by name.
    private var pendingSoloCallOutTargetID: UUID?

    private let presenter: GamePresenter
    private let settings: AppSettings
    /// Whose perspective the table renders (bottom seat, hand shown, intents dispatched).
    /// Equal to `presenter.localPlayerID` until a pass-and-play handoff is confirmed.
    private var displayedHumanID: UUID
    private let haptics: HapticEngine
    private let sound: SoundCoordinator
    private let onRoundEnd: (RoundResult) -> Void
    /// UI-test affordance: shorten the per-move timer to ~1s so a draw-driven test can advance a
    /// human's move-timer-paced turns quickly (a real game keeps the full 10s/5s limit). Set via
    /// the `--uitest-fast-timers` launch argument; never affects production play.
    private let fastTimers = ProcessInfo.processInfo.arguments.contains("--uitest-fast-timers")

    private var aiTask: Task<Void, Never>?
    private var roundTimerTask: Task<Void, Never>?
    private var moveTimerTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?
    private var forcedPickupTask: Task<Void, Never>?
    private var roundDeadline: Date?
    /// Round time left captured at pause, so resuming restores it instead of granting a fresh round.
    private var pausedRoundRemaining: TimeInterval?
    private var moveDeadline: Date?
    private var turnsThisRound = 0
    private var roundResultRecorded = false

    init(
        presenter: GamePresenter,
        settings: AppSettings,
        onRoundEnd: @escaping (RoundResult) -> Void = { _ in }
    ) {
        self.presenter = presenter
        self.settings = settings
        self.haptics = HapticEngine(settings: settings)
        self.sound = SoundCoordinator(settings: settings)
        self.onRoundEnd = onRoundEnd
        self.displayedHumanID = presenter.localPlayerID
        self.viewState = presenter.viewState
        updateHandoff()
        scheduleAITurnsIfNeeded()
        scheduleRoundTimerIfNeeded()
        scheduleMoveTimerIfNeeded()
        scheduleForcedPickupIfNeeded()
    }

    convenience init(
        config: GameConfig,
        settings: AppSettings,
        persistence: PersistenceService = PersistenceService(),
        onRoundEnd: @escaping (RoundResult) -> Void = { _ in }
    ) {
        self.init(presenter: GamePresenter(config: config, persistence: persistence),
                  settings: settings, onRoundEnd: onRoundEnd)
    }

    var localPlayerID: UUID { presenter.localPlayerID }

    // MARK: Pass-and-play (D1 — Active-Half Focus dual-ended table)

    /// Two human teammates share one device; the table renders both ends at once (no handoff).
    var isPassAndPlay: Bool { presenter.state.players.filter { $0.role == .human }.count >= 2 }
    /// The bottom (local) human — "You".
    var bottomHumanID: UUID { presenter.localPlayerID }
    /// The top human — the partner sharing the device.
    var topHumanID: UUID? {
        presenter.state.players.first { $0.role == .human && $0.id != presenter.localPlayerID }?.id
    }
    /// Which human is to act right now (their hand is live), if any.
    var currentHumanID: UUID? {
        presenter.state.currentPlayer.flatMap { $0.role == .human ? $0.id : nil }
    }
    /// The acting human's perspective — drives the shared centre's draw affordance + prompt so
    /// they follow whoever is to act. Falls back to the bottom human during AI turns.
    var activeViewState: GameViewState { presenter.viewState(for: currentHumanID ?? bottomHumanID) }

    /// A mid-resolution decision plus the human who owns it, so the dual-ended view can render
    /// the right overlay at the right end (rotated 180° when the top human owns it).
    enum ActiveDecision: Equatable {
        case colour(owner: UUID)
        case target(owner: UUID, candidates: [UUID])
        case teamPass(owner: UUID)
        case drawFourChallenge(owner: UUID, challengedName: String, priorColour: CardColour?)

        var owner: UUID {
            switch self {
            case .colour(let o), .target(let o, _), .teamPass(let o): return o
            case .drawFourChallenge(let o, _, _): return o
            }
        }
    }

    /// The pending decision owned by a human (either end), for the pass-and-play overlays.
    var activeDecision: ActiveDecision? {
        let s = presenter.state
        // Suppressed once the round has ended so no overlay lingers over the round-end screen (Tier 0c).
        guard s.phase == .playing || s.phase == .teamPass else { return nil }
        switch s.pendingDecision {
        case .colourChoice(let pid):
            return isHuman(pid) ? .colour(owner: pid) : nil
        case .targetChoice(let pid, let targets):
            return isHuman(pid) ? .target(owner: pid, candidates: targets) : nil
        case .teamPass(let pid):
            return isHuman(pid) ? .teamPass(owner: pid) : nil
        case .drawFourChallenge(let challengerID, let challengedID, let priorColour, _):
            guard isHuman(challengerID) else { return nil }
            let name = s.players.first { $0.id == challengedID }?.name ?? "The previous player"
            return .drawFourChallenge(owner: challengerID, challengedName: name, priorColour: priorColour)
        case .none:
            return nil
        }
    }

    /// The hand held by `playerID`, for rendering either human's fan in the dual-ended view.
    func hand(for playerID: UUID) -> [Card] {
        presenter.state.players.first { $0.id == playerID }?.hand ?? []
    }
    func handCount(for playerID: UUID) -> Int { hand(for: playerID).count }
    func name(for playerID: UUID) -> String {
        presenter.state.players.first { $0.id == playerID }?.name ?? ""
    }
    private func isHuman(_ id: UUID) -> Bool {
        presenter.state.players.first { $0.id == id }?.role == .human
    }

    // Explicit-actor intents — the dual-ended view dispatches as the acting human at either end.
    func play(_ card: Card, as playerID: UUID) { apply { presenter.play(card, as: playerID) } }
    func drawCard(as playerID: UUID) { apply { presenter.draw(as: playerID) } }
    func callSolo(as playerID: UUID) { haptics.soloCall(); sound.play(.soloCall); apply { presenter.callSolo(as: playerID) } }
    func chooseColour(_ c: CardColour, as playerID: UUID) { apply { presenter.chooseColour(c, as: playerID) } }
    func chooseTarget(_ id: UUID, as playerID: UUID) { apply { presenter.chooseTarget(id, as: playerID) } }
    func passTeamCard(_ card: Card?, as playerID: UUID) { apply { presenter.passTeamCard(card, as: playerID) } }
    func resolveDrawFourChallenge(_ challenge: Bool, as playerID: UUID) {
        if challenge { haptics.illegalCard() }
        apply { presenter.resolveDrawFourChallenge(challenge, as: playerID) }
    }
    var roundTimeLimit: TimeInterval { presenter.state.ruleProfile.roundTimeLimitSeconds }
    /// Effective per-move limit — 10s normally, 5s once the round enters its final minute (C10).
    var moveTimeLimit: TimeInterval {
        if fastTimers { return 1 }
        return presenter.state.ruleProfile.effectiveMoveLimit(roundRemaining: roundDeadline?.timeIntervalSinceNow)
    }
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
        apply { presenter.play(card.card, as: displayedHumanID) }
    }

    func drawCard()                       { apply { presenter.draw(as: displayedHumanID) } }
    func chooseColour(_ c: CardColour)     { apply { presenter.chooseColour(c, as: displayedHumanID) } }
    func chooseTarget(_ id: UUID)          { apply { presenter.chooseTarget(id, as: displayedHumanID) } }
    func passTeamCard(_ card: Card?)       { apply { presenter.passTeamCard(card, as: displayedHumanID) } }
    func callSolo()                        { haptics.soloCall(); sound.play(.soloCall); apply { presenter.callSolo(as: displayedHumanID) } }
    func callOut(_ id: UUID) {
        pendingSoloCallOutTargetID = id
        apply { presenter.callOut(id, as: displayedHumanID) }
        pendingSoloCallOutTargetID = nil
    }
    /// Draw Four challenge (Phase 17 B2): challenge the Draw Four, or accept it.
    func resolveDrawFourChallenge(_ challenge: Bool) {
        if challenge { haptics.illegalCard() }
        apply { presenter.resolveDrawFourChallenge(challenge, as: displayedHumanID) }
    }

    /// Pass-and-play: the receiving player has the device — flip the table to their
    /// perspective and resume their timers.
    func confirmHandoff() {
        guard let seat = pendingHandoffSeat else { return }
        displayedHumanID = seat.id
        pendingHandoffSeat = nil
        publishViewState()
        scheduleMoveTimerIfNeeded()
        scheduleForcedPickupIfNeeded()
    }

    func beginNextRound() {
        turnsThisRound = 0
        roundResultRecorded = false
        // Fresh round: drop any stale deadline so the scheduler arms the full limit anew.
        roundDeadline = nil
        pausedRoundRemaining = nil
        apply { presenter.beginNewRound() }
    }

    // MARK: Lifecycle

    func pause() {
        aiTask?.cancel()
        roundTimerTask?.cancel()
        moveTimerTask?.cancel()
        forcedPickupTask?.cancel()
        forcedPickupTask = nil
        tickTask?.cancel()
        tickTask = nil
        // Preserve how much round time was left so resume restores it rather than restarting.
        pausedRoundRemaining = roundDeadline.map { max(0, $0.timeIntervalSinceNow) }
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
        scheduleForcedPickupIfNeeded()
    }

    // MARK: Internals

    private func apply(_ action: () -> [GameEffect]) {
        let effects = action()
        turnsThisRound += 1
        handle(effects)
        updateHandoff()
        publishViewState()
        checkRoundEnd()
        enforceTurnCapIfNeeded()
        scheduleAITurnsIfNeeded()
        scheduleRoundTimerIfNeeded()
        scheduleMoveTimerIfNeeded()
        scheduleForcedPickupIfNeeded()
    }

    /// Pass-and-play: when the game starts waiting on a human other than the one shown,
    /// surface the handoff overlay (perspective flips only on `confirmHandoff`).
    private func updateHandoff() {
        // Pass-and-play renders both ends at once (D1), so there is no "pass the device" handoff.
        if isPassAndPlay {
            if pendingHandoffSeat != nil { pendingHandoffSeat = nil }
            return
        }
        let waiting = presenter.humanAwaitingInput()
        if let waiting, waiting != displayedHumanID {
            pendingHandoffSeat = presenter.viewState(for: waiting).seats.first { $0.id == waiting }
        } else if pendingHandoffSeat != nil {
            pendingHandoffSeat = nil
        }
    }

    /// Animates hand/table changes (card play/draw/turn pass — A9) unless the user has
    /// disabled animation (`AnimationSpeed.off`) or enabled Reduced Motion, in which case the
    /// new state is published instantly with no transition.
    private var stateAnimation: Animation? {
        guard !settings.userSettings.reducedVisualEffects else { return nil }
        switch settings.userSettings.animationSpeed {
        case .off:    return nil
        case .fast:   return Theme.Motion.fast
        case .normal: return Theme.Motion.turnPass
        }
    }

    private func publishViewState() {
        PerfSignpost.event("publishViewState")   // Tier-0d redraw suspect (R7)
        let next = presenter.viewState(for: displayedHumanID)
        guard let animation = stateAnimation else {
            viewState = next
            return
        }
        withAnimation(animation) { viewState = next }
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
        updateHandoff()
        publishViewState()
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
                self.updateHandoff()
                self.publishViewState()
                self.checkRoundEnd()
                self.enforceTurnCapIfNeeded()
            }
            self.scheduleMoveTimerIfNeeded()
            self.scheduleForcedPickupIfNeeded()
        }
    }

    /// Forced pickup (Phase 15): when a draw stack lands on the local player and they hold
    /// no card that can answer it, there is no decision to make — drawing is the only legal
    /// move. Prompting them to tap the pile was pure friction, so the penalty is drawn
    /// automatically after a short readable beat.
    private func scheduleForcedPickupIfNeeded() {
        forcedPickupTask?.cancel()
        forcedPickupTask = nil
        // Held back during a handoff so the receiving player sees their penalty drawn.
        guard let count = viewState.forcedPickupCount,
              pendingHandoffSeat == nil,
              presenter.state.phase == .playing,
              presenter.state.pendingDecision == nil else { return }
        announce("No card can answer the stack. Drawing \(count) cards.")
        let delay: TimeInterval = settings.userSettings.animationSpeed == .normal ? 1.2 : 0.4
        forcedPickupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled,
                  self.viewState.forcedPickupCount != nil else { return }
            self.haptics.drawPenalty()
            self.apply { self.presenter.draw() }
        }
    }

    /// Round-wide wall-clock fallback (`RuleProfile.roundTimeLimitSeconds`): if nobody empties
    /// their hand before this fires, the engine decides the round by lowest score.
    private func scheduleRoundTimerIfNeeded() {
        roundTimerTask?.cancel()
        guard presenter.state.phase == .playing else {
            roundDeadline = nil
            pausedRoundRemaining = nil
            return
        }
        // Single per-round countdown (not a per-turn reset): keep an already-armed deadline so it
        // actually counts down across turns. `beginNextRound`/pause seed the fresh/resume cases.
        let deadline = RoundTimerScheduler.deadline(
            now: Date(),
            existing: roundDeadline,
            pausedRemaining: pausedRoundRemaining,
            limit: presenter.state.ruleProfile.roundTimeLimitSeconds)
        pausedRoundRemaining = nil
        roundDeadline = deadline
        guard let deadline else { return }
        startTickingIfNeeded()
        let remaining = max(0, deadline.timeIntervalSinceNow)
        roundTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let effects = self.presenter.roundTimerExpired()
            self.roundDeadline = nil
            self.handle(effects)
            self.updateHandoff()
            self.publishViewState()
            self.checkRoundEnd()
        }
    }

    /// Per-move wall-clock fallback (`RuleProfile.moveTimeLimitSeconds`) for the local human
    /// only — forces a random legal move if they haven't acted in time.
    private func scheduleMoveTimerIfNeeded() {
        moveTimerTask?.cancel()
        moveDeadline = nil
        // Paused while a pass-the-device handoff is on screen — the receiving player
        // shouldn't lose move time before they've even taken the device.
        // In pass-and-play the timer applies to whichever human is currently to act (either end);
        // otherwise only to the single displayed human.
        let acting: UUID? = isPassAndPlay ? currentHumanID
            : (presenter.state.currentPlayer?.id == displayedHumanID ? displayedHumanID : nil)
        guard presenter.state.phase == .playing,
              presenter.state.pendingDecision == nil,
              pendingHandoffSeat == nil,
              let actingID = acting else { return }
        // 10s per move, tightening to 5s in the round's final minute (Phase 17 C10); ~1s under
        // the `--uitest-fast-timers` affordance (see `moveTimeLimit`).
        let seconds = moveTimeLimit
        guard seconds > 0 else { return }
        moveDeadline = Date().addingTimeInterval(seconds)
        startTickingIfNeeded()
        moveTimerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            let effects = self.presenter.forceTimedOutMove(for: actingID)
            self.moveDeadline = nil
            self.turnsThisRound += 1
            self.handle(effects)
            self.updateHandoff()
            self.publishViewState()
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
                PerfSignpost.event("timerTick")   // Tier-0d redraw suspect: 5 Hz countdown republish (R7)
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
              let winState = presenter.state.winState else { return }
        roundResultRecorded = true
        let localTeam = presenter.state.players.first { $0.id == localPlayerID }?.teamID
        let difficulty = presenter.state.players.first { $0.role == .ai }?.difficulty ?? .easy
        onRoundEnd(RoundResult(
            localTeamWon: winState.winningTeam == localTeam,
            difficulty: difficulty,
            turns: turnsThisRound,
            roundPoints: winState.roundPoints ?? 0,
            multiplier: winState.scoreMultiplier ?? 1))
    }

    private func handle(_ effects: [GameEffect]) {
        for effect in effects {
            switch effect {
            case .animateCardPlay(let card, let from):
                haptics.cardPlay()
                sound.play(soundEffect(forCardPlay: card))
                emitCardFlight(card, from: from)
            case .animateCardDraw(let to, let count):
                if to == displayedHumanID { haptics.cardDrawn() }
                sound.play(.cardDraw)
                emitDrawFlight(to: to, count: count)
                // Surface a penalty draw (2+ cards forced by a stack/effect) on the target seat.
                if count >= 2 { emitSeatCue([to], .drew(count)) }
            case .animateSkip(let pid):
                emitSeatCue([pid], .skipped)
            case .animateSkipTwo(let first, let second):
                emitSeatCue([first, second], .skipped)
            case .animateCardShuffle:            sound.play(.cardShuffle)
            case .animateHandSwap:               sound.play(.swapHands)
            case .announceSolo(let name):
                announce(soloAnnouncement(for: name))
            case .soloCallMissed(let name, let penalty):
                haptics.drawPenalty()
                sound.play(.soloMissed)
                // A local catch supplies the exact ID. AI catches arrive only with the engine's
                // display name, so fall back to the existing player list to keep the presentation
                // stamp visible for every successful catch without creating new rules state.
                let targetID = pendingSoloCallOutTargetID
                    ?? presenter.state.players.first(where: { $0.name == name })?.id
                if let targetID {
                    emitSoloPenalty(to: targetID, count: penalty)
                }
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

    private func emitSeatCue(_ seatIDs: [UUID], _ kind: SeatCueKind) {
        seatCueToken += 1
        seatCue = SeatCueEvent(seatIDs: seatIDs, kind: kind, token: seatCueToken)
    }

    private func emitCardFlight(_ card: Card, from seatID: UUID) {
        cardFlightToken += 1
        cardFlight = CardFlightEvent(card: card, fromSeatID: seatID, token: cardFlightToken)
    }

    private func emitDrawFlight(to seatID: UUID, count: Int) {
        drawFlightToken += 1
        drawFlight = DrawFlightEvent(toSeatID: seatID, count: count, token: drawFlightToken)
    }

    private func emitSoloPenalty(to seatID: UUID, count: Int) {
        soloPenaltyToken += 1
        soloPenalty = SoloPenaltyEvent(seatID: seatID, count: count, token: soloPenaltyToken)
    }

    /// Posts a VoiceOver live-region announcement without moving the accessibility cursor
    /// (accessibility-plan.md §2 — Solo!/round-end events must announce automatically).
    private func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func relation(toPlayerNamed name: String) -> String {
        guard let player = presenter.state.players.first(where: { $0.name == name }) else { return name }
        if player.id == displayedHumanID { return "you" }
        let localTeam = presenter.state.players.first { $0.id == displayedHumanID }?.teamID
        return player.teamID == localTeam ? "partner" : name
    }

    private func soloAnnouncement(for name: String) -> String {
        switch relation(toPlayerNamed: name) {
        case "you":     return "Solo called!"
        case "partner": return "Your partner called Solo!"
        default:        return "\(name) called Solo!"
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
        case .drawTwo, .drawEight:            return .drawTwoPlayed
        case .drawFour, .changeColour:        return .wildPlayed
        case .number, .discardAll, .discardColour, .targetedDraw, .forcedSwap, .teamPlay:
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

/// Tier-0d perf instrumentation (ruling R7): signposts on the redraw/timer suspects so an
/// Instruments "os_signpost" (Points of Interest) run can quantify view-publish and timer-tick
/// frequency after the redesign patch lands. DEBUG-only — compiles to nothing in release, and
/// uses on-device os logging only (no telemetry, no network). See docs/phase-18-perf/.
enum PerfSignpost {
    #if DEBUG
    private static let signposter = OSSignposter(subsystem: "com.wildpairs.perf", category: .pointsOfInterest)
    #endif
    @inline(__always) static func event(_ name: StaticString) {
        #if DEBUG
        signposter.emitEvent(name)
        #endif
    }
}
