import Foundation

// MARK: - GameEngine

/// The pure game logic reducer for Wild Pairs.
///
/// `GameEngine` contains no state of its own and performs no side effects.
/// Every operation is a pure function: given the same inputs, the output
/// is always identical. Side effects (animations, haptics, sound, persistence)
/// are communicated through the returned `[GameEffect]` array, which the
/// ViewModel processes independently.
///
/// Usage:
/// ```swift
/// let (newState, effects) = GameEngine.reduce(state: currentState, action: action)
/// ```
public struct GameEngine {

    // MARK: - Main Entry Point

    /// Applies a `GameAction` to the current `GameState` and returns the next state
    /// plus any side effects that should be processed by the ViewModel.
    ///
    /// - Parameters:
    ///   - state: The current game state.
    ///   - action: The action to apply.
    /// - Returns: A tuple of (newState, effects). If the action is illegal, the
    ///   state is returned unchanged with an `.accessibilityAnnounce` effect.
    public static func reduce(
        state: GameState,
        action: GameAction
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 2
        // Dispatch to the appropriate private handler based on action case.
        // All handlers receive the current state and return (GameState, [GameEffect]).
        // Increment state.actionCount on every successful action.
        var next = state
        next.actionCount += 1
        return (next, [])
    }

    // MARK: - Legal Move Validation

    /// Returns true if the given action is legal in the current state.
    ///
    /// Used by the ViewModel to guard AI moves and to compute the set of
    /// valid cards available to the current player.
    ///
    /// - Parameters:
    ///   - state: The current game state.
    ///   - action: The action to validate.
    /// - Returns: `true` if the action may be legally applied.
    public static func isLegalMove(state: GameState, action: GameAction) -> Bool {
        // TODO: Implement in Phase 2
        return false
    }

    /// Returns the set of cards in the given player's hand that can be legally played right now.
    ///
    /// - Parameters:
    ///   - state: The current game state.
    ///   - playerID: The player whose legal plays are requested.
    /// - Returns: Array of `Card` values that pass the legality check.
    public static func legalPlays(state: GameState, for playerID: UUID) -> [Card] {
        // TODO: Implement in Phase 2
        // A card is legal if:
        //   - Its colour matches state.currentColour, OR
        //   - Its type matches state.currentCardType, OR
        //   - It is a wild card (isWild == true)
        // Plus: respect stackDrawCards rule when a draw penalty is pending.
        return []
    }

    // MARK: - Private Action Handlers

    private static func handlePlayCard(
        _ card: Card,
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleDrawCard(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handlePassTurn(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleSelectColour(
        _ colour: CardColour,
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleSelectTarget(
        targetPlayerID: UUID,
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleTeamPass(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleCallSolo(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleChallengeDrawFour(
        challengerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleNewGame(
        config: GameConfig,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 2
        // 1. Validate config.ruleProfile.
        // 2. Generate or use provided seed.
        // 3. Create players from config.players.
        // 4. Build and shuffle deck.
        // 5. Deal initialHandSize cards to each player.
        // 6. Place first card on discard pile; ensure it is not a wild draw-four to start.
        // 7. Set currentColour from first discard.
        // 8. Set phase to .playing.
        // 9. Return effects: [.animateCardShuffle, .animateCardDraw * playerCount, .triggerAutosave]
        return (state, [])
    }

    private static func handleBeginNewRound(
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 3
        return (state, [])
    }

    private static func handleRestoreSnapshot(
        _ snapshot: GameSnapshot,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // TODO: Implement in Phase 2
        return (state, [])
    }

    // MARK: - Turn Management Helpers

    private static func nextPlayerIndex(
        from currentIndex: Int,
        direction: TurnDirection,
        playerCount: Int,
        skipCount: Int = 1
    ) -> Int {
        // TODO: Implement in Phase 2
        // Advance index by skipCount steps in the given direction, wrapping around playerCount.
        return (currentIndex + 1) % playerCount
    }

    private static func checkRoundEnd(state: GameState) -> (GameState, [GameEffect])? {
        // TODO: Implement in Phase 3
        // Check win condition from ruleProfile:
        //   - .bothTeammatesOut: look for any team where all players have hasFinishedRound == true
        //   - .singleOut: look for any player with hand.isEmpty
        // If win found, set phase to .roundEnded, populate winState, calculate points.
        return nil
    }

    private static func calculateRoundPoints(state: GameState) -> [TeamID: Int] {
        // TODO: Implement in Phase 3
        // Sum pointValue of all cards held by the losing team at round end.
        return [:]
    }

    private static func checkGameEnd(state: GameState) -> Bool {
        // TODO: Implement in Phase 3
        // If targetScore > 0, check whether any team score >= targetScore.
        return false
    }
}
