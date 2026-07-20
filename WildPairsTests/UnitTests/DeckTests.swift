import Testing
@testable import WildPairsCore

@Suite("Deck composition")
struct DeckTests {

    // MARK: Total card counts

    @Test("Beginner deck has 60 cards")
    func testBeginnerCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        #expect(deck.drawPile.count == 60)
    }

    @Test("Standard deck has 84 cards")
    func testStandardCount() {
        // 60 base + 8 Draw Two + 4 Colour Burst + 4 Draw Four + 8 Discard All (Colour Burst
        // moved to Standard in Phase 17 B4a; Discard All followed in Phase 19, +8 vs 76).
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .standard, rng: &rng)
        #expect(deck.drawPile.count == 84)
    }

    @Test("Advanced deck has 108 cards")
    func testAdvancedCount() {
        // 76 Standard base (incl. 4 Colour Burst) + 32 Advanced-only (incl. 4 Draw Eight,
        // Phase 17 B4b, and 8 Discard All raised from 4 in Phase 19) = 108.
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(deck.drawPile.count == 108)
    }

    @Test("Advanced deck has 4 Draw Eight cards (1 per colour, Phase 17 B4b)")
    func testAdvancedDrawEightCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(deck.drawPile.filter { $0.type == .drawEight }.count == 4)
    }

    @Test("Draw Eight is Advanced-only (absent from Beginner and Standard)")
    func testDrawEightAdvancedOnly() {
        var rng = SeededRNG(seed: 1)
        for set in [CardSet.beginner, .standard] {
            let deck = Deck.standard(cardSet: set, rng: &rng)
            #expect(!deck.drawPile.contains { $0.type == .drawEight })
        }
    }

    // MARK: Beginner card composition

    @Test("Beginner deck has exactly 4 Change Colour wilds")
    func testBeginnerChangeColour() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let count = deck.drawPile.filter { $0.type == .changeColour }.count
        #expect(count == 4)
    }

    @Test("Beginner deck has 8 Skip cards (2 per colour)")
    func testBeginnerSkipCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let count = deck.drawPile.filter { $0.type == .skip }.count
        #expect(count == 8)
    }

    @Test("Beginner deck has 8 Reverse cards (2 per colour)")
    func testBeginnerReverseCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let count = deck.drawPile.filter { $0.type == .reverse }.count
        #expect(count == 8)
    }

    @Test("Beginner deck has 40 number cards (0–9 per colour)")
    func testBeginnerNumberCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let count = deck.drawPile.filter {
            if case .number = $0.type { return true }
            return false
        }.count
        #expect(count == 40)
    }

    @Test("Beginner deck has one 0-card per colour (4 total)")
    func testBeginnerZeroCards() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let count = deck.drawPile.filter { $0.type == .number(0) }.count
        #expect(count == 4)
    }

    @Test("Beginner deck has no Draw Two cards")
    func testBeginnerNoDrawTwo() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        #expect(!deck.drawPile.contains { $0.type == .drawTwo })
    }

    @Test("Beginner deck has no Draw Four cards")
    func testBeginnerNoDrawFour() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .beginner, rng: &rng)
        #expect(!deck.drawPile.contains { $0.type == .drawFour })
    }

    // MARK: Standard card composition

    @Test("Standard deck has 8 Draw Two cards (2 per colour)")
    func testStandardDrawTwoCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .standard, rng: &rng)
        let count = deck.drawPile.filter { $0.type == .drawTwo }.count
        #expect(count == 8)
    }

    @Test("Standard deck has 4 Draw Four wilds")
    func testStandardDrawFourCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .standard, rng: &rng)
        let count = deck.drawPile.filter { $0.type == .drawFour }.count
        #expect(count == 4)
    }

    @Test("Standard deck has 4 Colour Burst cards (1 per colour, Phase 17 B4a)")
    func testStandardColourBurstCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .standard, rng: &rng)
        #expect(deck.drawPile.filter { $0.type == .discardColour }.count == 4)
    }

    @Test("Standard deck has no advanced-only cards")
    func testStandardNoAdvancedCards() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .standard, rng: &rng)
        // Colour Burst (`discardColour`) is a Standard card since Phase 17 B4a, and Discard All
        // (`discardAll`) since Phase 19 — neither is Advanced-only any more.
        let advancedTypes: [CardType] = [.targetedDraw, .forcedSwap, .skipTwo, .teamPlay]
        for type_ in advancedTypes {
            #expect(!deck.drawPile.contains { $0.type == type_ })
        }
    }

    // MARK: Advanced card composition

    @Test("Standard and Advanced decks both have 8 Discard All wilds (Phase 19)")
    func testAdvancedDiscardAllCount() {
        var rng = SeededRNG(seed: 1)
        let advanced = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(advanced.drawPile.filter { $0.type == .discardAll }.count == 8)

        var standardRNG = SeededRNG(seed: 1)
        let standard = Deck.standard(cardSet: .standard, rng: &standardRNG)
        #expect(standard.drawPile.filter { $0.type == .discardAll }.count == 8)

        // Beginner stays clear of it.
        var beginnerRNG = SeededRNG(seed: 1)
        let beginner = Deck.standard(cardSet: .beginner, rng: &beginnerRNG)
        #expect(!beginner.drawPile.contains { $0.type == .discardAll })
    }

    @Test("Advanced deck has 8 Targeted Draw cards (2 per colour)")
    func testAdvancedTargetedDrawCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(deck.drawPile.filter { $0.type == .targetedDraw }.count == 8)
    }

    @Test("Advanced deck has 4 Forced Swap cards (1 per colour)")
    func testAdvancedForcedSwapCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(deck.drawPile.filter { $0.type == .forcedSwap }.count == 4)
    }

    @Test("Advanced deck has 4 Skip Two cards (1 per colour)")
    func testAdvancedSkipTwoCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(deck.drawPile.filter { $0.type == .skipTwo }.count == 4)
    }

    @Test("Advanced deck has 4 Team Play cards (1 per colour)")
    func testAdvancedTeamPlayCount() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        #expect(deck.drawPile.filter { $0.type == .teamPlay }.count == 4)
    }

    // MARK: All four colours present

    @Test("Each colour appears in all 4 ColourCases in the standard deck")
    func testAllColoursPresent() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .standard, rng: &rng)
        for colour in CardColour.allCases {
            let count = deck.drawPile.filter { $0.colour == colour }.count
            #expect(count > 0, "Colour \(colour) missing from deck")
        }
    }

    // MARK: draw / deal / discard

    @Test("draw() removes from draw pile")
    func testDrawReducesPile() {
        var rng = SeededRNG(seed: 1)
        var deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let before = deck.drawPile.count
        let card = deck.draw(rng: &rng)
        #expect(card != nil)
        #expect(deck.drawPile.count == before - 1)
    }

    @Test("discard() adds to discard pile")
    func testDiscardAdds() {
        var rng = SeededRNG(seed: 1)
        var deck = Deck.standard(cardSet: .beginner, rng: &rng)
        let card = deck.draw(rng: &rng)!
        deck.discard(card)
        #expect(deck.topDiscard == card)
    }

    @Test("draw() reshuffles discard pile when draw pile is empty")
    func testReshuffle() {
        var rng = SeededRNG(seed: 1)
        // Build a tiny deck: 1 card in draw pile, 3 in discard
        let cards = (0..<3).map { CardFactory.number($0, .crimson) }
        let top = CardFactory.number(9, .cobalt)
        var deck = Deck(
            drawPile: [CardFactory.number(0, .amber)],
            discardPile: cards + [top]
        )
        _ = deck.draw(rng: &rng)  // draws the amber 0
        // Draw pile now empty; should reshuffle
        let drawn = deck.draw(rng: &rng)
        #expect(drawn != nil)
        // Top of discard pile should still be 'top'
        #expect(deck.topDiscard == top)
    }

    @Test("draw() returns nil when both piles are empty")
    func testDrawFromEmptyDecks() {
        var rng = SeededRNG(seed: 1)
        var deck = Deck(drawPile: [], discardPile: [])
        #expect(deck.draw(rng: &rng) == nil)
    }

    @Test("deal() returns exactly count cards when enough remain")
    func testDeal() {
        var rng = SeededRNG(seed: 1)
        var deck = Deck.standard(cardSet: .standard, rng: &rng)
        // Derived from the deck's own size so this asserts the dealing invariant rather than
        // duplicating the total, which `testStandardCount` already pins.
        let before = deck.drawPile.count
        let dealt = deck.deal(count: 7, rng: &rng)
        #expect(dealt.count == 7)
        #expect(deck.drawPile.count == before - 7)
    }

    @Test("After dealing 28 cards (4×7) the standard draw pile drops by exactly 28")
    func testDrawPileAfterDealing() {
        var rng = SeededRNG(seed: 1)
        var deck = Deck.standard(cardSet: .standard, rng: &rng)
        let before = deck.drawPile.count
        for _ in 0..<4 {
            _ = deck.deal(count: 7, rng: &rng)
        }
        #expect(deck.drawPile.count == before - 28)
        #expect(deck.drawPile.count == 56)   // 84 - 28 (Phase 19: Discard All moved to Standard)
    }
}
