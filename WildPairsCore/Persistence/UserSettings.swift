import Foundation

// MARK: - AnimationSpeed

public enum AnimationSpeed: String, Codable, Equatable, Sendable, CaseIterable {
    case normal
    case fast
    case off
}

public enum TableBackgroundStyle: String, Codable, Equatable, Sendable, CaseIterable {
    case felt
    case aurora
    case contours
}

/// How long each AI turn is held before the move lands, so a human can read the played card.
/// Scales the per-difficulty base delay in `AIPlayer.thinkDelay(for:)`.
public enum AITurnPace: String, Codable, Equatable, Sendable, CaseIterable {
    case brisk
    case steady
    case relaxed
    case slow

    public var delayMultiplier: Double {
        switch self {
        case .brisk:   return 0.55
        case .steady:  return 1.0
        case .relaxed: return 1.7
        case .slow:    return 2.6
        }
    }
}

// MARK: - UserSettings

public struct UserSettings: Codable, Equatable, Sendable {

    // Gameplay
    public var animationSpeed: AnimationSpeed
    public var confirmEndGame: Bool
    /// Draw stacking (Phase 11 F): a Draw Two/Four can be answered with another Draw Two/Four
    /// instead of drawing, accumulating the penalty. Core rule, on by default; this toggle is
    /// the house-rule escape hatch. Applied to `RuleProfile.stackDrawCards` at new-game time.
    public var stackingEnabled: Bool
    /// Draw Four challenge (Phase 17 B2): an optional house rule. When on, a Draw Four may be
    /// played as a bluff and its target may challenge it. Off by default. Applied to
    /// `RuleProfile.drawFourChallengeable` at new-game time. See `docs/game-rules.md`.
    public var drawFourChallengeEnabled: Bool

    // Appearance
    public var tableBackgroundStyle: TableBackgroundStyle

    // Pace
    public var aiTurnPace: AITurnPace

    // Accessibility
    public var hapticsEnabled: Bool
    public var soundEnabled: Bool
    public var reducedVisualEffects: Bool
    public var colourBlindMode: Bool
    public var patternFills: Bool
    public var largeCards: Bool

    // Onboarding
    public var hasSeenOnboarding: Bool

    // Two-player pass-and-play: recently used player names, most recent first, capped at
    // `maxSavedPlayerNames`, offered as one-tap suggestions in the new-game name fields.
    public var savedPlayerNames: [String]

    public static let maxSavedPlayerNames = 8

    public init(
        animationSpeed: AnimationSpeed = .normal,
        confirmEndGame: Bool = true,
        tableBackgroundStyle: TableBackgroundStyle = .felt,
        aiTurnPace: AITurnPace = .relaxed,
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = true,
        reducedVisualEffects: Bool = false,
        colourBlindMode: Bool = false,
        patternFills: Bool = false,
        largeCards: Bool = false,
        hasSeenOnboarding: Bool = false,
        stackingEnabled: Bool = true,
        drawFourChallengeEnabled: Bool = false,
        savedPlayerNames: [String] = []
    ) {
        self.animationSpeed = animationSpeed
        self.confirmEndGame = confirmEndGame
        self.tableBackgroundStyle = tableBackgroundStyle
        self.aiTurnPace = aiTurnPace
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.reducedVisualEffects = reducedVisualEffects
        self.colourBlindMode = colourBlindMode
        self.patternFills = patternFills
        self.largeCards = largeCards
        self.hasSeenOnboarding = hasSeenOnboarding
        self.stackingEnabled = stackingEnabled
        self.drawFourChallengeEnabled = drawFourChallengeEnabled
        self.savedPlayerNames = savedPlayerNames
    }

    /// Records names used to start a game: moved/inserted at the front, case-insensitively
    /// de-duplicated, blanks dropped, capped at `maxSavedPlayerNames`.
    public mutating func rememberPlayerNames(_ names: [String]) {
        let cleaned = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var result = cleaned
        for existing in savedPlayerNames
        where !result.contains(where: { $0.caseInsensitiveCompare(existing) == .orderedSame }) {
            result.append(existing)
        }
        savedPlayerNames = Array(result.prefix(Self.maxSavedPlayerNames))
    }

    // Custom decode so settings files saved before a new field was added still load —
    // missing keys fall back to the default rather than failing the whole decode (which
    // would silently revert every other saved preference per AppSettings.init's `try?`).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        animationSpeed = try c.decodeIfPresent(AnimationSpeed.self, forKey: .animationSpeed) ?? .normal
        confirmEndGame = try c.decodeIfPresent(Bool.self, forKey: .confirmEndGame) ?? true
        tableBackgroundStyle = try c.decodeIfPresent(TableBackgroundStyle.self, forKey: .tableBackgroundStyle) ?? .felt
        aiTurnPace = try c.decodeIfPresent(AITurnPace.self, forKey: .aiTurnPace) ?? .relaxed
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        reducedVisualEffects = try c.decodeIfPresent(Bool.self, forKey: .reducedVisualEffects) ?? false
        colourBlindMode = try c.decodeIfPresent(Bool.self, forKey: .colourBlindMode) ?? false
        patternFills = try c.decodeIfPresent(Bool.self, forKey: .patternFills) ?? false
        largeCards = try c.decodeIfPresent(Bool.self, forKey: .largeCards) ?? false
        hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
        stackingEnabled = try c.decodeIfPresent(Bool.self, forKey: .stackingEnabled) ?? true
        drawFourChallengeEnabled = try c.decodeIfPresent(Bool.self, forKey: .drawFourChallengeEnabled) ?? false
        savedPlayerNames = try c.decodeIfPresent([String].self, forKey: .savedPlayerNames) ?? []
    }
}
