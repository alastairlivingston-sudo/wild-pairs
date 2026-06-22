import Foundation

// MARK: - DifficultyStats

public struct DifficultyStats: Codable, Equatable, Sendable {
    public var gamesPlayed: Int
    public var wins: Int

    public var winRate: Double {
        gamesPlayed == 0 ? 0 : Double(wins) / Double(gamesPlayed)
    }

    public init(gamesPlayed: Int = 0, wins: Int = 0) {
        self.gamesPlayed = gamesPlayed
        self.wins = wins
    }
}

// MARK: - GameStats

public struct GameStats: Codable, Equatable, Sendable {

    public var totalGamesPlayed: Int
    public var totalWins: Int
    public var currentWinStreak: Int
    public var bestWinStreak: Int
    public var averageTurnsPerRound: Double

    // Per-difficulty breakdown (keyed by AIdifficulty raw value)
    public var byDifficulty: [String: DifficultyStats]

    public init(
        totalGamesPlayed: Int = 0,
        totalWins: Int = 0,
        currentWinStreak: Int = 0,
        bestWinStreak: Int = 0,
        averageTurnsPerRound: Double = 0,
        byDifficulty: [String: DifficultyStats] = [:]
    ) {
        self.totalGamesPlayed = totalGamesPlayed
        self.totalWins = totalWins
        self.currentWinStreak = currentWinStreak
        self.bestWinStreak = bestWinStreak
        self.averageTurnsPerRound = averageTurnsPerRound
        self.byDifficulty = byDifficulty
    }

    public static let empty = GameStats()
}
