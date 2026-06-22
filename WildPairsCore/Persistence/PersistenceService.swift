import Foundation

// MARK: - PersistenceService

/// Reads and writes game data to the Documents directory.
/// All operations are synchronous and occur on the calling thread.
/// The ViewModel is responsible for dispatching saves off the main thread if needed.
public struct PersistenceService {

    // MARK: File URLs

    private let gameURL: URL
    private let settingsURL: URL
    private let statsURL: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: Init

    public init(directory: URL? = nil) {
        let dir = directory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        gameURL     = dir.appendingPathComponent("wildpairs-game.json")
        settingsURL = dir.appendingPathComponent("wildpairs-settings.json")
        statsURL    = dir.appendingPathComponent("wildpairs-stats.json")

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: Game

    public func saveGame(_ snapshot: GameSnapshot) throws {
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: gameURL, options: .atomic)
        } catch let error as EncodingError {
            throw PersistenceError.encodingError(error.localizedDescription)
        } catch {
            throw PersistenceError.writeError(error.localizedDescription)
        }
    }

    public func loadGame() throws -> GameSnapshot {
        guard FileManager.default.fileExists(atPath: gameURL.path) else {
            throw PersistenceError.noSavedGame
        }
        do {
            let data = try Data(contentsOf: gameURL)
            return try decoder.decode(GameSnapshot.self, from: data)
        } catch {
            throw PersistenceError.decodingError(error.localizedDescription)
        }
    }

    public func hasSavedGame() -> Bool {
        FileManager.default.fileExists(atPath: gameURL.path)
    }

    // MARK: Settings

    public func saveSettings(_ settings: UserSettings) throws {
        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        } catch let error as EncodingError {
            throw PersistenceError.encodingError(error.localizedDescription)
        } catch {
            throw PersistenceError.writeError(error.localizedDescription)
        }
    }

    public func loadSettings() throws -> UserSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return UserSettings()  // Factory default — no file means first launch
        }
        do {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(UserSettings.self, from: data)
        } catch {
            throw PersistenceError.decodingError(error.localizedDescription)
        }
    }

    // MARK: Stats

    public func saveStats(_ stats: GameStats) throws {
        do {
            let data = try encoder.encode(stats)
            try data.write(to: statsURL, options: .atomic)
        } catch let error as EncodingError {
            throw PersistenceError.encodingError(error.localizedDescription)
        } catch {
            throw PersistenceError.writeError(error.localizedDescription)
        }
    }

    public func loadStats() throws -> GameStats {
        guard FileManager.default.fileExists(atPath: statsURL.path) else {
            return GameStats.empty
        }
        do {
            let data = try Data(contentsOf: statsURL)
            return try decoder.decode(GameStats.self, from: data)
        } catch {
            throw PersistenceError.decodingError(error.localizedDescription)
        }
    }

    // MARK: URLs for testing/reset

    public var gameFileURL: URL { gameURL }
    public var settingsFileURL: URL { settingsURL }
    public var statsFileURL: URL { statsURL }
}
