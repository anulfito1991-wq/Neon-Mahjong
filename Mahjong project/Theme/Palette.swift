import SwiftUI

/// All colors a theme provides. Field names match the legacy `NeonPalette`
/// enum so views don't need to know which palette is active — they just access
/// `NeonPalette.cyan` and the active theme's color is returned.
struct Palette: Hashable, Sendable {
    let bg0: Color
    let bg1: Color
    let bg2: Color

    let cyan: Color
    let green: Color
    let pink: Color
    let purple: Color
    let red: Color
    let white: Color
    let yellow: Color
    let orange: Color

    let tileFace: Color
    let tileEdge: Color
    let textDim: Color
}
