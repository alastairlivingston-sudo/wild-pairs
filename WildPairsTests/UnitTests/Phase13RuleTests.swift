import Testing
@testable import WildPairsCore

// Phase 13 rule fixes: final-card draw penalties always land, and Solo! must be declared
// while holding two cards (game-rules.md §Solo!, §Draw Two/Four Final-card rule).

@Suite("Phase 13 — final-card draw penalties")
struct FinalCardPenaltyTests {

    private func drawPile() -> [Card] {
        (1...9).map { CardFactory.number($0 % 10, .cobalt) }
    }

    @Test("Draw Four as the winning final card still makes the next player draw 4 (stacking on)")
    func testFinalDrawFourStackingOn() {
        let d4 = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [d4])
            .withDrawPile(drawPile())
            .build()
        #expect(state.ruleProfile.stackDrawCards == true)

        let (next, effects) = GameEngine.reduce(
            state: state, action: .playCard(d4, playerID: state.players[1].id))

        #expect(next.winState != nil, "Round should end — the +4 was the last card")
        #expect(next.players[2].hand.count == 4, "Next player must still draw the 4 penalty cards")
        #expect(next.pendingDrawCount == nil)
        #expect(effects.contains(.animateCardDraw(toPlayerID: next.players[2].id, count: 4)))
    }

    @Test("Draw Four as the winning final card still penalises with stacking disabled")
    func testFinalDrawFourStackingOff() {
        var profile = RuleProfile.standardTeams()
        profile.stackDrawCards = false
        let d4 = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [d4])
            .withDrawPile(drawPile())
            .build()

        let (next, _) = GameEngine.reduce(
            state: state, action: .playCard(d4, playerID: state.players[1].id))

        #expect(next.winState != nil)
        #expect(next.players[2].hand.count == 4)
    }

    @Test("A stacked Draw Two chain ending on the winner's final card delivers the whole stack")
    func testFinalStackedDrawTwoDeliversWholeStack() {
        let d2 = CardFactory.drawTwo(.jade)
        var state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.drawTwo(.crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [d2])
            .withDrawPile(drawPile())
            .build()
        state.pendingDrawCount = 2
        state.pendingDrawType = .drawTwo

        let (next, _) = GameEngine.reduce(
            state: state, action: .playCard(d2, playerID: state.players[1].id))

        #expect(next.winState != nil)
        #expect(next.players[2].hand.count == 4, "2 pending + 2 from the final Draw Two")
        #expect(next.pendingDrawCount == nil)
    }

    @Test("A non-final Draw Four still defers its penalty to the colour choice")
    func testNonFinalDrawFourUnchanged() {
        let d4 = CardFactory.drawFour()
        let keeper = CardFactory.number(3, .cobalt)
        let state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [d4, keeper])
            .withDrawPile(drawPile())
            .build()

        let (next, _) = GameEngine.reduce(
            state: state, action: .playCard(d4, playerID: state.players[1].id))

        #expect(next.winState == nil)
        #expect(next.pendingDecision != nil, "Colour choice should still be pending")
        #expect(next.players[2].hand.isEmpty, "Penalty only lands after the colour is chosen")
    }
}

@Suite("Phase 13 — Solo! declared before the second-to-last play")
struct SoloDeclarationTests {

    @Test("Declaring Solo while holding two cards is accepted and survives the play to one")
    func testDeclareAtTwoThenPlay() {
        let played = CardFactory.number(5, .crimson)
        let kept = CardFactory.number(3, .cobalt)
        let state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [played, kept])
            .withDrawPile([CardFactory.number(1, .jade)])
            .build()
        let humanID = state.players[0].id

        let (declared, declareEffects) = GameEngine.reduce(state: state, action: .callSolo(playerID: humanID))
        #expect(declared.players[0].hasCalledSolo == true)
        #expect(declareEffects.contains(.announceSolo(playerName: "You")))

