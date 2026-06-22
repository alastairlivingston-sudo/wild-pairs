import Foundation

// MARK: - DataResetService

/// Deletes exactly the three canonical Wild Pairs data files. Nothing else.
public struct DataResetService {

    private let service: PersistenceService

    public init(service: PersistenceService) {
        self.service = service
    }

    /// Removes the saved game file. No-op if it doesn't exist.
    public func resetGame() {
        try? FileManager.default.removeItem(at: service.gameFileURL)
    }

    /// Removes the statistics file. No-op if it doesn't exist.
    public func resetStats() {
        try? FileManager.default.removeItem(at: service.statsFileURL)
    }

    /// Removes all three canonical data files. No-op for each that doesn't exist.
    public func resetAll() {
        resetGame()
        resetStats()
        try? FileManager.default.removeItem(at: service.settingsFileURL)
    }
}
