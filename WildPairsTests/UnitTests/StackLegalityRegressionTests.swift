import Foundation
import Testing
@testable import WildPairsCore

/// Phase 17 A2/A3: while a Draw Two/Four penalty is pending, the *only* legal plays are matching
/// escalating draw cards — no Skip, number, or other action may be played until someone draws the
/// stack. These guard against the reported bugs (a Skip playable on a +2; an AI stacking an
/// illegal card) and lock in the centralisation of legality onto the single `GameRules` predicate
/// shared by the engine and the AI.
@Suite("Stack legality regression (Phase 17 A2/A3)")
struct StackLegalityRegressionTests {

    /// Builds the state after seat 0 plays a Draw Two, so seat 1 faces a pending +2 stack.
    private func pendingDrawTwoState(seat1Hand: [Card]) -> (GameState, UUID) {
        let two = CardFactory.drawTwo(.crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [two, CardFactory.number(1, .amber)])
            .withHand(forPlayer: 1, cards: seat1Hand)
            .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id
        let (afterTwo, _) = GameEngine.reduce(state: state, action: .playCard(two, playerID: p0))
        #expect(afterTwo.pendingDrawType == .drawTwo)
        #expect(afterTwo.pendingDrawCount == 2)
        return (afterTwo, p1)
    }

    // MARK: Human path — a Skip must never be playable on a pending +2

    @Test("A colour-matching Skip is illegal while a Draw Two stack is pending")
    func testSkipIllegalOnPendingDrawTwo() {
        // The Skip shares the active colour, so it would match if the stack rule were not enforced.
        let skip = CardFactory.skip(.crimson)
        let (state, p1) = pendingDrawTwoState(seat1Hand: [skip, CardFactory.number(1, .amber)])

        #expect(!GameEngine.isLegalMove(state: state, action: .playCard(skip, playerID: p1)))
        #expect(!GameRules.legalPlaysConsideringDrawFour(hand: state.players[1].hand, state: state)
            .contains { $0.id == skip.id })

        // Attempting it anyway leaves the stack untouched (engine rejects the move).
        let (afterRejected, _) = GameEngine.reduce(state: state, action: .playCard(skip, playerID: p1))
        #expect(afterRejected.pendingDrawCount == 2)
        #expect(afterRejected.players[1].hand.contains { $0.id == skip.id })
    }

    @Test("Only matching draw cards are legal plays while a Draw Two stack is pending")
    func testOnlyDrawCardsLegalOnPendingDrawTwo() {
        let skip = CardFactory.skip(.crimson)
        let matchingNumber = CardFactory.number(5, .crimson)   // matches colour + number normally
        let stackTwo = CardFactory.drawTwo(.jade)
        let stackFour = CardFactory.drawFour()
        let (state, _) = pendingDrawTwoState(
            seat1Hand: [skip, matchingNumber, stackTwo, stackFour])

        let legal = GameRules.legalPlaysConsideringDrawFour(hand: state.players[1].hand, state: state)
        #expect(Set(legal.map(\.id)) == Set([stackTwo.id, stackFour.id]))
    }

    // MARK: AI path — the AI shares the same predicate and can never propose an illegal stack move

    @Test("AI legal plays exclude non-stacking cards while a Draw Two stack is pending")
    func testAILegalPlaysExcludeNonStacking() {
        let aiSkip = CardFactory.skip(.crimson)
        let aiTwo = CardFactory.drawTwo(.jade)
        let aiNumber = CardFactory.number(3, .crimson)
        let (state, p1) = pendingDrawTwoState(seat1Hand: [aiSkip, aiTwo, aiNumber])

        let obs = AIObservation(from: state, for: p1)
        let legal = AIPlayer.legalPlays(observation: obs)
        #expect(legal.contains { $0.id == aiTwo.id })
        #expect(!legal.contains { $0.id == aiSkip.id })
        #expect(!legal.contains { $0.id == aiNumber.id })
        #expect(legal.allSatisfy { $0.type == CardType.drawTwo || $0.type == CardType.drawFour })
    }

    @Test("Every difficulty proposes only a stack card or a draw on a pending stack")
    func testEveryDifficultyNeverProposesIllegalStackMove() {
        let aiSkip = CardFactory.skip(.crimson)
        let aiTwo = CardFactory.drawTwo(.jade)
        let aiNumber = CardFactory.number(3, .crimson)
        let (state, p1) = pendingDrawTwoState(seat1Hand: [aiSkip, aiTwo, aiNumber])
        let obs = AIObservation(from: state, for: p1)

        for difficulty in Difficulty.allCases {
            var rng = SeededRNG(seed: 99)
            let action = AIPlayer.chooseMove(observation: obs, difficulty: difficulty, rng: &rng)
            switch action {
            case .playCard(let card, _):
                #expect(card.type == CardType.drawTwo || card.type == CardType.drawFour,
                        "\(difficulty) proposed a non-stacking card on a pending stack")
                #expect(GameEngine.isLegalMove(state: state, action: action),
                        "\(difficulty) proposed a move the engine would reject")
            case .drawCard:
                break  // drawing the stack is always legal
            default:
                Issue.record("\(difficulty) proposed an unexpected action: \(action)")
            }
        }
    }
}
