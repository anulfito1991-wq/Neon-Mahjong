import SwiftUI
import StoreKit

struct ThemesView: View {
    @Bindable var themeStore = ThemeStore.shared
    @Bindable var iap = IAPManager.shared
    var onClose: () -> Void

    @State private var purchasingID: String?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(Theme.all) { theme in
                            ThemeCard(
                                theme: theme,
                                isActive: themeStore.activeTheme.id == theme.id,
                                isUnlocked: themeStore.isUnlocked(theme),
                                priceLabel: priceLabel(for: theme),
                                isPurchasing: purchasingID == theme.id,
                                onSelect: { themeStore.select(theme) },
                                onBuy: { Task { await buy(theme) } }
                            )
                        }

                        Button(action: { Task { await restore() } }) {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(NeonPalette.cyan)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)

                        if let msg = errorMessage {
                            Text(msg)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(NeonPalette.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { SoundManager.shared.haptic(.button); onClose() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NeonPalette.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(NeonPalette.bg0.opacity(0.7))
                            .overlay(Circle().stroke(NeonPalette.tileEdge, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            Spacer()
            Text("THEMES")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(NeonPalette.purple)
                .neonGlow(NeonPalette.purple, radius: 6)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func priceLabel(for theme: Theme) -> String {
        if !theme.isPremium { return "FREE" }
        if let price = iap.displayPrice(forThemeID: theme.id) { return price }
        return "—"
    }

    @MainActor
    private func buy(_ theme: Theme) async {
        guard let product = iap.product(forThemeID: theme.id) else {
            errorMessage = "Product not available. Pull to refresh."
            return
        }
        purchasingID = theme.id
        errorMessage = nil
        let outcome = await iap.purchase(product)
        purchasingID = nil
        switch outcome {
        case .success:
            themeStore.select(theme)
        case .userCancelled:
            break
        case .pending:
            errorMessage = "Purchase pending approval."
        case .failed(let msg):
            errorMessage = msg
        }
    }

    @MainActor
    private func restore() async {
        errorMessage = nil
        await iap.restore()
    }
}

private struct ThemeCard: View {
    let theme: Theme
    let isActive: Bool
    let isUnlocked: Bool
    let priceLabel: String
    let isPurchasing: Bool
    let onSelect: () -> Void
    let onBuy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ThemePalettePreview(palette: theme.palette)
                    .frame(width: 90, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.palette.white)
                    Text(theme.tagline)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.palette.textDim)
                }
                Spacer()
                actionButton
            }

            if isActive {
                Text("ACTIVE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(theme.palette.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().stroke(theme.palette.green.opacity(0.7), lineWidth: 1)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.palette.bg0.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor, lineWidth: isActive ? 1.8 : 1)
                )
        )
    }

    private var borderColor: Color {
        if isActive { return theme.palette.cyan }
        return NeonPalette.tileEdge
    }

    @ViewBuilder
    private var actionButton: some View {
        if isUnlocked {
            Button(action: { SoundManager.shared.haptic(.button); onSelect() }) {
                Text(isActive ? "Selected" : "Use")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isActive ? theme.palette.textDim : theme.palette.bg0)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isActive ? theme.palette.tileEdge : theme.palette.cyan)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isActive)
        } else {
            Button(action: { SoundManager.shared.haptic(.button); onBuy() }) {
                HStack(spacing: 6) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(theme.palette.bg0)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(priceLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(theme.palette.bg0)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.palette.pink, theme.palette.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing)
        }
    }
}

/// Color swatch row showing a theme's primary suit colors.
private struct ThemePalettePreview: View {
    let palette: Palette

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.bg0)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(palette.tileEdge, lineWidth: 1)
                )
            HStack(spacing: 4) {
                swatch(palette.green)
                swatch(palette.cyan)
                swatch(palette.pink)
                swatch(palette.purple)
                swatch(palette.yellow)
                swatch(palette.orange)
            }
            .padding(.horizontal, 8)
        }
    }

    private func swatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(0.85), radius: 4)
    }
}
