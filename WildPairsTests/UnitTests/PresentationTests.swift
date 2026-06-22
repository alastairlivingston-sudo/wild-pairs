import Testing
import Foundation
@testable import WildPairsCore

@Suite("GameViewState derivation")
struct GameViewStateTests {

    @Test("Local hand marks only legal cards as playable on the local player's turn")
    func testPlayableFlags() {
        let legal = CardFactory.number(5, .crimson)
        let illegal = CardFactory.number(8, .jade)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(3, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [legal, illegal])
            .build()
        let vs = GameViewState(from: state, localPlayerID: state.players[0].id)
        let legalVM = vs.localHand.first { $0.id == legal.id }
        let illegalVM = vs.localHand.first { $0.id == illegal.id }
        #expect(legalVM?.isPlayable == true)
        #expect(illegalVM?.isPlayable == false)
        #expect(vs.isLocalPlayerTurn == true)
    }

    @Test("No cards are playable when it is not the local player's turn")
    func testNothingPlayableOffTurn() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(3, .crimson))
            .withCurrentPlayer(1)
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson)])
            .build()
        let vs = GameViewState(from: state, localPlayerID: state.players[0].id)
        #expect(vs.isLocalPlayerTurn == false)
        #expect(vs.localHand.allSatisfy { !$0.isPlayable })
    }

    @Test("Solo button is visible only when local holds one card and has not called")
    func testSoloButtonVisibility() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson)])
            .build()
        let vs = GameViewState(from: state, localPlayerID: state.players[0].id)
        #expect(vs.soloButtonVisible == true)
    }

    @Test("Match hint names the colour and the top number")
    func testMatchHint() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(7, .cobalt))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [CardFactory.number(7, .crimson)])
            .build()
        let hint = GameViewState.matchHint(state: state)
        #expect(hint.contains("Cobalt"))
        #expect(hint.contains("7"))
        #expect(hint.contains("wild"))
    }

    @Test("Prompt is chooseColour when a wild colour choice is pending for the local player")
    func testPromptChooseColour() {
        var s = GameStateBuilder().withPlayers().withCurrentColour(.amber).build()
        s.pendingDecision = .colourChoice(playerID: s.players[0].id)
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)
        #expect(vs.awaitingLocalColourChoice == true)
        if case .chooseColour = vs.prompt {} else { Issue.record("Expected chooseColour prompt") }
    }

    @Test("Local target choices are surfaced when a target decision is pending for local")
    func testLocalTargetChoices() {
        let realState = GameStateBuilder().withPlayers().withCurrentColour(.crimson).build()
        var s = realState
        let targets = [s.players[1].id, s.players[3].id]
        s.pendingDecision = .targetChoice(playerID: s.players[0].id, validTargets: targets)
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)
        #expect(vs.localTargetChoices == targets)
        if case .chooseTarget = vs.prompt {} else { Issue.record("Expected chooseTarget prompt") }
    }

    @Test("Catchable Solo! surfaces an opponent who forgot to call")
    func testCatchableSolo() {
        var s = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 1, cards: [CardFactory.number(5, .jade)])
            .build()
        // Opponent (seat 1) holds one card, has not called Solo!
        s.players[1].hasCalledSolo = false
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)
        #expect(vs.catchableSoloPlayerID == s.players[1].id)
    }

    @Test("Scoreboard lists both teams with their scores")
    func testScoreboard() {
        var s = GameStateBuilder().withPlayers().build()
        s.teamScores = [.teamA: 30, .teamB: 12]
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)
        #expect(vs.scoreboard.count == 2)
        #expect(vs.scoreboard.first { $0.teamID == .teamA }?.score == 30)
        #expect(vs.scoreboard.first { $0.teamID == .teamB }?.score == 12)
    }

    @Test("Seats are ordered by seat position and flag the local player")
    func testSeatsOrdering() {
        let s = GameStateBuilder().withPlayers().withCurrentPlayer(0).build()
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)
        #expect(vs.seats.map(\.seatPosition) == [0, 1, 2, 3])
        #expect(vs.seats.first { $0.isLocalPlayer }?.seatPosition == 0)
    }
}

