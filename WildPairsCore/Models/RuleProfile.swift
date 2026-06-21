import Foundation

// MARK: - WinCondition

/// The condition that ends a round.
public enum WinCondition: String, Codable, Equatable, Sendable {
    /// The round ends when both players on the winning team have empty hands.
    case bothTeammatesOut
    /// The round ends when the first player empties their hand.
    case singleOut
}

// MARK: - RuleProfile

/// The complete, validated rule configuration for a Wild Pairs game.
///
/// `RuleProfile` is the single source of truth for all mode-specific and
/// house-rule behaviour. The engine reads rule flags from this struct rather
/// than switching on `GameMode` directly, which means modes are just
/// pre-configured `RuleProfile` values — not special engine code paths.
public struct RuleProfile: Codable, Equatable, Sendable {

    // MARK: Win Condition

    /// Determines what causes a round to end.
    public var winCondition: WinCondition

    /// Total score required to win the overall game. 0 means single-round play.
    public var targetScore: Int

    // MARK: Draw Rules

    /// If true, a player who draws a playable card must immediately play it.
    public var mustPlayAfterDraw: Bool

    /// If true, a player draws cards until they get a playable one (instead of drawing exactly one).
    public var drawUntilPlayable: Bool

    /// If true, players may stack draw-two on draw-two and draw-four on draw-four,
    /// accumulating the draw count for the next player who cannot stack.
    public var stackDrawCards: Bool

    // MARK: Wild Card Rules

    /// If true, a player can challenge a draw-four by claiming the player had another legal play.
    /// If the challenge succeeds, the draw-four player draws 4; if it fails, the challenger draws 6.
    public var drawFourChallengeable: Bool

    // MARK: Special Card Availability

    /// Whether `discardAll` cards are included in the deck.
    public var discardAllEnabled: Bool

    /// Whether `targetedDraw` cards are included in the deck.
    public var targetedDrawEnabled: Bool

    /// Whether `forcedSwap` cards are included in the deck.
    public var forcedSwapEnabled: Bool

    /// Whether `skipTwo` cards are included in the deck.
    public var skipTwoEnabled: Bool

    /// Whether `teamPlay` cards are included in the deck.
    public var teamPlayEnabled: Bool

    // MARK: Card Set

    /// The card set to use when building the deck.
    public var cardSet: CardSet

    // MARK: Hand Size

    /// Number of cards dealt to each player at the start of a round.
    public var initialHandSize: Int

    // MARK: Team Pass

    /// Whether the team pass rule is active.
    public var teamPassEnabled: Bool

    /// Minimum number of turns that must elapse between team pass uses.
    public var teamPassCooldown: Int

    // MARK: Solo Call

    /// Whether players must call "Solo!" when they have one card left.
    public var soloCallEnabled: Bool

    /// Number of penalty cards drawn if a player fails to call Solo before someone challenges.
    public var soloCallPenaltyCards: Int

    // MARK: Validation

    /// Throws a `RuleProfileError` if the profile contains contradictory or invalid rule combinations.
    public func validate() throws {
        // TODO: Implement in Phase 2
        // Check: initialHandSize must be 1–20
        // Check: targetScore >= 0
        // Check: teamPassCooldown >= 0
        // Check: soloCallPenaltyCards >= 0
        // Check: drawUntilPlayable and mustPlayAfterDraw are compatible
        // Check: advanced card types require cardSet == .advanced
    }

    // MARK: Factory Methods

    /// Returns the default rule profile for Standard Teams mode.
    public static func standardTeams() -> RuleProfile {
        RuleProfile(
            winCondition: .bothTeammatesOut,
            targetScore: 500,
            mustPlayAfterDraw: false,
            drawUntilPlayable: false,
            stackDrawCards: false,
            drawFourChallengeable: true,
            discardAllEnabled: false,
            targetedDrawEnabled: false,
            forcedSwapEnabled: false,
            skipTwoEnabled: false,
            teamPlayEnabled: false,
            cardSet: .standard,
            initialHandSize: 7,
            teamPassEnabled: false,
            teamPassCooldown: 0,
            soloCallEnabled: true,
            soloCallPenaltyCards: 2
        )
    }

    /// Returns the default rule profile for All Wild mode.
    public static func allWild() -> RuleProfile {
        RuleProfile(
            winCondition: .singleOut,
            targetScore: 0,
            mustPlayAfterDraw: false,
            drawUntilPlayable: true,
            stackDrawCards: true,
            drawFourChallengeable: false,
            discardAllEnabled: true,
            targetedDrawEnabled: true,
            forcedSwapEnabled: true,
            skipTwoEnabled: true,
            teamPlayEnabled: true,
            cardSet: .advanced,
            initialHandSize: 7,
            teamPassEnabled: true,
            teamPassCooldown: 3,
            soloCallEnabled: true,
            soloCallPenaltyCards: 4
        )
    }

    /// Returns the default rule profile for Side to Side mode.
    public static func sideToSide() -> RuleProfile {
        RuleProfile(
            winCondition: .bothTeammatesOut,
            targetScore: 300,
            mustPlayAfterDraw: true,
            drawUntilPlayable: false,
            stackDrawCards: true,
            drawFourChallengeable: true,
            discardAllEnabled: false,
            targetedDrawEnabled: true,
            forcedSwapEnabled: false,
            skipTwoEnabled: true,
            teamPlayEnabled: false,
            cardSet: .standard,
            initialHandSize: 7,
            teamPassEnabled: false,
            teamPassCooldown: 0,
            soloCallEnabled: true,
            soloCallPenaltyCards: 2
        )
    }

    // MARK: Initialiser

    public init(
        winCondition: WinCondition,
        targetScore: Int,
        mustPlayAfterDraw: Bool,
        drawUntilPlayable: Bool,
        stackDrawCards: Bool,
        drawFourChallengeable: Bool,
        discardAllEnabled: Bool,
        targetedDrawEnabled: Bool,
        forcedSwapEnabled: Bool,
        skipTwoEnabled: Bool,
        teamPlayEnabled: Bool,
        cardSet: CardSet,
        initialHandSize: Int,
        teamPassEnabled: Bool,
        teamPassCooldown: Int,
        soloCallEnabled: Bool,
        soloCallPenaltyCards: Int
    ) {
        self.winCondition = winCondition
        self.targetScore = targetScore
        self.mustPlayAfterDraw = mustPlayAfterDraw
        self.drawUntilPlayable = drawUntilPlayable
        self.stackDrawCards = stackDrawCards
        self.drawFourChallengeable = drawFourChallengeable
        self.discardAllEnabled = discardAllEnabled
        self.targetedDrawEnabled = targetedDrawEnabled
        self.forcedSwapEnabled = forcedSwapEnabled
        self.skipTwoEnabled = skipTwoEnabled
        self.teamPlayEnabled = teamPlayEnabled
        self.cardSet = cardSet
        self.initialHandSize = initialHandSize
        self.teamPassEnabled = teamPassEnabled
        self.teamPassCooldown = teamPassCooldown
        self.soloCallEnabled = soloCallEnabled
        self.soloCallPenaltyCards = soloCallPenaltyCards
    }
}

// MARK: - RuleProfileError

/// Errors thrown when a `RuleProfile` fails validation.
public enum RuleProfileError: Error, Equatable {
    case invalidHandSize(Int)
    case invalidTargetScore(Int)
    case invalidTeamPassCooldown(Int)
    case advancedCardsRequireAdvancedSet
    case contradictoryDrawRules
}
