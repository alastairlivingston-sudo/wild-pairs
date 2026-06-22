import Testing
@testable import WildPairsCore

@Suite("Win conditions")
struct WinConditionTests {

    // MARK: bothTeammatesOut (default)

    @Test("Round does NOT end when only one Team A player empties hand (bothTeammatesOut)")
    func testPartialFinishDoesNotTriggerWin() {
        let card = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        // Player 0 (Team A) is out, but player 2 (Team A partner) still has cards
        #expect(next.phase == .playing)
        #expect(next.winState == nil)
        #expect(!effects.contains { if case .playRoundEnd = $0 { return true }; return false })
    }

    @Test("Round ends when both Team A players empty hands (bothTeammatesOut)")
    func testBothTeammatesOutWinsRound() {
        let card = CardFactory.number(5, .crimson)
        // Seat 2 (Team A partner) already finished
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withFinished(playerAtSeat: 2)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.phase == .roundEnded)
        #expect(next.winState?.winningTeam == .teamA)
        #expect(effects.contains { if case .playRoundEnd(let t) = $0 { return t == .teamA }; return false })
    }

    @Test("Round ends when both Team B players empty hands (bothTeammatesOut)")
    func testTeamBWinsRound() {
        let card = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 1, cards: [card])
            .withFinished(playerAtSeat: 3)
            .withDrawPile([])
            .build()
        let p1id = state.players[1].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p1id))
        #expect(next.phase == .roundEnded)
        #expect(next.winState?.winningTeam == .teamB)
        #expect(effects.contains { if case .playRoundEnd(let t) = $0 { return t == .teamB }; return false })
    }

    // MARK: singleOut

    @Test("Round ends the moment any player empties hand (singleOut)")
    func testSingleOutEndsRoundImmediately() {
        let card = CardFactory.number(5, .crimson)
        var profile = RuleProfile.standardTeams()
        profile.winCondition = .singleOut
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.phase == .roundEnded)
        #expect(next.winState?.winningTeam == .teamA)
    }

    // MARK: Game-level win (scoring)

    @Test("Game ends when winning team reaches targetScore across rounds")
    func testGameEndsOnTargetScore() {
        var profile = RuleProfile.standardTeams()
        profile.scoringEnabled = true
        profile.targetScore = 10
        // Seat 2 (Team A partner) already finished
        let card = CardFactory.number(5, .crimson)
        var state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withFinished(playerAtSeat: 2)
            .withDrawPile([])
            .build()
        // Give opponents cards worth more than targetScore so points accumulate
        state.players[1].hand = [CardFactory.number(9, .jade), CardFactory.number(9, .jade)]
        state.players[3].hand = [CardFactory.number(9, .jade)]
        let p0id = state.players[0].id
        let (next, effects) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.phase == .gameEnded)
        #expect(effects.contains { if case .playGameEnd(let t) = $0 { return t == .teamA }; return false })
    }

    // MARK: Win state fields

    @Test("WinState records winning team correctly")
    func testWinStateFields() {
        let card = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withFinished(playerAtSeat: 2)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        guard let win = next.winState else {
            Issue.record("Expected winState to be set")
            return
        }
        #expect(win.winningTeam == .teamA)
        #expect(win.reason == .bothTeammatesEmptiedHands)
    }

    // MARK: Points calculation

    @Test("Score awarded to winning team equals sum of losing team's card values")
    func testScoreCalculation() {
        var profile = RuleProfile.standardTeams()
        profile.scoringEnabled = true
        profile.targetScore = 1000
        let card = CardFactory.number(5, .crimson)
        var state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withFinished(playerAtSeat: 2)
            .withDrawPile([])
            .build()
        // Give Team B (seats 1 and 3) known hand values
        state.players[1].hand = [CardFactory.number(3, .jade)]   // 3 pts
        state.players[3].hand = [CardFactory.number(7, .amber)]  // 7 pts
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        // Team A wins; Team B had 3+7=10 points in hand
        #expect(next.teamScores[.teamA] == 10)
    }

    // MARK: New round after win

    @Test("beginNewRound increments roundNumber and resets player hands")
    func testBeginNewRoundResetsState() {
        var profile = RuleProfile.standardTeams()
        profile.cardSet = .standard
        var state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withFinished(playerAtSeat: 0)
            .withFinished(playerAtSeat: 2)
            .withDrawPile([])
            .build()
        state.phase = .roundEnded
        state.roundNumber = 1
        let (next, _) = GameEngine.reduce(state: state, action: .beginNewRound)
        #expect(next.roundNumber == 2)
        #expect(next.phase == .playing)
        for player in next.players {
            #expect(player.hand.count == profile.initialHandSize)
            #expect(!player.hasFinishedRound)
        }
    }
}
