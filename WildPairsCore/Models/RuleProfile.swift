import Foundation

// MARK: - WinCondition

public enum WinCondition: String, Codable, Equatable, Sendable {
    case bothTeammatesOut
    case singleOut
}

// MARK: - RuleProfile

public struct RuleProfile: Codable, Equatable, Sendable {

    // Win condition
    public var winCondition: WinCondition
    public var targetScore: Int

    // Draw rules
    public var mustPlayAfterDraw: Bool
    public var drawUntilPlayable: Bool
    public var stackDrawCards: Bool

    // Wild card rules
    public var drawFourChallengeable: Bool
    public var changeColourRequiresPlay: Bool

    // Special card availability (each controlled independently; all off in factory defaults)
    public var discardAllEnabled: Bool
    public var targetedDrawEnabled: Bool
    public var forcedSwapEnabled: Bool
    public var skipTwoEnabled: Bool
    public var teamPlayEnabled: Bool

    // Card set
    public var cardSet: CardSet

    // Hand size
    public var initialHandSize: Int

    // Team pass
    public var teamPassEnabled: Bool
    public var teamPassCooldown: Int

    // Solo call
    public var soloCallEnabled: Bool
    public var soloCallPenaltyCards: Int
    public var soloCallTimeoutSeconds: Double

    // Scoring
    public var scoringEnabled: Bool
    public var maxTurnsPerRound: Int

    // Team Play house-rule variant
    public var partnerPlaysImmediately: Bool

    // Round / move timers
    /// Wall-clock seconds before a round with no winner falls back to lowest-score scoring.
    /// The timer is owned by the presentation layer; the engine only reacts to
    /// `GameAction.roundTimerExpired` once it fires.
    public var roundTimeLimitSeconds: Double
    /// Wall-clock seconds the local human has to act before a fallback move is forced.
    public var moveTimeLimitSeconds: Double

    // MARK: Validation

    public func validate() throws {
        guard (1...20).contains(initialHandSize) else {
            throw RuleProfileError.invalidHandSize(initialHandSize)
        }
        guard targetScore >= 0 else {
            throw RuleProfileError.invalidTargetScore(targetScore)
        }
        guard teamPassCooldown >= 0 else {
            throw RuleProfileError.invalidTeamPassCooldown(teamPassCooldown)
        }
        guard soloCallPenaltyCards >= 0 else {
            throw RuleProfileError.invalidSoloCallPenaltyCards(soloCallPenaltyCards)
        }
        let usesAdvancedCards = discardAllEnabled || targetedDrawEnabled ||
            forcedSwapEnabled || skipTwoEnabled || teamPlayEnabled
        if usesAdvancedCards && cardSet != .advanced {
            throw RuleProfileError.advancedCardsRequireAdvancedSet
        }
    }

    // MARK: Factory Methods

    public static func standardTeams() -> RuleProfile {
        RuleProfile(
            winCondition: .singleOut, targetScore: 0,
            mustPlayAfterDraw: true, drawUntilPlayable: false, stackDrawCards: false,
            drawFourChallengeable: false, changeColourRequiresPlay: false,
            discardAllEnabled: false, targetedDrawEnabled: false,
            forcedSwapEnabled: false, skipTwoEnabled: false, teamPlayEnabled: false,
            cardSet: .standard, initialHandSize: 7,
            teamPassEnabled: false, teamPassCooldown: 0,
            soloCallEnabled: true, soloCallPenaltyCards: 2, soloCallTimeoutSeconds: 5.0,
            scoringEnabled: false, maxTurnsPerRound: 300, partnerPlaysImmediately: false,
            roundTimeLimitSeconds: 180, moveTimeLimitSeconds: 10
        )
    }

    public static func allWild() -> RuleProfile {
        RuleProfile(
            winCondition: .singleOut, targetScore: 0,
            mustPlayAfterDraw: true, drawUntilPlayable: false, stackDrawCards: false,
            drawFourChallengeable: false, changeColourRequiresPlay: false,
            discardAllEnabled: false, targetedDrawEnabled: false,
            forcedSwapEnabled: false, skipTwoEnabled: false, teamPlayEnabled: false,
            cardSet: .standard, initialHandSize: 7,
            teamPassEnabled: false, teamPassCooldown: 0,
            soloCallEnabled: true, soloCallPenaltyCards: 2, soloCallTimeoutSeconds: 5.0,
            scoringEnabled: false, maxTurnsPerRound: 300, partnerPlaysImmediately: false,
            roundTimeLimitSeconds: 180, moveTimeLimitSeconds: 10
        )
    }

    public static func sideToSide() -> RuleProfile {
        RuleProfile(
            winCondition: .singleOut, targetScore: 0,
            mustPlayAfterDraw: true, drawUntilPlayable: false, stackDrawCards: false,
            drawFourChallengeable: false, changeColourRequiresPlay: false,
            discardAllEnabled: false, targetedDrawEnabled: false,
            forcedSwapEnabled: false, skipTwoEnabled: false, teamPlayEnabled: false,
            cardSet: .standard, initialHandSize: 7,
            teamPassEnabled: true, teamPassCooldown: 0,
            soloCallEnabled: true, soloCallPenaltyCards: 2, soloCallTimeoutSeconds: 5.0,
            scoringEnabled: false, maxTurnsPerRound: 300, partnerPlaysImmediately: false,
            roundTimeLimitSeconds: 180, moveTimeLimitSeconds: 10
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
        changeColourRequiresPlay: Bool,
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
        soloCallPenaltyCards: Int,
        soloCallTimeoutSeconds: Double,
        scoringEnabled: Bool,
        maxTurnsPerRound: Int,
        partnerPlaysImmediately: Bool,
        roundTimeLimitSeconds: Double = 180,
        moveTimeLimitSeconds: Double = 10
    ) {
        self.winCondition = winCondition
        self.targetScore = targetScore
        self.mustPlayAfterDraw = mustPlayAfterDraw
        self.drawUntilPlayable = drawUntilPlayable
        self.stackDrawCards = stackDrawCards
        self.drawFourChallengeable = drawFourChallengeable
        self.changeColourRequiresPlay = changeColourRequiresPlay
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
        self.soloCallTimeoutSeconds = soloCallTimeoutSeconds
        self.scoringEnabled = scoringEnabled
        self.maxTurnsPerRound = maxTurnsPerRound
        self.partnerPlaysImmediately = partnerPlaysImmediately
        self.roundTimeLimitSeconds = roundTimeLimitSeconds
        self.moveTimeLimitSeconds = moveTimeLimitSeconds
    }
}

// MARK: - RuleProfileError

public enum RuleProfileError: Error, Equatable {
    case invalidHandSize(Int)
    case invalidTargetScore(Int)
    case invalidTeamPassCooldown(Int)
    case invalidSoloCallPenaltyCards(Int)
    case advancedCardsRequireAdvancedSet
    case contradictoryDrawRules
}
