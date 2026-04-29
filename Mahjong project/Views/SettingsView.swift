import SwiftUI
import StoreKit

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    var onClose: () -> Void

    @State private var confirmReset: Bool = false
    @State private var iconExportPath: String?
    @State private var showingThemes: Bool = false
    @State private var purchasingRemoveAds: Bool = false
    @State private var purchaseError: String?
    @Bindable private var themeStore = ThemeStore.shared
    @Bindable private var iap = IAPManager.shared

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        section(title: "UPGRADES") {
                            removeAdsRow
                            divider
                            Button {
                                SoundManager.shared.haptic(.button)
                                Task { await iap.restore() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .foregroundStyle(NeonPalette.cyan)
                                        .frame(width: 24)
                                    Text("Restore Purchases")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(NeonPalette.white)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }

                        if let msg = purchaseError {
                            Text(msg)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(NeonPalette.red)
                                .padding(.horizontal, 6)
                        }

                        section(title: "APPEARANCE") {
                            Button {
                                SoundManager.shared.haptic(.button)
                                showingThemes = true
                            } label: {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundStyle(NeonPalette.purple)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Themes")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(NeonPalette.white)
                                        Text(themeStore.activeTheme.name)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundStyle(NeonPalette.textDim)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(NeonPalette.textDim)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }

                        section(title: "AUDIO & FEEL") {
                            toggleRow(label: "Sound Effects",
                                      system: "speaker.wave.2.fill",
                                      color: NeonPalette.cyan,
                                      isOn: $settings.soundEnabled)
                            divider
                            toggleRow(label: "Haptics",
                                      system: "iphone.radiowaves.left.and.right",
                                      color: NeonPalette.pink,
                                      isOn: $settings.hapticsEnabled)
                        }

                        section(title: "DATA") {
                            Button {
                                SoundManager.shared.haptic(.button)
                                confirmReset = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundStyle(NeonPalette.red)
                                    Text("Reset Stats")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(NeonPalette.white)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }

                        section(title: "DEVELOPER") {
                            Button {
                                SoundManager.shared.haptic(.button)
                                iconExportPath = AppIconExporter.exportIcon()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .foregroundStyle(NeonPalette.cyan)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Export App Icon (1024)")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(NeonPalette.white)
                                        if let path = iconExportPath {
                                            Text(path)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundStyle(NeonPalette.green)
                                                .lineLimit(2)
                                                .truncationMode(.middle)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }

                        section(title: "ABOUT") {
                            HStack {
                                Text("Neon Mahjong")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(NeonPalette.white)
                                Spacer()
                                Text("v1.0")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(NeonPalette.textDim)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
        }
        .alert("Reset all stats?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { GameStats.shared.reset() }
        } message: {
            Text("Best times, scores, and daily streak will be cleared.")
        }
        .sheet(isPresented: $showingThemes) {
            ThemesView(onClose: { showingThemes = false })
        }
        .onAppear {
            if ScreenshotMode.requestedScene == .themes {
                showingThemes = true
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
            Text("SETTINGS")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(NeonPalette.cyan)
                .neonGlow(NeonPalette.cyan, radius: 6)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func section<Content: View>(title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(NeonPalette.textDim)
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(NeonPalette.bg0.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(NeonPalette.tileEdge, lineWidth: 1)
                        )
                )
        }
    }

    private func toggleRow(label: String, system: String, color: Color, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(NeonPalette.white)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.vertical, 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(NeonPalette.tileEdge)
            .frame(height: 0.5)
    }

    @ViewBuilder
    private var removeAdsRow: some View {
        let owned = iap.isAdsRemoved
        HStack {
            Image(systemName: owned ? "checkmark.seal.fill" : "sparkles")
                .foregroundStyle(owned ? NeonPalette.green : NeonPalette.yellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("Remove Ads")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(NeonPalette.white)
                Text(owned
                     ? "Owned · Unlimited hints unlocked"
                     : "Unlimited hints, no ads forever")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(NeonPalette.textDim)
            }
            Spacer()
            if owned {
                Text("OWNED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(NeonPalette.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().stroke(NeonPalette.green.opacity(0.7), lineWidth: 1))
            } else {
                Button {
                    SoundManager.shared.haptic(.button)
                    Task { await purchaseRemoveAds() }
                } label: {
                    HStack(spacing: 6) {
                        if purchasingRemoveAds {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(NeonPalette.bg0)
                                .scaleEffect(0.7)
                        }
                        Text(removeAdsPriceLabel)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(NeonPalette.bg0)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [NeonPalette.yellow, NeonPalette.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(purchasingRemoveAds || iap.removeAdsProduct == nil)
            }
        }
        .padding(.vertical, 10)
    }

    private var removeAdsPriceLabel: String {
        iap.removeAdsProduct?.displayPrice ?? "$3.99"
    }

    @MainActor
    private func purchaseRemoveAds() async {
        guard let product = iap.removeAdsProduct else {
            purchaseError = "Product not available. Try Restore Purchases."
            return
        }
        purchasingRemoveAds = true
        purchaseError = nil
        let outcome = await iap.purchase(product)
        purchasingRemoveAds = false
        switch outcome {
        case .success:        break
        case .userCancelled:  break
        case .pending:        purchaseError = "Purchase pending approval."
        case .failed(let m):  purchaseError = m
        }
    }
}
