import Foundation
import Observation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency

/// Owns the rewarded + interstitial ad lifecycle. Initialization order:
///
///   1. App launch → `AdManager.shared.bootstrap()` requests ATT consent and,
///      regardless of the response, starts the Google Mobile Ads SDK.
///   2. After SDK starts, `preloadRewarded()` and `preloadInterstitial()` warm
///      the ad cache so the next show is instant.
///   3. Game flow:
///        - Out of free hints → `showRewarded(.extraHint)` → returns true if
///          the user watched to completion.
///        - Game over (win or stuck) → `showInterstitialIfDue(from:)` shows
///          an interstitial every 3rd game finish (skipped entirely when
///          Remove Ads is owned).
@MainActor
@Observable
final class AdManager: NSObject {
    static let shared = AdManager()

    enum RewardKind: String {
        case extraHint
    }

    // MARK: - Ad unit IDs

    /// Live AdMob production unit IDs for Neon Mahjong.
    private enum AdUnits {
        static let rewarded     = "ca-app-pub-9508131695489221/7689208351"
        static let interstitial = "ca-app-pub-9508131695489221/1534863545"
    }

    // MARK: - Observed state

    private(set) var isPresenting: Bool = false
    private(set) var didBootstrap: Bool = false

    // MARK: - Private state

    private var rewardedAd: RewardedAd?
    private var interstitialAd: InterstitialAd?

    private var rewardContinuation: CheckedContinuation<Bool, Never>?
    private var rewardEarned: Bool = false

    private var interstitialContinuation: CheckedContinuation<Void, Never>?

    private let interstitialCounterKey = "ads.interstitialCounter"
    private var interstitialCounter: Int {
        get { UserDefaults.standard.integer(forKey: interstitialCounterKey) }
        set { UserDefaults.standard.set(newValue, forKey: interstitialCounterKey) }
    }

    /// Show an interstitial after this many game-finishes. Tuned to be visible
    /// without being annoying — most casual puzzles use 3-5.
    private let interstitialEveryNGames = 3

    // MARK: - Bootstrap

    /// Call once at app launch. Requests ATT consent (whichever response is
    /// fine — ads still serve), starts the Mobile Ads SDK, then preloads.
    /// Safe to call multiple times.
    func bootstrap() async {
        guard !didBootstrap else { return }
        if ScreenshotMode.isActive {
            didBootstrap = true
            return
        }
        await requestTrackingConsent()
        let _ = await MobileAds.shared.start()
        didBootstrap = true
        await preloadRewarded()
        await preloadInterstitial()
    }

    private func requestTrackingConsent() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }

    // MARK: - Rewarded

    /// Loads (if needed) and presents a rewarded ad. Returns true when the
    /// user watched to completion AND earned the reward, false on dismissal,
    /// load failure, or when there's no top-most view controller.
    /// Short-circuits to `true` when Remove Ads is owned.
    func showRewarded(_ kind: RewardKind) async -> Bool {
        if IAPManager.shared.isAdsRemoved { return true }
        if ScreenshotMode.isActive { return true }

        if rewardedAd == nil {
            await preloadRewarded()
        }
        guard let ad = rewardedAd, let rootVC = Self.topMostViewController() else {
            return false
        }
        rewardedAd = nil
        return await present(rewarded: ad, from: rootVC)
    }

    private func present(rewarded ad: RewardedAd,
                         from rootVC: UIViewController) async -> Bool {
        rewardEarned = false
        ad.fullScreenContentDelegate = self
        isPresenting = true
        return await withCheckedContinuation { continuation in
            rewardContinuation = continuation
            ad.present(from: rootVC) { [weak self] in
                self?.rewardEarned = true
            }
        }
    }

    private func preloadRewarded() async {
        do {
            let ad = try await RewardedAd.load(
                with: AdUnits.rewarded,
                request: Request()
            )
            rewardedAd = ad
        } catch {
            print("[AdManager] rewarded load failed: \(error)")
        }
    }

    // MARK: - Interstitial

    /// Increments the game-finish counter and shows an interstitial once per
    /// `interstitialEveryNGames` finishes. No-op when Remove Ads is owned.
    func showInterstitialIfDue() async {
        if IAPManager.shared.isAdsRemoved { return }
        if ScreenshotMode.isActive { return }

        interstitialCounter += 1
        guard interstitialCounter % interstitialEveryNGames == 0 else { return }
        if interstitialAd == nil {
            await preloadInterstitial()
        }
        guard let ad = interstitialAd, let rootVC = Self.topMostViewController() else {
            return
        }
        interstitialAd = nil
        await present(interstitial: ad, from: rootVC)
    }

    private func present(interstitial ad: InterstitialAd,
                         from rootVC: UIViewController) async {
        ad.fullScreenContentDelegate = self
        isPresenting = true
        await withCheckedContinuation { continuation in
            interstitialContinuation = continuation
            ad.present(from: rootVC)
        }
    }

    private func preloadInterstitial() async {
        do {
            let ad = try await InterstitialAd.load(
                with: AdUnits.interstitial,
                request: Request()
            )
            interstitialAd = ad
        } catch {
            print("[AdManager] interstitial load failed: \(error)")
        }
    }

    // MARK: - View-controller lookup

    private static func topMostViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        guard let window = scenes.first(where: { $0.activationState == .foregroundActive })?
                .windows.first(where: \.isKeyWindow) ?? scenes.first?.windows.first,
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: @preconcurrency FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        isPresenting = false
        if let cont = rewardContinuation {
            rewardContinuation = nil
            let earned = rewardEarned
            rewardEarned = false
            cont.resume(returning: earned)
            Task { await preloadRewarded() }
        }
        if let cont = interstitialContinuation {
            interstitialContinuation = nil
            cont.resume()
            Task { await preloadInterstitial() }
        }
    }

    func ad(_ ad: any FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: any Error) {
        isPresenting = false
        print("[AdManager] failed to present: \(error)")
        if let cont = rewardContinuation {
            rewardContinuation = nil
            rewardEarned = false
            cont.resume(returning: false)
            Task { await preloadRewarded() }
        }
        if let cont = interstitialContinuation {
            interstitialContinuation = nil
            cont.resume()
            Task { await preloadInterstitial() }
        }
    }
}
