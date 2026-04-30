import SwiftUI

/// A purchasable look-and-feel. The default theme is always available; the
/// rest are unlocked via in-app purchase.
struct Theme: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let isPremium: Bool
    /// StoreKit product identifier (nil for free themes). These IDs are
    /// internal-only and never shown to users — they remain stable across
    /// rebrands so existing purchases keep working.
    let productID: String?
    let palette: Palette
}

extension Theme {
    /// All themes shipped with the app, in display order.
    static let all: [Theme] = [.stoneGarden, .maple, .sakura, .bambooGrove]

    /// "Stone Garden" — warm charcoal background, smooth river-stone tiles,
    /// muted lantern-lit accents. The default, free theme.
    static let stoneGarden = Theme(
        id: "stone_garden",
        name: "Stone Garden",
        tagline: "Quiet stones at twilight",
        isPremium: false,
        productID: nil,
        palette: Palette(
            // Warm-charcoal background, no purple cast
            bg0:      Color(red: 0.10, green: 0.09, blue: 0.08),
            bg1:      Color(red: 0.16, green: 0.14, blue: 0.12),
            bg2:      Color(red: 0.07, green: 0.06, blue: 0.05),
            // Suit-distinguishing accents — muted lantern tones, not neon
            cyan:     Color(red: 0.50, green: 0.62, blue: 0.74),  // dusty slate (was cyan)
            green:    Color(red: 0.58, green: 0.72, blue: 0.55),  // moss
            pink:     Color(red: 0.82, green: 0.50, blue: 0.42),  // brick (warm "pink")
            purple:   Color(red: 0.65, green: 0.58, blue: 0.74),  // dusty plum
            red:      Color(red: 0.85, green: 0.38, blue: 0.32),  // ember
            white:    Color(red: 0.93, green: 0.88, blue: 0.78),  // warm bone
            yellow:   Color(red: 0.85, green: 0.70, blue: 0.38),  // aged gold
            orange:   Color(red: 0.82, green: 0.55, blue: 0.36),  // copper
            // Dark river stone (slightly warmer than bg, with a hint of slate)
            tileFace: Color(red: 0.20, green: 0.18, blue: 0.16),
            tileEdge: Color(red: 0.38, green: 0.34, blue: 0.30),
            textDim:  Color(red: 0.80, green: 0.74, blue: 0.64)
        )
    )

    /// "Maple" — warm autumn. Deep mahogany background, amber/ochre/copper.
    static let maple = Theme(
        id: "maple",
        name: "Maple",
        tagline: "Embers at the end of summer",
        isPremium: true,
        productID: "com.anulfito.mahjong.theme.solarflare",  // ID kept for sandbox compat
        palette: Palette(
            bg0:      Color(red: 0.12, green: 0.07, blue: 0.05),
            bg1:      Color(red: 0.20, green: 0.11, blue: 0.07),
            bg2:      Color(red: 0.08, green: 0.04, blue: 0.03),
            cyan:     Color(red: 0.85, green: 0.68, blue: 0.40),  // warm amber
            green:    Color(red: 0.78, green: 0.72, blue: 0.42),  // ochre
            pink:     Color(red: 0.92, green: 0.50, blue: 0.40),  // soft red
            purple:   Color(red: 0.78, green: 0.45, blue: 0.50),  // dusty rose
            red:      Color(red: 0.95, green: 0.40, blue: 0.30),  // crimson
            white:    Color(red: 0.96, green: 0.90, blue: 0.78),
            yellow:   Color(red: 0.95, green: 0.75, blue: 0.32),
            orange:   Color(red: 0.96, green: 0.55, blue: 0.25),
            tileFace: Color(red: 0.24, green: 0.15, blue: 0.11),
            tileEdge: Color(red: 0.46, green: 0.28, blue: 0.20),
            textDim:  Color(red: 0.88, green: 0.74, blue: 0.58)
        )
    )

    /// "Sakura" — soft pink, plum, blush, gold. Cherry blossom at dusk.
    static let sakura = Theme(
        id: "sakura",
        name: "Sakura",
        tagline: "Petals on still water",
        isPremium: true,
        productID: "com.anulfito.mahjong.theme.cyberbloom",  // ID kept for sandbox compat
        palette: Palette(
            bg0:      Color(red: 0.10, green: 0.07, blue: 0.10),
            bg1:      Color(red: 0.18, green: 0.11, blue: 0.18),
            bg2:      Color(red: 0.07, green: 0.05, blue: 0.08),
            cyan:     Color(red: 0.78, green: 0.62, blue: 0.78),  // dusty lavender
            green:    Color(red: 0.78, green: 0.85, blue: 0.78),  // mint blush
            pink:     Color(red: 0.95, green: 0.62, blue: 0.78),  // cherry blossom
            purple:   Color(red: 0.82, green: 0.55, blue: 0.85),  // plum
            red:      Color(red: 0.92, green: 0.50, blue: 0.62),  // rose
            white:    Color(red: 0.97, green: 0.92, blue: 0.95),
            yellow:   Color(red: 0.95, green: 0.82, blue: 0.62),  // soft gold
            orange:   Color(red: 0.92, green: 0.72, blue: 0.75),  // peach blossom
            tileFace: Color(red: 0.20, green: 0.15, blue: 0.22),
            tileEdge: Color(red: 0.40, green: 0.30, blue: 0.42),
            textDim:  Color(red: 0.90, green: 0.82, blue: 0.92)
        )
    )

    /// "Bamboo Grove" — mossy green, jade, slate, mist. Calm forest depth.
    static let bambooGrove = Theme(
        id: "bamboo_grove",
        name: "Bamboo Grove",
        tagline: "Mist through the forest",
        isPremium: true,
        productID: "com.anulfito.mahjong.theme.oceandrift",  // ID kept for sandbox compat
        palette: Palette(
            bg0:      Color(red: 0.06, green: 0.10, blue: 0.08),
            bg1:      Color(red: 0.10, green: 0.16, blue: 0.13),
            bg2:      Color(red: 0.04, green: 0.08, blue: 0.06),
            cyan:     Color(red: 0.60, green: 0.78, blue: 0.78),  // mist
            green:    Color(red: 0.55, green: 0.78, blue: 0.55),  // bamboo leaf
            pink:     Color(red: 0.78, green: 0.65, blue: 0.50),  // tea
            purple:   Color(red: 0.55, green: 0.62, blue: 0.78),  // distant slate
            red:      Color(red: 0.85, green: 0.55, blue: 0.42),  // clay
            white:    Color(red: 0.92, green: 0.95, blue: 0.90),
            yellow:   Color(red: 0.88, green: 0.85, blue: 0.55),  // pollen
            orange:   Color(red: 0.85, green: 0.65, blue: 0.40),
            tileFace: Color(red: 0.12, green: 0.18, blue: 0.15),
            tileEdge: Color(red: 0.30, green: 0.40, blue: 0.34),
            textDim:  Color(red: 0.78, green: 0.88, blue: 0.80)
        )
    )
}
