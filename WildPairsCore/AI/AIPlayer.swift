import Foundation

// MARK: - AIPlayer

/// The top-level dispatcher for AI move selection.
///
/// `AIPlayer` is a namespace (caseless enum) containing the public interface
/// used by the ViewModel to request an AI move. It dispatches to the appropriate
/// difficulty-specific implementation based on the `Difficulty` parameter.
///
/// ## Fairness
///
/// AI implementations receive only an `AIObservation`. The full `GameState`
/// is never passed to any AI function. See `AIObservation` for what the AI
/// may and may not see.
///
/// ## Determinism
///
/// All AI functions accept `rng: inout SeededRNG`. Given the same observation,
/// the same seed, and the same RNG state, every AI will make the same choice.
/// This enables reproducible AI behaviour in simulation tests.
///
/// ## Usage (from ViewModel)
///
/// ```swift
/// let observation = AIObservation(from: currentState, for: aiPlayerID)
/// let action = AIPlayer.chooseMove(
///     observation: observation,
///     difficulty: player.difficulty,
///     rng: &gameRNG
/// )
/// dispatch(action)
/// ```
public enum AIPlayer {

    // MARK: - Move Selection

    /// Returns the `GameAction` the AI chooses to take on its turn.
    ///
    /// This is the only public entry point for AI move selection. It dispatches
    /// to the correct difficulty-specific implementation and must only be called
    /// when `observation.isMyTurn` is true.
    ///
    /// - Parameters:
    ///   - observation: A filtered view of game state for the AI player.
    ///   - difficulty: The AI difficulty level to apply.
    ///   - rng: The seeded RNG; consumed and advanced by the AI call.
    /// - Returns: A legal `GameAction` for the AI to take.
    public static func chooseMove(
        observation: AIObservation,
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> GameAction {
        // TODO: Implement in Phase 4
        switch difficulty {
        case .easy:
            return EasyAI.chooseMove(observation: observation, rng: &rng)
        case .medium:
            return MediumAI.chooseMove(observation: observation, rng: &rng)
        case .hard:
            return HardAI.chooseMove(observation: observation, rng: &rng)
        case .expert:
            return ExpertAI.chooseMove(observation: observation, rng: &rng)
        }
    }

    // MARK: - Colour Selection

    /// Returns the colour the AI chooses after playing a wild card.
    ///
    /// Called by the ViewModel when the engine has returned a `.promptColourChoice` effect
    /// for an AI player.
    ///
    /// - Parameters:
    ///   - observation: Current observation for the AI player.
    ///   - difficulty: AI difficulty level.
    ///   - rng: The seeded RNG.
    /// - Returns: The chosen colour for the active colour constraint.
    public static func selectColour(
        observation: AIObservation,
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> CardColour {
        // TODO: Implement in Phase 4
        switch difficulty {
        case .easy:
            return EasyAI.selectColour(observation: observation, rng: &rng)
        case .medium, .hard, .expert:
            return MediumAI.selectColour(observation: observation, rng: &rng)
        }
    }

    // MARK: - Target Selection

    /// Returns the player ID the AI nominates when playing a targeted card.
    ///
    /// Called by the ViewModel when the engine has returned a `.promptTargetChoice` effect
    /// for an AI player.
    ///
    /// - Parameters:
    ///   - observation: Current observation for the AI player.
    ///   - validTargets: The set of player IDs that may be legally targeted.
    ///   - difficulty: AI difficulty level.
    ///   - rng: The seeded RNG.
    /// - Returns: The chosen target player ID.
    public static func selectTarget(
        observation: AIObservation,
        validTargets: [UUID],
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> UUID {
        // TODO: Implement in Phase 4
        switch difficulty {
        case .easy:
            return EasyAI.selectTarget(observation: observation, validTargets: validTargets, rng: &rng)
        case .medium, .hard, .expert:
            return MediumAI.selectTarget(observation: observation, validTargets: validTargets, rng: &rng)
        }
    }

    // MARK: - Think Delay

    /// The simulated thinking delay in seconds for the given difficulty.
    ///
    /// The ViewModel uses this value for `Task.sleep` before dispatching the AI move.
    /// Set to 0 in fast/simulation mode.
    ///
    /// - Parameter difficulty: The AI difficulty level.
    /// - Returns: Delay in seconds.
    public static func thinkDelay(for difficulty: Difficulty) -> TimeInterval {
        switch difficulty {
        case .easy:   return 0.3
        case .medium: return 0.6
        case .hard:   return 0.9
        case .expert: return 1.2
        }
    }
}

// MARK: - EasyAI

/// Random move selection with no strategy. See ai-strategy.md §3.
enum EasyAI {

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        // TODO: Implement in Phase 4
        return .drawCard(playerID: observation.myPlayerID)
    }

    static func selectColour(observation: AIObservation, rng: inout SeededRNG) -> CardColour {
        // TODO: Implement in Phase 4
        return CardColour.allCases.randomElement(using: &rng) ?? .crimson
    }

    static func selectTarget(
        observation: AIObservation,
        validTargets: [UUID],
        rng: inout SeededRNG
    ) -> UUID {
        // TODO: Implement in Phase 4
        return validTargets.randomElement(using: &rng) ?? observation.myPlayerID
    }
}

// MARK: - MediumAI

/// Prefers action cards; chooses beneficial colour; avoids targeting partner. See ai-strategy.md §4.
enum MediumAI {

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        // TODO: Implement in Phase 4
        return .drawCard(playerID: observation.myPlayerID)
    }

    static func selectColour(observation: AIObservation, rng: inout SeededRNG) -> CardColour {
        // TODO: Implement in Phase 4
        let counts = Dictionary(
            grouping: observation.myHand.compactMap(\.colour),
            by: { $0 }
        ).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
            ?? CardColour.allCases.randomElement(using: &rng)
            ?? .crimson
    }

    static func selectTarget(
        observation: AIObservation,
        validTargets: [UUID],
        rng: inout SeededRNG
    ) -> UUID {
        // TODO: Implement in Phase 4
        let opponents = validTargets.filter { $0 != observation.partnerID }
        let pool = opponents.isEmpty ? validTargets : opponents
        return pool.min(by: {
            observation.cardCounts[$0, default: 7] < observation.cardCounts[$1, default: 7]
        }) ?? pool.first ?? observation.myPlayerID
    }
}

// MARK: - HardAI

/// Multi-factor move scoring. See ai-strategy.md §5.
enum HardAI {

