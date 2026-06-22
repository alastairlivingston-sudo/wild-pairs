import Foundation

// MARK: - GameConfig

/// Configuration provided when starting a new game.
public struct GameConfig: Codable, Equatable, Sendable {
    public let mode: GameMode
    public let players: [PlayerConfig]
    public let ruleProfile: RuleProfile
    public let seed: UInt64?  // nil = generate from system RNG

    public init(
        mode: GameMode,
        players: [PlayerConfig],
        ruleProfile: RuleProfile,
        seed: UInt64? = nil
    ) {
        self.mode = mode
        self.players = players
        self.ruleProfile = ruleProfile
        self.seed = seed
    }
}

/// Configuration for a single player seat in a new game.
public struct PlayerConfig: Codable, Equatable, Sendable {
    public let name: String
    public let role: PlayerRole
    public let teamID: TeamID
    public let difficulty: Difficulty
    public let seatPosition: Int

    public init(
        name: String,
        role: PlayerRole,
        teamID: TeamID,
        difficulty: Difficulty = .medium,
        seatPosition: Int
    ) {
        self.name = name
        self.role = role
        self.teamID = teamID
        self.difficulty = difficulty
        self.seatPosition = seatPosition
    }
}

// MARK: - GameAction

/// Every possible input that can advance the game state machine.
///
/// `GameAction` is a value type so that action sequences can be recorded,
/// logged, replayed, and tested without side effects.
///
/// All cases conform to `Codable` to support action-sequence serialisation.
public enum GameAction: Codable, Equatable, Sendable {

    // MARK: Normal Turn Actions

    /// The specified player plays a card from their hand.
    case playCard(Card, playerID: UUID)

    /// The specified player draws one card from the draw pile.
    case drawCard(playerID: UUID)

    /// The specified player passes their turn without drawing (only legal in certain rule configurations).
    case passTurn(playerID: UUID)

    // MARK: Decision Resolution

    /// The specified player selects a new active colour (follows drawFour or changeColour).
    case selectColour(CardColour, playerID: UUID)

    /// The specified player nominates a target (follows targetedDraw, forcedSwap, skipTwo).
    case selectTarget(targetPlayerID: UUID, playerID: UUID)

    // MARK: Team Actions

    /// The specified player invokes team pass, allowing their partner to play a card this turn.
    case teamPass(playerID: UUID)

    // MARK: Solo Call

    /// The specified player announces "Solo!" declaring they hold exactly one card.
    case callSolo(playerID: UUID)

    /// `callerID` calls out `targetPlayerID` for failing to declare Solo! while holding
    /// exactly one card. If valid, the target draws the Solo! penalty cards.
    case callOutSolo(targetPlayerID: UUID, callerID: UUID)

    // MARK: Challenge

    /// The specified player challenges the draw-four card just played, claiming the player
    /// had a legal alternative play.
    case challengeDrawFour(challengerID: UUID)

    // MARK: Game Control

    /// Pause the game (e.g., app goes to background).
    case pauseGame

    /// Resume the game after a pause.
    case resumeGame

    /// Start a completely new game with the given configuration.
    case newGame(config: GameConfig)

    /// Restore a previously saved game from a snapshot.
    case restoreSnapshot(GameSnapshot)

    /// Advance past a pending AI decision that has been computed externally.
    case advancePendingDecision

    // MARK: AI

    /// Wraps an AI-computed action before it is dispatched into the engine.
    /// The engine unwraps and processes the inner action. Separate from `.playCard`
    /// so that the ViewModel can distinguish human from AI moves for animation pacing.
    indirect case aiMove(GameAction, playerID: UUID)

    // MARK: Round Control

    /// Begin dealing cards for a new round (called by ViewModel after round-end animation).
    case beginNewRound

    /// The round's wall-clock timer (`RuleProfile.roundTimeLimitSeconds`) elapsed with nobody
    /// having emptied their hand. The engine decides the round by lowest card-point score.
    case roundTimerExpired

    // MARK: Debug (Debug builds only)

    /// Directly overwrite the game state. Available only in debug builds.
    /// The engine rejects this action silently in production.
    case forceState(GameState)
}
