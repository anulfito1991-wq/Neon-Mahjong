import Foundation
import Observation

/// User-toggleable preferences, persisted via UserDefaults. Singleton because
/// the SoundManager and other infra need to read live values without view binding.
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let sound  = "settings.sound"
        static let haptic = "settings.haptic"
        static let firstLaunch = "settings.firstLaunch"
    }

    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.sound) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptic) }
    }

    private init() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Keys.firstLaunch) {
            defaults.set(true, forKey: Keys.firstLaunch)
            defaults.set(true, forKey: Keys.sound)
            defaults.set(true, forKey: Keys.haptic)
        }
        self.soundEnabled = defaults.bool(forKey: Keys.sound)
        self.hapticsEnabled = defaults.bool(forKey: Keys.haptic)
    }
}
