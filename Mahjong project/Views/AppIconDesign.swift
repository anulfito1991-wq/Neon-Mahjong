import SwiftUI

/// The Zen Mahjong app icon, rendered programmatically. Used both for the
/// in-app "About" preview and for one-shot PNG export via ImageRenderer.
struct AppIconDesign: View {
    /// Standard iOS icon canvas: 1024×1024 (icon images are square; iOS rounds
    /// the corners automatically when displaying).
    static let canonicalSize: CGFloat = 1024

    var body: some View {
        ZStack {
            // Warm-charcoal stone-garden gradient (matches Stone Garden theme bg).
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.11, blue: 0.09),
                    Color(red: 0.18, green: 0.15, blue: 0.12),
                    Color(red: 0.08, green: 0.07, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft lantern glows in opposite corners — warm gold + ember.
            RadialGradient(
                colors: [Color(red: 0.85, green: 0.70, blue: 0.38).opacity(0.35), .clear],
                center: .topTrailing, startRadius: 80, endRadius: 760
            )
            RadialGradient(
                colors: [Color(red: 0.85, green: 0.55, blue: 0.36).opacity(0.25), .clear],
                center: .bottomLeading, startRadius: 80, endRadius: 760
            )

            // Three stacked stones, fanned out.
            iconTileStack
        }
        .frame(width: AppIconDesign.canonicalSize, height: AppIconDesign.canonicalSize)
        .clipShape(RoundedRectangle(cornerRadius: AppIconDesign.canonicalSize * 0.22,
                                     style: .continuous))
    }

    private var iconTileStack: some View {
        ZStack {
            iconTile(text: "中", accent: Color(red: 0.85, green: 0.38, blue: 0.32)) // ember
                .rotationEffect(.degrees(-12))
                .offset(x: -120, y: 80)
            iconTile(text: "禪", accent: Color(red: 0.85, green: 0.70, blue: 0.38)) // aged gold
                .rotationEffect(.degrees(0))
            iconTile(text: "發", accent: Color(red: 0.58, green: 0.72, blue: 0.55)) // moss
                .rotationEffect(.degrees(12))
                .offset(x: 120, y: -80)
        }
    }

    private func iconTile(text: String, accent: Color) -> some View {
        ZStack {
            // River-stone face — smooth, slightly warmer than background.
            RoundedRectangle(cornerRadius: 70, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.20, blue: 0.18),
                            Color(red: 0.16, green: 0.14, blue: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 70, style: .continuous)
                        .stroke(Color(red: 0.35, green: 0.31, blue: 0.27), lineWidth: 4)
                )
                .frame(width: 360, height: 460)
                .shadow(color: .black.opacity(0.55), radius: 24, y: 10)

            Text(text)
                .font(.system(size: 240, weight: .heavy, design: .serif))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.45), radius: 14)
        }
    }
}

#Preview {
    AppIconDesign()
        .scaleEffect(0.25)
        .frame(width: 256, height: 256)
}
