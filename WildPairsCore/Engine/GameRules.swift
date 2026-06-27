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
        // Draw stacking (Phase 11 F): a pending draw stack overrides every other legality
        // rule, including All-Wild's "anything plays" — you must stack or draw, full stop.
        if state.ruleProfile.stackDrawCards, let pendingType = state.pendingDrawType {
            switch pendingType {
            case .drawTwo: return card.type == .drawTwo || card.type == .drawFour
            case .drawFour: return card.type == .drawFour
            default: return false
            }
        }

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

    // MARK: Combined legality (colour/type match + Draw-Four restriction + stacking)

    /// The single source of truth for "can this card be played right now," combining
    /// `isLegal`'s colour/type/stacking rules with the Draw Four "no colour match in hand"
    /// restriction. The Draw Four restriction does **not** apply while answering a pending
    /// draw stack — stacking a +4 onto a +2 is legal regardless of what colours are also in
    /// hand, since it's a stack response, not a normal play.
    public static func isCardLegal(_ card: Card, hand: [Card], state: GameState) -> Bool {
        guard isLegal(card, in: state) else { return false }
        guard card.type == .drawFour else { return true }
        if state.ruleProfile.stackDrawCards, state.pendingDrawType != nil { return true }
        return drawFourIsLegal(hand: hand, state: state)
    }

    /// Every card in `hand` legal to play right now (`isCardLegal` applied to each).
    public static func legalPlaysConsideringDrawFour(hand: [Card], state: GameState) -> [Card] {
        hand.filter { isCardLegal($0, hand: hand, state: state) }
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
