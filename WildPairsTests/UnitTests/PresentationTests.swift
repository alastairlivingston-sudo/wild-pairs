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

    @Test("Pending draw badge reflects an in-flight Draw Four during its colour choice (Phase 17 A1)")
    func testPendingDrawBadgeIncludesInFlightDrawFour() {
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

        let (afterTwo, _) = GameEngine.reduce(state: state, action: .playCard(two, playerID: p0))
        #expect(GameViewState(from: afterTwo, localPlayerID: p0).pendingDrawCount == 2)

        // +4 played but colour not yet chosen: engine holds the stack at 2, but the badge must
        // already show the true total of 6 rather than the stale 2.
        let (afterFourPlay, _) = GameEngine.reduce(state: afterTwo, action: .playCard(four, playerID: p1))
        #expect(afterFourPlay.pendingDrawCount == 2, "Engine timing unchanged")
        #expect(GameViewState(from: afterFourPlay, localPlayerID: p0).pendingDrawCount == 6,
                "Badge shows the in-flight +4 immediately")

        // After the colour is chosen the engine total catches up and the badge is unchanged at 6.
        let (afterColour, _) = GameEngine.reduce(state: afterFourPlay, action: .selectColour(.jade, playerID: p1))
        #expect(afterColour.pendingDrawCount == 6)
        #expect(GameViewState(from: afterColour, localPlayerID: p0).pendingDrawCount == 6)
    }

    @Test("A Draw Four that starts a stack shows +4 while its colour is being chosen (Phase 17 A1)")
    func testPendingDrawBadgeForDrawFourStartingStack() {
        let four = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withHand(forPlayer: 0, cards: [four, CardFactory.number(1, .jade)])
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id

        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(four, playerID: p0))
        #expect(afterPlay.pendingDrawCount == nil, "Engine has not added the +4 yet")
        #expect(GameViewState(from: afterPlay, localPlayerID: p0).pendingDrawCount == 4,
                "Badge already reads +4")
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

    @Test("Solo button shows at two cards on your turn, and at one card only with effect-drop grace")
    func testSoloButtonVisibility() {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson),
                                            CardFactory.number(2, .cobalt)])
            .build()
        let localID = state.players[0].id
        #expect(GameViewState(from: state, localPlayerID: localID).soloButtonVisible == true,
                "Two cards on the local player's turn — declare before playing")

        state.players[0].hand = [CardFactory.number(5, .crimson)]
        #expect(GameViewState(from: state, localPlayerID: localID).soloButtonVisible == false,
                "One card after a normal play — too late to declare")

        state.players[0].soloGraceAtOne = true
        #expect(GameViewState(from: state, localPlayerID: localID).soloButtonVisible == true,
                "One card via an effect drop — grace declaration allowed")
    }

    @Test("mustDrawNow and forcedPickup: stack with no answer flags the forced pickup")
    func testForcedPickupDerivation() {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.drawTwo(.crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson)])   // no +2/+4 in hand
            .build()
        state.pendingDrawCount = 4
        state.pendingDrawType = .drawTwo
        let localID = state.players[0].id

        let vs = GameViewState(from: state, localPlayerID: localID)
        #expect(vs.mustDrawNow == true)
        #expect(vs.forcedPickupCount == 4)
        #expect(vs.prompt == .forcedPickup(count: 4))

        // Holding a stackable card: no forced pickup — the stack-or-draw choice is real.
        state.players[0].hand = [CardFactory.drawTwo(.cobalt)]
        let vsStackable = GameViewState(from: state, localPlayerID: localID)
        #expect(vsStackable.mustDrawNow == false)
        #expect(vsStackable.forcedPickupCount == nil)
        #expect(vsStackable.prompt == .stackOrDraw(count: 4))
    }

    @Test("mustDrawNow is set on a plain no-legal-play turn, without a forced pickup")
    func testMustDrawNowWithoutStack() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(3, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [CardFactory.number(8, .jade)])
            .build()
        let vs = GameViewState(from: state, localPlayerID: state.players[0].id)
        #expect(vs.mustDrawNow == true)
        #expect(vs.forcedPickupCount == nil)
        #expect(vs.prompt == .mustDraw)
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
        #expect(hint.contains("Rain"))
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

    @Test("Only the partner's seat exposes visible hand contents; opponents stay count-only")
    func testVisiblePartnerHand() {
        let partnerHand = [CardFactory.number(4, .jade), CardFactory.skip(.cobalt)]
        let s = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 1, cards: [CardFactory.number(2, .amber)])
            .withHand(forPlayer: 2, cards: partnerHand)
            .withHand(forPlayer: 3, cards: [CardFactory.number(3, .crimson)])
            .build()
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)

        let partnerSeat = vs.seats.first { $0.seatPosition == 2 }
        #expect(partnerSeat?.visiblePartnerHand == partnerHand)

        let leftOpponentSeat = vs.seats.first { $0.seatPosition == 1 }
        let rightOpponentSeat = vs.seats.first { $0.seatPosition == 3 }
        #expect(leftOpponentSeat?.visiblePartnerHand == nil)
        #expect(rightOpponentSeat?.visiblePartnerHand == nil)

        let localSeat = vs.seats.first { $0.seatPosition == 0 }
        #expect(localSeat?.visiblePartnerHand == nil)
    }

    @Test("Points at risk is the raw card-value sum of the local team's hands only, no multiplier")
    func testLocalTeamPointsAtRisk() {
        // Local (seat 0, Team A): 5 + skip(20) = 25. Partner (seat 2, Team A): 3 + drawFour(50) = 53.
        // Opponents (Team B) must never affect this value.
        let s = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson), CardFactory.skip(.jade)])
            .withHand(forPlayer: 1, cards: [CardFactory.number(9, .amber)])
            .withHand(forPlayer: 2, cards: [CardFactory.number(3, .cobalt), CardFactory.drawFour()])
            .withHand(forPlayer: 3, cards: [CardFactory.number(9, .amber)])
            .build()
        let vs = GameViewState(from: s, localPlayerID: s.players[0].id)
        #expect(vs.localTeamPointsAtRisk == 25 + 53)
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

