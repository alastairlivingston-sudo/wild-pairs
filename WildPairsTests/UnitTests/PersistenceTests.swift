import Testing
import Foundation
@testable import WildPairsCore

// MARK: - Helpers

/// Creates an isolated temporary directory for each test to prevent cross-test contamination.
private func makeTempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("WildPairsTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

private func minimalState() -> GameState {
    GameStateBuilder()
        .withPlayers()
        .withCurrentColour(.crimson)
        .withTopDiscard(CardFactory.number(5, .crimson))
        .withDrawPile((0..<20).map { CardFactory.number($0 % 10, .cobalt) })
        .build()
}

// MARK: - GameSnapshot round-trip

@Suite("Persistence — GameSnapshot round-trip")
struct GameSnapshotTests {

    @Test("GameSnapshot encodes and decodes to identical state")
    func testGameSnapshotRoundTrip() throws {
        let state = minimalState()
        let snapshot = GameSnapshot(state: state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(GameSnapshot.self, from: data)

        #expect(decoded.state == snapshot.state)
        #expect(decoded.schemaVersion == 1)
        #expect(decoded.buildVersion == "0.1.0")
    }

    @Test("GameSnapshot preserves pendingDecision through encode/decode")
    func testSnapshotWithPendingDecision() throws {
        var state = minimalState()
        state.pendingDecision = .colourChoice(playerID: state.players[0].id)
        let snapshot = GameSnapshot(state: state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(GameSnapshot.self, from: data)
        #expect(decoded.state.pendingDecision == state.pendingDecision)
    }

    @Test("GameSnapshot preserves targetChoice pendingDecision")
    func testSnapshotWithTargetChoicePending() throws {
        var state = minimalState()
        let pid = state.players[0].id
        let targets = [state.players[1].id, state.players[3].id]
        state.pendingDecision = .targetChoice(playerID: pid, validTargets: targets)
        let snapshot = GameSnapshot(state: state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(GameSnapshot.self, from: data)
        #expect(decoded.state.pendingDecision == state.pendingDecision)
    }

    @Test("GameSnapshot with WinState round-trips correctly")
    func testSnapshotWithWinState() throws {
        var state = minimalState()
        state.winState = WinState(
            winningTeam: .teamA,
            winningPlayerID: state.players[0].id,
            reason: .bothTeammatesEmptiedHands,
            finalScores: [.teamA: 50, .teamB: 20]
        )
        state.phase = .roundEnded
        let snapshot = GameSnapshot(state: state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        let decoded = try decoder.decode(GameSnapshot.self, from: data)
        #expect(decoded.state.winState == state.winState)
        #expect(decoded.state.phase == .roundEnded)
    }
}

// MARK: - UserSettings round-trip

@Suite("Persistence — UserSettings round-trip")
struct UserSettingsTests {

    @Test("Default UserSettings encodes and decodes identically")
    func testDefaultSettingsRoundTrip() throws {
        let settings = UserSettings()
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: data)
        #expect(decoded == settings)
    }

    @Test("Non-default UserSettings round-trips correctly")
    func testCustomSettingsRoundTrip() throws {
        let settings = UserSettings(
            animationSpeed: .fast,
            confirmEndGame: false,
            hapticsEnabled: false,
            reducedVisualEffects: true,
            colourBlindMode: true,
            patternFills: true,
            largeCards: true
        )
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: data)
        #expect(decoded == settings)
        #expect(decoded.animationSpeed == .fast)
        #expect(decoded.colourBlindMode == true)
    }

    @Test("AnimationSpeed raw values are stable")
    func testAnimationSpeedRawValues() {
        #expect(AnimationSpeed.normal.rawValue == "normal")
        #expect(AnimationSpeed.fast.rawValue == "fast")
        #expect(AnimationSpeed.off.rawValue == "off")
    }
}

// MARK: - GameStats round-trip

@Suite("Persistence — GameStats round-trip")
struct GameStatsTests {

    @Test("Empty GameStats round-trips correctly")
    func testEmptyStatsRoundTrip() throws {
        let stats = GameStats.empty
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)
        #expect(decoded == stats)
    }

    @Test("Populated GameStats round-trips correctly")
    func testPopulatedStatsRoundTrip() throws {
        let stats = GameStats(
            totalGamesPlayed: 42,
            totalWins: 28,
            currentWinStreak: 3,
            bestWinStreak: 7,
            averageTurnsPerRound: 22.5,
            byDifficulty: ["easy": DifficultyStats(gamesPlayed: 20, wins: 15)]
        )
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)
        #expect(decoded == stats)
        #expect(decoded.byDifficulty["easy"]?.wins == 15)
    }

    @Test("DifficultyStats winRate is 0 for 0 games played")
    func testWinRateZeroGames() {
        let stats = DifficultyStats(gamesPlayed: 0, wins: 0)
        #expect(stats.winRate == 0.0)
    }

    @Test("DifficultyStats winRate calculation correct")
    func testWinRateCalculation() {
        let stats = DifficultyStats(gamesPlayed: 10, wins: 7)
        #expect(abs(stats.winRate - 0.7) < 0.001)
    }
}

// MARK: - PersistenceService save/load

@Suite("PersistenceService — file operations")
struct PersistenceServiceTests {

    @Test("saveGame then loadGame returns identical snapshot")
    func testSaveAndLoadGame() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let state = minimalState()
        let snapshot = GameSnapshot(state: state)

        try service.saveGame(snapshot)
        let loaded = try service.loadGame()
        #expect(loaded.state == snapshot.state)
    }

    @Test("loadGame throws noSavedGame when no file exists")
    func testLoadGameNoFile() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        #expect(throws: PersistenceError.noSavedGame) {
            _ = try service.loadGame()
        }
    }

    @Test("hasSavedGame returns false before save, true after save")
    func testHasSavedGame() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        #expect(!service.hasSavedGame())
        try service.saveGame(GameSnapshot(state: minimalState()))
        #expect(service.hasSavedGame())
    }

    @Test("saveSettings then loadSettings returns identical settings")
    func testSaveAndLoadSettings() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let settings = UserSettings(animationSpeed: .fast, largeCards: true)
        try service.saveSettings(settings)
        let loaded = try service.loadSettings()
        #expect(loaded == settings)
    }

    @Test("loadSettings returns defaults when no file exists")
    func testLoadSettingsDefault() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let loaded = try service.loadSettings()
        #expect(loaded == UserSettings())
    }

    @Test("saveStats then loadStats returns identical stats")
    func testSaveAndLoadStats() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let stats = GameStats(totalGamesPlayed: 10, totalWins: 6, currentWinStreak: 2, bestWinStreak: 4, averageTurnsPerRound: 18.0)
        try service.saveStats(stats)
        let loaded = try service.loadStats()
        #expect(loaded == stats)
    }

    @Test("loadStats returns empty stats when no file exists")
    func testLoadStatsDefault() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let loaded = try service.loadStats()
        #expect(loaded == GameStats.empty)
    }

    @Test("loadGame with corrupted JSON throws decodingError")
    func testLoadGameCorruptedJSON() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let corruptData = "this is not valid json".data(using: .utf8)!
        try corruptData.write(to: service.gameFileURL)

        do {
            _ = try service.loadGame()
            Issue.record("Expected decodingError to be thrown")
        } catch let error as PersistenceError {
            if case .decodingError = error {
                // pass
            } else {
                Issue.record("Expected .decodingError but got \(error)")
            }
        }
    }

    @Test("Snapshot state with pending colourChoice survives save/load")
    func testSnapshotWithPendingDecisionSurvivesDisk() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        var state = minimalState()
        state.pendingDecision = .colourChoice(playerID: state.players[0].id)
        let snapshot = GameSnapshot(state: state)
        try service.saveGame(snapshot)
        let loaded = try service.loadGame()
        #expect(loaded.state.pendingDecision == state.pendingDecision)
    }
}

