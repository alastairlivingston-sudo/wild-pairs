import Foundation

// MARK: - AIObservation

/// A filtered, read-only view of `GameState` that contains only the information
/// a fair AI player is permitted to see.
///
/// ## Fairness Guarantee
///
/// `AIObservation` is the **only** input passed to any AI implementation.
/// It deliberately omits the hand contents of every player except the AI's
/// own player and its teammate — mirroring what a human player can observe
/// at the table, where partner hands are open by design (see
/// `docs/game-rules.md` Team Communication Rules).
///
/// AI implementations must never:
/// - Receive or inspect a full `GameState` directly.
/// - Access opponent hand contents through any other path.
/// - Use the RNG state or draw pile order.
///
/// ## Construction
///
/// Call `init(from:for:)` inside the engine or ViewModel, immediately before
/// invoking the AI. The constructor filters the state automatically.
public struct AIObservation: Sendable {

    // MARK: Public Game State (visible to all players)

    /// All cards on the discard pile, in play order (oldest first, newest last).
    /// Enables card counting for Hard and Expert AI.
    public let discardPile: [Card]

    /// The colour that must be matched by the next card played.
    public let currentColour: CardColour

    /// The type of the most recently played card, if still relevant (e.g., pending draw).
    public let currentCardType: CardType?

    /// The number of cards each player currently holds.
    /// Keys are player IDs. Values are hand sizes only — not hand contents.
    public let cardCounts: [UUID: Int]

    /// History of all cards played this round, in order.
    /// Equivalent to `discardPile` contents but may include metadata in future.
    public let playedCardHistory: [Card]

    /// Team membership information for all players.
    public let teamState: TeamState

    /// The current round number (1-based).
    public let roundNumber: Int

    /// Cumulative team scores.
    public let teamScores: [TeamID: Int]

    // MARK: Turn Context (public)

    /// The player ID whose turn it currently is.
    public let activePlayerID: UUID

    /// True when `myPlayerID == activePlayerID`.
    public let isMyTurn: Bool

    /// Direction of turn progression around the table.
    public let turnDirection: TurnDirection

    // MARK: Mode and Rules (public)

    /// The game mode for this session.
    public let mode: GameMode

    /// The full rule configuration for this game.
    public let ruleProfile: RuleProfile

    // MARK: Own Hand Only (private to this AI player)

    /// The AI's own hand.
    public let myHand: [Card]

    /// The AI's partner's hand contents — open between teammates by design.
    /// Empty if the AI has no partner. Opponent hands are never exposed.
    public let partnerHand: [Card]

    /// The player ID of the AI receiving this observation.
    public let myPlayerID: UUID

    /// The team the AI belongs to.
    public let myTeamID: TeamID

    // MARK: Derived Convenience Properties

    /// The player ID of the AI's partner on the same team, if one exists.
    public var partnerID: UUID? {
        teamState.partnerID(for: myPlayerID)
    }

    /// The player IDs of all opponents (players on the opposing team).
    public var opponentIDs: [UUID] {
        teamState.players(on: myTeamID.opponent)
    }

    /// The opponent with the fewest cards remaining, or nil if no opponents.
    public var nearestOpponentToWin: UUID? {
        opponentIDs.min(by: {
            cardCounts[$0, default: 99] < cardCounts[$1, default: 99]
        })
    }

    /// Whether the AI currently holds exactly one card.
    public var isAtOneCard: Bool {
        myHand.count == 1
    }

    // MARK: Initialiser (filtered construction from full GameState)

    /// Creates an `AIObservation` by filtering a full `GameState` for the given player.
    ///
    /// Only the specified player's hand and their partner's hand are included.
    /// Opponent hands are replaced with card count values only.
    ///
    /// - Parameters:
    ///   - state: The full game state (accessible only to the engine/ViewModel).
    ///   - playerID: The AI player for whom the observation is being constructed.
    public init(from state: GameState, for playerID: UUID) {
        // TODO: Implement in Phase 4
        // Extract the target player's hand.
        // Build cardCounts by mapping all players to (id, hand.count) — not hand.cards.
        // Copy all public fields verbatim.
        // Deliberately omit all other players' hand contents.
        let targetPlayer = state.players.first(where: { $0.id == playerID })

        self.discardPile = state.deck.discardPile
        self.currentColour = state.currentColour
        self.currentCardType = state.currentCardType
        self.cardCounts = Dictionary(
            uniqueKeysWithValues: state.players.map { ($0.id, $0.handCount) }
        )
        self.playedCardHistory = state.deck.discardPile
        self.teamState = state.teamState
        self.roundNumber = state.roundNumber
        self.teamScores = state.teamScores
        self.activePlayerID = state.currentPlayer?.id ?? playerID
        self.isMyTurn = state.currentPlayer?.id == playerID
        self.turnDirection = state.turnDirection
        self.mode = state.mode
        self.ruleProfile = state.ruleProfile
        self.myHand = targetPlayer?.hand ?? []
        self.myPlayerID = playerID
        self.myTeamID = targetPlayer?.teamID ?? .teamA

        let partnerID = state.teamState.partnerID(for: playerID)
        self.partnerHand = state.players.first(where: { $0.id == partnerID })?.hand ?? []
    }
}
