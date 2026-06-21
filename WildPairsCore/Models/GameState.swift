import Foundation

// MARK: - Supporting Enums

/// Direction of turn progression around the table.
public enum TurnDirection: String, Codable, Equatable, Sendable {
    case clockwise
    case counterClockwise
}

/// The current phase of the game lifecycle.
public enum GamePhase: String, Codable, Equatable, Sendable {
    case dealing       // Cards are being dealt; no actions yet
    case playing       // Active round in progress
    case roundEnded    // A round has finished; scoring in progress
    case gameEnded     // The game has a winner
}

/// The three game modes available in Wild Pairs.
public enum GameMode: String, Codable, CaseIterable, Equatable, Sendable {
    /// Two teams of two; both teammates must empty hands to win the round.
    case standardTeams
    /// All-Wild variant; every draw pile card starts face-up or wild-eligible.
    case allWild
    /// Side-to-side variant; seating partners alternate rather than diagonal.
    case sideToSide
}

/// A decision that requires player input before the game can continue.
public enum PendingDecision: Codable, Equatable, Sendable {
    /// The player with this ID must choose a new active colour.
    case colourChoice(playerID: UUID)
    /// The player with this ID must choose a target from the valid list.
    case targetChoice(playerID: UUID, validTargets: [UUID])
    /// The player with this ID may invoke team pass (their teammate plays a card).
    case teamPass(playerID: UUID)
    /// A challenged draw-four is awaiting resolution.
    case drawFourChallenge(challengerID: UUID, challengedID: UUID)
}

/// The result recorded when a game or round ends.
public struct WinState: Codable, Equatable, Sendable {
    public let winningTeam: TeamID
    public let winningPlayerID: UUID?  // nil if team win not triggered by single player
    public let reason: WinReason
    public let finalScores: [TeamID: Int]

    public init(
        winningTeam: TeamID,
        winningPlayerID: UUID?,
        reason: WinReason,
        finalScores: [TeamID: Int]
    ) {
        self.winningTeam = winningTeam
        self.winningPlayerID = winningPlayerID
        self.reason = reason
        self.finalScores = finalScores
    }
}

/// How a win was achieved.
public enum WinReason: String, Codable, Equatable, Sendable {
    case bothTeammatesEmptiedHands
    case singlePlayerEmptiedHand
    case targetScoreReached
    case opponentSoloCallMissed
}

/// A lightweight debug event recorded in the event log.
public struct GameEvent: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let playerID: UUID?
    public let description: String

    public init(playerID: UUID?, description: String) {
        self.timestamp = Date()
        self.playerID = playerID
        self.description = description
    }
}

// MARK: - GameState

/// The complete, serialisable state of a Wild Pairs game at any point in time.
///
/// `GameState` is a pure value type. The engine never mutates it in place;
/// it always returns a new value. Every field that changes during play is
/// represented here — there is no mutable global state.
public struct GameState: Codable, Equatable, Sendable {

    // MARK: Schema

    /// Schema version for migration. Increment when breaking changes are made to this struct.
    public let schemaVersion: Int

    // MARK: Players & Seating

    /// All player seats in table order (seat 0 = local human, proceeding clockwise).
    public var players: [Player]

    // MARK: Turn Management

    /// Index into `players` indicating whose turn it currently is.
    public var currentPlayerIndex: Int

    /// Direction of turn progression.
    public var turnDirection: TurnDirection

    // MARK: Active Card State

    /// The colour that must be matched by the next card played, unless wild.
    public var currentColour: CardColour

    /// The type of the most recently played card. Nil after colour-change cards resolve.
    public var currentCardType: CardType?

    // MARK: Pending Decisions

    /// Non-nil when the engine is waiting for a player to make a choice before continuing.
    public var pendingDecision: PendingDecision?

    // MARK: Deck

    /// The draw and discard piles for the current round.
    public var deck: Deck

    // MARK: Game Phase & Mode

