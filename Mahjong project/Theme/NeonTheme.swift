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

/// Background gradient used across menu and game screens.
struct NeonBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [NeonPalette.bg0, NeonPalette.bg1, NeonPalette.bg2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [NeonPalette.purple.opacity(0.18), .clear],
                center: .topLeading, startRadius: 10, endRadius: 380
            )
            RadialGradient(
                colors: [NeonPalette.cyan.opacity(0.14), .clear],
                center: .bottomTrailing, startRadius: 10, endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

/// Adds a layered neon glow around a view.
struct NeonGlow: ViewModifier {
    let color: Color
    var radius: CGFloat = 8
    var intensity: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.85 * intensity), radius: radius * 0.5)
            .shadow(color: color.opacity(0.55 * intensity), radius: radius)
            .shadow(color: color.opacity(0.35 * intensity), radius: radius * 2)
    }
}

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 8, intensity: CGFloat = 1.0) -> some View {
        modifier(NeonGlow(color: color, radius: radius, intensity: intensity))
    }
}
