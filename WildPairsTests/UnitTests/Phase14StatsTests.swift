import Foundation
import Testing
@testable import WildPairsCore

// Phase 14: WinState carries the round's raw points + multiplier, and GameStats keeps
// biggest-win records (raw and multiplied) without breaking pre-Phase-14 stats files.

@Suite("Phase 14 — round points on WinState")
struct WinStatePointsTests {

    @Test("A hand-emptying win records the losers' raw points and their toughest multiplier")
    func testWinStateCarriesPointsAndMultiplier() {
        let winning = CardFactory.number(5, .crimson)
        let state = GameStateBuilder()
            .withPlayers()
            .withDifficulty(.expert, forPlayer: 1)
            .withDifficulty(.easy, forPlayer: 3)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .withCurrentPlayer(0)
            .withHand(forPlayer: 0, cards: [winning])
            .withHand(forPlayer: 1, cards: [CardFactory.number(9, .jade)])
            .withHand(forPlayer: 3, cards: [CardFactory.drawFour()])
            .withDrawPile([CardFactory.number(1, .cobalt)])
            .build()

        let (next, _) = GameEngine.reduce(
            state: state, action: .playCard(winning, playerID: state.players[0].id))

        let win = next.winState
        #expect(win != nil)
        #expect(win?.roundPoints == 59, "9 + 50 from the losing team's hands")
        #expect(win?.scoreMultiplier == Difficulty.expert.scoreMultiplier,
                "The toughest losing opponent sets the multiplier")
    }

    @Test("A pre-Phase-14 WinState snapshot still decodes (no points fields)")
    func testLegacyWinStateDecodes() throws {
        // finalScores is [TeamID: Int]; Codable encodes non-String-keyed dictionaries as a
        // flat key/value array — matching what pre-Phase-14 snapshot files actually contain.
        let legacy = """
        {"winningTeam":"teamA","winningPlayerID":null,
         "reason":"singlePlayerEmptiedHand","finalScores":["teamA",120,"teamB",0]}
        """
        let decoded = try JSONDecoder().decode(WinState.self, from: Data(legacy.utf8))
        #expect(decoded.roundPoints == nil)
        #expect(decoded.scoreMultiplier == nil)
    }
}

@Suite("Phase 14 — biggest-win records")
struct BiggestWinRecordTests {

    @Test("Raw and multiplied records move independently")
    func testRecordsIndependent() {
        var stats = GameStats.empty
        stats.recordWin(points: 100, multiplier: 2)
        #expect(stats.biggestRawWin?.points == 100)
        #expect(stats.biggestMultipliedWin?.total == 200)

        // Bigger raw round on an easy table: raw record moves, multiplied does not.
        stats.recordWin(points: 150, multiplier: 1)
        #expect(stats.biggestRawWin?.points == 150)
        #expect(stats.biggestMultipliedWin?.total == 200)

        // Smaller raw round at Master ×24: multiplied record moves, raw does not.
        stats.recordWin(points: 90, multiplier: 24)
        #expect(stats.biggestRawWin?.points == 150)
        #expect(stats.biggestMultipliedWin?.total == 2160)
        #expect(stats.biggestMultipliedWin?.multiplier == 24)
    }

    @Test("Ties and zero-point rounds never overwrite a standing record")
    func testNoOverwriteOnTieOrZero() {
        var stats = GameStats.empty
        let first = Date(timeIntervalSince1970: 1_000)
        stats.recordWin(points: 100, multiplier: 2, date: first)
        stats.recordWin(points: 100, multiplier: 2, date: Date(timeIntervalSince1970: 2_000))
        #expect(stats.biggestRawWin?.date == first, "The first holder keeps a tied record")
        stats.recordWin(points: 0, multiplier: 24)
        #expect(stats.biggestRawWin?.points == 100)
    }

    @Test("A pre-Phase-14 stats file still decodes (no record keys)")
    func testLegacyStatsDecode() throws {
        let legacy = """
        {"totalGamesPlayed":3,"totalWins":2,"currentWinStreak":1,"bestWinStreak":2,
         "averageTurnsPerRound":20.5,"byDifficulty":{}}
        """
        let decoded = try JSONDecoder().decode(GameStats.self, from: Data(legacy.utf8))
        #expect(decoded.biggestRawWin == nil)
        #expect(decoded.biggestMultipliedWin == nil)
        #expect(decoded.totalGamesPlayed == 3)
    }

    @Test("Records round-trip through the stats file")
    func testRecordsRoundTrip() throws {
        var stats = GameStats.empty
        stats.recordWin(points: 264, multiplier: 8, date: Date(timeIntervalSince1970: 1_780_000_000))
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)
        #expect(decoded == stats)
    }
}
