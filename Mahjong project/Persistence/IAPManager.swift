import Foundation
import Observation
import StoreKit

/// StoreKit 2 wrapper: loads products, processes purchases, listens for
/// transactions, and keeps `ThemeStore.unlockedIDs` in sync with current
/// entitlements.
@MainActor
@Observable
final class IAPManager {
    static let shared = IAPManager()

    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    enum PurchaseOutcome {
        case success
        case userCancelled
        case pending
        case failed(String)
    }

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var loadState: LoadState = .idle

    /// Functional (non-cosmetic) IAPs. These don't unlock themes — they
    /// change game behavior (e.g. removes ads, raises caps).
    static let removeAdsProductID = "com.anulfito.mahjong.removeads"

    /// All product IDs the app sells (themes + functional unlocks).
    static let allProductIDs: Set<String> = {
        var ids = Set(Theme.all.compactMap(\.productID))
        ids.insert(removeAdsProductID)
        return ids
    }()

    /// True when the player has purchased Remove Ads. Drives ad gating and
    /// raises the per-game hint cap.
    var isAdsRemoved: Bool {
        purchasedProductIDs.contains(Self.removeAdsProductID)
    }

    var removeAdsProduct: Product? {
        products.first { $0.id == Self.removeAdsProductID }
    }

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await refresh() }
    }
    // No deinit: IAPManager is a singleton that lives for the app's lifetime.

    // MARK: - Loading

    func refresh() async {
        loadState = .loading
        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            // Sort to match Theme.all ordering for consistent UI.
            self.products = loaded.sorted { lhs, rhs in
                let order = Theme.all.compactMap(\.productID)
                let li = order.firstIndex(of: lhs.id) ?? Int.max
                let ri = order.firstIndex(of: rhs.id) ?? Int.max
                return li < ri
            }
            await refreshEntitlements()
            loadState = .ready
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let txn) = result {
                owned.insert(txn.productID)
            }
        }
        purchasedProductIDs = owned
        let unlockedThemeIDs: Set<String> = Set(
            Theme.all.compactMap { theme in
                guard let pid = theme.productID, owned.contains(pid) else { return nil }
                return theme.id
            }
        )
        ThemeStore.shared.setUnlocked(unlockedThemeIDs)
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let txn) = verification else {
                    return .failed("Receipt failed verification")
                }
                purchasedProductIDs.insert(txn.productID)
                if let theme = Theme.all.first(where: { $0.productID == txn.productID }) {
                    ThemeStore.shared.unlock(theme.id)
                }
                await txn.finish()
                return .success
            case .userCancelled: return .userCancelled
            case .pending:       return .pending
            @unknown default:    return .failed("Unknown purchase state")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Lookups

    func product(forThemeID themeID: String) -> Product? {
        guard let pid = Theme.all.first(where: { $0.id == themeID })?.productID else { return nil }
        return products.first { $0.id == pid }
    }

    func displayPrice(forThemeID themeID: String) -> String? {
        product(forThemeID: themeID)?.displayPrice
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let txn) = result {
                    await txn.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
