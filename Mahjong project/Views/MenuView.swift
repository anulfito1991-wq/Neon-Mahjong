import SwiftUI

struct MenuView: View {
    var onPlay: (GameSession) -> Void
    var onOpenStats: () -> Void
    var onOpenSettings: () -> Void

    @State private var showingLayoutPicker = false
    @Bindable private var stats = GameStats.shared

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 0) {
                Spacer().frame(height: 40)
                titleBlock
                Spacer()
                actionStack
                Spacer()
                legend
                Spacer().frame(height: 28)
            }
            .padding(.horizontal, 24)

            // Top corner buttons.
            VStack {
                HStack {
                    cornerButton(system: "chart.bar.fill", color: NeonPalette.pink) {
                        SoundManager.shared.haptic(.button)
                        onOpenStats()
                    }
                    Spacer()
                    cornerButton(system: "gearshape.fill", color: NeonPalette.cyan) {
                        SoundManager.shared.haptic(.button)
                        onOpenSettings()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                Spacer()
            }
        }
        .sheet(isPresented: $showingLayoutPicker) {
            LayoutPickerView(
                onPick: { layout in
                    showingLayoutPicker = false
                    onPlay(.freePlay(layout: layout))
                },
                onCancel: { showingLayoutPicker = false }
            )
        }
        .onAppear {
            if ScreenshotMode.requestedScene == .layouts {
                showingLayoutPicker = true
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("NEON")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .tracking(8)
                .foregroundStyle(NeonPalette.cyan)
                .neonGlow(NeonPalette.cyan, radius: 18, intensity: 1.3)
            Text("MAHJONG")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .tracking(6)
                .foregroundStyle(NeonPalette.pink)
                .neonGlow(NeonPalette.pink, radius: 14, intensity: 1.1)
            Text("A modern take on a timeless puzzle")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(NeonPalette.textDim)
                .padding(.top, 8)
        }
    }

    private var actionStack: some View {
        VStack(spacing: 14) {
            primaryButton(title: "PLAY",
                          system: "play.fill",
                          gradient: [NeonPalette.cyan, NeonPalette.pink]) {
                onPlay(.freePlay(layout: .neonPyramid))
            }
            secondaryButton(title: "Choose Layout",
                            system: "square.grid.3x3.square",
                            color: NeonPalette.purple) {
                showingLayoutPicker = true
            }
            secondaryButton(title: dailyButtonTitle,
                            system: dailyButtonIcon,
                            color: dailyButtonColor) {
                onPlay(.daily())
            }
            .disabled(DailyChallenge.isCompletedToday())
            .opacity(DailyChallenge.isCompletedToday() ? 0.55 : 1.0)
        }
    }

    private var dailyButtonTitle: String {
        DailyChallenge.isCompletedToday() ? "Daily Complete ✓" : "Daily Challenge"
    }
    private var dailyButtonIcon: String {
        DailyChallenge.isCompletedToday() ? "checkmark.seal.fill" : "calendar.badge.plus"
    }
    private var dailyButtonColor: Color {
        DailyChallenge.isCompletedToday() ? NeonPalette.green : NeonPalette.yellow
    }

    private var legend: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                legendDot(NeonPalette.green,  "Bamboo")
                legendDot(NeonPalette.cyan,   "Dots")
                legendDot(NeonPalette.pink,   "Characters")
            }
            HStack(spacing: 14) {
                legendDot(NeonPalette.purple, "Winds")
                legendDot(NeonPalette.red,    "Dragons")
                legendDot(NeonPalette.yellow, "Bonus")
            }
        }
    }

    // MARK: - Components

    private func primaryButton(title: String, system: String,
                               gradient: [Color],
                               action: @escaping () -> Void) -> some View {
        Button(action: { SoundManager.shared.haptic(.button); action() }) {
            HStack(spacing: 10) {
                Image(systemName: system)
                Text(title).tracking(4)
            }
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(NeonPalette.bg0)
            .padding(.horizontal, 56)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(
                    LinearGradient(colors: gradient,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
            )
            .neonGlow(gradient.last ?? .white, radius: 18, intensity: 1.0)
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, system: String, color: Color,
                                 action: @escaping () -> Void) -> some View {
        Button(action: { SoundManager.shared.haptic(.button); action() }) {
            HStack(spacing: 10) {
                Image(systemName: system)
                Text(title)
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .frame(maxWidth: 280)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(NeonPalette.bg0.opacity(0.7))
                    .overlay(Capsule().stroke(color.opacity(0.6), lineWidth: 1.2))
            )
            .neonGlow(color, radius: 6, intensity: 0.5)
        }
        .buttonStyle(.plain)
    }

    private func cornerButton(system: String, color: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(NeonPalette.bg0.opacity(0.7))
                        .overlay(Circle().stroke(color.opacity(0.55), lineWidth: 1))
                )
                .neonGlow(color, radius: 5, intensity: 0.5)
        }
        .buttonStyle(.plain)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .neonGlow(color, radius: 4, intensity: 1.0)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(NeonPalette.textDim)
        }
    }
}