        let (next, _) = GameEngine.reduce(state: declared, action: .playCard(played, playerID: humanID))
        #expect(next.players[0].hand.count == 1)
        #expect(next.players[0].hasCalledSolo == true, "Pre-declaration protects the one-card state")

        let (caught, _) = GameEngine.reduce(
            state: next, action: .callOutSolo(targetPlayerID: humanID, callerID: next.players[1].id))
        #expect(caught.players[0].hand.count == 1, "A declared player cannot be caught")
    }

    @Test("Calling Solo at one card after a normal play is rejected — too late")
    func testLateCallAtOneRejected() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [played, CardFactory.number(3, .cobalt)])
            .withDrawPile((0..<6).map { CardFactory.number($0, .jade) })
            .build()
        let humanID = state.players[0].id

        let (atOne, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: humanID))
        #expect(atOne.players[0].hand.count == 1)

        let (afterLateCall, _) = GameEngine.reduce(state: atOne, action: .callSolo(playerID: humanID))
        #expect(afterLateCall.players[0].hasCalledSolo == false,
                "No grace for play-driven drops — the declaration had to come at two cards")

        let (caught, _) = GameEngine.reduce(
            state: afterLateCall,
            action: .callOutSolo(targetPlayerID: humanID, callerID: afterLateCall.players[1].id))
        #expect(caught.players[0].hand.count == 3, "Caught: 1 card + 2 penalty")
    }

    @Test("An effect-driven drop to one card grants a grace declaration at one card")
    func testEffectDropGraceAllowsCallAtOne() {
        var state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 0, cards: [CardFactory.number(3, .cobalt)])
            .withDrawPile([])
            .build()
        state.players[0].soloGraceAtOne = true
        state.players[0].hasCalledSolo = false
        let humanID = state.players[0].id

        let (declared, _) = GameEngine.reduce(state: state, action: .callSolo(playerID: humanID))
        #expect(declared.players[0].hasCalledSolo == true)
    }

    @Test("A standing declaration is invalidated when the hand grows past two")
    func testDeclarationClearedWhenHandGrows() {
        var state = GameStateBuilder()
            .withPlayers()
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: (1...4).map { CardFactory.number($0, .cobalt) })
            .withDrawPile([])
            .build()
        state.players[0].hasCalledSolo = true
        state.players[0].soloGraceAtOne = true

        let (normalised, _) = GameEngine.reduce(state: state, action: .resumeGame)
        #expect(normalised.players[0].hasCalledSolo == false)
        #expect(normalised.players[0].soloGraceAtOne == nil)
    }

    @Test("AI forget chance falls with difficulty and Master never slips")
    func testAIForgetChanceLadder() {
        let chances = [Difficulty.easy, .medium, .hard, .expert, .master]
            .map { GameRules.aiSoloForgetChance(for: $0) }
        #expect(chances == chances.sorted(by: >), "Chance must not increase with difficulty")
        #expect(chances.last == 0, "Master never forgets")
        #expect(chances.first! > 0, "Easy must actually forget sometimes")
    }

    @Test("AI declaration on playing to one card matches the shared deterministic roll")
    func testAIDeclarationDeterministic() {
        let played = CardFactory.number(5, .crimson)
        let seed: UInt64 = 42
        let state = GameStateBuilder()
            .withPlayers()
            .withRngSeed(seed)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [played, CardFactory.number(3, .cobalt)])
            .withDrawPile([])
            .build()

        // Mirror the engine: rng seeded with rngSeed + actionCount (incremented to 1 before
        // the roll), and a number card consumes no randomness before the Solo! roll.
        var mirror = SeededRNG(seed: seed &+ 1)
        let expectedForgets = GameRules.aiForgetsSolo(difficulty: .easy, rng: &mirror)

        let (next, _) = GameEngine.reduce(
            state: state, action: .playCard(played, playerID: state.players[1].id))
        #expect(next.players[1].hasCalledSolo == !expectedForgets)
    }
}
