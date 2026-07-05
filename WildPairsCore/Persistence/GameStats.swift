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

// MARK: - WinRecord

/// One record-setting round win: the raw card points taken, the difficulty multiplier in
/// force, and when it happened.
public struct WinRecord: Codable, Equatable, Sendable {
    public var points: Int
    public var multiplier: Int
    public var date: Date

    public var total: Int { points * multiplier }

    public init(points: Int, multiplier: Int, date: Date = Date()) {
        self.points = points
        self.multiplier = multiplier
        self.date = date
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

    // Biggest-win records (Phase 14). Optional so pre-Phase-14 stats files still decode.
    public var biggestRawWin: WinRecord?
    public var biggestMultipliedWin: WinRecord?

    public init(
        totalGamesPlayed: Int = 0,
        totalWins: Int = 0,
        currentWinStreak: Int = 0,
        bestWinStreak: Int = 0,
        averageTurnsPerRound: Double = 0,
        byDifficulty: [String: DifficultyStats] = [:],
        biggestRawWin: WinRecord? = nil,
        biggestMultipliedWin: WinRecord? = nil
    ) {
        self.totalGamesPlayed = totalGamesPlayed
        self.totalWins = totalWins
        self.currentWinStreak = currentWinStreak
        self.bestWinStreak = bestWinStreak
        self.averageTurnsPerRound = averageTurnsPerRound
        self.byDifficulty = byDifficulty
        self.biggestRawWin = biggestRawWin
        self.biggestMultipliedWin = biggestMultipliedWin
    }

    /// Folds a won round into the records: the raw record is the most card points taken in
    /// one round, the multiplied record the highest points × multiplier product — one big
    /// low-difficulty round can hold the raw record while a harder, smaller round holds the
    /// multiplied one.
    public mutating func recordWin(points: Int, multiplier: Int, date: Date = Date()) {
        guard points > 0 else { return }
        let record = WinRecord(points: points, multiplier: multiplier, date: date)
        if record.points > (biggestRawWin?.points ?? 0) { biggestRawWin = record }
        if record.total > (biggestMultipliedWin?.total ?? 0) { biggestMultipliedWin = record }
    }

    public static let empty = GameStats()
}
