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
        isLegal(
            card,
            currentColour: state.currentColour,
            topCardType: state.currentCardType,
            mode: state.mode,
            stackDrawCards: state.ruleProfile.stackDrawCards,
            pendingDrawType: state.pendingDrawType
        )
    }

    /// Core match legality from primitives — the single rule shared by the engine
    /// (`isLegal(_:in:)`) and the AI (via `AIObservation`), so the two can never drift.
    /// `state.currentCardType` always equals the top discard's type (it's set to the played
    /// card's type on every play), so passing it as `topCardType` matches the engine exactly.
    /// The Draw Four "no colour match in hand" timing restriction is layered on by
    /// `isCardLegal`, not here.
    public static func isLegal(
        _ card: Card,
        currentColour: CardColour,
        topCardType: CardType?,
        mode: GameMode,
        stackDrawCards: Bool,
        pendingDrawType: CardType?
    ) -> Bool {
        // Draw stacking (Phase 11 F): a pending draw stack overrides every other legality
        // rule, including All-Wild's "anything plays" — you must stack or draw, full stop.
        if stackDrawCards, let pendingType = pendingDrawType {
            switch pendingType {
            case .drawTwo: return card.type == .drawTwo || card.type == .drawFour
            case .drawFour: return card.type == .drawFour
            default: return false
            }
        }

        if mode == .allWild { return true }

        // Wild-type cards (no colour) are always playable; Draw Four's timing restriction
        // is enforced by isCardLegal/drawFourIsLegal, not here.
        if card.isWild { return true }

        guard let cardColour = card.colour else { return true }

        // Match by colour
        if cardColour == currentColour { return true }

        // Match by card type / number
        if let topCardType {
            if card.type == topCardType { return true }
            if case .number(let v1) = card.type, case .number(let v2) = topCardType, v1 == v2 {
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
        isCardLegal(
            card,
            hand: hand,
            currentColour: state.currentColour,
            topCardType: state.currentCardType,
            mode: state.mode,
            stackDrawCards: state.ruleProfile.stackDrawCards,
            pendingDrawType: state.pendingDrawType,
            drawFourChallengeable: state.ruleProfile.drawFourChallengeable
        )
    }

    /// Primitive combined legality — shared by the engine and the AI so neither can drift.
    public static func isCardLegal(
        _ card: Card,
        hand: [Card],
        currentColour: CardColour,
        topCardType: CardType?,
        mode: GameMode,
        stackDrawCards: Bool,
        pendingDrawType: CardType?,
        drawFourChallengeable: Bool
    ) -> Bool {
        guard isLegal(card, currentColour: currentColour, topCardType: topCardType,
                      mode: mode, stackDrawCards: stackDrawCards,
                      pendingDrawType: pendingDrawType) else { return false }
        guard card.type == .drawFour else { return true }
        // A +4 answering a pending stack is legal regardless of hand contents.
        if stackDrawCards, pendingDrawType != nil { return true }
        return drawFourIsLegal(hand: hand, currentColour: currentColour, mode: mode,
                               drawFourChallengeable: drawFourChallengeable)
    }

    /// Every card in `hand` legal to play right now (`isCardLegal` applied to each).
    public static func legalPlaysConsideringDrawFour(hand: [Card], state: GameState) -> [Card] {
        hand.filter { isCardLegal($0, hand: hand, state: state) }
    }

    // MARK: Draw-Four restriction

    /// True if the active player may legally play a Draw Four right now.
    /// Draw Four requires no other colour-matching card in hand (standard rule).
    public static func drawFourIsLegal(hand: [Card], state: GameState) -> Bool {
        drawFourIsLegal(hand: hand, currentColour: state.currentColour, mode: state.mode,
                        drawFourChallengeable: state.ruleProfile.drawFourChallengeable)
    }

    /// Primitive Draw-Four restriction — shared by the engine and the AI.
    public static func drawFourIsLegal(
        hand: [Card],
        currentColour: CardColour,
        mode: GameMode,
        drawFourChallengeable: Bool
    ) -> Bool {
        if mode == .allWild { return true }                   // every card is playable
        if drawFourChallengeable { return true }              // house rule: always playable
        // Legal only when no other card matches the current colour
        return !hand.contains { card in
            guard !card.isWild, card.type != .drawFour else { return false }
            return card.colour == currentColour
        }
    }

    // MARK: Solo! declaration

    /// Probability that an AI at this difficulty forgets to declare Solo! before playing
    /// down to one card, leaving it catchable for the penalty. Master never slips.
    public static func aiSoloForgetChance(for difficulty: Difficulty) -> Double {
        switch difficulty {
        case .easy:   return 0.25
        case .medium: return 0.15
        case .hard:   return 0.08
        case .expert: return 0.03
        case .master: return 0
        }
    }

    /// Deterministic forget roll — the engine and tests share this exact function so AI
    /// declaration behaviour is reproducible from the game seed.
    public static func aiForgetsSolo(difficulty: Difficulty, rng: inout SeededRNG) -> Bool {
        let roll = Double(rng.next() % 10_000) / 10_000
        return roll < aiSoloForgetChance(for: difficulty)
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
