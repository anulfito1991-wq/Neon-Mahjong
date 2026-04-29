import Foundation
import Observation
import SwiftUI

/// Owns the active theme and the set of unlocked themes. Backed by UserDefaults
/// so selection and unlocks persist across launches. IAPManager is the source
/// of truth for what's actually purchased — `unlockedIDs` mirrors the latest
/// entitlement read.
@MainActor
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private(set) var activeTheme: Theme
    private(set) var unlockedIDs: Set<String>

    var palette: Palette { activeTheme.palette }

    private enum Keys {
        static let active   = "theme.active"
        static let unlocked = "theme.unlocked"
    }

    private init() {
        let defaults = UserDefaults.standard
        let stored = defaults.string(forKey: Keys.active)
        self.activeTheme = Theme.all.first { $0.id == stored } ?? .classic

        if let arr = defaults.stringArray(forKey: Keys.unlocked) {
            self.unlockedIDs = Set(arr).union([Theme.classic.id])
        } else {
            self.unlockedIDs = [Theme.classic.id]
        }
    }

    func isUnlocked(_ theme: Theme) -> Bool { unlockedIDs.contains(theme.id) }

    func select(_ theme: Theme) {
        guard isUnlocked(theme) else { return }
        activeTheme = theme
        UserDefaults.standard.set(theme.id, forKey: Keys.active)
    }

    /// Sets the unlocked set from current entitlements. Always includes classic.
    func setUnlocked(_ ids: Set<String>) {
        unlockedIDs = ids.union([Theme.classic.id])
        UserDefaults.standard.set(Array(unlockedIDs), forKey: Keys.unlocked)
        // If active theme is no longer unlocked (e.g. refund), fall back to classic.
        if !unlockedIDs.contains(activeTheme.id) {
            select(.classic)
        }
    }

    func unlock(_ themeID: String) {
        var next = unlockedIDs
        next.insert(themeID)
        setUnlocked(next)
    }
}
