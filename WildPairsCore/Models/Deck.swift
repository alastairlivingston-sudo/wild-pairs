import Foundation

// MARK: - CardSet

/// The set of card types available in a game, controlling which special cards are included.
public enum CardSet: String, Codable, CaseIterable, Equatable, Sendable {
    /// Only number cards (0–9) per colour — suitable for learners.
    case beginner
    /// Number cards plus skip, reverse, drawTwo, drawFour, changeColour — the standard game.
    case standard
    /// All card types including discardAll, targetedDraw, forcedSwap, skipTwo, teamPlay.
    case advanced
}

// MARK: - Deck

/// The combined draw pile and discard pile for one game round.
public struct Deck: Codable, Equatable, Sendable {

    // MARK: State

    /// The draw pile. Players draw from the front (index 0). Shuffled at creation and on reshuffle.
    public private(set) var drawPile: [Card]

    /// The discard pile. The top card is the last element (highest index).
    public private(set) var discardPile: [Card]

    // MARK: Computed Properties

    /// The card currently on top of the discard pile, if any.
    public var topDiscard: Card? {
        discardPile.last
    }

    /// True when the draw pile is empty.
    public var isDrawPileEmpty: Bool {
        drawPile.isEmpty
    }

    // MARK: Factory

    /// Creates a full, shuffled deck appropriate for the given card set.
    ///
    /// - Parameters:
    ///   - cardSet: Determines which card types are included.
    ///   - rng: Seeded random number generator for deterministic shuffling.
    /// - Returns: A new `Deck` with a full draw pile and empty discard pile.
    public static func standard(cardSet: CardSet, rng: inout SeededRNG) -> Deck {
        // TODO: Implement in Phase 2
        // Build full card list according to cardSet, then shuffle with rng.
        // Standard composition per colour:
        //   - One 0 card
        //   - Two of each 1–9
        //   - Two skips, two reverses, two draw-twos
        // Wild cards (no colour):
        //   - Four changeColour
        //   - Four drawFour
        // Advanced additions per colour:
        //   - Two discardAll, two targetedDraw, two forcedSwap, two skipTwo, two teamPlay
        let cards: [Card] = []
        var shuffled = cards
        shuffled.shuffle(using: &rng)
        return Deck(drawPile: shuffled, discardPile: [])
    }

    // MARK: Mutation

    /// Draws the top card from the draw pile.
    ///
    /// If the draw pile is empty, the discard pile (all but the top card) is shuffled
    /// back into the draw pile and a new draw is attempted.
    ///
    /// - Returns: The drawn card, or `nil` if both piles are empty.
    public mutating func draw() -> Card? {
        // TODO: Implement in Phase 2
        // 1. If drawPile is not empty, remove and return first element.
        // 2. If drawPile is empty and discardPile has > 1 card:
        //    a. Keep topDiscard aside.
        //    b. Shuffle remaining discardPile into drawPile using a fresh SeededRNG step.
        //    c. Clear discardPile, restore topDiscard.
        //    d. Recurse / retry draw.
        // 3. If both empty, return nil.
        return nil
    }

    /// Adds a card to the top of the discard pile.
    ///
    /// - Parameter card: The card to discard.
    public mutating func discard(_ card: Card) {
        // TODO: Implement in Phase 2
        discardPile.append(card)
    }

    /// Deals `count` cards from the draw pile, returning them as an array.
    ///
    /// - Parameter count: Number of cards to deal.
    /// - Returns: Array of dealt cards (may be fewer than `count` if deck runs low).
    public mutating func deal(count: Int) -> [Card] {
        // TODO: Implement in Phase 2
        return []
    }

    // MARK: Initialiser

    public init(drawPile: [Card] = [], discardPile: [Card] = []) {
        self.drawPile = drawPile
        self.discardPile = discardPile
    }
}
