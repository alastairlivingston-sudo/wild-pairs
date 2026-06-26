import Testing
@testable import WildPairsCore

@Suite("Side-to-Side Team Pass (G1)")
struct TeamPassTests {

    @Test("New game in Side-to-Side mode enters .teamPass phase, pending on seat 0")
    func testNewGameEntersTeamPassPhase() {
        let config = GameConfig(
            mode: .sideToSide,
            players: [
                PlayerConfig(name: "A0", role: .ai, teamID: .teamA, seatPosition: 0),
                PlayerConfig(name: "B1", role: .ai, teamID: .teamB, seatPosition: 1),
                PlayerConfig(name: "A2", role: .ai, teamID: .teamA, seatPosition: 2),
                PlayerConfig(name: "B3", role: .ai, teamID: .teamB, seatPosition: 3)
            ],
            ruleProfile: .sideToSide(),
            seed: 1
        )
        let (state, _) = GameEngine.reduce(state: GameState(players: []), action: .newGame(config: config))
        #expect(state.phase == .teamPass)
        if case .teamPass(let pid) = state.pendingDecision {
            #expect(pid == state.players[0].id)
        } else {
            Issue.record("Expected pendingDecision == .teamPass(seat 0)")
        }
    }

    @Test("Standard Teams mode never enters .teamPass phase")
    func testStandardTeamsSkipsTeamPassPhase() {
        let config = GameConfig(
            mode: .standardTeams,
            players: [
                PlayerConfig(name: "A0", role: .ai, teamID: .teamA, seatPosition: 0),
                PlayerConfig(name: "B1", role: .ai, teamID: .teamB, seatPosition: 1),
                PlayerConfig(name: "A2", role: .ai, teamID: .teamA, seatPosition: 2),
                PlayerConfig(name: "B3", role: .ai, teamID: .teamB, seatPosition: 3)
            ],
            ruleProfile: .standardTeams(),
            seed: 1
        )
        let (state, _) = GameEngine.reduce(state: GameState(players: []), action: .newGame(config: config))
        #expect(state.phase == .playing)
        #expect(state.pendingDecision == nil)
    }

    /// Drives all four players through the team-pass phase via `GameEngine.reduce` directly.
    private func submitAll(_ submissions: [Card?], state: GameState) -> GameState {
        var s = state
        for card in submissions {
            guard case .teamPass(let pid) = s.pendingDecision else {
                Issue.record("Expected a pending .teamPass decision")
                return s
            }
            (s, _) = GameEngine.reduce(state: s, action: .submitTeamPass(playerID: pid, card: card))
        }
        return s
    }

    @Test("Both teams pass: each player's chosen card lands in their partner's hand")
    func testBothTeamsSwapCorrectly() {
        var state = GameStateBuilder()
            .withMode(.sideToSide)
            .withRuleProfile(.sideToSide())
            .withPlayers()
            .withPhase(.teamPass)
            .build()
        let a0Card = CardFactory.number(1, .crimson)
        let b1Card = CardFactory.number(2, .cobalt)
        let a2Card = CardFactory.number(3, .jade)
        let b3Card = CardFactory.number(4, .amber)
        state.players[0].hand = [a0Card, CardFactory.number(9, .crimson)]
        state.players[1].hand = [b1Card, CardFactory.number(9, .cobalt)]
        state.players[2].hand = [a2Card, CardFactory.number(9, .jade)]
        state.players[3].hand = [b3Card, CardFactory.number(9, .amber)]
        state.pendingDecision = .teamPass(playerID: state.players[0].id)

        let final = submitAll([a0Card, b1Card, a2Card, b3Card], state: state)

        #expect(final.phase == .playing)
        #expect(final.pendingDecision == nil)
        #expect(final.teamPassSelections == nil)
        #expect(final.teamPassDeclined == nil)
        // Seat 0 (Team A) gave a0Card, received a2Card from its partner (seat 2).
        #expect(final.players[0].hand.contains { $0.id == a2Card.id })
        #expect(!final.players[0].hand.contains { $0.id == a0Card.id })
        #expect(final.players[2].hand.contains { $0.id == a0Card.id })
        #expect(!final.players[2].hand.contains { $0.id == a2Card.id })
        // Seat 1 (Team B) gave b1Card, received b3Card from its partner (seat 3).
        #expect(final.players[1].hand.contains { $0.id == b3Card.id })
        #expect(final.players[3].hand.contains { $0.id == b1Card.id })
    }