    // Weight constants — adjust here for balancing (see ai-strategy.md §14).
    enum Weight {
        static let handReduction:      Float = 1.0
        static let actionBonus:        Float = 0.5
        static let opponentDisruption: Float = 2.0
        static let colourAdvantage:    Float = 0.3
        static let actionConservation: Float = 1.5
        static let partnerPenalty:     Float = 3.0
    }

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        // TODO: Implement in Phase 4
        return .drawCard(playerID: observation.myPlayerID)
    }

    static func scoreMove(_ card: Card, observation: AIObservation) -> Float {
        // TODO: Implement in Phase 4
        return 0.0
    }

    static func computeUrgency(_ observation: AIObservation) -> Float {
        let count = Float(observation.myHand.count)
        return max(0.0, 1.0 - count / 7.0)
    }
}

// MARK: - ExpertAI

/// Short-horizon simulation with move scoring. See ai-strategy.md §6.
enum ExpertAI {

    enum Config {
        static let simulationBreadth: Int = 5
        static let simulationDepth: Int = 3
    }

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        // TODO: Implement in Phase 4
        return .drawCard(playerID: observation.myPlayerID)
    }

    static func simulateWinProbability(
        card: Card,
        observation: AIObservation,
        depth: Int,
        rng: inout SeededRNG
    ) -> Float {
        // TODO: Implement in Phase 4
        return 0.0
    }
}
