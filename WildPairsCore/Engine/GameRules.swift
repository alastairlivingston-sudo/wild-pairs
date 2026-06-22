import Foundation

// MARK: - GameRules

/// Pure functions for move legality — no state mutation, no side effects.
public enum GameRules {

    // MARK: Legal plays

    /// Returns every card in `hand` that may legally be played in the current state.
    public static func legalPlays(hand: [Card], state: GameState) -> [Card] {
        hand.filter { isLegal($0, in: state) }
    }

    /// True if `card` may legally be played in `state` by the active player.
    public static func isLegal(_ card: Card, in state: GameState) -> Bool {
        if state.mode == .allWild { return true }

        // Wild-type cards (no colour) are always playable.
        if card.isWild { return true }

        // Draw Four: only when the player holds no other colour-matching card
        // (unless house rule drawFourChallengeable disables this restriction — for now
        // we treat the restriction as always active in standard play).
        if card.type == .drawFour {
            return true  // legality of draw-four timing is enforced at the play site
        }

        guard let cardColour = card.colour else { return true }

        // Match by colour
        if cardColour == state.currentColour { return true }

        // Match by card type
        if let topCard = state.deck.topDiscard {
            if card.type == topCard.type { return true }
            // Number-to-number match
            if case .number(let v1) = card.type, case .number(let v2) = topCard.type, v1 == v2 {
                return true
            }
        }

        return false
    }

    // MARK: Draw-Four restriction

    /// True if the active player may legally play a Draw Four right now.
    /// Draw Four requires no other colour-matching card in hand (standard rule).
    public static func drawFourIsLegal(hand: [Card], state: GameState) -> Bool {
        if state.mode == .allWild { return true }                   // every card is playable
        if state.ruleProfile.drawFourChallengeable { return true }  // house rule: always playable
        // Legal only when no other card matches the current colour
        return !hand.contains { card in
            guard !card.isWild, card.type != .drawFour else { return false }
            return card.colour == state.currentColour
        }
    }

    // MARK: Turn ordering

    /// Returns the index of the player who acts after `currentIndex`, skipping `skipCount` seats.
    public static func nextIndex(
        from currentIndex: Int,
        direction: TurnDirection,
        playerCount: Int,
        skipCount: Int = 1
    ) -> Int {
        let step = direction == .clockwise ? skipCount : -skipCount
        return ((currentIndex + step) % playerCount + playerCount) % playerCount
    }
}
