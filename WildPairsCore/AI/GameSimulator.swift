import Foundation

// MARK: - SimulationResult

public struct SimulationResult: Sendable {
    public let winner: TeamID?
    public let turns: Int
    public let illegalMoveAttempts: Int
    public let stuck: Bool

    public init(winner: TeamID?, turns: Int, illegalMoveAttempts: Int, stuck: Bool) {
        self.winner = winner
        self.turns = turns
        self.illegalMoveAttempts = illegalMoveAttempts
        self.stuck = stuck
    }
}

// MARK: - GameSimulator

/// Runs a complete Wild Pairs game headlessly for simulation and balance testing.
///
/// All four players are AI-controlled. The simulator uses `GameEngine.reduce` directly
/// and never involves SwiftUI or UIKit. Results are deterministic for a given seed.
///
/// Usage:
/// ```swift
/// let result = GameSimulator.run(mode: .standardTeams, difficulty: .easy, seed: 42)
/// assert(result.illegalMoveAttempts == 0)
/// assert(!result.stuck)
/// ```
public enum GameSimulator {

    // MARK: Run

    public static func run(
        mode: GameMode = .standardTeams,
        difficulty: Difficulty = .easy,
        seed: UInt64 = 0,
        maxTurns: Int = 300
    ) -> SimulationResult {
        let config = GameConfig(
            mode: mode,
            players: [
                PlayerConfig(name: "A0", role: .ai, teamID: .teamA, difficulty: difficulty, seatPosition: 0),
                PlayerConfig(name: "B1", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 1),
                PlayerConfig(name: "A2", role: .ai, teamID: .teamA, difficulty: difficulty, seatPosition: 2),
                PlayerConfig(name: "B3", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 3)
            ],
            ruleProfile: ruleProfile(for: mode),
            seed: seed
        )

        var (state, _) = GameEngine.reduce(state: emptyState(), action: .newGame(config: config))
        var rng = SeededRNG(seed: seed)
        var turns = 0
        var illegalAttempts = 0

        while state.phase == .playing || state.pendingDecision != nil {
            guard turns < maxTurns else {
                return SimulationResult(winner: nil, turns: turns, illegalMoveAttempts: illegalAttempts, stuck: true)
            }

            // Resolve pending decision first
            if let pending = state.pendingDecision {
                (state, _) = resolvePending(pending: pending, state: state, rng: &rng, difficulty: difficulty)
                turns += 1
                continue
            }

            guard let currentPlayer = state.currentPlayer else { break }

            let observation = AIObservation(from: state, for: currentPlayer.id)
            let action = AIPlayer.chooseMove(observation: observation, difficulty: currentPlayer.difficulty, rng: &rng)

            // Validate the action before dispatching
            if !GameEngine.isLegalMove(state: state, action: action) {
                illegalAttempts += 1
                // Force a draw to avoid getting stuck
                let draw = GameAction.drawCard(playerID: currentPlayer.id)
                (state, _) = GameEngine.reduce(state: state, action: draw)
            } else {
                (state, _) = GameEngine.reduce(state: state, action: action)
            }
            turns += 1

            // After a round ends, auto-begin next round for multi-round simulation
            if state.phase == .roundEnded {
                (state, _) = GameEngine.reduce(state: state, action: .beginNewRound)
                // Stop after 1 round — for simulation we measure single-round completion
                break
            }
            if state.phase == .gameEnded {
                break
            }
        }

        return SimulationResult(
            winner: state.winState?.winningTeam,
            turns: turns,
            illegalMoveAttempts: illegalAttempts,
            stuck: false
        )
    }

    // MARK: Batch run

    public static func runBatch(
        mode: GameMode = .standardTeams,
        difficulty: Difficulty = .easy,
        seeds: Range<UInt64>,
        maxTurns: Int = 300
    ) -> [SimulationResult] {
        seeds.map { run(mode: mode, difficulty: difficulty, seed: $0, maxTurns: maxTurns) }
    }

    // MARK: Private helpers

    private static func resolvePending(
        pending: PendingDecision,
        state: GameState,
        rng: inout SeededRNG,
        difficulty: Difficulty
    ) -> (GameState, [GameEffect]) {
        switch pending {
        case .colourChoice(let playerID):
            guard let player = state.players.first(where: { $0.id == playerID }) else {
                return (state, [])
            }
            let observation = AIObservation(from: state, for: playerID)
            let colour = AIPlayer.selectColour(observation: observation, difficulty: player.difficulty, rng: &rng)
            return GameEngine.reduce(state: state, action: .selectColour(colour, playerID: playerID))

        case .targetChoice(let playerID, let validTargets):
            guard let player = state.players.first(where: { $0.id == playerID }) else {
                return (state, [])
            }
            let observation = AIObservation(from: state, for: playerID)
            let targetID = AIPlayer.selectTarget(observation: observation, validTargets: validTargets, difficulty: player.difficulty, rng: &rng)
            return GameEngine.reduce(state: state, action: .selectTarget(targetPlayerID: targetID, playerID: playerID))

        case .teamPass, .drawFourChallenge:
            // These pending decisions are resolved by advancing past them in simulation
            var s = state
            s.pendingDecision = nil
            return (s, [])
        }
    }

    private static func emptyState() -> GameState {
        GameState(players: [])
    }

    private static func ruleProfile(for mode: GameMode) -> RuleProfile {
        switch mode {
        case .standardTeams: return .standardTeams()
        case .allWild: return .allWild()
        case .sideToSide: return .sideToSide()
        }
    }
}
