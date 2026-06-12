import SwiftUI

/// A single Mahjong tile, rendered as a physical ivory tile: bone face,
/// engraved ink glyph, beveled edges, drop shadow lifting it off the table.
struct TileView: View {
    let tile: Tile
    let size: CGSize
    let isSelected: Bool
    let isHinted: Bool
    let isMismatched: Bool
    let isFree: Bool
    let onTap: () -> Void

    var body: some View {
        let radius = size.width * 0.16
        return ZStack {
            // Ivory bone face — gradient + grain + bevel.
            PaintedTileFace(seed: tileSeed, cornerRadius: radius)

            // Border: quiet tan at rest; gold for selection/hint, red for
            // mismatch. Traditional tiles aren't color-coded by suit border —
            // state is the only thing the border communicates.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)

            // Selection / hint outer halo (on the dark table, not the face)
            if isSelected || isHinted || isMismatched {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(haloColor, lineWidth: 2)
                    .blur(radius: 2.5)
                    .opacity(0.85)
            }

            // Engraved glyphs — fixed traditional ink colors (red/green/
            // blue/ink), with a hairline light shadow below the strokes so
            // the ink reads carved into the bone rather than printed on it.
            VStack(spacing: size.height * 0.02) {
                Text(tile.kind.primaryGlyph)
                    .font(.system(size: size.height * 0.46,
                                  weight: .bold,
                                  design: .serif))
                    .foregroundStyle(tile.kind.inkColor)
                if let suit = tile.kind.suitGlyph {
                    Text(suit)
                        .font(.system(size: size.height * 0.17,
                                      weight: .semibold,
                                      design: .serif))
                        .foregroundStyle(tile.kind.inkColor.opacity(0.8))
                }
            }
            .shadow(color: .white.opacity(0.55), radius: 0.4, x: 0, y: 0.8)

            // Covered tiles fall into shade instead of going transparent —
            // dimming the face keeps the ivory material readable while
            // making "playable" unmistakable.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.black.opacity(isFree ? 0 : 0.32))
        }
        .frame(width: size.width, height: size.height)
        .compositingGroup()
        .shadow(color: .black.opacity(isFree ? 0.40 : 0.25),
                radius: isSelected ? 6 : 3,
                x: 0, y: isSelected ? 4 : 2)
        .scaleEffect(scale)
        .modifier(MismatchShake(active: isMismatched))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHinted)
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
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
        if isMismatched { return NeonPalette.red }
        if isSelected   { return NeonPalette.yellow }
        if isHinted     { return NeonPalette.yellow }
        return NeonPalette.tileEdge
    }

    private var borderWidth: CGFloat {
        (isSelected || isMismatched) ? 2.4 : (isHinted ? 2.0 : 1.0)
    }

    private var haloColor: Color {
        if isMismatched { return NeonPalette.red }
        return NeonPalette.yellow
    }

    /// Deterministic per-slot seed for the painted-face grain. Derived from
    /// the board POSITION, not the tile UUID: positions survive shuffles and
    /// launches (UUID.hashValue does neither), so tile textures never
    /// invalidate en masse mid-animation.
    private var tileSeed: UInt64 {
        let p = tile.position
        let mixed = p.col &* 73_856_093 ^ p.row &* 19_349_663 ^ p.layer &* 83_492_791
        return UInt64(bitPattern: Int64(mixed))
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
