import Testing
@testable import WildPairsCore

// MARK: - Scenario Tests
// Covers multi-step rule interactions from testing-strategy.md §5.
// Persistence, AI, and Side-to-Side team-pass scenarios are in their respective test files.

@Suite("Engine scenarios")
struct ScenarioTests {

    // MARK: Draw scenarios

    @Test("Player with no valid cards — legalPlays returns empty")
    func testHumanHasNoValidCardMustDraw() {
        // Top discard is Crimson 5; hand holds only Cobalt 7 and Jade 3 — no match
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [
                CardFactory.number(7, .cobalt),
                CardFactory.number(3, .jade)
            ])
            .withDrawPile([CardFactory.number(1, .amber)])
            .build()
        let p0id = state.players[0].id
        let legal = GameEngine.legalPlays(state: state, for: p0id)
        #expect(legal.isEmpty)
    }

    @Test("Human draws a matching card — discard updates when card is then played")
    func testHumanDrawsPlayableCard() {
        let matchingCard = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [])
            .withDrawPile([matchingCard])
            .build()
        let p0id = state.players[0].id

        // Player draws — gets the crimson 5
        let (afterDraw, _) = GameEngine.reduce(state: state, action: .drawCard(playerID: p0id))
        // Turn has already advanced (simplified Phase 2 behaviour)
        #expect(afterDraw.players[0].hand.count == 1)

        // The player could then play it on their next turn if colour/number matches
        // Simulate that by setting them as current player again
        var afterDrawAsCurrentPlayer = afterDraw
        afterDrawAsCurrentPlayer.currentPlayerIndex = 0
        afterDrawAsCurrentPlayer.currentColour = .crimson

        let (afterPlay, _) = GameEngine.reduce(
            state: afterDrawAsCurrentPlayer,
            action: .playCard(matchingCard, playerID: p0id)
        )
        #expect(afterPlay.deck.topDiscard?.id == matchingCard.id)
        #expect(afterPlay.players[0].hand.count == 0)
    }

    @Test("Human draws an unplayable card — turn passes, draw pile shrinks by 1")
    func testHumanDrawsUnplayableCardTurnPasses() {
        let unplayable = CardFactory.number(9, .amber)  // doesn't match cobalt
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [])
            .withDrawPile([unplayable])
            .build()
        let p0id = state.players[0].id
        let drawPileBefore = state.deck.drawPile.count

        let (next, _) = GameEngine.reduce(state: state, action: .drawCard(playerID: p0id))
        #expect(next.players[0].hand.count == 1)
        #expect(next.deck.drawPile.count == drawPileBefore - 1)
        #expect(next.currentPlayerIndex == 1)  // turn advanced
    }

    @Test("Drawing a playable card keeps the turn so the player can play it (mustPlayAfterDraw)")
    func testDrawPlayableCardKeepsTurn() {
        // Colour is cobalt, top is cobalt 3; hand has no match. Draw pile yields a cobalt 8 (playable).
        let playable = CardFactory.number(8, .cobalt)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [CardFactory.number(7, .crimson)])  // no legal play
            .withDrawPile([playable])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .drawCard(playerID: p0id))
        #expect(next.players[0].hand.count == 2)
        // Turn stays with player 0 so they can play the drawn cobalt 8
        #expect(next.currentPlayerIndex == 0)
        // And the drawn card is indeed now a legal play
        #expect(GameEngine.legalPlays(state: next, for: p0id).contains { $0.id == playable.id })
    }

    // MARK: Deck conservation

    @Test("No card leaks out of the deck when a new game is dealt (standard = 72 cards)")
    func testNewGameConservesAllCards() {
        let config = GameConfig(
            mode: .standardTeams,
            players: [
                PlayerConfig(name: "A0", role: .human, teamID: .teamA, difficulty: .easy, seatPosition: 0),
                PlayerConfig(name: "B1", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 1),
                PlayerConfig(name: "A2", role: .ai, teamID: .teamA, difficulty: .easy, seatPosition: 2),
                PlayerConfig(name: "B3", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 3)
            ],
            ruleProfile: .standardTeams(),
            seed: 42
        )
        let (state, _) = GameEngine.reduce(state: GameState(players: []), action: .newGame(config: config))
        let inHands = state.players.reduce(0) { $0 + $1.hand.count }
        let total = inHands + state.deck.drawPile.count + state.deck.discardPile.count
        #expect(total == 72)
        #expect(inHands == 28)  // 4 players × 7
        #expect(state.deck.discardPile.count == 1)  // exactly one start card
    }

    @Test("No card leaks when a new round begins")
    func testBeginNewRoundConservesAllCards() {
        var state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(.standardTeams())
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        state.phase = .roundEnded
        let (next, _) = GameEngine.reduce(state: state, action: .beginNewRound)
        let inHands = next.players.reduce(0) { $0 + $1.hand.count }
        let total = inHands + next.deck.drawPile.count + next.deck.discardPile.count
        #expect(total == 72)
        #expect(next.deck.discardPile.count == 1)
    }

    // MARK: Wild card colour flow

    @Test("Human plays Wild — enters colourChoice, picks Jade, colour changes")
    func testHumanChoosesColourAfterWild() {
        let card = CardFactory.changeColour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id

        let (pending, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        if case .colourChoice(let pid) = pending.pendingDecision {
            #expect(pid == p0id)
        } else {
            Issue.record("Expected colourChoice pending")
        }

        let (resolved, _) = GameEngine.reduce(state: pending, action: .selectColour(.jade, playerID: p0id))
        #expect(resolved.currentColour == .jade)
        #expect(resolved.pendingDecision == nil)
        #expect(resolved.currentPlayerIndex == 1)
    }

    // MARK: Targeted Draw flow

    @Test("Human plays Targeted Draw — pending target, target draws +2, target NOT skipped")
    func testHumanChoosesTargetAfterTargetedDraw() {
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

        let (pending, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        if case .targetChoice(let pid, let targets) = pending.pendingDecision {
            #expect(pid == p0id)
            // Valid targets are opponents only (seats 1 and 3 for seat 0)
            #expect(targets.contains(p1id))
        } else {
            Issue.record("Expected targetChoice pending")
        }

        let before = pending.players[1].hand.count
        let (resolved, _) = GameEngine.reduce(state: pending, action: .selectTarget(targetPlayerID: p1id, playerID: p0id))
        #expect(resolved.players[1].hand.count == before + 2)
        // Target (player 1) is NOT skipped
        #expect(resolved.currentPlayerIndex == 1)
    }

    // MARK: Reshuffle

    @Test("Draw pile exhausted — discard reshuffles to allow further draws")
    func testResuffleWhenDrawPileEmpty() {
        // Start with empty draw pile and a discard pile of 4 cards (+ the top)
        let topCard = CardFactory.number(5, .crimson)
        let discardCards: [Card] = (1...4).map { CardFactory.number($0, .cobalt) }
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(topCard)
            .withDrawPile([])
            .build()
        // Manually populate discard pile beyond just the top card
        for c in discardCards { state.deck.discard(c) }

        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .drawCard(playerID: p0id))
        // After reshuffle, player should have drawn a card (no crash, no nil draw)
        #expect(next.players[0].hand.count == 1)
    }

    // MARK: Solo! mechanic

    @Test("Player calls Solo! when they reach 1 card — flag set, no penalty")
    func testSoloCallSetsFlag() {
        let card = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card, CardFactory.number(3, .crimson)])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id

        // Play a card, leaving 1 in hand
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(afterPlay.players[0].hand.count == 1)
        #expect(afterPlay.players[0].hasCalledSolo == false)

        // Call Solo!
        let (afterSolo, _) = GameEngine.reduce(state: afterPlay, action: .callSolo(playerID: p0id))
        #expect(afterSolo.players[0].hasCalledSolo == true)
        // No penalty draw
        #expect(afterSolo.players[0].hand.count == 1)
    }

    @Test("Solo! call with > 1 card has no effect")
    func testSoloCallIgnoredWithMultipleCards() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [
                CardFactory.number(1, .crimson),
                CardFactory.number(2, .crimson)
            ])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .callSolo(playerID: p0id))
        // callSolo on a player with >1 card is a no-op
        #expect(next.players[0].hasCalledSolo == false)
        #expect(next.players[0].hand.count == 2)
    }

    // MARK: Multi-turn win scenario

    @Test("Player goes out, partner still has cards — play continues, win triggers when partner goes out")
    func testPlayerGoesOutButPartnerStillHasCards() {
        let lastCardP0 = CardFactory.number(5, .crimson)
        let lastCardP2 = CardFactory.number(7, .crimson)

        // Build state: player 0 has 1 card, player 2 has 1 card, others have cards
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [lastCardP0])
            .withHand(forPlayer: 1, cards: [CardFactory.number(3, .jade)])
            .withHand(forPlayer: 2, cards: [lastCardP2])
            .withHand(forPlayer: 3, cards: [CardFactory.number(8, .amber)])
            .withDrawPile([])
            .build()

        let p0id = state.players[0].id

        // Player 0 plays last card — team partner (seat 2) still has cards
        let (afterP0Out, _) = GameEngine.reduce(state: state, action: .playCard(lastCardP0, playerID: p0id))
        #expect(afterP0Out.phase == .playing)
        #expect(afterP0Out.winState == nil)
        #expect(afterP0Out.players[0].hasFinishedRound == true)

        // Fast-forward to player 2's turn
        var stateAtP2Turn = afterP0Out
        stateAtP2Turn.currentPlayerIndex = 2
        stateAtP2Turn.currentColour = .crimson

        let p2id = stateAtP2Turn.players[2].id
        let (afterWin, effects) = GameEngine.reduce(state: stateAtP2Turn, action: .playCard(lastCardP2, playerID: p2id))
        #expect(afterWin.phase == .roundEnded)
        #expect(afterWin.winState?.winningTeam == .teamA)
        #expect(effects.contains { if case .playRoundEnd(let t) = $0 { return t == .teamA }; return false })
    }

    // MARK: All-Wild mode

    @Test("In All-Wild mode every card in hand is legal regardless of colour or type")
    func testAllWildModeEveryCardPlayable() {
        let state = GameStateBuilder()
            .withPlayers()
            .withMode(.allWild)
            .withRuleProfile(RuleProfile.allWild())
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [
                CardFactory.number(9, .jade),
                CardFactory.skip(.cobalt),
                CardFactory.reverse(.amber),
                CardFactory.drawTwo(.jade),
                CardFactory.changeColour(),
                CardFactory.drawFour()
            ])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let legal = GameEngine.legalPlays(state: state, for: p0id)
        #expect(legal.count == state.players[0].hand.count)
    }

    // MARK: Pass turn

    @Test("passTurn advances to next player without playing a card")
    func testPassTurnAdvancesPlayer() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .passTurn(playerID: p0id))
        #expect(next.currentPlayerIndex == 1)
    }

    @Test("passTurn by non-current player has no effect")
    func testPassTurnByWrongPlayerIgnored() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        // Player 1 tries to pass when it's player 0's turn
        let p1id = state.players[1].id
        let (next, _) = GameEngine.reduce(state: state, action: .passTurn(playerID: p1id))
        #expect(next.currentPlayerIndex == 0)
    }

    // MARK: Pause / resume

    @Test("pauseGame sets phase to roundEnded; resumeGame sets phase to playing")
    func testPauseResumeCyclePreservesState() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        let (paused, _) = GameEngine.reduce(state: state, action: .pauseGame)
        #expect(paused.phase == .roundEnded)

        let (resumed, _) = GameEngine.reduce(state: paused, action: .resumeGame)
        #expect(resumed.phase == .playing)
        #expect(resumed.currentColour == state.currentColour)
    }

    // MARK: forceState

    @Test("forceState replaces state wholesale — used for snapshot restore")
    func testForceStateReplaces() {
        let initial = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        let replacement = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.jade)
            .withDrawPile([])
            .build()
        let (next, _) = GameEngine.reduce(state: initial, action: .forceState(replacement))
        #expect(next.currentColour == .jade)
    }
}
