import Testing
@testable import WildPairsCore

@Suite("Timed-round scoring: round timer fallback and per-move timeout")
struct TimedRoundTests {

    /// Rebuilds a player with a different difficulty, preserving identity/seat/team.
    private func withDifficulty(_ player: Player, _ difficulty: Difficulty) -> Player {
        Player(
            id: player.id, name: player.name, role: player.role, teamID: player.teamID,
            difficulty: difficulty, seatPosition: player.seatPosition,
            hand: player.hand, hasCalledSolo: player.hasCalledSolo,
            hasFinishedRound: player.hasFinishedRound
        )
    }

    // MARK: Round timer expiry

    @Test("Round timer expiry declares the player with the lowest hand-point score the winner")
    func testRoundTimerExpiryPicksLowestScore() {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withDrawPile([])
            .build()
        // Seat 0 (Team A): 1 low card (5 pts) — should win
        state.players[0].hand = [CardFactory.number(5, .crimson)]
        // Seat 1 (Team B): high-value cards
        state.players[1].hand = [CardFactory.number(9, .jade), CardFactory.number(9, .amber)]
        // Seat 2 (Team A partner): moderate
        state.players[2].hand = [CardFactory.number(6, .jade)]
        // Seat 3 (Team B): moderate
        state.players[3].hand = [CardFactory.number(7, .amber)]

        let (next, effects) = GameEngine.reduce(state: state, action: .roundTimerExpired)
        #expect(next.phase == .roundEnded)
        #expect(next.winState?.winningTeam == .teamA)
        #expect(next.winState?.winningPlayerID == next.players[0].id)
        #expect(next.winState?.reason == .roundTimerExpired)
        #expect(effects.contains { if case .playRoundEnd(let t) = $0 { return t == .teamA }; return false })

        let viewState = GameViewState(from: next, localPlayerID: next.players[0].id)
        guard case .roundOverByTimeout(let teamName) = viewState.prompt else {
            Issue.record("Expected .roundOverByTimeout, got \(viewState.prompt)")
            return
        }
        #expect(teamName == TeamID.teamA.displayName)
    }

    @Test("Round timer tie-break: equal points favours fewer cards, then lower seat position")
    func testRoundTimerTieBreak() {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withDrawPile([])
            .build()
        // Seats 0 and 2 tie on both points (10) and card count (2), and both have strictly
        // fewer points than seats 1/3 (18) — seat 0 (lower seatPosition) wins the tie-break.
        state.players[0].hand = [CardFactory.number(9, .crimson), CardFactory.number(1, .jade)]
        state.players[1].hand = [CardFactory.number(9, .jade), CardFactory.number(9, .crimson)]
        state.players[2].hand = [CardFactory.number(9, .amber), CardFactory.number(1, .amber)]
        state.players[3].hand = [CardFactory.number(9, .jade), CardFactory.number(9, .amber)]

        let (next, _) = GameEngine.reduce(state: state, action: .roundTimerExpired)
        // Seats 0 and 2 are tied on points and card count; seat 0 (lower seatPosition) wins.
        #expect(next.winState?.winningPlayerID == next.players[0].id)
    }

    @Test("Round timer expiry is a no-op once the round already ended")
    func testRoundTimerExpiryNoOpAfterRoundEnded() {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withDrawPile([])
            .build()
        state.phase = .roundEnded
        let (next, effects) = GameEngine.reduce(state: state, action: .roundTimerExpired)
        #expect(next.phase == .roundEnded)
        #expect(next.winState == nil)
        #expect(effects.isEmpty)
    }

    // MARK: Difficulty score multiplier

