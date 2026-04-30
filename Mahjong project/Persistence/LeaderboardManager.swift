import Foundation
import GameKit
import Observation

/// Game Center wrapper. Authenticates the local player on launch, exposes a
/// reactive `isAuthenticated` flag, and submits best-time scores per layout
/// when the player wins. Operates as a singleton because Game Center state is
/// process-wide.
///
/// **Setup required outside this file:**
/// 1. In Xcode → Signing & Capabilities, add the **Game Center** capability
///    (creates `Mahjong project.entitlements` with `com.apple.developer.game-center`).
/// 2. In App Store Connect → My Apps → Mahjong Zen Garden → Services → Game Center,
///    enable Game Center.
/// 3. Add three leaderboards under Game Center → Leaderboards with these IDs:
///       \(BoardLayout.neonPyramid.id) → "Neon Pyramid · Best Time"
///       \(BoardLayout.sparkstone.id)  → "Sparkstone · Best Time"
///       \(BoardLayout.cathedral.id)   → "Cathedral · Best Time"
///    Sort: Low to High. Score format: Elapsed time (seconds, integer).
@MainActor
@Observable
final class LeaderboardManager {
    static let shared = LeaderboardManager()

    enum AuthState: Equatable {
        case unknown
        case authenticating
        case authenticated
        case failed(String)
        case unavailable     // user declined or device blocks Game Center
    }

    private(set) var authState: AuthState = .unknown
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true } else { return false }
    }

    private init() {}

    /// Leaderboard ID convention: namespaced under the bundle, suffixed with
    /// the layout's id. Configured to match the strings in App Store Connect.
    static func leaderboardID(forLayoutID layoutID: String) -> String {
        "com.anulfito.mahjong.leaderboard.bestTime.\(layoutID)"
    }

    static var allLeaderboardIDs: [String] {
        BoardLayout.all.map { leaderboardID(forLayoutID: $0.id) }
    }

    // MARK: - Authentication

    func authenticate() {
        guard authState != .authenticating, !isAuthenticated else { return }
        authState = .authenticating

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    Self.presentOnTopMost(viewController)
                    return
                }
                if let error {
                    let nsError = error as NSError
                    // Common case: user signed out / cancelled. Treat as graceful.
                    if nsError.code == GKError.cancelled.rawValue
                        || nsError.code == GKError.notAuthenticated.rawValue {
                        self.authState = .unavailable
                    } else {
                        self.authState = .failed(error.localizedDescription)
                    }
                    return
                }
                if GKLocalPlayer.local.isAuthenticated {
                    self.authState = .authenticated
                } else {
                    self.authState = .unavailable
                }
            }
        }
    }

    /// Walks scenes to find the front-most view controller, then presents the
    /// Game Center sign-in sheet on it.
    private static func presentOnTopMost(_ vc: UIViewController) {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        guard let window = scenes.first(where: { $0.activationState == .foregroundActive })?
                .windows.first(where: \.isKeyWindow) ?? scenes.first?.windows.first,
              var top = window.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        top.present(vc, animated: true)
    }

    // MARK: - Score submission

    /// Submits a best-time score (seconds, integer) for the given layout. No-op
    /// when the player isn't authenticated. Throws are swallowed since this is
    /// fire-and-forget from the win path.
    func submitBestTime(seconds: Int, layoutID: String) {
        guard isAuthenticated else { return }
        let leaderboardID = Self.leaderboardID(forLayoutID: layoutID)
        Task.detached {
            do {
                try await GKLeaderboard.submitScore(
                    seconds,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
            } catch {
                // Logging only — leaderboard submission shouldn't block gameplay.
                print("[LeaderboardManager] submit failed for \(leaderboardID): \(error)")
            }
        }
    }
}