// MARK: - Two-player pass-and-play (Phase 15)

@Suite("Two-player pass-and-play")
struct TwoPlayerPassAndPlayTests {

    /// Canonical two-human table: humans at seats 0 and 2 (Team A), AI at 1 and 3 (Team B).
    private func twoHumanState(currentSeat: Int) -> GameState {
        var state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(3, .crimson))
            .withCurrentPlayer(currentSeat)
            .withDrawPile([CardFactory.number(1, .jade)])
            .build()
        let p2 = state.players[2]
        state.players[2] = Player(id: p2.id, name: "Beth", role: .human, teamID: p2.teamID,
                                  difficulty: p2.difficulty, seatPosition: p2.seatPosition,
                                  hand: p2.hand)
        return state
    }

    @Test("humanAwaitingInput names whichever human the game waits on, nil for AI turns")
    func testHumanAwaitingInput() {
        let onSeat0 = twoHumanState(currentSeat: 0)
        let p0 = GamePresenter(state: onSeat0, localPlayerID: onSeat0.players[0].id)
        #expect(p0.humanAwaitingInput() == onSeat0.players[0].id)

        let onSeat2 = twoHumanState(currentSeat: 2)
        let p2 = GamePresenter(state: onSeat2, localPlayerID: onSeat2.players[0].id)
        #expect(p2.humanAwaitingInput() == onSeat2.players[2].id)
        #expect(p2.nextAutomaticAction() == nil, "AI must never act for a human seat")

        let onSeat1 = twoHumanState(currentSeat: 1)
        let pAI = GamePresenter(state: onSeat1, localPlayerID: onSeat1.players[0].id)
        #expect(pAI.humanAwaitingInput() == nil)
        #expect(pAI.nextAutomaticAction() != nil)
    }

    @Test("humanAwaitingInput follows a pending decision owned by the second human")
    func testHumanAwaitingInputPendingDecision() {
        var state = twoHumanState(currentSeat: 2)
        state.pendingDecision = .colourChoice(playerID: state.players[2].id)
        let presenter = GamePresenter(state: state, localPlayerID: state.players[0].id)
        #expect(presenter.humanAwaitingInput() == state.players[2].id)
    }

    @Test("viewState(for:) rotates tablePosition so the perspective player sits at the bottom")
    func testPerspectiveRotation() {
        let state = twoHumanState(currentSeat: 2)
        let presenter = GamePresenter(state: state, localPlayerID: state.players[0].id)

        // Seat 0's own view: identity mapping.
        let vs0 = presenter.viewState(for: state.players[0].id)
        #expect(vs0.seats.first { $0.seatPosition == 0 }?.tablePosition == 0)
        #expect(vs0.seats.first { $0.seatPosition == 2 }?.tablePosition == 2)

        // Seat 2's view: they sit at the bottom, seat 0 is across, 3 left, 1 right.
        let vs2 = presenter.viewState(for: state.players[2].id)
        #expect(vs2.seats.first { $0.seatPosition == 2 }?.tablePosition == 0)
        #expect(vs2.seats.first { $0.seatPosition == 0 }?.tablePosition == 2)
        #expect(vs2.seats.first { $0.seatPosition == 3 }?.tablePosition == 1)
        #expect(vs2.seats.first { $0.seatPosition == 1 }?.tablePosition == 3)
        #expect(vs2.seats.first { $0.seatPosition == 2 }?.isLocalPlayer == true)
        #expect(vs2.isLocalPlayerTurn == true, "Seat 2's perspective on seat 2's turn")

        // The partner's open hand follows the perspective: seat 2 sees seat 0's hand.
        #expect(vs2.seats.first { $0.seatPosition == 0 }?.visiblePartnerHand != nil)
        #expect(vs2.seats.first { $0.seatPosition == 1 }?.visiblePartnerHand == nil)
    }

    @Test("Intents dispatch as the acting human via the `as:` parameter")
    func testActingPlayerIntents() {
        var state = twoHumanState(currentSeat: 2)
        let card = CardFactory.number(3, .crimson)
        state.players[2].hand = [card, CardFactory.number(9, .cobalt)]
        let presenter = GamePresenter(state: state, localPlayerID: state.players[0].id)
        let beth = state.players[2].id

        presenter.play(card, as: beth)
        #expect(presenter.state.players[2].hand.count == 1)
        #expect(presenter.state.deck.topDiscard?.id == card.id)
    }

    @Test("rememberPlayerNames keeps most-recent-first, dedupes case-insensitively, caps at 8")
    func testRememberPlayerNames() {
        var settings = UserSettings()
        settings.rememberPlayerNames(["Alastair", "Beth"])
        #expect(settings.savedPlayerNames == ["Alastair", "Beth"])

        settings.rememberPlayerNames(["beth", "Carol"])
        #expect(settings.savedPlayerNames == ["beth", "Carol", "Alastair"])

        settings.rememberPlayerNames(["  ", "Dave"])
        #expect(settings.savedPlayerNames.first == "Dave")
        #expect(!settings.savedPlayerNames.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))

        settings.rememberPlayerNames(["E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8"])
        #expect(settings.savedPlayerNames.count == UserSettings.maxSavedPlayerNames)
        #expect(settings.savedPlayerNames.prefix(2) == ["E1", "E2"])
    }

    @Test("Saved names round-trip through the settings JSON; older files decode to empty")
    func testSavedNamesPersistence() throws {
        var settings = UserSettings()
        settings.rememberPlayerNames(["Alastair", "Beth"])
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: data)
        #expect(decoded.savedPlayerNames == ["Alastair", "Beth"])

        let legacy = #"{"animationSpeed":"normal"}"#.data(using: .utf8)!
        let old = try JSONDecoder().decode(UserSettings.self, from: legacy)
        #expect(old.savedPlayerNames.isEmpty)
    }
}
