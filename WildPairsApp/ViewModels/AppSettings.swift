import SwiftUI
import WildPairsCore

// Observable store for user preferences and local statistics. Persists through the Core
// PersistenceService. Injected into views via explicit initialisers (no @EnvironmentObject
// for game state per project rules; settings is app-wide chrome so it is acceptable here).

@MainActor
final class AppSettings: ObservableObject {

    @Published var userSettings: UserSettings {
        didSet { try? persistence.saveSettings(userSettings) }
    }
    @Published private(set) var stats: GameStats

    private let persistence: PersistenceService

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
        self.userSettings = (try? persistence.loadSettings()) ?? UserSettings()
        self.stats = (try? persistence.loadStats()) ?? .empty
    }

    func recordRoundResult(localTeamWon: Bool, difficulty: Difficulty, turns: Int) {
        var s = stats
        s.totalGamesPlayed += 1
        if localTeamWon {
            s.totalWins += 1
            s.currentWinStreak += 1
            s.bestWinStreak = max(s.bestWinStreak, s.currentWinStreak)
        } else {
            s.currentWinStreak = 0
        }
        // Rolling average of turns per round.
        let n = Double(s.totalGamesPlayed)
        s.averageTurnsPerRound = ((s.averageTurnsPerRound * (n - 1)) + Double(turns)) / n

        var byDiff = s.byDifficulty[difficulty.rawValue] ?? DifficultyStats()
        byDiff.gamesPlayed += 1
        if localTeamWon { byDiff.wins += 1 }
        s.byDifficulty[difficulty.rawValue] = byDiff

        stats = s
        try? persistence.saveStats(s)
    }

    func resetStats() {
        DataResetService(service: persistence).resetStats()
        stats = .empty
    }

    func resetAll() {
        DataResetService(service: persistence).resetAll()
        userSettings = UserSettings()
        stats = .empty
    }

    var hasSavedGame: Bool { persistence.hasSavedGame() }
}