// MARK: - DataResetService

@Suite("DataResetService")
struct DataResetServiceTests {

    @Test("resetAll deletes all three canonical files")
    func testResetAllDeletesFiles() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let reset = DataResetService(service: service)

        // Write all three files
        try service.saveGame(GameSnapshot(state: minimalState()))
        try service.saveSettings(UserSettings())
        try service.saveStats(GameStats.empty)

        #expect(FileManager.default.fileExists(atPath: service.gameFileURL.path))
        #expect(FileManager.default.fileExists(atPath: service.settingsFileURL.path))
        #expect(FileManager.default.fileExists(atPath: service.statsFileURL.path))

        reset.resetAll()

        #expect(!FileManager.default.fileExists(atPath: service.gameFileURL.path))
        #expect(!FileManager.default.fileExists(atPath: service.settingsFileURL.path))
        #expect(!FileManager.default.fileExists(atPath: service.statsFileURL.path))
    }

    @Test("resetGame deletes only the game file, leaves settings and stats")
    func testResetGameOnly() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let reset = DataResetService(service: service)

        try service.saveGame(GameSnapshot(state: minimalState()))
        try service.saveSettings(UserSettings())
        try service.saveStats(GameStats.empty)

        reset.resetGame()

        #expect(!FileManager.default.fileExists(atPath: service.gameFileURL.path))
        #expect(FileManager.default.fileExists(atPath: service.settingsFileURL.path))
        #expect(FileManager.default.fileExists(atPath: service.statsFileURL.path))
    }

    @Test("resetStats deletes only the stats file")
    func testResetStatsOnly() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let reset = DataResetService(service: service)

        try service.saveGame(GameSnapshot(state: minimalState()))
        try service.saveStats(GameStats.empty)

        reset.resetStats()

        #expect(FileManager.default.fileExists(atPath: service.gameFileURL.path))
        #expect(!FileManager.default.fileExists(atPath: service.statsFileURL.path))
    }

    @Test("resetAll is safe to call when no files exist")
    func testResetAllIdempotent() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let reset = DataResetService(service: service)
        // No crash when files don't exist
        reset.resetAll()
        // Still no files
        #expect(!service.hasSavedGame())
    }

    @Test("After resetAll, loadSettings returns default UserSettings")
    func testSettingsDefaultAfterReset() throws {
        let dir = try makeTempDir()
        let service = PersistenceService(directory: dir)
        let reset = DataResetService(service: service)

        let custom = UserSettings(animationSpeed: .off, largeCards: true)
        try service.saveSettings(custom)
        reset.resetAll()

        let loaded = try service.loadSettings()
        #expect(loaded == UserSettings())
    }
}
