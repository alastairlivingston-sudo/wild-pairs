import Testing
@testable import WildPairsCore

// MARK: - GameEngineTests

/// Unit tests for `GameEngine` and the core game rules.
///
/// All tests use `SeededRNG(seed:)` for deterministic shuffling and
/// `GameStateBuilder` for concise test fixture construction.
/// No mocking — all tests exercise the real engine.
@Suite("GameEngine Tests")
struct GameEngineTests {

    // MARK: - Deck Tests

    @Test("Standard deck is created with the correct card count")
    func testDeckCreation() {
        // TODO: Implement in Phase 2
        // 1. Create a SeededRNG with a fixed seed.
        // 2. Call Deck.standard(cardSet: .standard, rng: &rng).
        // 3. Assert draw pile contains 108 cards (standard Wild Pairs deck size).
        // 4. Assert discard pile is empty.
    }

    @Test("Dealing distributes the correct number of cards to each player")
    func testDealingDistributesCorrectCardCount() {
        // TODO: Implement in Phase 2
        // 1. Build a GameState with 4 players and default rule profile (initialHandSize: 7).
        // 2. Dispatch GameAction.newGame(config:) with a fixed seed.
        // 3. Assert each player's hand.count == 7.
        // 4. Assert the draw pile has decreased by 4 * 7 = 28 cards.
    }

    // MARK: - Legal Move Tests

    @Test("Playing a card that matches the current colour is a valid move")
    func testValidMoveMatchingColour() {
        // TODO: Implement in Phase 2
        // 1. Build a state where currentColour == .crimson.
        // 2. Give player 0 a hand containing a Crimson 5.
        // 3. Call GameEngine.isLegalMove(state:action:) with .playCard(crimson5, playerID).
        // 4. Assert the result is true.
    }

    @Test("Playing a card that matches the current card type (number) is a valid move")
    func testValidMoveMatchingNumber() {
        // TODO: Implement in Phase 2
        // 1. Build a state where the discard top is a Cobalt 7 (currentCardType == .number, number == 7).
        // 2. Give player 0 a Crimson 7 (different colour, same number).
        // 3. Assert GameEngine.isLegalMove returns true for playing the Crimson 7.
    }

    @Test("Playing a card that matches neither colour nor type is an invalid move")
    func testInvalidMoveNoMatch() {
        // TODO: Implement in Phase 2
        // 1. Build a state where currentColour == .cobalt and discard top is Cobalt 3.
        // 2. Give player 0 a Crimson 5 (different colour, different number).
        // 3. Assert GameEngine.isLegalMove returns false for playing the Crimson 5.
    }

    @Test("A wild card (changeColour or drawFour) can always be played regardless of current colour")
    func testWildCardAlwaysPlayable() {
        // TODO: Implement in Phase 2
        // 1. Build a state where currentColour == .amber.
        // 2. Give player 0 a changeColour wild card.
        // 3. Assert GameEngine.isLegalMove returns true.
        // 4. Repeat with a drawFour card.
        // 5. Assert both return true.
    }

    // MARK: - Turn Advancement Tests

    @Test("After a valid play, the turn advances to the next player")
    func testTurnAdvancesAfterValidPlay() {
        // TODO: Implement in Phase 3
        // 1. Build a state with 4 players, currentPlayerIndex == 0, direction == .clockwise.
        // 2. Player 0 plays a matching number card.
        // 3. Assert the returned state has currentPlayerIndex == 1.
    }

    @Test("A Skip card skips exactly one player in clockwise direction")
    func testSkipCardSkipsNextPlayer() {
        // TODO: Implement in Phase 3
        // 1. Build a state with 4 players, currentPlayerIndex == 0.
        // 2. Player 0 plays a Skip card matching the current colour.
        // 3. Assert currentPlayerIndex == 2 (player 1 was skipped).
    }

    @Test("A Reverse card reverses the turn direction and advances one step")
    func testReverseCardChangesTurnDirection() {
        // TODO: Implement in Phase 3
        // 1. Build a state with direction == .clockwise, currentPlayerIndex == 1.
        // 2. Player 1 plays a Reverse card.
        // 3. Assert turnDirection == .counterClockwise.
        // 4. Assert currentPlayerIndex advanced counterclockwise (i.e., to player 0).
    }

    @Test("A DrawTwo card forces the next player to draw 2 cards and lose their turn")
    func testDrawTwoForcesNextPlayerToDraw() {
        // TODO: Implement in Phase 3
        // 1. Build a state with 4 players, player 0 active.
        // 2. Player 0 plays a DrawTwo card.
        // 3. Assert player 1's hand.count increased by 2.
        // 4. Assert currentPlayerIndex == 2 (player 1 lost their turn).
    }

    // MARK: - Solo Call Tests

    @Test("callSolo succeeds when player holds exactly one card")
    func testSoloCallSucceedsWithOneCard() {
        // TODO: Implement in Phase 3
        // 1. Build a state where player 0 holds exactly 1 card and hasCalledSolo == false.
        // 2. Dispatch .callSolo(playerID: player0.id).
        // 3. Assert player 0's hasCalledSolo == true.
        // 4. Assert the returned effects contain .announceSolo(playerName:).
    }

    @Test("callSolo fails gracefully when player holds more than one card")
    func testSoloCallIgnoredWithMoreThanOneCard() {
        // TODO: Implement in Phase 3
        // 1. Build a state where player 0 holds 3 cards.
        // 2. Dispatch .callSolo(playerID: player0.id).
        // 3. Assert the state is unchanged.
        // 4. Assert no .announceSolo effect was returned.
    }

    // MARK: - Win Condition Tests

    @Test("Round ends when both teammates empty their hands (standard teams win condition)")
    func testRoundEndsWhenBothTeammatesEmptyHands() {
        // TODO: Implement in Phase 3
        // 1. Build a state with 4 players, TeamA = [0,2], TeamB = [1,3].
        // 2. Set players 0 and 2 to each hold exactly 1 card; all others have normal hands.
        // 3. Player 0 plays their last card; player 2 already has hasFinishedRound == true.
        // 4. Assert returned state.phase == .roundEnded.
        // 5. Assert state.winState?.winningTeam == .teamA.
    }
}