@Suite("GamePresenter orchestration")
struct GamePresenterTests {

    private func standardConfig(seed: UInt64) -> GameConfig {
        GameConfig(
            mode: .standardTeams,
            players: [
                PlayerConfig(name: "You", role: .human, teamID: .teamA, difficulty: .easy, seatPosition: 0),
                PlayerConfig(name: "Left", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 1),
                PlayerConfig(name: "Partner", role: .ai, teamID: .teamA, difficulty: .easy, seatPosition: 2),
                PlayerConfig(name: "Right", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 3)
            ],
            ruleProfile: .standardTeams(),
            seed: seed
        )
    }

    @Test("New presenter starts a dealt game with the human as local player")
    func testPresenterStart() {
        let presenter = GamePresenter(config: standardConfig(seed: 1))
        #expect(presenter.state.players.count == 4)
        #expect(presenter.state.players.first { $0.id == presenter.localPlayerID }?.role == .human)
        #expect(presenter.viewState.seats.count == 4)
    }

    @Test("nextAutomaticAction returns nil on the local player's turn")
    func testNoAutomaticOnLocalTurn() {
        let presenter = GamePresenter(config: standardConfig(seed: 1))
        // Game starts with seat 0 (human) to act
        #expect(presenter.state.currentPlayerIndex == 0)
        #expect(presenter.nextAutomaticAction() == nil)
    }

    @Test("advanceAutomatic drives AI turns and stops at the local player")
    func testAdvanceStopsAtLocal() throws {
        let presenter = GamePresenter(config: standardConfig(seed: 7))
        // Force it to be an AI's turn by passing the human's turn first
        presenter.dispatch(.passTurn(playerID: presenter.localPlayerID))
        var guardCounter = 0
        while presenter.advanceAutomatic() != nil {
            guardCounter += 1
            try #require(guardCounter < 200)  // must terminate
        }
        // Now it should be the local player's turn (or the round/game ended)
        let isLocalTurn = presenter.state.currentPlayer?.id == presenter.localPlayerID
        #expect(isLocalTurn || presenter.state.phase != .playing)
    }

    @Test("Autosave writes a snapshot when persistence is provided")
    func testAutosaveOnDispatch() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("WP-presenter-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let service = PersistenceService(directory: dir)
        let presenter = GamePresenter(config: standardConfig(seed: 3), persistence: service)
        presenter.dispatch(.passTurn(playerID: presenter.localPlayerID))
        #expect(service.hasSavedGame())
    }

    @Test("Two presenters with the same seed produce identical automatic actions")
    func testDeterministicAutomatic() {
        let p1 = GamePresenter(config: standardConfig(seed: 99))
        let p2 = GamePresenter(config: standardConfig(seed: 99))
        p1.dispatch(.passTurn(playerID: p1.localPlayerID))
        p2.dispatch(.passTurn(playerID: p2.localPlayerID))
        // Advance both the same number of automatic steps; states stay in lockstep
        for _ in 0..<10 {
            let a = p1.advanceAutomatic()
            let b = p2.advanceAutomatic()
            #expect((a == nil) == (b == nil))
            if a == nil { break }
        }
        // Player/card UUIDs are random per construction, so compare a structural
        // fingerprint (hand contents, turn state, deck order) rather than raw identity.
        #expect(fingerprint(p1.state) == fingerprint(p2.state))
    }

    private func fingerprint(_ state: GameState) -> String {
        func describe(_ card: Card) -> String { "\(card.type)-\(String(describing: card.colour))" }
        let hands = state.players.map { $0.hand.map(describe) }
        let drawPile = state.deck.drawPile.map(describe)
        let discardPile = state.deck.discardPile.map(describe)
        return "\(hands)|\(drawPile)|\(discardPile)|\(state.currentPlayerIndex)|\(state.currentColour)|\(state.currentCardType.map(String.init(describing:)) ?? "nil")|\(state.actionCount)"
    }
}
