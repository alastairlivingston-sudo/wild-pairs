import Foundation

// MARK: - AnimationSpeed

public enum AnimationSpeed: String, Codable, Equatable, Sendable, CaseIterable {
    case normal
    case fast
    case off
}

// MARK: - UserSettings

public struct UserSettings: Codable, Equatable, Sendable {

    // Gameplay
    public var animationSpeed: AnimationSpeed
    public var confirmEndGame: Bool

    // Accessibility
    public var hapticsEnabled: Bool
    public var reducedVisualEffects: Bool
    public var colourBlindMode: Bool
    public var patternFills: Bool
    public var largeCards: Bool

    // Onboarding
    public var hasSeenOnboarding: Bool

    public init(
        animationSpeed: AnimationSpeed = .normal,
        confirmEndGame: Bool = true,
        hapticsEnabled: Bool = true,
        reducedVisualEffects: Bool = false,
        colourBlindMode: Bool = false,
        patternFills: Bool = false,
        largeCards: Bool = false,
        hasSeenOnboarding: Bool = false
    ) {
        self.animationSpeed = animationSpeed
        self.confirmEndGame = confirmEndGame
        self.hapticsEnabled = hapticsEnabled
        self.reducedVisualEffects = reducedVisualEffects
        self.colourBlindMode = colourBlindMode
        self.patternFills = patternFills
        self.largeCards = largeCards
        self.hasSeenOnboarding = hasSeenOnboarding
    }

    // Custom decode so settings files saved before a new field was added still load —
    // missing keys fall back to the default rather than failing the whole decode (which
    // would silently revert every other saved preference per AppSettings.init's `try?`).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        animationSpeed = try c.decodeIfPresent(AnimationSpeed.self, forKey: .animationSpeed) ?? .normal
        confirmEndGame = try c.decodeIfPresent(Bool.self, forKey: .confirmEndGame) ?? true
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        reducedVisualEffects = try c.decodeIfPresent(Bool.self, forKey: .reducedVisualEffects) ?? false
        colourBlindMode = try c.decodeIfPresent(Bool.self, forKey: .colourBlindMode) ?? false
        patternFills = try c.decodeIfPresent(Bool.self, forKey: .patternFills) ?? false
        largeCards = try c.decodeIfPresent(Bool.self, forKey: .largeCards) ?? false
        hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
    }
}
