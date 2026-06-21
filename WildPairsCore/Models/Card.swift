import Foundation

// MARK: - CardColour

/// The four named colours in Wild Pairs, plus a wild sentinel for colourless cards.
public enum CardColour: String, Codable, CaseIterable, Equatable, Sendable {
    case crimson  // Flame — red suit
    case cobalt   // Wave — blue suit
    case jade     // Leaf — green suit
    case amber    // Sun  — yellow suit
    case wild     // No colour; used for draw-four and change-colour cards
}

extension CardColour {
    /// All colours that are not wild (i.e., the four named suits).
    public static var nonWild: [CardColour] {
        allCases.filter { $0 != .wild }
    }

    /// A human-readable display name for the colour.
    public var displayName: String {
        switch self {
        case .crimson: return "Crimson"
        case .cobalt:  return "Cobalt"
        case .jade:    return "Jade"
        case .amber:   return "Amber"
        case .wild:    return "Wild"
        }
    }
}

// MARK: - CardType

/// Every distinct card type that can appear in a Wild Pairs deck.
public enum CardType: String, Codable, CaseIterable, Equatable, Sendable {
    case number        // 0–9 numbered cards
    case skip          // Skip the next player's turn
    case reverse       // Reverse turn direction
    case drawTwo       // Next player must draw 2 cards
    case drawFour      // Wild; next player draws 4; requires colour choice
    case changeColour  // Wild; changes the active colour; no draw penalty
    case discardAll    // Discard all cards of a chosen colour from own hand
    case targetedDraw  // A chosen opponent must draw 2 cards
    case forcedSwap    // Swap own hand with a chosen player's hand
    case skipTwo       // Skip the next two players' turns
    case teamPlay      // Allows a teammate to play a card on your turn
}

// MARK: - Card

/// A single playing card in Wild Pairs.
public struct Card: Codable, Equatable, Hashable, Sendable {

    // MARK: Identity

    /// Unique identifier for this card instance (each physical card has its own UUID).
    public let id: UUID

    // MARK: Type & Colour

    /// The functional type of the card, determining its game effect.
    public let type: CardType

    /// The suit colour. `nil` only for cards whose colour is determined at play time
    /// (drawFour, changeColour). Stored as `.wild` for such cards.
    public let colour: CardColour

    // MARK: Number (number cards only)

    /// The face value (0–9) for `.number` cards; `nil` for all other types.
    public let number: Int?

    // MARK: Display

    /// A short label suitable for rendering on the card face.
    public var displayName: String {
        switch type {
        case .number:
            return "\(colour.displayName) \(number ?? 0)"
        case .skip:
            return "\(colour.displayName) Skip"
        case .reverse:
            return "\(colour.displayName) Reverse"
        case .drawTwo:
            return "\(colour.displayName) +2"
        case .drawFour:
            return "Wild +4"
        case .changeColour:
            return "Wild Change"
        case .discardAll:
            return "\(colour.displayName) Discard All"
        case .targetedDraw:
            return "\(colour.displayName) Targeted +2"
        case .forcedSwap:
            return "\(colour.displayName) Forced Swap"
        case .skipTwo:
            return "\(colour.displayName) Skip Two"
        case .teamPlay:
            return "\(colour.displayName) Team Play"
        }
    }

    /// A full accessibility label suitable for VoiceOver.
    public var accessibilityLabel: String {
        switch type {
        case .number:
            return "\(colour.displayName) \(number ?? 0)"
        case .skip:
            return "\(colour.displayName) Skip — skips the next player"
        case .reverse:
            return "\(colour.displayName) Reverse — reverses turn direction"
        case .drawTwo:
            return "\(colour.displayName) Draw Two — next player draws 2 cards"
        case .drawFour:
            return "Wild Draw Four — next player draws 4 cards; choose a colour"
        case .changeColour:
            return "Wild Change Colour — choose a new colour to play"
        case .discardAll:
            return "\(colour.displayName) Discard All — discard all your cards of one colour"
        case .targetedDraw:
            return "\(colour.displayName) Targeted Draw — choose an opponent to draw 2 cards"
        case .forcedSwap:
            return "\(colour.displayName) Forced Swap — swap your hand with another player"
        case .skipTwo:
            return "\(colour.displayName) Skip Two — skip the next two players"
        case .teamPlay:
            return "\(colour.displayName) Team Play — your teammate can play a card this turn"
        }
    }

    // MARK: Scoring

    /// Point value of this card (used for scoring when opponents hold it at round end).
    public var pointValue: Int {
        switch type {
        case .number:
            return number ?? 0
        case .skip, .reverse, .drawTwo, .skipTwo, .teamPlay:
            return 20
        case .targetedDraw, .discardAll:
            return 25
        case .forcedSwap:
            return 30
        case .drawFour, .changeColour:
            return 50
        }
    }

    // MARK: Computed Properties

    /// True for cards that have no inherent colour (drawFour, changeColour).
    public var isWild: Bool {
        colour == .wild
    }

    /// True for cards that require the player to choose a new active colour after playing.
    public var changesColour: Bool {
        type == .drawFour || type == .changeColour
    }

    /// True for cards that require the player to nominate a target player.
    public var requiresTarget: Bool {
        type == .targetedDraw || type == .forcedSwap || type == .skipTwo
    }

    /// True for cards that require a colour choice from the player.
    public var requiresColourChoice: Bool {
        changesColour
    }

    // MARK: Initialiser

    public init(
        id: UUID = UUID(),
        type: CardType,
        colour: CardColour,
        number: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.colour = colour
        self.number = number
    }
}
