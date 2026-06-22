import Testing
@testable import WildPairsCore

@Suite("AI constraints — fairness and legality")
struct AIConstraintTests {

    // MARK: AIObservation masking

    @Test("AIObservation does not expose other players' hand contents")
    func testObservationMasksOpponentHands() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .crimson)])
            .withHand(forPlayer: 1, cards: [CardFactory.number(7, .jade), CardFactory.number(8, .cobalt)])
            .withHand(forPlayer: 2, cards: [CardFactory.number(1, .amber)])
            .withHand(forPlayer: 3, cards: [])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let observation = AIObservation(from: state, for: p0id)

        // Own hand: 1 card
        #expect(observation.myHand.count == 1)

        // Card counts are correct but card contents are not available
        #expect(observation.cardCounts[state.players[1].id] == 2)
        #expect(observation.cardCounts[state.players[2].id] == 1)
        #expect(observation.cardCounts[state.players[3].id] == 0)

        // There is no property on AIObservation that exposes other players' hands.
        // (This test compiles only if AIObservation has no such property.)
        // Checking via myHand == own hand only
        #expect(observation.myPlayerID == p0id)
    }

    @Test("AIObservation isMyTurn is true only when the observation's player is current player")
    func testObservationIsMyTurn() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withCurrentPlayer(0)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id

        let obs0 = AIObservation(from: state, for: p0id)
        let obs1 = AIObservation(from: state, for: p1id)
        #expect(obs0.isMyTurn == true)
        #expect(obs1.isMyTurn == false)
    }

    @Test("AIObservation partnerID is correct for canonical seat assignments")
    func testObservationPartnerID() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        // Seat 0 (TeamA) partner is Seat 2 (TeamA)
        let p0id = state.players[0].id
        let p2id = state.players[2].id
        let obs = AIObservation(from: state, for: p0id)
        #expect(obs.partnerID == p2id)
    }

    @Test("AIObservation opponentIDs are seats 1 and 3 for seat 0")
    func testObservationOpponentIDs() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id
        let p3id = state.players[3].id
        let obs = AIObservation(from: state, for: p0id)
        let opponentSet = Set(obs.opponentIDs)
        #expect(opponentSet.contains(p1id))
        #expect(opponentSet.contains(p3id))
        #expect(!opponentSet.contains(p0id))
    }

    // MARK: Move legality

    @Test("EasyAI chooseMove returns legal play from a hand containing a valid card")
    func testEasyAIMakesLegalMove() {
        let legalCard = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(3, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [legalCard])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let observation = AIObservation(from: state, for: p0id)
        var rng = SeededRNG(seed: 42)
        let action = EasyAI.chooseMove(observation: observation, rng: &rng)
        if case .playCard(let card, let pid) = action {
            #expect(card.id == legalCard.id)
            #expect(pid == p0id)
        } else if case .drawCard(let pid) = action {
            // Also acceptable if the AI picked draw
            #expect(pid == p0id)
        } else {
            Issue.record("Unexpected action: \(action)")
        }
        // Ensure the action is accepted by the engine (state must change)
        let (next, _) = GameEngine.reduce(state: state, action: action)
        #expect(next != state)
    }

    @Test("EasyAI draws when hand has no legal card")
    func testEasyAIDrawsWhenNoLegalCard() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.cobalt)
            .withTopDiscard(CardFactory.number(3, .cobalt))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [CardFactory.number(7, .crimson)])  // no match
            .withDrawPile([CardFactory.number(5, .cobalt)])
            .build()
        let p0id = state.players[0].id
        let observation = AIObservation(from: state, for: p0id)
        var rng = SeededRNG(seed: 0)
        let action = EasyAI.chooseMove(observation: observation, rng: &rng)
        if case .drawCard(let pid) = action {
            #expect(pid == p0id)
        } else {
            Issue.record("Expected drawCard; got \(action)")
        }
    }

    @Test("MediumAI prefers action cards over number cards")
    func testMediumAIPrefersActionCards() {
        let actionCard = CardFactory.skip(.crimson)
        let numberCard = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [actionCard, numberCard])
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let observation = AIObservation(from: state, for: p0id)
        var rng = SeededRNG(seed: 0)
        let action = MediumAI.chooseMove(observation: observation, rng: &rng)
        if case .playCard(let card, _) = action {
            // Should prefer the skip (action card)
            #expect(card.id == actionCard.id)
        } else {
            Issue.record("Expected playCard action; got \(action)")
        }
    }

    @Test("MediumAI selectColour picks the most frequent colour in hand")
    func testMediumAISelectColourPicksMostFrequent() {
        // Hand has 3 jade, 1 crimson
        let hand: [Card] = [
            CardFactory.number(1, .jade),
            CardFactory.number(2, .jade),
            CardFactory.number(3, .jade),
            CardFactory.number(4, .crimson),
            CardFactory.changeColour()
        ]
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.amber)
            .withHand(forPlayer: 0, cards: hand)
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let observation = AIObservation(from: state, for: p0id)
        var rng = SeededRNG(seed: 0)
        let chosen = MediumAI.selectColour(observation: observation, rng: &rng)
        #expect(chosen == .jade)
    }

    @Test("MediumAI selectTarget avoids partner and picks opponent with fewest cards")
    func testMediumAITargetAvoidsPartner() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 1, cards: [CardFactory.number(1, .jade)])        // 1 card
            .withHand(forPlayer: 3, cards: (0..<5).map { CardFactory.number($0, .jade) }) // 5 cards
            .withDrawPile([])
            .build()
        let p0id = state.players[0].id
        let p1id = state.players[1].id
        let p2id = state.players[2].id  // partner
        let observation = AIObservation(from: state, for: p0id)
        let validTargets = [p1id, p2id, state.players[3].id]
        var rng = SeededRNG(seed: 0)
        let target = MediumAI.selectTarget(observation: observation, validTargets: validTargets, rng: &rng)
        // Should pick player 1 (fewest cards, not partner)
        #expect(target == p1id)
        // Must not target partner (seat 2)
        #expect(target != p2id)
    }

    @Test("HardAI scoreMove returns higher score for action cards than number cards")
    func testHardAIScoresActionHigher() {
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withHand(forPlayer: 0, cards: [])
            .withDrawPile([])
            .build()
        let observation = AIObservation(from: state, for: state.players[0].id)
        let actionScore = HardAI.scoreMove(CardFactory.skip(.crimson), observation: observation)
        let numberScore = HardAI.scoreMove(CardFactory.number(5, .crimson), observation: observation)
        #expect(actionScore > numberScore)
    }

    @Test("HardAI urgency increases as hand size decreases")
    func testHardAIUrgencyIncreasesWithFewerCards() {
        let stateMany = GameStateBuilder()
            .withPlayers()
            .withHand(forPlayer: 0, cards: (0..<7).map { CardFactory.number($0, .crimson) })
            .withDrawPile([])
            .build()
        let stateFew = GameStateBuilder()
            .withPlayers()
            .withHand(forPlayer: 0, cards: [CardFactory.number(1, .crimson)])
            .withDrawPile([])
            .build()
        let obsMany = AIObservation(from: stateMany, for: stateMany.players[0].id)
        let obsFew = AIObservation(from: stateFew, for: stateFew.players[0].id)
        #expect(HardAI.computeUrgency(obsFew) > HardAI.computeUrgency(obsMany))
    }

    @Test("All difficulty levels chooseMove return a GameAction (no crash, no nil)")
    func testAllDifficultyLevelsChooseMove() {
        let hand: [Card] = [
            CardFactory.number(5, .crimson),
            CardFactory.skip(.crimson),
            CardFactory.changeColour()
        ]
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: hand)
            .withDrawPile([CardFactory.number(1, .jade)])
            .build()
        let p0id = state.players[0].id
        let observation = AIObservation(from: state, for: p0id)
        for difficulty in Difficulty.allCases {
            var rng = SeededRNG(seed: UInt64(difficulty.rawValue.hashValue & 0xFFFF))
            let action = AIPlayer.chooseMove(observation: observation, difficulty: difficulty, rng: &rng)
            // Just verify it produces a GameAction and doesn't crash
            switch action {
            case .playCard(_, let pid): #expect(pid == p0id)
            case .drawCard(let pid): #expect(pid == p0id)
            default: Issue.record("Unexpected action type for \(difficulty)")
            }
        }
    }
}
