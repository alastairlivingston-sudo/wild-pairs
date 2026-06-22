import Testing
@testable import WildPairsCore

@Suite("Valid move rules")
struct ValidMoveTests {

    // MARK: Colour matching

    @Test("Card matching current colour is legal")
    func testColourMatch() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(3, .crimson))
            .build()
        #expect(GameRules.isLegal(CardFactory.number(7, .crimson), in: state))
    }

    @Test("Card not matching colour or number is illegal")
    func testNoMatch() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .build()
        #expect(!GameRules.isLegal(CardFactory.number(5, .crimson), in: state))
    }

    @Test("Card matching number but not colour is legal")
    func testNumberMatch() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(7, .cobalt))
            .build()
        #expect(GameRules.isLegal(CardFactory.number(7, .crimson), in: state))
    }

    // MARK: Action card matching

    @Test("Skip on Skip is legal (same action type)")
    func testSkipOnSkip() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.jade)
            .withTopDiscard(CardFactory.skip(.jade))
            .build()
        #expect(GameRules.isLegal(CardFactory.skip(.amber), in: state))
    }

    @Test("Skip on Reverse is illegal")
    func testSkipOnReverse() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.jade)
            .withTopDiscard(CardFactory.reverse(.jade))
            .build()
        #expect(!GameRules.isLegal(CardFactory.skip(.crimson), in: state))
    }

    @Test("Action card matching current colour is legal")
    func testActionCardColourMatch() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.amber)
            .withTopDiscard(CardFactory.number(5, .amber))
            .build()
        #expect(GameRules.isLegal(CardFactory.skip(.amber), in: state))
    }

    // MARK: Wild cards

    @Test("changeColour is always legal")
    func testChangeColourAlwaysLegal() {
        for colour in CardColour.allCases {
            let state = GameStateBuilder()
                .withPlayers()
                .withCurrentColour(colour)
                .build()
            #expect(GameRules.isLegal(CardFactory.changeColour(), in: state))
        }
    }

    @Test("drawFour is always legal per isLegal (restriction checked separately)")
    func testDrawFourIsLegalBase() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.jade)
            .build()
        #expect(GameRules.isLegal(CardFactory.drawFour(), in: state))
    }

    // MARK: Draw-Four restriction

    @Test("drawFourIsLegal false when player holds colour-matching card")
    func testDrawFourRestrictedWhenHasMatch() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [
                CardFactory.number(5, .crimson),
                CardFactory.drawFour()
            ])
            .build()
        let hand = state.players[0].hand
        #expect(!GameRules.drawFourIsLegal(hand: hand, state: state))
    }

    @Test("drawFourIsLegal true when player holds no colour-matching card")
    func testDrawFourAllowedWhenNoMatch() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [
                CardFactory.number(5, .cobalt),
                CardFactory.drawFour()
            ])
            .build()
        let hand = state.players[0].hand
        #expect(GameRules.drawFourIsLegal(hand: hand, state: state))
    }

    // MARK: All-Wild mode

    @Test("In allWild mode every card is legal")
    func testAllWildEveryCardLegal() {
        let state = GameStateBuilder()
            .withPlayers()
            .withMode(.allWild)
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .build()
        let cards: [Card] = [
            CardFactory.number(9, .crimson),
            CardFactory.skip(.amber),
            CardFactory.reverse(.jade),
            CardFactory.changeColour(),
        ]
        for card in cards {
            #expect(GameRules.isLegal(card, in: state))
        }
    }

    // MARK: nextIndex

    @Test("nextIndex clockwise wraps correctly")
    func testNextIndexClockwise() {
        #expect(GameRules.nextIndex(from: 3, direction: .clockwise, playerCount: 4) == 0)
        #expect(GameRules.nextIndex(from: 0, direction: .clockwise, playerCount: 4) == 1)
    }

    @Test("nextIndex counterClockwise wraps correctly")
    func testNextIndexCounterClockwise() {
        #expect(GameRules.nextIndex(from: 0, direction: .counterClockwise, playerCount: 4) == 3)
        #expect(GameRules.nextIndex(from: 2, direction: .counterClockwise, playerCount: 4) == 1)
    }

    @Test("nextIndex skip=2 skips one seat")
    func testNextIndexSkip2() {
        #expect(GameRules.nextIndex(from: 0, direction: .clockwise, playerCount: 4, skipCount: 2) == 2)
    }
}
