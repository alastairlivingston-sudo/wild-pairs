import Foundation

// MARK: - CardSet

public enum CardSet: String, Codable, CaseIterable, Equatable, Sendable {
    case beginner
    case standard
    case advanced
}

// MARK: - Deck

public struct Deck: Codable, Equatable, Sendable {

    public private(set) var drawPile: [Card]
    public private(set) var discardPile: [Card]

    public var topDiscard: Card? { discardPile.last }
    public var isDrawPileEmpty: Bool { drawPile.isEmpty }

    // MARK: Factory

    /// Builds a full shuffled deck for the given card set.
    public static func standard(cardSet: CardSet, rng: inout SeededRNG) -> Deck {
        var cards: [Card] = []

        // Number cards: one 0 and one each of 1–9 per colour = 40 cards
        for colour in CardColour.allCases {
            cards.append(Card(type: .number(0), colour: colour))
            for n in 1...9 {
                cards.append(Card(type: .number(n), colour: colour))
            }
        }

        // Skip + Reverse: 2 per colour = 8 + 8 = 16 cards
        for colour in CardColour.allCases {
            for _ in 0..<2 {
                cards.append(Card(type: .skip, colour: colour))
                cards.append(Card(type: .reverse, colour: colour))
            }
        }

        // Change Colour (wild): 4 cards
        for _ in 0..<4 {
            cards.append(Card(type: .changeColour, colour: nil))
        }

        // Standard additions: Draw Two (8) + Draw Four wild (4) = 12 cards
        if cardSet == .standard || cardSet == .advanced {
            for colour in CardColour.allCases {
                for _ in 0..<2 {
                    cards.append(Card(type: .drawTwo, colour: colour))
                }
            }
            for _ in 0..<4 {
                cards.append(Card(type: .drawFour, colour: nil))
            }
        }

        // Advanced additions: 24 cards
        if cardSet == .advanced {
            for _ in 0..<4 {
                cards.append(Card(type: .discardAll, colour: nil))
            }
            for colour in CardColour.allCases {
                for _ in 0..<2 {
                    cards.append(Card(type: .targetedDraw, colour: colour))
                }
                cards.append(Card(type: .forcedSwap, colour: colour))
                cards.append(Card(type: .skipTwo, colour: colour))
                cards.append(Card(type: .teamPlay, colour: colour))
            }
        }

        cards.shuffle(using: &rng)
        return Deck(drawPile: cards, discardPile: [])
    }

    // MARK: Mutation

    /// Draws the top card from the draw pile, reshuffling the discard pile if needed.
    public mutating func draw(rng: inout SeededRNG) -> Card? {
        if !drawPile.isEmpty {
            return drawPile.removeFirst()
        }
        guard discardPile.count > 1 else { return nil }
        let top = discardPile.removeLast()
        drawPile = discardPile
        drawPile.shuffle(using: &rng)
        discardPile = [top]
        guard !drawPile.isEmpty else { return nil }
        return drawPile.removeFirst()
    }

    /// Deals `count` cards from the draw pile.
    public mutating func deal(count: Int, rng: inout SeededRNG) -> [Card] {
        (0..<count).compactMap { _ in draw(rng: &rng) }
    }

    /// Adds a card to the top of the discard pile.
    public mutating func discard(_ card: Card) {
        discardPile.append(card)
    }

    /// Returns cards to the bottom of the draw pile. Used when burying wild-type cards
    /// drawn while flipping the starting discard card, so no card leaves the game.
    public mutating func returnToDrawPileBottom(_ cards: [Card]) {
        drawPile.append(contentsOf: cards)
    }

    // MARK: Initialiser

    public init(drawPile: [Card] = [], discardPile: [Card] = []) {
        self.drawPile = drawPile
        self.discardPile = discardPile
    }
}
