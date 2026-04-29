import Foundation

/// Generates a deterministic seed from today's date so every player gets the
/// same daily puzzle.
enum DailyChallenge {
    static var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: Date())
    }

    /// Seed derived from yyyyMMdd as a single integer; stable per device per day.
    static var todaySeed: UInt64 {
        let parts = todayString.split(separator: "-").compactMap { UInt64($0) }
        guard parts.count == 3 else { return 0xCAFEF00D }
        return parts[0] * 10_000 + parts[1] * 100 + parts[2]
    }

    static func isCompletedToday() -> Bool {
        GameStats.shared.snapshot.dailyCompleted.contains(todayString)
    }
}
