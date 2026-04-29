import SwiftUI

struct GameView: View {
    @State private var vm: GameViewModel
    var onExit: () -> Void

    init(session: GameSession, onExit: @escaping () -> Void) {
        _vm = State(initialValue: GameViewModel(session: session))
        self.onExit = onExit
    }

    var body: some View {
        ZStack {
            NeonBackground()

            VStack(spacing: 8) {
                HUDView(vm: vm)
                BoardView(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ActionBar(vm: vm, onMenu: onExit)
            }
            .padding(.top, 4)

            if vm.phase == .won {
                EndGameOverlay(
                    title: vm.session.isDaily ? "DAILY COMPLETE" : "BOARD CLEARED",
                    accent: NeonPalette.green,
                    vm: vm,
                    onPlayAgain: { vm.startNewGame() },
                    onMenu: onExit
                )
            } else if vm.phase == .stuck {
                EndGameOverlay(
                    title: "NO MOVES LEFT",
                    accent: NeonPalette.red,
                    vm: vm,
                    onPlayAgain: { vm.startNewGame() },
                    onMenu: onExit
                )
            }
        }
        .onAppear {
            if let scene = ScreenshotMode.requestedScene,
               scene == .game || scene == .win {
                vm.loadScreenshotState(scene)
            }
        }
        .onDisappear { vm.stopTimer() }
    }
}

private struct EndGameOverlay: View {
    let title: String
    let accent: Color
    @Bindable var vm: GameViewModel
    var onPlayAgain: () -> Void
    var onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(accent)
                    .neonGlow(accent, radius: 14, intensity: 1.2)
                    .multilineTextAlignment(.center)

                VStack(spacing: 6) {
                    summaryRow("Score",   "\(vm.score)",      color: NeonPalette.yellow)
                    summaryRow("Time",    vm.formattedTime,    color: NeonPalette.cyan)
                    summaryRow("Pairs",   "\(vm.matchedPairs)/\(vm.totalPairs)", color: NeonPalette.pink)
                    summaryRow("Hints",   "\(vm.hintsUsed)",   color: NeonPalette.yellow)
                    summaryRow("Undos",   "\(vm.undosUsed)",   color: NeonPalette.cyan)
                    summaryRow("Shuffles","\(vm.shufflesUsed)",color: NeonPalette.purple)
                }
                .padding(.horizontal, 22)

                HStack(spacing: 12) {
                    if !vm.session.isDaily {
                        overlayButton("Play Again", color: NeonPalette.green, action: onPlayAgain)
                    }
                    overlayButton("Menu", color: NeonPalette.white, action: onMenu)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(accent.opacity(0.6), lineWidth: 1.5)
                    )
                    .neonGlow(accent, radius: 18, intensity: 0.8)
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }

    private func summaryRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(NeonPalette.textDim)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .neonGlow(color, radius: 3, intensity: 0.6)
        }
    }

    private func overlayButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: { SoundManager.shared.haptic(.button); action() }) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(NeonPalette.bg1.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(color.opacity(0.7), lineWidth: 1.2)
                        )
                )
                .neonGlow(color, radius: 6, intensity: 0.7)
        }
        .buttonStyle(.plain)
    }
}