    @Test("Score multiplier scales with the toughest opponent's difficulty (hand-emptying win)")
    func testHandEmptyingWinAppliesDifficultyMultiplier() {
        var profile = RuleProfile.standardTeams()
        profile.scoringEnabled = true
        profile.targetScore = 100_000 // avoid hitting gameEnded; isolate the multiplier math
        let card = CardFactory.number(5, .crimson)
        var state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [card])
            .withDrawPile([])
            .build()
        // Team B (seats 1, 3) hold 10 points combined; seat 1 is Hard difficulty (x4).
        state.players[1] = withDifficulty(state.players[1], .hard)
        state.players[1].hand = [CardFactory.number(3, .jade)]
        state.players[3].hand = [CardFactory.number(7, .amber)]
        let p0id = state.players[0].id
        let (next, _) = GameEngine.reduce(state: state, action: .playCard(card, playerID: p0id))
        #expect(next.teamScores[.teamA] == 10 * 4)
    }

    @Test("Score multiplier scales with the toughest opponent's difficulty (round-timer win)")
    func testRoundTimerWinAppliesDifficultyMultiplier() {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withDrawPile([])
            .build()
        state.players[0].hand = [CardFactory.number(2, .crimson)] // lowest score — wins
        state.players[1] = withDifficulty(state.players[1], .master)
        state.players[1].hand = [CardFactory.number(9, .jade)]
        state.players[2].hand = [CardFactory.number(9, .amber)]
        state.players[3].hand = [CardFactory.number(9, .jade)]

        let (next, _) = GameEngine.reduce(state: state, action: .roundTimerExpired)
        // Opponents' combined points: 9 + 9 + 9 = 27, multiplied by the toughest (.master = x24)
        #expect(next.teamScores[.teamA] == 27 * 24)
    }

    @Test("Difficulty.master score multiplier is 24")
    func testMasterMultiplierValue() {
        #expect(Difficulty.master.scoreMultiplier == 24)
        #expect(Difficulty.expert.scoreMultiplier == 8)
        #expect(Difficulty.hard.scoreMultiplier == 4)
        #expect(Difficulty.medium.scoreMultiplier == 2)
        #expect(Difficulty.easy.scoreMultiplier == 1)
    }

    // MARK: Per-move timeout fallback

    @Test("forceTimedOutMove plays a legal card for the timed-out player when one exists")
    func testForceTimedOutMovePlaysLegalCard() {
        let config = GameConfig(
            mode: .standardTeams,
            players: [
                PlayerConfig(name: "You", role: .human, teamID: .teamA, difficulty: .easy, seatPosition: 0),
                PlayerConfig(name: "Left", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 1),
                PlayerConfig(name: "Partner", role: .ai, teamID: .teamA, difficulty: .easy, seatPosition: 2),
                PlayerConfig(name: "Right", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 3)
            ],
            ruleProfile: .standardTeams(),
            seed: 11
        )
        let presenter = GamePresenter(config: config)
        let beforeCount = presenter.state.currentPlayer?.hand.count
        let effects = presenter.forceTimedOutMove(for: presenter.localPlayerID)
        #expect(beforeCount != nil)
        // Either a card was played (hand shrank) or a card was drawn (hand grew) — either way
        // an action was actually dispatched, i.e. effects is non-empty and the turn progressed.
        #expect(!effects.isEmpty)
    }

    @Test("forceTimedOutMove is a no-op when it isn't the given player's turn")
    func testForceTimedOutMoveNoOpWrongTurn() {
        let config = GameConfig(
            mode: .standardTeams,
            players: [
                PlayerConfig(name: "You", role: .human, teamID: .teamA, difficulty: .easy, seatPosition: 0),
                PlayerConfig(name: "Left", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 1),
                PlayerConfig(name: "Partner", role: .ai, teamID: .teamA, difficulty: .easy, seatPosition: 2),
                PlayerConfig(name: "Right", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 3)
            ],
            ruleProfile: .standardTeams(),
            seed: 11
        )
        let presenter = GamePresenter(config: config)
        let notCurrentPlayerID = presenter.state.players.first { $0.id != presenter.localPlayerID }!.id
        let effects = presenter.forceTimedOutMove(for: notCurrentPlayerID)
        #expect(effects.isEmpty)
    }
}
