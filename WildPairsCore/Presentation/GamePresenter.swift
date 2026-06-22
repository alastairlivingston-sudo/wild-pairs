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
        guard state.phase == .playing else { return nil }

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
        case .teamPass, .drawFourChallenge:
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
        return dispatch(action)
    }

    // MARK: Local player intents (thin wrappers for clarity at the call site)

    @discardableResult public func play(_ card: Card) -> [GameEffect] {
        dispatch(.playCard(card, playerID: localPlayerID))
    }
    @discardableResult public func draw() -> [GameEffect] {
        dispatch(.drawCard(playerID: localPlayerID))
    }
    @discardableResult public func chooseColour(_ colour: CardColour) -> [GameEffect] {
        dispatch(.selectColour(colour, playerID: localPlayerID))
    }
    @discardableResult public func chooseTarget(_ targetID: UUID) -> [GameEffect] {
        dispatch(.selectTarget(targetPlayerID: targetID, playerID: localPlayerID))
    }
    @discardableResult public func callSolo() -> [GameEffect] {
        dispatch(.callSolo(playerID: localPlayerID))
    }
    @discardableResult public func callOut(_ targetID: UUID) -> [GameEffect] {
        dispatch(.callOutSolo(targetPlayerID: targetID, callerID: localPlayerID))
    }
    @discardableResult public func beginNewRound() -> [GameEffect] {
        dispatch(.beginNewRound)
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
}
