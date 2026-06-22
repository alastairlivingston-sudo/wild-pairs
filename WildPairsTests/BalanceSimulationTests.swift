import Testing
@testable import WildPairsCore

// MARK: - Smoke suite (100 games per difficulty)
// Full balance suite (1,000 games) runs at phase gate only.
// Run with: swift test --filter WildPairsTests.BalanceSimulationTests

@Suite("Balance simulation — smoke suite (100 games per difficulty)")
struct BalanceSimulationTests {

    static let smokeSeedRange: Range<UInt64> = 0..<100
    static let maxTurns = 300

    // MARK: Easy

    @Test("Easy AI: 0 illegal moves in 100 games")
    func testEasyZeroIllegalMoves() {
        let results = GameSimulator.runBatch(difficulty: .easy, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let totalIllegal = results.reduce(0) { $0 + $1.illegalMoveAttempts }
        #expect(totalIllegal == 0)
    }

    @Test("Easy AI: 0 stuck games in 100 games")
    func testEasyZeroStuckGames() {
        let results = GameSimulator.runBatch(difficulty: .easy, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let stuckCount = results.filter { $0.stuck }.count
        #expect(stuckCount == 0)
    }

    @Test("Easy AI: all games complete (winner is not nil)")
    func testEasyAllGamesComplete() {
        let results = GameSimulator.runBatch(difficulty: .easy, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let incomplete = results.filter { $0.winner == nil && !$0.stuck }.count
        #expect(incomplete == 0)
    }

    // MARK: Medium

    @Test("Medium AI: 0 illegal moves in 100 games")
    func testMediumZeroIllegalMoves() {
        let results = GameSimulator.runBatch(difficulty: .medium, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let totalIllegal = results.reduce(0) { $0 + $1.illegalMoveAttempts }
        #expect(totalIllegal == 0)
    }

    @Test("Medium AI: 0 stuck games in 100 games")
    func testMediumZeroStuckGames() {
        let results = GameSimulator.runBatch(difficulty: .medium, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let stuckCount = results.filter { $0.stuck }.count
        #expect(stuckCount == 0)
    }

    // MARK: Hard

    @Test("Hard AI: 0 illegal moves in 100 games")
    func testHardZeroIllegalMoves() {
        let results = GameSimulator.runBatch(difficulty: .hard, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let totalIllegal = results.reduce(0) { $0 + $1.illegalMoveAttempts }
        #expect(totalIllegal == 0)
    }

    @Test("Hard AI: 0 stuck games in 100 games")
    func testHardZeroStuckGames() {
        let results = GameSimulator.runBatch(difficulty: .hard, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let stuckCount = results.filter { $0.stuck }.count
        #expect(stuckCount == 0)
    }

    // MARK: Expert

    @Test("Expert AI: 0 illegal moves in 100 games")
    func testExpertZeroIllegalMoves() {
        let results = GameSimulator.runBatch(difficulty: .expert, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let totalIllegal = results.reduce(0) { $0 + $1.illegalMoveAttempts }
        #expect(totalIllegal == 0)
    }

    @Test("Expert AI: 0 stuck games in 100 games")
    func testExpertZeroStuckGames() {
        let results = GameSimulator.runBatch(difficulty: .expert, seeds: Self.smokeSeedRange, maxTurns: Self.maxTurns)
        let stuckCount = results.filter { $0.stuck }.count
        #expect(stuckCount == 0)
    }

    // MARK: Cross-mode checks

    @Test("AllWild mode: 0 illegal moves in 20 games")
    func testAllWildZeroIllegalMoves() {
        let results = GameSimulator.runBatch(mode: .allWild, difficulty: .easy, seeds: 0..<20, maxTurns: Self.maxTurns)
        let totalIllegal = results.reduce(0) { $0 + $1.illegalMoveAttempts }
        #expect(totalIllegal == 0)
    }

    // MARK: Determinism

    @Test("Same seed produces same result across two runs")
    func testDeterminism() {
        let r1 = GameSimulator.run(difficulty: .hard, seed: 999)
        let r2 = GameSimulator.run(difficulty: .hard, seed: 999)
        #expect(r1.winner == r2.winner)
        #expect(r1.turns == r2.turns)
        #expect(r1.illegalMoveAttempts == r2.illegalMoveAttempts)
    }

    @Test("Different seeds may produce different winners (not constant bias)")
    func testNonConstantBias() {
        let winners = (0..<20).map {
            GameSimulator.run(difficulty: .easy, seed: UInt64($0)).winner
        }
        let teamAWins = winners.filter { $0 == .teamA }.count
        let teamBWins = winners.filter { $0 == .teamB }.count
        // Both teams should win at least once in 20 games
        #expect(teamAWins > 0)
        #expect(teamBWins > 0)
    }
}
