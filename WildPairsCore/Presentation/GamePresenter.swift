import Foundation

// MARK: - GamePresenter
//
// The platform-agnostic orchestration layer between the SwiftUI ViewModel and the pure
// engine. It owns the current `GameState`, applies actions, triggers autosave, and decides
// the next automatic (AI) action deterministically. It deliberately uses no Combine /
// ObservableObject so it compiles and is fully unit-testable on any Swift toolchain.
//
// The SwiftUI `GameViewModel` (app target) is a thin @MainActor wrapper that owns one of
// these, republishes `viewState` via @Published, and handles only timing (AI think delay,
// Solo! timeout) and effect playback (animation / haptics / sound).

public final class GamePresenter {

    public private(set) var state: GameState
    public let localPlayerID: UUID

    /// Optional persistence. When present, `dispatch` autosaves on `.triggerAutosave`.
    private let persistence: PersistenceService?

    public init(state: GameState, localPlayerID: UUID, persistence: PersistenceService? = nil) {
        self.state = state
        self.localPlayerID = localPlayerID
        self.persistence = persistence
    }

    /// Convenience: start a fresh game from a config.
    public convenience init(
        config: GameConfig,
        localPlayerID: UUID? = nil,
        persistence: PersistenceService? = nil
    ) {
        let (state, _) = GameEngine.reduce(state: GameState(players: []), action: .newGame(config: config))
        let localID = localPlayerID
            ?? state.players.first(where: { $0.role == .human })?.id
            ?? state.players.first!.id
        self.init(state: state, localPlayerID: localID, persistence: persistence)
    }

    // MARK: Derived view-state

    public var viewState: GameViewState {
        GameViewState(from: state, localPlayerID: localPlayerID)
    }

    /// Perspective-flipped view-state for pass-and-play: derive the table as seen by any
    /// human seat (the active human renders at the bottom via `tablePosition`).
    public func viewState(for playerID: UUID) -> GameViewState {
        GameViewState(from: state, localPlayerID: playerID)
    }

    /// The human player the game is currently waiting on — their turn, or a pending
    /// decision they own. Nil while an AI acts or the round is over. Drives the
    /// pass-the-device handoff in two-human games; in single-human games this is always
    /// either `localPlayerID` or nil.
    public func humanAwaitingInput() -> UUID? {
        guard state.phase == .playing || state.phase == .teamPass else { return nil }
        switch state.pendingDecision {
        case .colourChoice(let pid), .teamPass(let pid):
            return humanPlayer(pid)?.id
        case .targetChoice(let pid, _):
            return humanPlayer(pid)?.id
        case .drawFourChallenge:
            return nil
        case .none:
            break
        }
        guard let current = state.currentPlayer, current.role == .human else { return nil }
        return current.id
    }

    // MARK: Dispatch

    /// Applies an action through the engine, updates state, and autosaves when requested.
    @discardableResult
    public func dispatch(_ action: GameAction) -> [GameEffect] {
        let (next, effects) = GameEngine.reduce(state: state, action: action)
        state = next
        if let persistence, effects.contains(where: { $0 == .triggerAutosave }) {
            try? persistence.saveGame(GameSnapshot(state: state))
        }
        return effects
    }

    // MARK: Automatic (AI) progression

    /// True when the game is waiting on the local human (their turn or their pending choice),
    /// or has ended. When false, `nextAutomaticAction()` returns a non-nil AI action.
    public var isWaitingForLocalPlayer: Bool {
        nextAutomaticAction() == nil && (state.phase == .playing)
    }

    /// The next action an AI should take, or nil if it is the local player's move / a choice
    /// the local player must make / the game is not in play. Deterministic: AI RNG is derived
    /// from the game seed and action count, exactly like the engine's per-action RNG.
    public func nextAutomaticAction() -> GameAction? {
        guard state.phase == .playing || state.phase == .teamPass else { return nil }

        var rng = derivedRNG()

        // Resolve a pending decision owned by an AI player first.
        switch state.pendingDecision {
        case .colourChoice(let pid):
            guard let player = aiPlayer(pid) else { return nil }
            let colour = AIPlayer.selectColour(observation: observation(for: pid),
                                               difficulty: player.difficulty, rng: &rng)
            return .selectColour(colour, playerID: pid)
        case .targetChoice(let pid, let targets):
            guard let player = aiPlayer(pid) else { return nil }
            let target = AIPlayer.selectTarget(observation: observation(for: pid),
                                               validTargets: targets,
                                               difficulty: player.difficulty, rng: &rng)
            return .selectTarget(targetPlayerID: target, playerID: pid)
        case .teamPass(let pid):
            guard let player = aiPlayer(pid) else { return nil }
            let card = AIPlayer.selectTeamPassCard(observation: observation(for: pid),
                                                   difficulty: player.difficulty, rng: &rng)
            return .submitTeamPass(playerID: pid, card: card)
        case .drawFourChallenge:
            return nil
        case .none:
            break
        }

        // Otherwise it is a turn. Only automate AI turns.
        guard let current = state.currentPlayer, current.role == .ai else { return nil }
        return AIPlayer.chooseMove(observation: observation(for: current.id),
                                   difficulty: current.difficulty, rng: &rng)
    }

