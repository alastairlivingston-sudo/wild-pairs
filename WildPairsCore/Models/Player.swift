import Foundation

// MARK: - PlayerRole

/// Whether a player seat is controlled by a human or the AI.
public enum PlayerRole: String, Codable, Equatable, Sendable {
    case human
    case ai
}

// MARK: - TeamID

/// The two teams in a standard Wild Pairs game.
public enum TeamID: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case teamA
    case teamB

    /// The opposing team.
    public var opponent: TeamID {
        switch self {
        case .teamA: return .teamB
        case .teamB: return .teamA
        }
    }

    /// A human-readable display name.
    public var displayName: String {
        switch self {
        case .teamA: return "Team A"
        case .teamB: return "Team B"
        }
    }
}

// MARK: - Difficulty

/// AI difficulty level. Applies only to players with role `.ai`.
public enum Difficulty: String, Codable, CaseIterable, Equatable, Sendable {
    case easy
    case medium
    case hard
    case expert
    /// Top tier: same strategy as `.expert`, highest score multiplier.
    case master

    /// Score multiplier applied to round-win points when this difficulty is the toughest
    /// opponent faced in the match. Rewards beating harder AI.
    public var scoreMultiplier: Int {
        switch self {
        case .easy:   return 1
        case .medium: return 2
        case .hard:   return 4
        case .expert: return 8
        case .master: return 24
        }
    }
}

// MARK: - TeamState

/// A snapshot of team membership and seating used by both the engine and AI.
public struct TeamState: Codable, Equatable, Sendable {

    /// All player IDs and their team assignments.
    public let assignments: [UUID: TeamID]

    /// Player IDs in seat order. Dictionary iteration order depends on each UUID's hash,
    /// which varies between otherwise-identical games (player IDs are freshly random per
    /// deal), so any ordering AI/UI relies on for deterministic tie-breaks must come from
    /// this seat-ordered list rather than from iterating `assignments` directly.
    public let orderedPlayerIDs: [UUID]

    /// Returns the team for a given player, or nil if player is not found.
    public func team(for playerID: UUID) -> TeamID? {
        assignments[playerID]
    }

    /// Returns all player IDs on a given team, in seat order.
    public func players(on team: TeamID) -> [UUID] {
        orderedPlayerIDs.filter { assignments[$0] == team }
    }

    /// Returns the partner's player ID for the given player, if one exists.
    public func partnerID(for playerID: UUID) -> UUID? {
        guard let myTeam = assignments[playerID] else { return nil }
        return orderedPlayerIDs.first { $0 != playerID && assignments[$0] == myTeam }
    }

    public init(assignments: [UUID: TeamID], orderedPlayerIDs: [UUID]) {
        self.assignments = assignments
        self.orderedPlayerIDs = orderedPlayerIDs
    }
}

// MARK: - Player

/// A single player seat in a Wild Pairs game.
public struct Player: Codable, Equatable, Identifiable, Sendable {

    // MARK: Identity

    /// Stable unique identifier for this player across saves.
    public let id: UUID

    /// Display name shown in the UI.
    public let name: String

    /// Whether this seat is human-controlled or AI-controlled.
    public let role: PlayerRole

    /// The team this player belongs to.
    public let teamID: TeamID

    /// AI difficulty; ignored when `role == .human`.
    public let difficulty: Difficulty

    // MARK: Seating

    /// Physical seat position (0–3, clockwise from bottom/local player).
    /// Seat 0 is always the local human player.
    public let seatPosition: Int

    // MARK: Hand

    /// The cards currently held by this player.
    public var hand: [Card]

    // MARK: Game State Flags

    /// True once this player has called "Solo!" to declare they have one card left.
    public var hasCalledSolo: Bool

    /// True if this player has played their last card and exited this round.
    public var hasFinishedRound: Bool

    // MARK: Computed Properties

    /// The number of cards in hand.
    public var handCount: Int {
        hand.count
    }

    /// True when the player holds exactly one card and has not yet called Solo.
    public var mustCallSolo: Bool {
        hand.count == 1 && !hasCalledSolo
    }

    // MARK: Initialiser

    public init(
        id: UUID = UUID(),
        name: String,
        role: PlayerRole,
        teamID: TeamID,
        difficulty: Difficulty = .medium,
        seatPosition: Int,
        hand: [Card] = [],
        hasCalledSolo: Bool = false,
        hasFinishedRound: Bool = false
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.teamID = teamID
        self.difficulty = difficulty
        self.seatPosition = seatPosition
        self.hand = hand
        self.hasCalledSolo = hasCalledSolo
        self.hasFinishedRound = hasFinishedRound
    }
}
