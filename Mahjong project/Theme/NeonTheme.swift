import SwiftUI

/// Color slots used everywhere in the UI. Each property reads through to the
/// currently-active theme's palette, so swapping themes restyles the whole app
/// without touching individual views.
@MainActor
enum NeonPalette {
    static var bg0:      Color { ThemeStore.shared.palette.bg0 }
    static var bg1:      Color { ThemeStore.shared.palette.bg1 }
    static var bg2:      Color { ThemeStore.shared.palette.bg2 }

    static var cyan:     Color { ThemeStore.shared.palette.cyan }
    static var green:    Color { ThemeStore.shared.palette.green }
    static var pink:     Color { ThemeStore.shared.palette.pink }
    static var purple:   Color { ThemeStore.shared.palette.purple }
    static var red:      Color { ThemeStore.shared.palette.red }
    static var white:    Color { ThemeStore.shared.palette.white }
    static var yellow:   Color { ThemeStore.shared.palette.yellow }
    static var orange:   Color { ThemeStore.shared.palette.orange }

    static var tileFace: Color { ThemeStore.shared.palette.tileFace }
    static var tileEdge: Color { ThemeStore.shared.palette.tileEdge }
    static var textDim:  Color { ThemeStore.shared.palette.textDim }
}

extension TileKind {
    /// Primary glow color, derived from suit. MainActor-isolated because it
    /// reads through `ThemeStore`.
    @MainActor
    var neonColor: Color {
        switch self {
        case .bamboo:           return NeonPalette.green
        case .dots:             return NeonPalette.cyan
        case .characters:       return NeonPalette.pink
        case .wind:             return NeonPalette.purple
        case .dragon(.red):     return NeonPalette.red
        case .dragon(.green):   return NeonPalette.green
        case .dragon(.white):   return NeonPalette.white
        case .flower:           return NeonPalette.yellow
        case .season:           return NeonPalette.orange
        }
    }

    /// Big glyph rendered on the tile face.
    var primaryGlyph: String {
        switch self {
        case .bamboo(let n), .dots(let n), .characters(let n):
            return "\(n)"
        case .wind(let w):    return w.symbol
        case .dragon(let d):  return d.symbol
        case .flower(let f):  return f.symbol
        case .season(let s):  return s.symbol
        }
    }

    /// Small subscript indicating the suit family.
    var suitGlyph: String? {
        switch self {
        case .bamboo:     return "‖"
        case .dots:       return "●"
        case .characters: return "萬"
        case .wind:       return "風"
        case .dragon:     return nil
        case .flower:     return "花"
        case .season:     return "季"
        }
    }
}

/// Background gradient used across menu and game screens. Uses a warm
/// lantern-glow ambient (yellow top-leading, orange bottom-trailing) layered
/// over the theme's dark base. The radial glows give the scene depth without
/// fighting the foreground text.
struct NeonBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [NeonPalette.bg1, NeonPalette.bg0, NeonPalette.bg2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Warm ambient — soft lantern in upper-left
            RadialGradient(
                colors: [NeonPalette.yellow.opacity(0.16), .clear],
                center: .topLeading, startRadius: 20, endRadius: 480
            )
            // Cooler counterpoint in bottom-right keeps the scene from feeling flat
            RadialGradient(
                colors: [NeonPalette.orange.opacity(0.10), .clear],
                center: .bottomTrailing, startRadius: 20, endRadius: 520
            )
            // Subtle center brightness — anchors the eye without obscuring tiles
            RadialGradient(
                colors: [Color.white.opacity(0.04), .clear],
                center: .center, startRadius: 0, endRadius: 320
            )
            // Dark vignette around the edges for focus
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.35)],
                center: .center, startRadius: 280, endRadius: 720
            )
        }
        .ignoresSafeArea()
    }
}

/// Adds a soft ambient glow around a view. Two outer shadow layers form a
/// halo without an inner-tight shadow — that inner layer (in the previous
/// implementation) visually thickened text strokes and made glyphs look
/// blurry against the warm earth-tone palettes. The outer-only stack reads
/// as "lit from within" while keeping text crisp.
struct NeonGlow: ViewModifier {
    let color: Color
    var radius: CGFloat = 8
    var intensity: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.40 * intensity), radius: radius * 0.9)
            .shadow(color: color.opacity(0.18 * intensity), radius: radius * 1.8)
    }
}

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 8, intensity: CGFloat = 1.0) -> some View {
        modifier(NeonGlow(color: color, radius: radius, intensity: intensity))
    }
}
