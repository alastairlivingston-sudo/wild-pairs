import Testing
@testable import WildPairsCore


@Suite("Card effects")
struct CardEffectTests {

    // MARK: Skip

    @Test("Skip advances currentPlayerIndex by 2 (skips player 1)")
    func testSkipSkipsCorrectPlayer() {
        let card = CardFactory.skip(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .cobalt) })
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.currentPlayerIndex == 2)
    }

    // MARK: Skip Two

    @Test("Skip Two advances from player 0 to player 3 (skips 1 and 2)")
    func testSkipTwoSkipsTwoPlayers() {
        let card = CardFactory.skipTwo(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile({ var p = RuleProfile.standardTeams(); p.cardSet = .advanced; p.skipTwoEnabled = true; return p }())
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.currentPlayerIndex == 3)
    }

    // MARK: Reverse

    @Test("Reverse flips turn direction to counterClockwise")
    func testReverseFlipsDirection() {
        let card = CardFactory.reverse(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .cobalt) })
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.turnDirection == .counterClockwise)
    }

    @Test("Reverse from player 1 clockwise advances to player 0 (counter-clockwise)")
    func testReverseDirectionWith4Players() {
        let card = CardFactory.reverse(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .cobalt) })
            .build()
        let p1id = state.players[1].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p1id))
        #expect(next.turnDirection == .counterClockwise)
        // CCW from seat 1: next is seat 0
        #expect(next.currentPlayerIndex == 0)
    }

    // MARK: Draw Two

    @Test("Draw Two gives target player 2 cards and skips their turn (stacking disabled, legacy rule)")
    func testDrawTwoAppliesPenaltyAndSkips() {
        let card = CardFactory.drawTwo(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile({ var p = RuleProfile.standardTeams(); p.stackDrawCards = false; return p }())
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let before = state.players[1].hand.count
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.players[1].hand.count == before + 2)
        // Player 1 skipped → player 2's turn
        #expect(next.currentPlayerIndex == 2)
    }

    // MARK: Draw Four

    @Test("Draw Four sets pendingDecision.colourChoice for playing player")
    func testDrawFourSetsPendingColourChoice() {
        let card = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        if case .colourChoice(let pid) = next.pendingDecision {
            #expect(pid == p0id)
        } else {
            Issue.record("Expected .colourChoice pending decision")
        }
    }

    @Test("Selecting colour after Draw Four deals 4 cards to next player and skips them (stacking disabled, legacy rule)")
    func testDrawFourPenaltyAfterColourSelect() {
        let card = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile({ var p = RuleProfile.standardTeams(); p.stackDrawCards = false; return p }())
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .jade) })
            .build()
        let p0id = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        let before = afterPlay.players[1].hand.count
        let (afterColour, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.jade, playerID: p0id))
        #expect(afterColour.currentColour == .jade)
        #expect(afterColour.players[1].hand.count == before + 4)
        #expect(afterColour.currentPlayerIndex == 2)
    }

    // MARK: Change Colour

    @Test("Change Colour sets pendingDecision.colourChoice")
    func testChangeColourSetsPending() {
        let card = CardFactory.changeColour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.amber)
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        if case .colourChoice(let pid) = next.pendingDecision {
            #expect(pid == p0id)
        } else {
            Issue.record("Expected colourChoice pending decision")
        }
    }

    @Test("Selecting colour after Change Colour advances turn")
    func testSelectColourAdvancesTurn() {
        let card = CardFactory.changeColour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.amber)
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        let (afterColour, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.jade, playerID: p0id))
        #expect(afterColour.currentColour == .jade)
        #expect(afterColour.pendingDecision == nil)
        #expect(afterColour.currentPlayerIndex == 1)
    }

    // MARK: Discard All

    @Test("Discard All removes all cards of chosen colour from player hand")
    func testDiscardAllRemovesChosenColour() {
        let card = CardFactory.discardAll()
        let hand: [Card] = [
            CardFactory.number(1, .cobalt),
            CardFactory.number(2, .cobalt),
            CardFactory.number(3, .jade),
            card
        ]
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: hand)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        let (afterColour, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.cobalt, playerID: p0id))
        let remaining = afterColour.players[0].hand
        #expect(!remaining.contains { $0.colour == .cobalt })
        #expect(remaining.contains { $0.colour == .jade })
    }

    // MARK: Targeted Draw

    @Test("Targeted Draw sets pendingDecision for player to choose target")
    func testTargetedDrawSetsPending() {
        let card = CardFactory.targetedDraw(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile({ var p = RuleProfile.standardTeams(); p.cardSet = .advanced; p.targetedDrawEnabled = true; return p }())
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        if case .targetChoice(let pid, _) = next.pendingDecision {
            #expect(pid == p0id)
        } else {
            Issue.record("Expected targetChoice pending decision")
        }
    }

    @Test("Targeted Draw gives target 2 cards without skipping their turn (canonical rule)")
    func testTargetedDrawDoesNotSkipTarget() {
        let card = CardFactory.targetedDraw(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        let before = afterPlay.players[1].hand.count
        let (afterTarget, _) = GameEngine.reduce(state: afterPlay, action: .selectTarget(targetPlayerID: p1id, playerID: p0id))
        // Target draws 2
        #expect(afterTarget.players[1].hand.count == before + 2)
        // Turn advances to player 1 (NOT skipped)
        #expect(afterTarget.currentPlayerIndex == 1)
    }

    // MARK: Forced Swap

    @Test("Forced Swap exchanges complete hands between two players")
    func testForcedSwapExchangesHands() {
        let card = CardFactory.forcedSwap(.crimson)
        let myHand: [Card] = [card, CardFactory.number(3, .jade)]
        let theirHand: [Card] = [CardFactory.number(7, .amber), CardFactory.number(8, .amber)]
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: myHand)
            .withHand(forPlayer: 2, cards: theirHand)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let p2id = state.players[2].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        let (afterSwap, _) = GameEngine.reduce(state: afterPlay, action: .selectTarget(targetPlayerID: p2id, playerID: p0id))
        // After swap: player 0 has player 2's old hand (minus the card that was played)
        // and player 2 has player 0's old remaining hand
        let p0HandAfter = afterSwap.players[0].hand
        let p2HandAfter = afterSwap.players[2].hand

        // Player 0 should now hold what player 2 had
        for c in theirHand {
            #expect(p0HandAfter.contains { $0.id == c.id })
        }
        // Player 2 should now hold what player 0 had (excluding played card)
        let myRemainingHand = myHand.filter { $0.id != card.id }
        for c in myRemainingHand {
            #expect(p2HandAfter.contains { $0.id == c.id })
        }
    }

    // MARK: Team Play

    @Test("Team Play causes both partners to draw 1 card each (default rule)")
    func testTeamPlayBothPartnersDraw() {
        let card = CardFactory.teamPlay(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile((0..<10).map { CardFactory.number($0, .jade) })
            .build()
        let p0id = state.players[0].id
        let before0 = state.players[0].hand.count  // 1 (just the teamPlay card)
        let before2 = state.players[2].hand.count  // 0 default

        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        // Both seat 0 (Team A) and seat 2 (Team A, partner) draw 1 card each
        // Player 0 played 1 card (hand -1) then drew 1 = net 0 change
        #expect(next.players[0].hand.count == before0 - 1 + 1)
        #expect(next.players[2].hand.count == before2 + 1)
        // Opponents (seats 1, 3) unchanged
        #expect(next.players[1].hand.count == state.players[1].hand.count)
        #expect(next.players[3].hand.count == state.players[3].hand.count)
    }

    // MARK: Invalid play rejection

    @Test("Playing a card not in player's hand has no effect")
    func testPlayCardNotInHand() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson)])
            .build()
        let p0id = state.players[0].id
        let impostor = CardFactory.number(5, .crimson)  // different UUID
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(impostor, playerID: p0id))
        #expect(next.currentPlayerIndex == state.currentPlayerIndex)
    }

    @Test("Playing out of turn has no effect")
    func testPlayOutOfTurn() {
        let card = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withCurrentPlayer(1)
            .withHand(forPlayer: 0, cards: [card])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.currentPlayerIndex == 1)
    }
}