    /// Applies one automatic AI action if one is available. Returns the effects, or nil if it
    /// is the local player's move. Use in a loop to fast-forward all consecutive AI turns.
    @discardableResult
    public func advanceAutomatic() -> [GameEffect]? {
        guard let action = nextAutomaticAction() else { return nil }
        // Defence in depth (Phase 17 A2/A3): never dispatch an illegal AI card play. Legality
        // is centralised in GameRules and shared with the AI, so this should not fire — but if
        // an AI ever proposes an illegal card, fall back to drawing (mirrors GameSimulator's
        // guard) so a bad move can never mutate state.
        if case .playCard(_, let playerID) = action,
           !GameEngine.isLegalMove(state: state, action: action) {
            return dispatch(.drawCard(playerID: playerID))
        }
        return dispatch(action)
    }

    // MARK: Local player intents (thin wrappers for clarity at the call site)
    // `as playerID:` selects which human acts — pass-and-play forwards the displayed
    // human's ID; the default keeps single-human call sites unchanged.

    @discardableResult public func play(_ card: Card, as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.playCard(card, playerID: playerID ?? localPlayerID))
    }
    @discardableResult public func draw(as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.drawCard(playerID: playerID ?? localPlayerID))
    }
    @discardableResult public func chooseColour(_ colour: CardColour, as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.selectColour(colour, playerID: playerID ?? localPlayerID))
    }
    @discardableResult public func chooseTarget(_ targetID: UUID, as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.selectTarget(targetPlayerID: targetID, playerID: playerID ?? localPlayerID))
    }
    /// Submits a Side-to-Side Team Pass choice — `card` from the acting player's hand to
    /// give to their partner, or nil to decline.
    @discardableResult public func passTeamCard(_ card: Card?, as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.submitTeamPass(playerID: playerID ?? localPlayerID, card: card))
    }
    @discardableResult public func callSolo(as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.callSolo(playerID: playerID ?? localPlayerID))
    }
    @discardableResult public func callOut(_ targetID: UUID, as playerID: UUID? = nil) -> [GameEffect] {
        dispatch(.callOutSolo(targetPlayerID: targetID, callerID: playerID ?? localPlayerID))
    }
    @discardableResult public func beginNewRound() -> [GameEffect] {
        dispatch(.beginNewRound)
    }

    /// Call when the round's wall-clock timer (`RuleProfile.roundTimeLimitSeconds`) elapses
    /// with nobody having emptied their hand. No-op if the round already ended.
    @discardableResult public func roundTimerExpired() -> [GameEffect] {
        dispatch(.roundTimerExpired)
    }

    /// Forces a random legal move for `playerID` (same fallback `EasyAI` uses), for when their
    /// per-move timer (`RuleProfile.moveTimeLimitSeconds`) elapses without input. Scoped to the
    /// current turn only — a no-op if it isn't this player's turn or a decision is pending.
    @discardableResult public func forceTimedOutMove(for playerID: UUID) -> [GameEffect] {
        guard state.phase == .playing, state.pendingDecision == nil,
              state.currentPlayer?.id == playerID else { return [] }
        var rng = derivedRNG()
        let action = EasyAI.chooseMove(observation: observation(for: playerID), rng: &rng)
        return dispatch(action)
    }

    // MARK: Private

    /// A fresh RNG derived from the game's seed and current action count — matches the
    /// engine's scheme so AI behaviour is reproducible from a saved snapshot.
    private func derivedRNG() -> SeededRNG {
        SeededRNG(seed: state.rngSeed &+ UInt64(state.actionCount))
    }

    private func observation(for playerID: UUID) -> AIObservation {
        AIObservation(from: state, for: playerID)
    }

    private func aiPlayer(_ id: UUID) -> Player? {
        state.players.first { $0.id == id && $0.role == .ai }
    }

    private func humanPlayer(_ id: UUID) -> Player? {
        state.players.first { $0.id == id && $0.role == .human }
    }
}
