import SwiftUI

/// Top stats bar.
struct HUDView: View {
    @Bindable var vm: GameViewModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                statChip("TIME",  value: vm.formattedTime,                    color: NeonPalette.cyan)
                statChip("PAIRS", value: "\(vm.matchedPairs)/\(vm.totalPairs)", color: NeonPalette.pink)
                statChip("SCORE", value: "\(vm.score)",                       color: NeonPalette.yellow)
            }

            ProgressView(value: vm.progress)
                .progressViewStyle(.linear)
                .tint(NeonPalette.pink)
                .frame(height: 4)
        }
        .padding(.horizontal, 14)
    }

    private func statChip(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(color.opacity(0.8))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .neonGlow(color, radius: 4, intensity: 0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(NeonPalette.bg0.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

/// Bottom action bar.
struct ActionBar: View {
    @Bindable var vm: GameViewModel
    var onMenu: () -> Void

    @State private var confirmHintAd: Bool = false
    @Bindable private var ads = AdManager.shared

    var body: some View {
        HStack(spacing: 10) {
            hintButton
            actionButton("Undo",    "arrow.uturn.backward",  color: NeonPalette.cyan)   { vm.undo() }
            actionButton("Shuffle", "shuffle",               color: NeonPalette.purple) { vm.shuffle() }
            actionButton("Menu",    "line.3.horizontal",     color: NeonPalette.white,  action: onMenu)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
        .alert("Out of free hints", isPresented: $confirmHintAd) {
            Button("Watch Ad") {
                Task { await vm.showHintAfterAd() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Watch a short ad for one more hint, or unlock unlimited hints in Settings → Remove Ads.")
        }
        .overlay {
            if ads.isPresenting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(NeonPalette.yellow)
                        Text("Loading ad…")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(NeonPalette.textDim)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(NeonPalette.bg0.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(NeonPalette.tileEdge, lineWidth: 1)
                            )
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: ads.isPresenting)
    }

    @ViewBuilder
    private var hintButton: some View {
        let color = NeonPalette.yellow
        let outOfFree = !vm.hasFreeHintsRemaining

        Button {
            SoundManager.shared.haptic(.button)
            if vm.hasFreeHintsRemaining {
                vm.showHint()
            } else {
                confirmHintAd = true
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .semibold))
                    if outOfFree {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(NeonPalette.bg0)
                            .padding(2)
                            .background(Circle().fill(color))
                            .offset(x: 11, y: -8)
                    }
                }
                Text(hintLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(color.opacity(0.55), lineWidth: 1)
                    )
            )
            .neonGlow(color, radius: 5, intensity: 0.55)
        }
        .buttonStyle(.plain)
    }

    private var hintLabel: String {
        if IAPManager.shared.isAdsRemoved { return "Hint" }
        if vm.hasFreeHintsRemaining { return "Hint · \(vm.freeHintsRemaining)" }
        return "Hint"
    }

    private func actionButton(_ title: String, _ system: String,
                              color: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: system)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(color.opacity(0.55), lineWidth: 1)
                    )
            )
            .neonGlow(color, radius: 5, intensity: 0.55)
        }
        .buttonStyle(.plain)
    }
}
