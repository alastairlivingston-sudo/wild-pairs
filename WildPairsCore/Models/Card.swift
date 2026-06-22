import Foundation

// MARK: - CardColour

public enum CardColour: String, Codable, Equatable, Sendable, CaseIterable {
    case crimson
    case cobalt
    case jade
    case amber
}

// MARK: - CardType

public enum CardType: Codable, Equatable, Sendable {
    case number(Int)
    case skip
    case reverse
    case drawTwo
    case drawFour
    case changeColour
    case discardAll
    case targetedDraw
    case forcedSwap
    case skipTwo
    case teamPlay
}

// MARK: - Card

public struct Card: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let type: CardType
    public let colour: CardColour?

    public var isWild: Bool { colour == nil }

    public init(id: UUID = UUID(), type: CardType, colour: CardColour?) {
        self.id = id
        self.type = type
        self.colour = colour
    }
}
