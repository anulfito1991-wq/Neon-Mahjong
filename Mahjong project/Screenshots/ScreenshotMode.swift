import Foundation
import SwiftUI

/// Marketing scenes the UI test harness can request via launch environment.
/// Each scene corresponds to one App Store screenshot.
enum ScreenshotScene: String, CaseIterable {
    case menu        // Title + main menu
    case game        // Mid-game with neon tiles glowing
    case layouts     // Layout picker with all three options
    case stats       // Stats screen pre-populated with attractive numbers
    case win         // End-game overlay celebrating a win
    case settings    // Settings screen — used as IAP review screenshot for Remove Ads
    case themes      // Settings → Themes sheet — used as IAP review screenshot for theme packs

    var fileName: String { "\(rawValue).png" }
}

/// Detects whether the app is running in screenshot capture mode and exposes
/// helpers to bootstrap a clean, attractive state for each scene.
@MainActor
enum ScreenshotMode {
    /// Set by UI tests via launch environment.
    static var requestedScene: ScreenshotScene? {
        guard let raw = ProcessInfo.processInfo.environment["SCREENSHOT_SCENE"] else { return nil }
        return ScreenshotScene(rawValue: raw)
    }

    static var isActive: Bool { requestedScene != nil }

    /// Primes GameStats with attractive demo data so cards on Stats / Layout
    /// pages aren't empty in the screenshots. Idempotent.
    static func primeStats() {
        var snap = StatsSnapshot()
        snap.gamesPlayed = 47
        snap.gamesWon = 31
        snap.totalSeconds = 31 * 240   // ~4 min average per win
        snap.bestTimeByLayout = [
            BoardLayout.neonPyramid.id: 218,
            BoardLayout.sparkstone.id:  92,
            BoardLayout.cathedral.id:   276
        ]
        snap.bestScoreByLayout = [
            BoardLayout.neonPyramid.id: 8420,
            BoardLayout.sparkstone.id:  6180,
            BoardLayout.cathedral.id:   8120
        ]
        snap.dailyCompleted = [
            "2026-04-21", "2026-04-22", "2026-04-23",
            "2026-04-24", "2026-04-25", "2026-04-26",
            "2026-04-27", "2026-04-28"
        ]
        snap.currentStreak = 8
        snap.longestStreak = 14
        snap.lastDailyDate = "2026-04-28"
        GameStats.shared.replaceSnapshot(snap)
    }
}