    @Test("One player declines: their team's swap is cancelled, the other team's still happens")
    func testUnilateralDeclineCancelsOnlyThatTeam() {
        var state = GameStateBuilder()
            .withMode(.sideToSide)
            .withRuleProfile(.sideToSide())
            .withPlayers()
            .withPhase(.teamPass)
            .build()
        let a0Card = CardFactory.number(1, .crimson)
        let a2Card = CardFactory.number(3, .jade)
        let b1Card = CardFactory.number(2, .cobalt)
        let b3Card = CardFactory.number(4, .amber)
        state.players[0].hand = [a0Card]
        state.players[1].hand = [b1Card]
        state.players[2].hand = [a2Card]
        state.players[3].hand = [b3Card]
        state.pendingDecision = .teamPass(playerID: state.players[0].id)

        // Seat 0 declines (nil); seat 2 (their Team A partner) still offers a card — no swap
        // should occur for Team A. Team B (seats 1 and 3) both pass — swap should occur.
        let final = submitAll([nil, b1Card, a2Card, b3Card], state: state)

        #expect(final.phase == .playing)
        #expect(final.players[0].hand.contains { $0.id == a0Card.id }, "Team A seat 0 keeps its card — partner's offer alone doesn't trigger a swap")
        #expect(final.players[2].hand.contains { $0.id == a2Card.id }, "Team A seat 2 keeps its card too")
        #expect(final.players[1].hand.contains { $0.id == b3Card.id }, "Team B still swaps since both members passed")
        #expect(final.players[3].hand.contains { $0.id == b1Card.id })
    }

    @Test("Submitting for the wrong player (not the pending one) is rejected")
    func testWrongPlayerSubmissionRejected() {
        let state = GameStateBuilder()
            .withMode(.sideToSide)
            .withRuleProfile(.sideToSide())
            .withPlayers()
            .withPhase(.teamPass)
            .build()
        var s = state
        s.pendingDecision = .teamPass(playerID: s.players[0].id)
        let wrongPlayerID = s.players[1].id

        let (next, _) = GameEngine.reduce(state: s, action: .submitTeamPass(playerID: wrongPlayerID, card: nil))
        #expect(next.phase == .teamPass)
        #expect(next.pendingDecision == .teamPass(playerID: s.players[0].id), "Pending decision must be unchanged")
    }

    @Test("Submitting a card not in hand is rejected")
    func testCardNotInHandRejected() {
        var state = GameStateBuilder()
            .withMode(.sideToSide)
            .withRuleProfile(.sideToSide())
            .withPlayers()
            .withPhase(.teamPass)
            .build()
        state.players[0].hand = [CardFactory.number(1, .crimson)]
        state.pendingDecision = .teamPass(playerID: state.players[0].id)
        let notInHand = CardFactory.number(9, .amber)

        let (next, _) = GameEngine.reduce(state: state, action: .submitTeamPass(playerID: state.players[0].id, card: notInHand))
        #expect(next.pendingDecision == .teamPass(playerID: state.players[0].id))
        #expect(next.players[0].hand.count == 1, "Hand must be untouched by the rejected submission")
    }

    @Test("Medium+ AI never offers a wild card when a non-wild card is available")
    func testAIAvoidsPassingWildCards() {
        let hand = [CardFactory.drawFour(), CardFactory.changeColour(), CardFactory.number(5, .crimson)]
        var state = GameStateBuilder().withPlayers().build()
        state.players[0].hand = hand
        let observation = AIObservation(from: state, for: state.players[0].id)
        var rng = SeededRNG(seed: 7)

        for difficulty in [Difficulty.medium, .hard, .expert, .master] {
            let chosen = AIPlayer.selectTeamPassCard(observation: observation, difficulty: difficulty, rng: &rng)
            #expect(chosen?.id == hand[2].id, "\(difficulty) should offer the only non-wild card")
        }
    }

    @Test("1,000-game Side-to-Side batch: 0 illegal moves, 0 stuck games, every game has a winner")
    func testSideToSideBatchHealthy() {
        let results = GameSimulator.runBatch(mode: .sideToSide, difficulty: .medium, seeds: 0..<1000, maxTurns: 1000)
        let stuck = results.filter(\.stuck).count
        let illegal = results.reduce(0) { $0 + $1.illegalMoveAttempts }
        let noWinner = results.filter { $0.winner == nil && !$0.stuck }.count
        #expect(stuck == 0)
        #expect(illegal == 0)
        #expect(noWinner == 0)
    }
}
