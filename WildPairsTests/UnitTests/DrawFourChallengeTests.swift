import Foundation
import Testing
@testable import WildPairsCore

/// Phase 17 B2: the opt-in Draw Four challenge (`RuleProfile.drawFourChallengeable`). A fresh
/// Draw Four's target may challenge it, alleging the player bluffed (held a card of the colour in
/// force before the Draw Four's own colour choice). Covers both outcomes, both stacking modes,
/// accept, and the invariant that a legally *stacked* Draw Four is never challengeable.
@Suite("Draw Four challenge (Phase 17 B2)")
struct DrawFourChallengeTests {

    private func profile(stacking: Bool) -> RuleProfile {
        var p = RuleProfile.standardTeams()
        p.drawFourChallengeable = true
        p.stackDrawCards = stacking
        return p
    }

    /// Seat 0 plays a fresh Draw Four (active colour crimson) and picks jade; seat 1 is then the
    /// target facing the challenge decision. `seat0Hand` must include the Draw Four.
    private func challengeState(seat0Hand: [Card], stacking: Bool) -> (GameState, UUID, UUID) {
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile(stacking: stacking))
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: seat0Hand)
            .withHand(forPlayer: 1, cards: [CardFactory.number(3, .amber), CardFactory.number(4, .jade)])
            .withDrawPile((0..<40).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id
        let df = seat0Hand.first { $0.type == .drawFour }!
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(df, playerID: p0))
        let (afterColour, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.jade, playerID: p0))
        return (afterColour, p0, p1)
    }

    @Test("A fresh Draw Four raises a challenge decision for its target, carrying the prior colour")
    func testChallengeDecisionRaised() {
        let (state, p0, p1) = challengeState(
            seat0Hand: [CardFactory.drawFour(), CardFactory.number(5, .crimson), CardFactory.number(1, .amber)],
            stacking: true)
        guard case .drawFourChallenge(let challenger, let challenged, let prior, let total) = state.pendingDecision else {
            Issue.record("Expected a drawFourChallenge decision, got \(String(describing: state.pendingDecision))")
            return
        }
        #expect(challenger == p1)
        #expect(challenged == p0)
        #expect(prior == .crimson)     // colour before the Draw Four's jade choice
        #expect(total == 4)
    }

    @Test("Round-timer expiry clears a pending challenge (no stranded overlay over round-end)")
    func testRoundTimerExpiryClearsPendingChallenge() {
        // Tier 0c: a Draw Four challenge is pending on the target when the round timer fires.
        // The round must end AND the decision must be cleared, so the challenge overlay can't
        // linger on top of the round-end screen with dead buttons.
        let (state, _, _) = challengeState(
            seat0Hand: [CardFactory.drawFour(), CardFactory.number(5, .crimson), CardFactory.number(1, .amber)],
            stacking: true)
        #expect(state.pendingDecision != nil)   // precondition: a challenge is pending
        let (after, _) = GameEngine.reduce(state: state, action: .roundTimerExpired)
        #expect(after.pendingDecision == nil)
        #expect(after.phase != .playing)
        #expect(after.winState != nil)
    }

    @Test("Challenge upheld (bluff): the challenged player draws 4 and the target plays on")
    func testChallengeUpheld() {
        // Seat 0 keeps a crimson card after the Draw Four → the play was a bluff.
        let (state, p0, p1) = challengeState(
            seat0Hand: [CardFactory.drawFour(), CardFactory.number(5, .crimson), CardFactory.number(1, .amber)],
            stacking: true)
        let challengedBefore = state.players.first { $0.id == p0 }!.hand.count   // 2 after playing
        let (after, effects) = GameEngine.reduce(state: state, action: .challengeDrawFour(challengerID: p1))

        #expect(after.pendingDecision == nil)
        #expect(after.pendingDrawCount == nil)
        #expect(after.players.first { $0.id == p0 }!.hand.count == challengedBefore + 4)  // bluffer draws
        #expect(after.players.first { $0.id == p1 }!.hand.count == 2)                     // target unchanged
        #expect(after.currentPlayer?.id == p1)                                            // target takes their turn
        #expect(effects.contains { if case .animateCardDraw(let to, let n) = $0 { return to == p0 && n == 4 }; return false })
    }

    @Test("Challenge failed (legal): the challenger draws 4 + 2 and is skipped")
    func testChallengeFailed() {
        // Seat 0 keeps no crimson card → the Draw Four was legal, so the challenge is wrong.
        let (state, _, p1) = challengeState(
            seat0Hand: [CardFactory.drawFour(), CardFactory.number(1, .amber), CardFactory.number(2, .jade)],
            stacking: true)
        let p2 = state.players[2].id
        let (after, effects) = GameEngine.reduce(state: state, action: .challengeDrawFour(challengerID: p1))

        #expect(after.pendingDecision == nil)
        #expect(after.pendingDrawCount == nil)
        #expect(after.players.first { $0.id == p1 }!.hand.count == 2 + 6)   // wrong challenger draws 6
        #expect(after.currentPlayer?.id == p2)                             // challenger skipped
        #expect(effects.contains { if case .animateCardDraw(let to, let n) = $0 { return to == p1 && n == 6 }; return false })
    }

    @Test("Accept under stacking leaves the target facing the +4 stack (normal flow)")
    func testAcceptStacking() {
        let (state, _, p1) = challengeState(
            seat0Hand: [CardFactory.drawFour(), CardFactory.number(1, .amber)],
            stacking: true)
        let (after, _) = GameEngine.reduce(state: state, action: .acceptDrawFour(challengerID: p1))

        #expect(after.pendingDecision == nil)
        #expect(after.pendingDrawCount == 4)               // stack still pending for the target
        #expect(after.currentPlayer?.id == p1)             // target must now stack or absorb
        #expect(after.players.first { $0.id == p1 }!.hand.count == 2)   // hasn't drawn yet
    }

    @Test("Accept without stacking draws the deferred 4 and skips the target")
    func testAcceptImmediate() {
        let (state, _, p1) = challengeState(
            seat0Hand: [CardFactory.drawFour(), CardFactory.number(1, .amber)],
            stacking: false)
        let p2 = state.players[2].id
        let (after, effects) = GameEngine.reduce(state: state, action: .acceptDrawFour(challengerID: p1))

        #expect(after.pendingDecision == nil)
        #expect(after.pendingDrawCount == nil)
        #expect(after.players.first { $0.id == p1 }!.hand.count == 2 + 4)  // deferred draw delivered
        #expect(after.currentPlayer?.id == p2)                            // target skipped
        #expect(effects.contains { if case .animateCardDraw(let to, let n) = $0 { return to == p1 && n == 4 }; return false })
    }

    @Test("A Draw Four legally stacked onto a pending draw is NOT challengeable")
    func testStackedDrawFourNotChallengeable() {
        // Seat 0 plays a Draw Two; seat 1 answers with a Draw Four (a legal stack). The stacked
        // Draw Four must not raise a challenge — a colour match was never a legal alternative.
        let two = CardFactory.drawTwo(.crimson)
        let df = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile(stacking: true))
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [two, CardFactory.number(1, .amber)])
            .withHand(forPlayer: 1, cards: [df, CardFactory.number(2, .crimson)])
            .withDrawPile((0..<40).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let p1 = state.players[1].id
        let p2 = state.players[2].id
        let (afterTwo, _) = GameEngine.reduce(state: state, action: .playCard(two, playerID: p0))
        #expect(afterTwo.pendingDrawCount == 2)
        let (afterFour, _) = GameEngine.reduce(state: afterTwo, action: .playCard(df, playerID: p1))
        let (afterColour, _) = GameEngine.reduce(state: afterFour, action: .selectColour(.jade, playerID: p1))

        #expect(afterColour.pendingDecision == nil)        // no challenge raised on a stacked Draw Four
        #expect(afterColour.pendingDrawCount == 6)          // +2 escalated to +6
        #expect(afterColour.currentPlayer?.id == p2)        // stack passes to the next player
    }

    @Test("With the rule off (default), a Draw Four resolves normally with no challenge decision")
    func testDefaultOffUnchanged() {
        let df = CardFactory.drawFour()
        let state = GameStateBuilder()
            .withPlayers()                                   // default profile: drawFourChallengeable == false
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withHand(forPlayer: 0, cards: [df, CardFactory.number(5, .crimson)])
            .withHand(forPlayer: 1, cards: [CardFactory.number(3, .amber)])
            .withDrawPile((0..<40).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p0 = state.players[0].id
        let (afterPlay, _) = GameEngine.reduce(state: state, action: .playCard(df, playerID: p0))
        let (after, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.jade, playerID: p0))
        if case .drawFourChallenge = after.pendingDecision {
            Issue.record("Draw Four must not raise a challenge when the rule is off")
        }
    }
}
