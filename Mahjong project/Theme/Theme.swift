import SwiftUI

/// A purchasable look-and-feel. The "classic" theme is always available; the
/// rest are unlocked via in-app purchase.
struct Theme: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let isPremium: Bool
    /// StoreKit product identifier (nil for free themes).
    let productID: String?
    let palette: Palette
}

extension Theme {
    /// All themes shipped with the app, in display order.
    static let all: [Theme] = [.classic, .solarFlare, .cyberbloom, .oceanDrift]

    static let classic = Theme(
        id: "classic",
        name: "Classic Neon",
        tagline: "The original glow",
        isPremium: false,
        productID: nil,
        palette: Palette(
            bg0:      Color(red: 0.04, green: 0.02, blue: 0.10),
            bg1:      Color(red: 0.08, green: 0.04, blue: 0.18),
            bg2:      Color(red: 0.02, green: 0.06, blue: 0.16),
            cyan:     Color(red: 0.00, green: 0.95, blue: 1.00),
            green:    Color(red: 0.22, green: 1.00, blue: 0.40),
            pink:     Color(red: 1.00, green: 0.20, blue: 0.85),
            purple:   Color(red: 0.65, green: 0.30, blue: 1.00),
            red:      Color(red: 1.00, green: 0.25, blue: 0.35),
            white:    Color(red: 0.90, green: 0.95, blue: 1.00),
            yellow:   Color(red: 1.00, green: 0.90, blue: 0.25),
            orange:   Color(red: 1.00, green: 0.55, blue: 0.20),
            tileFace: Color(red: 0.10, green: 0.08, blue: 0.18),
            tileEdge: Color(red: 0.18, green: 0.16, blue: 0.30),
            textDim:  Color(red: 0.70, green: 0.75, blue: 0.90)
        )
    )

    /// Sunset reds, deep oranges, gold — warm and dramatic.
    static let solarFlare = Theme(
        id: "solar_flare",
        name: "Solar Flare",
        tagline: "Sunset to inferno",
        isPremium: true,
        productID: "com.anulfito.mahjong.theme.solarflare",
        palette: Palette(
            bg0:      Color(red: 0.10, green: 0.03, blue: 0.04),
            bg1:      Color(red: 0.18, green: 0.05, blue: 0.05),
            bg2:      Color(red: 0.08, green: 0.02, blue: 0.02),
            cyan:     Color(red: 1.00, green: 0.78, blue: 0.30),  // gold (was cyan)
            green:    Color(red: 0.95, green: 0.90, blue: 0.45),  // amber-yellow
            pink:     Color(red: 1.00, green: 0.35, blue: 0.30),  // coral red
            purple:   Color(red: 0.80, green: 0.30, blue: 0.50),  // hibiscus
            red:      Color(red: 1.00, green: 0.20, blue: 0.20),
            white:    Color(red: 1.00, green: 0.95, blue: 0.85),
            yellow:   Color(red: 1.00, green: 0.85, blue: 0.20),
            orange:   Color(red: 1.00, green: 0.50, blue: 0.10),
            tileFace: Color(red: 0.16, green: 0.06, blue: 0.06),
            tileEdge: Color(red: 0.30, green: 0.14, blue: 0.10),
            textDim:  Color(red: 0.85, green: 0.70, blue: 0.55)
        )
    )

    /// Hot magenta, lavender, electric purple — florals at night.
    static let cyberbloom = Theme(
        id: "cyberbloom",
        name: "Cyberbloom",
        tagline: "Magenta in moonlight",
        isPremium: true,
        productID: "com.anulfito.mahjong.theme.cyberbloom",
        palette: Palette(
            bg0:      Color(red: 0.08, green: 0.02, blue: 0.14),
            bg1:      Color(red: 0.16, green: 0.04, blue: 0.24),
            bg2:      Color(red: 0.06, green: 0.02, blue: 0.12),
            cyan:     Color(red: 0.55, green: 0.35, blue: 1.00),  // violet
            green:    Color(red: 0.60, green: 1.00, blue: 0.85),  // mint-blush
            pink:     Color(red: 1.00, green: 0.30, blue: 0.75),
            purple:   Color(red: 0.85, green: 0.40, blue: 1.00),
            red:      Color(red: 1.00, green: 0.35, blue: 0.55),
            white:    Color(red: 0.95, green: 0.92, blue: 1.00),
            yellow:   Color(red: 1.00, green: 0.75, blue: 0.95),  // soft pink-yellow
            orange:   Color(red: 0.95, green: 0.55, blue: 0.85),
            tileFace: Color(red: 0.14, green: 0.06, blue: 0.22),
            tileEdge: Color(red: 0.28, green: 0.18, blue: 0.40),
            textDim:  Color(red: 0.80, green: 0.70, blue: 0.95)
        )
    )

    /// Cool teals, aquamarines, deep blues — ocean depths.
    static let oceanDrift = Theme(
        id: "ocean_drift",
        name: "Ocean Drift",
        tagline: "Below the waves",
        isPremium: true,
        productID: "com.anulfito.mahjong.theme.oceandrift",
        palette: Palette(
            bg0:      Color(red: 0.02, green: 0.06, blue: 0.12),
            bg1:      Color(red: 0.04, green: 0.10, blue: 0.20),
            bg2:      Color(red: 0.02, green: 0.04, blue: 0.10),
            cyan:     Color(red: 0.30, green: 0.95, blue: 1.00),
            green:    Color(red: 0.40, green: 1.00, blue: 0.80),  // seafoam
            pink:     Color(red: 0.55, green: 0.85, blue: 1.00),  // sky
            purple:   Color(red: 0.30, green: 0.55, blue: 1.00),  // deep blue
            red:      Color(red: 1.00, green: 0.45, blue: 0.55),
            white:    Color(red: 0.90, green: 0.97, blue: 1.00),
            yellow:   Color(red: 0.95, green: 1.00, blue: 0.55),  // soft chartreuse
            orange:   Color(red: 1.00, green: 0.65, blue: 0.45),
            tileFace: Color(red: 0.06, green: 0.12, blue: 0.22),
            tileEdge: Color(red: 0.15, green: 0.25, blue: 0.40),
            textDim:  Color(red: 0.65, green: 0.85, blue: 1.00)
        )
    )
}
