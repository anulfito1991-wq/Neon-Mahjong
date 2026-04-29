import SwiftUI

/// A single Mahjong tile rendered with neon glow.
struct TileView: View {
    let tile: Tile
    let size: CGSize
    let isSelected: Bool
    let isHinted: Bool
    let isMismatched: Bool
    let isFree: Bool
    let onTap: () -> Void

    private var color: Color { tile.kind.neonColor }

    var body: some View {
        ZStack {
            // Base
            RoundedRectangle(cornerRadius: size.width * 0.18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            NeonPalette.tileFace,
                            NeonPalette.tileFace.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Inner border (suit-tinted on free tiles)
            RoundedRectangle(cornerRadius: size.width * 0.18, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)

            // Selection / hint outer halo
            if isSelected || isHinted {
                RoundedRectangle(cornerRadius: size.width * 0.18, style: .continuous)
                    .stroke(haloColor, lineWidth: 2)
                    .blur(radius: 2)
                    .opacity(0.9)
            }

            // Glyphs
            VStack(spacing: size.height * 0.02) {
                Text(tile.kind.primaryGlyph)
                    .font(.system(size: size.height * 0.46,
                                  weight: .heavy,
                                  design: .rounded))
                    .foregroundStyle(color)
                if let suit = tile.kind.suitGlyph {
                    Text(suit)
                        .font(.system(size: size.height * 0.18,
                                      weight: .semibold,
                                      design: .rounded))
                        .foregroundStyle(color.opacity(0.85))
                }
            }
            .neonGlow(color, radius: glowRadius, intensity: glowIntensity)
            .opacity(isFree ? 1.0 : 0.55)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(scale)
        .modifier(MismatchShake(active: isMismatched))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHinted)
        .contentShape(RoundedRectangle(cornerRadius: size.width * 0.18, style: .continuous))
        .onTapGesture {
            if isFree { onTap() }
        }
    }

    private var scale: CGFloat {
        if isSelected { return 1.07 }
        if isHinted   { return 1.04 }
        return 1.0
    }

    private var borderColor: Color {
        if isMismatched      { return NeonPalette.red }
        if isSelected        { return color }
        if isHinted          { return NeonPalette.yellow }
        if isFree            { return color.opacity(0.55) }
        return NeonPalette.tileEdge
    }

    private var borderWidth: CGFloat {
        (isSelected || isMismatched) ? 2.4 : (isHinted ? 2.0 : 1.2)
    }

    private var haloColor: Color {
        if isMismatched { return NeonPalette.red }
        if isHinted     { return NeonPalette.yellow }
        return color
    }

    private var glowRadius: CGFloat {
        if isSelected { return 14 }
        if isHinted   { return 12 }
        if isFree     { return 6 }
        return 2
    }

    private var glowIntensity: CGFloat {
        if isSelected { return 1.4 }
        if isHinted   { return 1.2 }
        if isFree     { return 0.7 }
        return 0.25
    }
}

/// Brief horizontal shake for mismatched pairs.
struct MismatchShake: ViewModifier {
    let active: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: active) { _, newValue in
                guard newValue else { return }
                Task { @MainActor in
                    let pattern: [CGFloat] = [-6, 6, -4, 4, -2, 2, 0]
                    for v in pattern {
                        withAnimation(.easeInOut(duration: 0.04)) { offset = v }
                        try? await Task.sleep(nanoseconds: 40_000_000)
                    }
                    offset = 0
                }
            }
    }
}
