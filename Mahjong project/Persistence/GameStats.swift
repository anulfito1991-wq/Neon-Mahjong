import Foundation
import Observation

/// Persistent records of player accomplishments. Stored as a single JSON blob
/// in UserDefaults — small enough that a key/value store is fine.
struct StatsSnapshot: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalSeconds: Int = 0
    var bestTimeByLayout: [String: Int] = [:]   // layout id → seconds
    var bestScoreByLayout: [String: Int] = [:]  // layout id → score
    var dailyCompleted: Set<String> = []        // yyyy-MM-dd strings
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastDailyDate: String?

    var winRate: Double {
        gamesPlayed == 0 ? 0 : Double(gamesWon) / Double(gamesPlayed)
    }
}

@MainActor
@Observable
final class GameStats {
    static let shared = GameStats()

    private(set) var snapshot: StatsSnapshot
    private let key = "stats.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: "stats.v1"),
           let decoded = try? JSONDecoder().decode(StatsSnapshot.self, from: data) {
            self.snapshot = decoded
        } else {
            self.snapshot = StatsSnapshot()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func recordGameStart() {
        snapshot.gamesPlayed += 1
        save()
    }

    func recordWin(layoutID: String, seconds: Int, score: Int, isDaily: Bool, dailyDate: String?) {
        snapshot.gamesWon += 1
        snapshot.totalSeconds += seconds
        if let prev = snapshot.bestTimeByLayout[layoutID] {
            snapshot.bestTimeByLayout[layoutID] = min(prev, seconds)
        } else {
            snapshot.bestTimeByLayout[layoutID] = seconds
        }
        if let prev = snapshot.bestScoreByLayout[layoutID] {
            snapshot.bestScoreByLayout[layoutID] = max(prev, score)
        } else {
            snapshot.bestScoreByLayout[layoutID] = score
        }
        if isDaily, let date = dailyDate {
            snapshot.dailyCompleted.insert(date)
            updateStreak(today: date)
            snapshot.lastDailyDate = date
        }
        save()
    }

    private func updateStreak(today: String) {
        guard let last = snapshot.lastDailyDate else {
            snapshot.currentStreak = 1
            snapshot.longestStreak = max(snapshot.longestStreak, 1)
            return
        }
        if last == today { return }  // already counted
        if isYesterday(last, relativeTo: today) {
            snapshot.currentStreak += 1
        } else {
            snapshot.currentStreak = 1
        }
        snapshot.longestStreak = max(snapshot.longestStreak, snapshot.currentStreak)
    }

    private func isYesterday(_ a: String, relativeTo b: String) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        guard let dateA = f.date(from: a), let dateB = f.date(from: b) else { return false }
        let diff = Calendar.current.dateComponents([.day], from: dateA, to: dateB).day ?? 0
        return diff == 1
    }

    func reset() {
        snapshot = StatsSnapshot()
        save()
    }

    /// Replaces the entire snapshot — used by the screenshot harness to inject
    /// attractive demo data, and by tests.
    func replaceSnapshot(_ snapshot: StatsSnapshot) {
        self.snapshot = snapshot
        save()
    }
}
