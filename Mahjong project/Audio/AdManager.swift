import Foundation
import Observation
import UIKit

/// Owns the rewarded-ad lifecycle. Today this is a STUB that auto-grants the
/// reward after a short simulated delay so the app's UX flows are real and
/// testable. When you wire in the real AdMob SDK, only this file changes.
///
/// **To go live with real ads:**
///
/// 1. In Xcode, File → Add Package Dependencies… and add
///    `https://github.com/googleads/swift-package-manager-google-mobile-ads`
///    targeting `Up to Next Major: 12.0.0` (or current).
/// 2. Add to Info.plist (via INFOPLIST_KEY_GADApplicationIdentifier build
///    setting): your AdMob app ID, e.g. `ca-app-pub-XXXX~YYYY`.
/// 3. Add `NSUserTrackingUsageDescription` for ATT, plus the SKAdNetwork
///    identifiers AdMob requires (see Google's docs).
/// 4. Add a `PrivacyInfo.xcprivacy` manifest declaring tracking domains.
/// 5. Replace `await runStub(...)` below with `await loadAndPresentRewardedAd(...)`
///    using `RewardedAd.load(with:request:)` and `present(from:userDidEarnReward:)`.
@MainActor
@Observable
final class AdManager {
    static let shared = AdManager()

    enum RewardKind: String {
        case extraHint
        case shuffle
        case streakSave
    }

    private(set) var isPresenting: Bool = false

    private init() {}

    /// Test ad unit IDs from Google. Safe to use in development; replace with
    /// your real unit IDs from AdMob console before App Store release.
    enum AdUnits {
        /// Test rewarded — always fills with a sample ad.
        static let rewardedTest = "ca-app-pub-3940256099942544/1712485313"
        /// Test interstitial.
        static let interstitialTest = "ca-app-pub-3940256099942544/4411468910"
    }

    /// Shows a rewarded ad and returns true if the user earned the reward
    /// (watched to completion). When ads are removed via IAP, this short-
    /// circuits to a free reward — premium players never see ads.
    func showRewarded(_ kind: RewardKind) async -> Bool {
        if IAPManager.shared.isAdsRemoved {
            return true
        }
        return await runStub(kind: kind)
    }

    /// STUB: simulates an ad load + view, granting the reward after a short
    /// delay. Replace with real GoogleMobileAds calls once the SDK is wired up.
    private func runStub(kind: RewardKind) async -> Bool {
        isPresenting = true
        defer { isPresenting = false }
        try? await Task.sleep(nanoseconds: 800_000_000)
        // Always succeeds in stub mode so dev/test flows are uninterrupted.
        return true
    }
}
