import SwiftUI

/// The Neon Mahjong app icon, rendered programmatically. Used both for the
/// in-app "About" preview and for one-shot PNG export via ImageRenderer.
struct AppIconDesign: View {
    /// Standard iOS icon canvas: 1024×1024 (icon images are square; iOS rounds
    /// the corners automatically when displaying).
    static let canonicalSize: CGFloat = 1024

    var body: some View {
        ZStack {
            // Deep gradient background — same family as the app's NeonBackground.
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.10),
                    Color(red: 0.10, green: 0.04, blue: 0.22),
                    Color(red: 0.02, green: 0.06, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft glows in opposite corners.
            RadialGradient(
                colors: [NeonPalette.purple.opacity(0.55), .clear],
                center: .topTrailing, startRadius: 60, endRadius: 700
            )
            RadialGradient(
                colors: [NeonPalette.cyan.opacity(0.40), .clear],
                center: .bottomLeading, startRadius: 60, endRadius: 700
            )

            // Three stacked tiles, fanned out (like a mini Mahjong stack).
            iconTileStack
        }
        .frame(width: AppIconDesign.canonicalSize, height: AppIconDesign.canonicalSize)
        .clipShape(RoundedRectangle(cornerRadius: AppIconDesign.canonicalSize * 0.22,
                                     style: .continuous))
    }

    private var iconTileStack: some View {
        ZStack {
            iconTile(text: "中", color: NeonPalette.red)
                .rotationEffect(.degrees(-12))
                .offset(x: -120, y: 80)
            iconTile(text: "9", color: NeonPalette.cyan, sub: "●")
                .rotationEffect(.degrees(0))
            iconTile(text: "發", color: NeonPalette.green)
                .rotationEffect(.degrees(12))
                .offset(x: 120, y: -80)
        }
    }

    private func iconTile(text: String, color: Color, sub: String? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.08, blue: 0.18),
                            Color(red: 0.14, green: 0.10, blue: 0.24)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 60, style: .continuous)
                        .stroke(color.opacity(0.85), lineWidth: 8)
                )
                .frame(width: 360, height: 460)
                .shadow(color: color.opacity(0.7), radius: 30)
                .shadow(color: color.opacity(0.5), radius: 60)

            VStack(spacing: 8) {
                Text(text)
                    .font(.system(size: 220, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.95), radius: 12)
                    .shadow(color: color.opacity(0.7), radius: 30)
                if let sub {
                    Text(sub)
                        .font(.system(size: 90, weight: .semibold, design: .rounded))
                        .foregroundStyle(color.opacity(0.85))
                }
            }
        }
    }
}

#Preview {
    AppIconDesign()
        .scaleEffect(0.25)
        .frame(width: 256, height: 256)
}
