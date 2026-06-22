import Foundation

// MARK: - CardFactory

/// Convenience constructors for test fixtures and engine setup.
/// Each call returns a new Card with a fresh UUID.
public enum CardFactory {

    // MARK: Number Cards

    public static func number(_ value: Int, _ colour: CardColour) -> Card {
        Card(type: .number(value), colour: colour)
    }

    // MARK: Action Cards (coloured)

    public static func skip(_ colour: CardColour) -> Card {
        Card(type: .skip, colour: colour)
    }

    public static func reverse(_ colour: CardColour) -> Card {
        Card(type: .reverse, colour: colour)
    }

    public static func drawTwo(_ colour: CardColour) -> Card {
        Card(type: .drawTwo, colour: colour)
    }

    public static func targetedDraw(_ colour: CardColour) -> Card {
        Card(type: .targetedDraw, colour: colour)
    }

    public static func forcedSwap(_ colour: CardColour) -> Card {
        Card(type: .forcedSwap, colour: colour)
    }

    public static func skipTwo(_ colour: CardColour) -> Card {
        Card(type: .skipTwo, colour: colour)
    }

    public static func teamPlay(_ colour: CardColour) -> Card {
        Card(type: .teamPlay, colour: colour)
    }

    // MARK: Wild Cards (no colour)

    public static func changeColour() -> Card {
        Card(type: .changeColour, colour: nil)
    }

    public static func drawFour() -> Card {
        Card(type: .drawFour, colour: nil)
    }

    public static func discardAll() -> Card {
        Card(type: .discardAll, colour: nil)
    }
}
