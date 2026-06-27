import Testing
@testable import WildPairsCore

@Suite("Draw stacking (Phase 11 F)")
struct StackingTests {

    // MARK: +2 → +2 = 4

    @Test("Draw Two stacked on Draw Two accumulates to 4, then the stack is drawn in full")
    func testDrawTwoStacksOnDrawTwo() {
        let firstTwo = CardFactory.drawTwo(.crimson)
        let secondTwo = CardFactory.drawTwo(.jade)
        // Each playing hand keeps a filler card so playing the stack card doesn't empty their
        // hand and end the round before the stack itself is finished.
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [firstTwo, CardFactory.number(1, .amber)])
            .withHand(forPlayer: 1, cards: [secondTwo, CardFactory.number(1, .amber)])
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id
        let p2 = state.players[2].id

        let (afterFirst, _) = GameEngine.reduce(state: state, action: .playCard(firstTwo, playerID: p0))
        #expect(afterFirst.pendingDrawCount == 2)
        #expect(afterFirst.pendingDrawType == .drawTwo)
        #expect(afterFirst.currentPlayerIndex == 1)
        // The target does not draw immediately — they may stack instead.
        #expect(afterFirst.players[1].hand.count == 2)

        let (afterSecond, _) = GameEngine.reduce(state: afterFirst, action: .playCard(secondTwo, playerID: p1))
        #expect(afterSecond.pendingDrawCount == 4)
        #expect(afterSecond.pendingDrawType == .drawTwo)
        #expect(afterSecond.currentPlayerIndex == 2)

        let before = afterSecond.players[2].hand.count
        let (afterDraw, _) = GameEngine.reduce(state: afterSecond, action: .drawCard(playerID: p2))
        #expect(afterDraw.players[2].hand.count == before + 4)
        #expect(afterDraw.pendingDrawCount == nil)
        #expect(afterDraw.pendingDrawType == nil)
        #expect(afterDraw.currentPlayerIndex == 3)
    }

    // MARK: +2 → +4 = 6

    @Test("Draw Four stacked on Draw Two accumulates to 6")
    func testDrawFourStacksOnDrawTwo() {
        let two = CardFactory.drawTwo(.crimson)
        let four = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [two, CardFactory.number(1, .amber)])
            .withHand(forPlayer: 1, cards: [four, CardFactory.number(1, .amber)])
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id
        let p2 = state.players[2].id

        let (afterTwo, _) = GameEngine.reduce(state: state, action: .playCard(two, playerID: p0))
        #expect(afterTwo.pendingDrawCount == 2)

        // Draw Four still requires a colour choice; the stack accumulates once chosen.
        let (afterFourPlay, _) = GameEngine.reduce(state: afterTwo, action: .playCard(four, playerID: p1))
        if case .colourChoice(let pid) = afterFourPlay.pendingDecision {
            #expect(pid == p1)
        } else {
            Issue.record("Expected colourChoice pending for the Draw Four player")
        }
        #expect(afterFourPlay.pendingDrawCount == 2, "Stack must not grow until colour is chosen")

        let (afterColour, _) = GameEngine.reduce(state: afterFourPlay, action: .selectColour(.jade, playerID: p1))
        #expect(afterColour.pendingDrawCount == 6)
        #expect(afterColour.pendingDrawType == .drawFour)
        #expect(afterColour.currentPlayerIndex == 2)

        let before = afterColour.players[2].hand.count
        let (afterDraw, _) = GameEngine.reduce(state: afterColour, action: .drawCard(playerID: p2))
        #expect(afterDraw.players[2].hand.count == before + 6)
    }

    // MARK: +4 → +4 = 8

    @Test("Draw Four stacked on Draw Four accumulates to 8")
    func testDrawFourStacksOnDrawFour() {
        let firstFour = CardFactory.drawFour()
        let secondFour = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [firstFour, CardFactory.number(1, .jade)])
            .withHand(forPlayer: 1, cards: [secondFour, CardFactory.number(1, .jade)])
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id
        let p2 = state.players[2].id

        let (afterFirstPlay, _) = GameEngine.reduce(state: state, action: .playCard(firstFour, playerID: p0))
        let (afterFirstColour, _) = GameEngine.reduce(state: afterFirstPlay, action: .selectColour(.jade, playerID: p0))
        #expect(afterFirstColour.pendingDrawCount == 4)
        #expect(afterFirstColour.currentPlayerIndex == 1)

        let (afterSecondPlay, _) = GameEngine.reduce(state: afterFirstColour, action: .playCard(secondFour, playerID: p1))
        let (afterSecondColour, _) = GameEngine.reduce(state: afterSecondPlay, action: .selectColour(.amber, playerID: p1))
        #expect(afterSecondColour.pendingDrawCount == 8)
        #expect(afterSecondColour.currentPlayerIndex == 2)

        let before = afterSecondColour.players[2].hand.count
        let (afterDraw, _) = GameEngine.reduce(state: afterSecondColour, action: .drawCard(playerID: p2))
        #expect(afterDraw.players[2].hand.count == before + 8)
    }

    // MARK: +2 blocked on +4

    @Test("A Draw Two cannot be played to answer a pending Draw Four stack")
    func testDrawTwoBlockedOnDrawFourStack() {
        let four = CardFactory.drawFour()
        let two = CardFactory.drawTwo(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [four, CardFactory.number(1, .jade)])
            .withHand(forPlayer: 1, cards: [two, CardFactory.number(1, .jade)])
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id

        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(four, playerID: p0))
        let (afterColour, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.jade, playerID: p0))
        #expect(afterColour.pendingDrawType == .drawFour)

        #expect(!GameEngine.isLegalMove(state: afterColour, action: .playCard(two, playerID: p1)))

        // Attempting it anyway leaves the stack untouched (engine rejects the move).
        let (afterRejected, _) = GameEngine.reduce(state: afterColour, action: .playCard(two, playerID: p1))
        #expect(afterRejected.pendingDrawCount == 4)
        #expect(afterRejected.players[1].hand.contains { $0.id == two.id })
    }

    // MARK: Toggle off = legacy behaviour

    @Test("With stacking disabled, Draw Two resolves immediately and never sets a pending stack")
    func testStackingDisabledIsLegacyImmediateDraw() {
        let card = CardFactory.drawTwo(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile({ var p = RuleProfile.standardTeams(); p.stackDrawCards = false; return p }())
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card, CardFactory.number(1, .jade)])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0 = state.players[0].id
        let before = state.players[1].hand.count

        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0))
        #expect(next.pendingDrawCount == nil)
        #expect(next.pendingDrawType == nil)
        #expect(next.players[1].hand.count == before + 2)
        #expect(next.currentPlayerIndex == 2, "Target is skipped, legacy rule")
    }
}
