import Testing
import Foundation
@testable import WildPairsCore

/// Colour Burst (`discardColour`): a coloured action card that, when played, discards every
/// card of its own colour from the player's hand along with it. No colour prompt — the
/// colour is fixed. Rules: docs/game-rules.md §Colour Burst.
@Suite("Colour Burst — coloured discard-of-a-colour")
struct ColourBurstTests {

    // MARK: Core effect

    @Test("Playing a Colour Burst discards every same-colour card; other colours untouched")
    func testBurstRemovesSameColourOnly() {
        let burst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(2, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [
                burst,
                CardFactory.number(3, .crimson),
                CardFactory.number(7, .crimson),
                CardFactory.number(4, .jade),
                CardFactory.number(5, .jade)
            ])
            .withDrawPile([])
            .build()
        let p0 = state.players[0].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(burst, playerID: p0))

        // Two jade cards remain; both crimson number cards and the burst itself are gone.
        #expect(next.players[0].hand.count == 2)
        #expect(next.players[0].hand.allSatisfy { $0.colour == .jade })
        // The played card's colour stays the active colour.
        #expect(next.currentColour == .crimson)
        #expect(effects.contains { if case .animateDiscardAll = $0 { return true }; return false })
    }

    @Test("A Colour Burst removing no other same-colour cards discards only itself")
    func testBurstWithNoMatchesRemovesOnlyItself() {
        let burst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(2, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [
                burst, CardFactory.number(4, .jade), CardFactory.number(5, .cobalt)
            ])
            .withDrawPile([])
            .build()
        let p0 = state.players[0].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(burst, playerID: p0))

        #expect(next.players[0].hand.count == 2)  // jade + cobalt survive
        // No same-colour sweep → no discard-all animation.
        #expect(!effects.contains { if case .animateDiscardAll = $0 { return true }; return false })
    }

    @Test("A Colour Burst that empties the hand wins the round for the team")
    func testBurstEmptyingHandWins() {
        let burst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(2, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [
                burst, CardFactory.number(3, .crimson), CardFactory.number(7, .crimson)
            ])
            .withDrawPile([])
            .build()
        let p0 = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(burst, playerID: p0))

        #expect(next.players[0].hand.isEmpty)
        #expect(next.players[0].hasFinishedRound)
        #expect(next.winState != nil)
    }

    // MARK: Solo! interaction

    @Test("Burst sweeping extras down to one card grants a Solo! grace window")
    func testBurstToOneWithExtrasGrantsGrace() {
        let burst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(2, .crimson))
            .withCurrentPlayer(0)  // human
            .withHand(forPlayer: 0, cards: [
                burst,
                CardFactory.number(3, .crimson),
                CardFactory.number(7, .crimson),
                CardFactory.number(9, .crimson),
                CardFactory.number(4, .jade)
            ])
            .withDrawPile([])
            .build()
        let p0 = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(burst, playerID: p0))

        #expect(afterPlay.players[0].hand.count == 1)
        #expect(afterPlay.players[0].hasCalledSolo == false)
        #expect(afterPlay.players[0].soloGraceAtOne == true)

        // The grace makes a declaration at one card legal.
        let (afterCall, _) = GameEngine.reduce(state: afterPlay, action: .callSolo(playerID: p0))
        #expect(afterCall.players[0].hasCalledSolo == true)
    }

    @Test("Burst that merely plays down to one (no extras removed) gives no grace")
    func testBurstToOneWithoutExtrasNoGrace() {
        let burst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(2, .crimson))
            .withCurrentPlayer(0)  // human
            .withHand(forPlayer: 0, cards: [burst, CardFactory.number(4, .jade)])
            .withDrawPile([])
            .build()
        let p0 = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(burst, playerID: p0))

        #expect(afterPlay.players[0].hand.count == 1)
        #expect(afterPlay.players[0].soloGraceAtOne != true)

        // With no grace, a declaration at one card is a no-op — the player is catchable.
        let (afterCall, _) = GameEngine.reduce(state: afterPlay, action: .callSolo(playerID: p0))
        #expect(afterCall.players[0].hasCalledSolo == false)
    }

    // MARK: Legality

    @Test("A Colour Burst is legal on a colour match")
    func testBurstLegalByColour() {
        let burst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(2, .crimson))
            .withHand(forPlayer: 0, cards: [burst])
            .build()
        #expect(GameRules.isCardLegal(burst, hand: [burst], state: state))
    }

    @Test("A Colour Burst is legal on a type match with another Colour Burst on top")
    func testBurstLegalByType() {
        let topBurst = CardFactory.discardColour(.jade)
        let handBurst = CardFactory.discardColour(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(topBurst)  // active colour becomes jade
            .withHand(forPlayer: 0, cards: [handBurst])
            .build()
        // Different colour, but discardColour == discardColour matches by type.
        #expect(GameRules.isCardLegal(handBurst, hand: [handBurst], state: state))
    }

    // MARK: Deck composition & value

    @Test("Advanced deck contains exactly one Colour Burst per colour and totals 104")
    func testAdvancedDeckComposition() {
        var rng = SeededRNG(seed: 1)
        let deck = Deck.standard(cardSet: .advanced, rng: &rng)
        let all = deck.drawPile + deck.discardPile
        let bursts = all.filter { if case .discardColour = $0.type { return true }; return false }
        #expect(bursts.count == 4)
        for colour in CardColour.allCases {
            #expect(bursts.filter { $0.colour == colour }.count == 1)
        }
        #expect(all.count == 104)   // +4 Draw Eight vs the pre-Phase-17 100
    }

    @Test("Standard deck contains one Colour Burst per colour; Beginner has none (Phase 17 B4a)")
    func testColourBurstSetMembership() {
        var rng = SeededRNG(seed: 1)
        // Standard now ships Colour Burst (moved down from Advanced in Phase 17 B4a).
        let standard = Deck.standard(cardSet: .standard, rng: &rng)
        let standardAll = standard.drawPile + standard.discardPile
        let standardBursts = standardAll.filter {
            if case .discardColour = $0.type { return true }; return false
        }
        #expect(standardBursts.count == 4)
        for colour in CardColour.allCases {
            #expect(standardBursts.filter { $0.colour == colour }.count == 1)
        }
        // Beginner still has none.
        let beginner = Deck.standard(cardSet: .beginner, rng: &rng)
        let beginnerAll = beginner.drawPile + beginner.discardPile
        #expect(!beginnerAll.contains { if case .discardColour = $0.type { return true }; return false })
    }

    @Test("A Colour Burst scores 20 points, like other action cards")
    func testBurstScores20() {
        #expect(GameEngine.pointValue(for: CardFactory.discardColour(.amber)) == 20)
    }

    @Test("A Draw Eight scores 60 points — the highest-tier draw card (Phase 17 B4b)")
    func testDrawEightScores60() {
        #expect(GameEngine.pointValue(for: CardFactory.drawEight(.crimson)) == 60)
    }

    @Test("A Colour Burst survives a Codable round-trip")
    func testBurstCodableRoundTrip() throws {
        let card = CardFactory.discardColour(.cobalt)
        let data = try JSONEncoder().encode(card)
        let decoded = try JSONDecoder().decode(Card.self, from: data)
        #expect(decoded == card)
        #expect(decoded.type == .discardColour)
        #expect(decoded.colour == .cobalt)
    }
}
