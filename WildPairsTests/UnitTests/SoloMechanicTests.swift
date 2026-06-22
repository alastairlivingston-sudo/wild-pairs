import Testing
@testable import WildPairsCore

@Suite("Solo! mechanic — auto-call and penalty")
struct SoloMechanicTests {

    // MARK: Auto-call by role (B5)

    @Test("Human dropping to one card is NOT auto-called (must call manually)")
    func testHumanMustCallSolo() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)  // seat 0 is human
            .withHand(forPlayer: 0, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p0id))
        #expect(next.players[0].hand.count == 1)
        #expect(next.players[0].hasCalledSolo == false)
    }

    @Test("AI dropping to one card is auto-called (hasCalledSolo == true)")
    func testAIAutoCallsSolo() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)  // seat 1 is AI
            .withHand(forPlayer: 1, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile([])
            .build()
        let p1id = state.players[1].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p1id))
        #expect(next.players[1].hand.count == 1)
        #expect(next.players[1].hasCalledSolo == true)
        #expect(effects.contains { if case .announceSolo = $0 { return true }; return false })
    }

    // MARK: Catch penalty (B4)

    @Test("Calling out a human who forgot Solo! draws the penalty cards")
    func testCallOutAppliesPenalty() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id

        // Human plays down to 1 card, does NOT call Solo!
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p0id))
        #expect(afterPlay.players[0].hand.count == 1)

        // Opponent calls them out → +2 penalty
        let (afterCatch, effects) = GameEngine.reduce(
            state: afterPlay,
            action: .callOutSolo(targetPlayerID: p0id, callerID: p1id)
        )
        #expect(afterCatch.players[0].hand.count == 3)  // 1 + 2 penalty
        #expect(effects.contains { if case .soloCallMissed = $0 { return true }; return false })
    }

    @Test("Calling out a player who DID call Solo! applies no penalty")
    func testCallOutAfterSoloCallNoPenalty() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id

        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p0id))
        let (afterSolo, _) = GameEngine.reduce(state: afterPlay, action: .callSolo(playerID: p0id))
        #expect(afterSolo.players[0].hasCalledSolo == true)

        let (afterCatch, _) = GameEngine.reduce(
            state: afterSolo,
            action: .callOutSolo(targetPlayerID: p0id, callerID: p1id)
        )
        #expect(afterCatch.players[0].hand.count == 1)  // no penalty
    }

    @Test("Calling out a player holding more than one card has no effect")
    func testCallOutWithMultipleCardsIgnored() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [
                CardFactory.number(1, .crimson),
                CardFactory.number(2, .crimson)
            ])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id
        let (next, _) = GameEngine.reduce(
            state: state,
            action: .callOutSolo(targetPlayerID: p0id, callerID: p1id)
        )
        #expect(next.players[0].hand.count == 2)
    }

    @Test("Calling out an AI is a no-op because AI auto-called")
    func testCallOutAIIsNoOp() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p1id = state.players[1].id
        let p0id = state.players[0].id

        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p1id))
        let (afterCatch, _) = GameEngine.reduce(
            state: afterPlay,
            action: .callOutSolo(targetPlayerID: p1id, callerID: p0id)
        )
        #expect(afterCatch.players[1].hand.count == 1)  // auto-called → no penalty
    }

    @Test("Calling yourself out has no effect")
    func testCallOutSelfIgnored() {
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p0id))
        let (afterCatch, _) = GameEngine.reduce(
            state: afterPlay,
            action: .callOutSolo(targetPlayerID: p0id, callerID: p0id)
        )
        #expect(afterCatch.players[0].hand.count == 1)
    }

    @Test("Solo! penalty disabled by house rule applies no penalty")
    func testSoloPenaltyDisabled() {
        var profile = RuleProfile.standardTeams()
        profile.soloCallEnabled = false
        let played = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [played, CardFactory.number(3, .crimson)])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(played, playerID: p0id))
        let (afterCatch, _) = GameEngine.reduce(
            state: afterPlay,
            action: .callOutSolo(targetPlayerID: p0id, callerID: p1id)
        )
        #expect(afterCatch.players[0].hand.count == 1)
    }
}
