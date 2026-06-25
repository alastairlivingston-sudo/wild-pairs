import Foundation

// MARK: - HapticStyle

/// The style of haptic feedback to generate.
public enum HapticStyle: String, Equatable, Sendable {
    case light       // A subtle tap — card draw, card hover
    case medium      // A clear impact — card play
    case heavy       // A strong impact — wild card play, round end
    case rigid       // A sharp click — illegal move rejected
    case soft        // A gentle pulse — solo call
    case success     // A success pattern — winning a round
    case warning     // A warning pattern — draw penalty incoming
    case error       // An error pattern — illegal action
    case selectionChanged  // A tick — colour/target selection scroll
}

// MARK: - SoundEffect

/// Named sound effects that the audio coordinator will play.
public enum SoundEffect: String, Equatable, Sendable, CaseIterable {
    case cardPlay        // Standard card played onto discard pile
    case cardDraw        // Card drawn from draw pile
    case cardShuffle     // Draw pile reshuffled
    case skipPlayed      // Skip card played
    case reversePlayed   // Reverse card played
    case drawTwoPlayed   // Draw-two card played
    case wildPlayed      // Wild (changeColour or drawFour) played
    case soloCall        // Player calls "Solo!"
    case soloMissed      // Player failed to call Solo — penalty
    case roundWin        // A team wins the round
    case gameWin         // A team wins the game
    case buttonTap       // Generic UI button tap
    case cardFan         // Cards fanning into hand
    case swapHands       // Forced swap animation
}

// MARK: - AnimationPosition

/// A logical position identifier used to target animations.
public enum AnimationPosition: Equatable, Sendable {
    case playerHand(playerID: UUID)
    case discardPile
    case drawPile
    case tableCenter
}

// MARK: - GameEffect

/// A side effect that the engine requests but does not perform.
///
/// `GameEffect` values are returned by `GameEngine.reduce` alongside the new state.
/// The ViewModel dispatches each effect to the appropriate coordinator (animation,
/// haptics, sound, accessibility). Effects are pure value types — no closures.
public enum GameEffect: Equatable, Sendable {

    // MARK: Card Animations

    /// Animate a card moving from a player's hand to the discard pile.
    case animateCardPlay(card: Card, fromPlayerID: UUID)

    /// Animate one or more cards moving from the draw pile to a player's hand.
    case animateCardDraw(toPlayerID: UUID, count: Int)

    /// Animate the deck being shuffled (discard recombined into draw pile).
    case animateCardShuffle

    /// Animate the draw pile running empty.
    case animateDeckEmpty

    /// Animate cards moving between two players (forced swap).
    case animateHandSwap(fromPlayerID: UUID, toPlayerID: UUID)

    /// Animate all cards of a colour being removed from a player's hand.
    case animateDiscardAll(playerID: UUID, colour: CardColour)

    // MARK: Turn Flow

    /// Animate a skip indicator over the skipped player's seat.
    case animateSkip(playerID: UUID)

    /// Animate the turn-direction arrow reversing.
    case animateReverse

    /// Animate skip indicators over two consecutively skipped players' seats.
    case animateSkipTwo(firstPlayerID: UUID, secondPlayerID: UUID)

    /// Animate the team-play indicator showing the partner is invited to play.
    case animateTeamPlay(partnerID: UUID)

    // MARK: Wild Card Resolution

    /// Show the colour picker for the given player.
    case promptColourChoice(playerID: UUID)

    /// Show the target picker for the given player, restricted to the valid target list.
    case promptTargetChoice(playerID: UUID, validTargets: [UUID])

    // MARK: Solo Call

    /// Display and announce the Solo call for the named player.
    case announceSolo(playerName: String)

    /// Indicate that the given player failed to call Solo before drawing — penalty cards dealt.
    case soloCallMissed(playerName: String, penaltyCards: Int)

    // MARK: Round & Game End

    /// Trigger the round-end fanfare for the winning team.
    case playRoundEnd(winningTeam: TeamID)

    /// Trigger the game-end celebration for the winning team.
    case playGameEnd(winningTeam: TeamID)

    // MARK: Haptics

    /// Request a haptic feedback pulse.
    case triggerHaptic(HapticStyle)

    // MARK: Sound

    /// Request a sound effect to be played.
    case playSound(SoundEffect)

    // MARK: Accessibility

    /// Post a VoiceOver announcement string.
    case accessibilityAnnounce(String)

    // MARK: AI Scheduling

    /// Tell the ViewModel to schedule an AI move for the given player after the given delay.
    case scheduleAIMove(playerID: UUID, delay: TimeInterval)

    // MARK: Persistence

    /// Tell the ViewModel to save the current state immediately.
    case triggerAutosave
}
