import Foundation

// MARK: - GameStateBuilder

/// Fluent builder that constructs minimal GameState values for testing.
/// Not for production use — lives in WildPairsCore so test targets can access it
/// without importing a separate testing module.
public final class GameStateBuilder {

    private var players: [Player] = []
    private var mode: GameMode = .standardTeams
    private var ruleProfile: RuleProfile = .standardTeams()
    private var currentColour: CardColour = .crimson
    private var currentCardType: CardType? = nil
    private var topDiscard: Card? = nil
    private var drawPile: [Card] = []
    private var direction: TurnDirection = .clockwise
    private var currentPlayerIndex: Int = 0
    private var pendingDecision: PendingDecision? = nil
    private var phase: GamePhase = .playing
    private var teamScores: [TeamID: Int] = [.teamA: 0, .teamB: 0]
    private var rngSeed: UInt64 = 42
    private var roundNumber: Int = 1

    public init() {}

    // MARK: Fluent setters

    /// Creates 4 default players using the canonical seat→team mapping.
    @discardableResult
    public func withPlayers(_ count: Int = 4) -> GameStateBuilder {
        let teams: [TeamID] = [.teamA, .teamB, .teamA, .teamB]
        let roles: [PlayerRole] = [.human, .ai, .ai, .ai]
        players = (0..<count).map { i in
            Player(
                name: ["You", "Left", "Partner", "Right"][i % 4],
                role: roles[i % 4],
                teamID: teams[i % 4],
                difficulty: .easy,
                seatPosition: i
            )
        }
        return self
    }

    @discardableResult
    public func withMode(_ mode: GameMode) -> GameStateBuilder {
        self.mode = mode
        return self
    }

    @discardableResult
    public func withRuleProfile(_ profile: RuleProfile) -> GameStateBuilder {
        self.ruleProfile = profile
        return self
    }

    @discardableResult
    public func withCurrentColour(_ colour: CardColour) -> GameStateBuilder {
        self.currentColour = colour
        return self
    }

    @discardableResult
    public func withCurrentCardType(_ type: CardType?) -> GameStateBuilder {
        self.currentCardType = type
        return self
    }

    @discardableResult
    public func withTopDiscard(_ card: Card) -> GameStateBuilder {
        self.topDiscard = card
        self.currentColour = card.colour ?? currentColour
        self.currentCardType = card.type
        return self
    }

    @discardableResult
    public func withDrawPile(_ cards: [Card]) -> GameStateBuilder {
        self.drawPile = cards
        return self
    }

    @discardableResult
    public func withHand(forPlayer seatIndex: Int, cards: [Card]) -> GameStateBuilder {
        guard players.indices.contains(seatIndex) else { return self }
        players[seatIndex].hand = cards
        return self
    }

    @discardableResult
    public func withCurrentPlayer(_ seatIndex: Int) -> GameStateBuilder {
        self.currentPlayerIndex = seatIndex
        return self
    }

    @discardableResult
    public func withTurnDirection(_ direction: TurnDirection) -> GameStateBuilder {
        self.direction = direction
        return self
    }

    @discardableResult
    public func withPendingDecision(_ decision: PendingDecision?) -> GameStateBuilder {
        self.pendingDecision = decision
        return self
    }

    @discardableResult
    public func withPhase(_ phase: GamePhase) -> GameStateBuilder {
        self.phase = phase
        return self
    }

    @discardableResult
    public func withRngSeed(_ seed: UInt64) -> GameStateBuilder {
        self.rngSeed = seed
        return self
    }

    @discardableResult
    public func withFinished(playerAtSeat seat: Int) -> GameStateBuilder {
        guard players.indices.contains(seat) else { return self }
        players[seat].hasFinishedRound = true
        players[seat].hand = []
        return self
    }

    // MARK: Build

    public func build() -> GameState {
        if players.isEmpty { _ = withPlayers(4) }

        var discardPile: [Card] = []
        if let top = topDiscard { discardPile = [top] }

        return GameState(
            schemaVersion: 1,
            players: players,
            currentPlayerIndex: currentPlayerIndex,
            turnDirection: direction,
            currentColour: currentColour,
            currentCardType: currentCardType,
            pendingDecision: pendingDecision,
            deck: Deck(drawPile: drawPile, discardPile: discardPile),
            phase: phase,
            mode: mode,
            ruleProfile: ruleProfile,
            roundNumber: roundNumber,
            teamScores: teamScores,
            winState: nil,
            rngSeed: rngSeed,
            actionCount: 0,
            eventLog: []
        )
    }
}
