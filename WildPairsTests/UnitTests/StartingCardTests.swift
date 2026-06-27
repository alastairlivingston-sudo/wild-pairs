import Testing
@testable import WildPairsCore

@Suite("Starting card effects (Phase 11 G)")
struct StartingCardTests {

    private func makePlayers() -> [Player] {
        let teams: [TeamID] = [.teamA, .teamB, .teamA, .teamB]
        let roles: [PlayerRole] = [.human, .ai, .ai, .ai]
        return (0..<4).map { i in
            Player(name: "P\(i)", role: roles[i], teamID: teams[i], difficulty: .easy, seatPosition: i)
        }
    }

    @Test("A Skip as the starting card skips seat 0; play opens with seat 1")
    func testStartingSkip() {
        var players = makePlayers()
        var deck = Deck(drawPile: [], discardPile: [])
        var rng = SeededRNG(seed: 1)
        let result = GameEngine.applyStartingCardEffect(
            CardFactory.skip(.crimson), players: &players, deck: &deck, rng: &rng)
        #expect(result.currentPlayerIndex == 1)
        #expect(result.turnDirection == .clockwise)
    }

    @Test("A Reverse as the starting card flips direction; seat 0 still opens play")
    func testStartingReverse() {
        var players = makePlayers()
        var deck = Deck(drawPile: [], discardPile: [])
        var rng = SeededRNG(seed: 1)
        let result = GameEngine.applyStartingCardEffect(
            CardFactory.reverse(.jade), players: &players, deck: &deck, rng: &rng)
        #expect(result.currentPlayerIndex == 0)
        #expect(result.turnDirection == .counterClockwise)
    }

    @Test("A Draw Two as the starting card makes seat 0 draw 2 and skips them")
    func testStartingDrawTwo() {
        var players = makePlayers()
        let drawPile = (0..<10).map { CardFactory.number($0, .amber) }
        var deck = Deck(drawPile: drawPile, discardPile: [])
        var rng = SeededRNG(seed: 1)
        let before = players[0].hand.count
        let result = GameEngine.applyStartingCardEffect(
            CardFactory.drawTwo(.cobalt), players: &players, deck: &deck, rng: &rng)
        #expect(players[0].hand.count == before + 2)
        #expect(result.currentPlayerIndex == 1)
        #expect(result.turnDirection == .clockwise)
    }

    @Test("A number card as the starting card has no special effect — seat 0 opens play")
    func testStartingNumberCardIsNoOp() {
        var players = makePlayers()
        var deck = Deck(drawPile: [], discardPile: [])
        var rng = SeededRNG(seed: 1)
        let result = GameEngine.applyStartingCardEffect(
            CardFactory.number(5, .crimson), players: &players, deck: &deck, rng: &rng)
        #expect(result.currentPlayerIndex == 0)
        #expect(result.turnDirection == .clockwise)
        #expect(players[0].hand.isEmpty)
    }

    @Test("A real new game wires the starting-card effect into the initial GameState")
    func testNewGameAppliesStartingCardEffect() {
        // Smoke test through the public entry point: whatever the shuffle flips, the engine
        // must produce a state whose currentPlayerIndex/turnDirection are internally
        // consistent with applyStartingCardEffect's contract (skip-or-not, direction).
        let config = GameConfig(
            mode: .standardTeams,
            players: [
                PlayerConfig(name: "You", role: .human, teamID: .teamA, difficulty: .easy, seatPosition: 0),
                PlayerConfig(name: "Left", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 1),
                PlayerConfig(name: "Partner", role: .ai, teamID: .teamA, difficulty: .easy, seatPosition: 2),
                PlayerConfig(name: "Right", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 3)
            ],
            ruleProfile: .standardTeams(),
            seed: 12345
        )
        let (state, _) = GameEngine.reduce(state: GameState(players: []), action: .newGame(config: config))
        switch state.currentCardType {
        case .skip:
            #expect(state.currentPlayerIndex == 1)
        case .reverse:
            #expect(state.turnDirection == TurnDirection.counterClockwise)
            #expect(state.currentPlayerIndex == 0)
        case .drawTwo:
            #expect(state.currentPlayerIndex == 1)
            #expect(state.players[0].hand.count == state.ruleProfile.initialHandSize + 2)
        default:
            #expect(state.currentPlayerIndex == 0)
            #expect(state.turnDirection == TurnDirection.clockwise)
        }
    }
}
