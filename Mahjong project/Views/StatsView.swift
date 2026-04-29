import SwiftUI

struct StatsView: View {
    @Bindable var stats = GameStats.shared
    var onClose: () -> Void
    var onOpenLeaderboards: (() -> Void)? = nil

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 16) {
                        if onOpenLeaderboards != nil {
                            leaderboardButton
                        }
                        overviewGrid
                        streakCard
                        bestTimesCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
        }
    }

    private var leaderboardButton: some View {
        Button {
            SoundManager.shared.haptic(.button)
            onOpenLeaderboards?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(NeonPalette.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leaderboards")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(NeonPalette.white)
                    Text("Compare best times worldwide")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(NeonPalette.textDim)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NeonPalette.textDim)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(NeonPalette.yellow.opacity(0.5), lineWidth: 1)
                    )
            )
            .neonGlow(NeonPalette.yellow, radius: 5, intensity: 0.4)
        }
        .buttonStyle(.plain)
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
            Text("STATS")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(NeonPalette.pink)
                .neonGlow(NeonPalette.pink, radius: 6)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var overviewGrid: some View {
        let s = stats.snapshot
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Games Played", "\(s.gamesPlayed)", color: NeonPalette.cyan, icon: "gamecontroller.fill")
            statCard("Games Won",    "\(s.gamesWon)",    color: NeonPalette.green, icon: "trophy.fill")
            statCard("Win Rate",     "\(Int(s.winRate * 100))%", color: NeonPalette.yellow, icon: "percent")
            statCard("Total Time",   formatLong(s.totalSeconds), color: NeonPalette.purple, icon: "clock.fill")
        }
    }

    private var streakCard: some View {
        let s = stats.snapshot
        return VStack(alignment: .leading, spacing: 10) {
            Text("DAILY CHALLENGE")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(NeonPalette.textDim)
            HStack(spacing: 18) {
                streakItem(label: "Today", value: DailyChallenge.isCompletedToday() ? "✓" : "—",
                           color: DailyChallenge.isCompletedToday() ? NeonPalette.green : NeonPalette.textDim)
                streakItem(label: "Streak",   value: "\(s.currentStreak)", color: NeonPalette.orange)
                streakItem(label: "Longest",  value: "\(s.longestStreak)", color: NeonPalette.pink)
                streakItem(label: "Total",    value: "\(s.dailyCompleted.count)", color: NeonPalette.cyan)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NeonPalette.bg0.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(NeonPalette.tileEdge, lineWidth: 1)
                )
        )
    }

    private var bestTimesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BEST TIMES BY LAYOUT")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(NeonPalette.textDim)
            VStack(spacing: 8) {
                ForEach(BoardLayout.all) { layout in
                    HStack {
                        Text(layout.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(NeonPalette.white)
                        Spacer()
                        if let best = stats.snapshot.bestTimeByLayout[layout.id] {
                            Text(format(seconds: best))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(NeonPalette.yellow)
                        } else {
                            Text("—")
                                .foregroundStyle(NeonPalette.textDim)
                        }
                        if let score = stats.snapshot.bestScoreByLayout[layout.id] {
                            Text("· \(score) pts")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(NeonPalette.cyan.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NeonPalette.bg0.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(NeonPalette.tileEdge, lineWidth: 1)
                )
        )
    }

    private func statCard(_ label: String, _ value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .neonGlow(color, radius: 5, intensity: 0.7)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(NeonPalette.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NeonPalette.bg0.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func streakItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .neonGlow(color, radius: 4, intensity: 0.6)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(NeonPalette.textDim)
        }
        .frame(maxWidth: .infinity)
    }

    private func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func formatLong(_ seconds: Int) -> String {
        if seconds < 3600 { return format(seconds: seconds) }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return "\(h)h \(m)m"
    }
}