    /// The current lifecycle phase of the game.
    public var phase: GamePhase

    /// The game mode for this session.
    public let mode: GameMode

    /// The full rule configuration governing this game.
    public var ruleProfile: RuleProfile

    // MARK: Scoring & Rounds

    /// 1-based counter of the current round.
    public var roundNumber: Int

    /// Cumulative team scores across all completed rounds.
    public var teamScores: [TeamID: Int]

    // MARK: Win State

    /// Populated when `phase` transitions to `.roundEnded` or `.gameEnded`.
    public var winState: WinState?

    // MARK: Randomness

    /// The seed used to initialise the RNG for this game.
    /// Stored here so the game can be resumed or replayed identically.
    public let rngSeed: UInt64

    /// Total number of actions that have been dispatched in this game.
    /// Used to fast-forward the RNG to the correct position after restoring from a snapshot.
    public var actionCount: Int

    // MARK: Debug Event Log

    /// A capped ring buffer of game events for debugging.
    /// Never used in production logic. Excluded from `Equatable` comparison.
    public var eventLog: [GameEvent]

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, players, currentPlayerIndex, turnDirection
        case currentColour, currentCardType, pendingDecision, deck
        case phase, mode, ruleProfile, roundNumber, teamScores
        case winState, rngSeed, actionCount, eventLog
    }

    // Custom Equatable to exclude eventLog from equality checks
    public static func == (lhs: GameState, rhs: GameState) -> Bool {
        lhs.schemaVersion == rhs.schemaVersion &&
        lhs.players == rhs.players &&
        lhs.currentPlayerIndex == rhs.currentPlayerIndex &&
        lhs.turnDirection == rhs.turnDirection &&
        lhs.currentColour == rhs.currentColour &&
        lhs.currentCardType == rhs.currentCardType &&
        lhs.pendingDecision == rhs.pendingDecision &&
        lhs.deck == rhs.deck &&
        lhs.phase == rhs.phase &&
        lhs.mode == rhs.mode &&
        lhs.ruleProfile == rhs.ruleProfile &&
        lhs.roundNumber == rhs.roundNumber &&
        lhs.teamScores == rhs.teamScores &&
        lhs.winState == rhs.winState &&
        lhs.rngSeed == rhs.rngSeed &&
        lhs.actionCount == rhs.actionCount
        // eventLog intentionally excluded
    }

    // MARK: Computed Properties

    /// The player whose turn it currently is.
    public var currentPlayer: Player? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex]
    }

    /// A lightweight view of team membership, suitable for AI and UI.
    public var teamState: TeamState {
        let assignments = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0.teamID) })
        return TeamState(assignments: assignments)
    }

    // MARK: Initialiser

    public init(
        schemaVersion: Int = 1,
        players: [Player],
        currentPlayerIndex: Int = 0,
        turnDirection: TurnDirection = .clockwise,
        currentColour: CardColour = .crimson,
        currentCardType: CardType? = nil,
        pendingDecision: PendingDecision? = nil,
        deck: Deck = Deck(),
        phase: GamePhase = .dealing,
        mode: GameMode = .standardTeams,
        ruleProfile: RuleProfile = .standardTeams(),
        roundNumber: Int = 1,
        teamScores: [TeamID: Int] = [.teamA: 0, .teamB: 0],
        winState: WinState? = nil,
        rngSeed: UInt64 = 0,
        actionCount: Int = 0,
        eventLog: [GameEvent] = []
    ) {
        self.schemaVersion = schemaVersion
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnDirection = turnDirection
        self.currentColour = currentColour
        self.currentCardType = currentCardType
        self.pendingDecision = pendingDecision
        self.deck = deck
        self.phase = phase
        self.mode = mode
        self.ruleProfile = ruleProfile
        self.roundNumber = roundNumber
        self.teamScores = teamScores
        self.winState = winState
        self.rngSeed = rngSeed
        self.actionCount = actionCount
        self.eventLog = eventLog
    }
}
