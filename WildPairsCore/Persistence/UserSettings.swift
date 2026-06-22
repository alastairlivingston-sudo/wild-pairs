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

    public init(
        animationSpeed: AnimationSpeed = .normal,
        confirmEndGame: Bool = true,
        hapticsEnabled: Bool = true,
        reducedVisualEffects: Bool = false,
        colourBlindMode: Bool = false,
        patternFills: Bool = false,
        largeCards: Bool = false
    ) {
        self.animationSpeed = animationSpeed
        self.confirmEndGame = confirmEndGame
        self.hapticsEnabled = hapticsEnabled
        self.reducedVisualEffects = reducedVisualEffects
        self.colourBlindMode = colourBlindMode
        self.patternFills = patternFills
        self.largeCards = largeCards
    }
}
