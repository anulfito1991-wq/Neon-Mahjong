import SwiftUI
import GameKit

// TODO(iOS 26+): GKGameCenterViewController is deprecated. Migrate to the new
// SwiftUI-native Game Center sheet when bumping the deployment target. Until
// then this works fine on every iOS we support.
@available(iOS, deprecated: 26.0)
struct LeaderboardsView: UIViewControllerRepresentable {
    let leaderboardID: String?
    var onClose: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onClose: onClose) }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc: GKGameCenterViewController
        if let leaderboardID {
            vc = GKGameCenterViewController(
                leaderboardID: leaderboardID,
                playerScope: .global,
                timeScope: .allTime
            )
        } else {
            vc = GKGameCenterViewController(state: .leaderboards)
        }
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let onClose: () -> Void
        init(onClose: @escaping () -> Void) { self.onClose = onClose }
        nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            Task { @MainActor in self.onClose() }
        }
    }
}

/// Compact picker that lets the user choose which layout's leaderboard to view,
/// then presents the native Game Center UI as a full-screen cover.
struct LeaderboardsBrowser: View {
    var onClose: () -> Void

    @Bindable private var leaderboards = LeaderboardManager.shared
    @State private var presentedLeaderboardID: String?

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        if !leaderboards.isAuthenticated {
                            authPrompt
                        }
                        ForEach(BoardLayout.all) { layout in
                            layoutRow(layout)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { presentedLeaderboardID.map { LeaderboardSheet(id: $0) } },
            set: { presentedLeaderboardID = $0?.id }
        )) { sheet in
            deprecatedLeaderboardSheet(id: sheet.id)
                .ignoresSafeArea()
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
            Text("LEADERBOARDS")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(NeonPalette.green)
                .neonGlow(NeonPalette.green, radius: 6)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var authPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(NeonPalette.yellow)
            Text(authMessage)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(NeonPalette.textDim)
                .multilineTextAlignment(.center)
            Button {
                SoundManager.shared.haptic(.button)
                LeaderboardManager.shared.authenticate()
            } label: {
                Text("Sign in to Game Center")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(NeonPalette.bg0)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(NeonPalette.cyan))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NeonPalette.bg0.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(NeonPalette.yellow.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var authMessage: String {
        switch leaderboards.authState {
        case .failed(let m):    return "Couldn't sign in: \(m)"
        case .unavailable:      return "Sign in to Game Center to see worldwide best times for each layout."
        case .authenticating:   return "Signing in…"
        default:                return "Sign in to compare your best times worldwide."
        }
    }

    private func layoutRow(_ layout: BoardLayout) -> some View {
        Button {
            SoundManager.shared.haptic(.button)
            if leaderboards.isAuthenticated {
                presentedLeaderboardID = LeaderboardManager.leaderboardID(forLayoutID: layout.id)
            } else {
                LeaderboardManager.shared.authenticate()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(NeonPalette.yellow)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(layout.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(NeonPalette.white)
                    Text(layout.subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(NeonPalette.textDim)
                }
                Spacer()
                if let best = GameStats.shared.snapshot.bestTimeByLayout[layout.id] {
                    Text(format(seconds: best))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(NeonPalette.cyan)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NeonPalette.textDim)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(NeonPalette.tileEdge, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(leaderboards.isAuthenticated ? 1.0 : 0.65)
    }

    private func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    @available(iOS, deprecated: 26.0)
    private func deprecatedLeaderboardSheet(id: String) -> some View {
        LeaderboardsView(leaderboardID: id, onClose: { presentedLeaderboardID = nil })
    }
}

private struct LeaderboardSheet: Identifiable {
    let id: String
}
