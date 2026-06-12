import SwiftUI

/// Procedural "painted" surfaces rendered with `Canvas`.
///
/// Visual direction (v1.1 "traditional" pass): tiles are ivory/bone — the
/// look of a real Mahjong set — sitting on a dark stone-garden table. The
/// light-tile-on-dark-table contrast is what makes the board read instantly;
/// suit glyphs are engraved ink colors (see `TileKind.inkColor`).

// MARK: - Tile face

/// An ivory tile face: bone gradient + soft sheen + sparse warm grain +
/// beveled edges (light catches the top/left, shade falls bottom/right).
///
/// `seed` must be deterministic across launches AND shuffles — derive it
/// from the tile's board position, never from `UUID.hashValue` (randomized
/// per process, and shuffles mint new UUIDs, which forced a full-board
/// texture repaint mid-animation).
struct PaintedTileFace: View {
    let seed: UInt64
    let cornerRadius: CGFloat

    var body: some View {
        // Read theme colors in the view body (observation-tracked) and
        // capture the resolved values — reads inside the Canvas renderer
        // closure are not reliably tracked by @Observable.
        let face = NeonPalette.tileFace
        let edge = NeonPalette.tileEdge

        Canvas(rendersAsynchronously: false) { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let path = Path(roundedRect: rect, cornerRadius: cornerRadius,
                            style: .continuous)
            ctx.clip(to: path)

            // 1. Bone gradient — lighter top, slightly warmer/darker base.
            ctx.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        face.lighter(by: 0.05),
                        face,
                        face.darker(by: 0.06)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // 2. Soft sheen from upper-left, like lacquered bone.
            let hl = CGRect(x: -size.width * 0.25,
                            y: -size.height * 0.35,
                            width: size.width * 1.1,
                            height: size.height * 0.8)
            ctx.fill(
                Path(ellipseIn: hl),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.30),
                        Color.white.opacity(0.0)
                    ]),
                    center: CGPoint(x: hl.midX, y: hl.midY),
                    startRadius: 0,
                    endRadius: hl.width * 0.55
                )
            )

            // 3. Sparse warm grain — bone is not plastic. Density kept low:
            //    this runs for 144 tiles, so every dot here costs 144×.
            var rng = SeededRNG(seed: seed)
            let dotCount = Int(size.width * size.height / 110)
            for _ in 0..<dotCount {
                let x = rng.nextDouble() * size.width
                let y = rng.nextDouble() * size.height
                let r = 0.3 + rng.nextDouble() * 0.7
                let alpha = 0.025 + rng.nextDouble() * 0.04
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(Color(red: 0.45, green: 0.36, blue: 0.24)
                        .opacity(alpha))
                )
            }

            // 4. Bevel — the defining cue of a physical tile. Light edge on
            //    top, shade on the bottom; drawn as two clipped arcs of the
            //    border so the corners stay clean.
            let inset = rect.insetBy(dx: 0.6, dy: 0.6)
            let bevel = Path(roundedRect: inset,
                             cornerRadius: max(1, cornerRadius - 0.6),
                             style: .continuous)
            // top-light
            var topClip = ctx
            topClip.clip(to: Path(CGRect(x: 0, y: 0,
                                         width: size.width,
                                         height: size.height * 0.45)))
            topClip.stroke(bevel, with: .color(.white.opacity(0.55)),
                           lineWidth: 1.1)
            // bottom-shade
            var bottomClip = ctx
            bottomClip.clip(to: Path(CGRect(x: 0, y: size.height * 0.55,
                                            width: size.width,
                                            height: size.height * 0.45)))
            bottomClip.stroke(bevel, with: .color(edge.darker(by: 0.18).opacity(0.7)),
                              lineWidth: 1.1)
        }
    }
}

// MARK: - Painted scene background

/// The stone-garden table: warm dark gradient, a few soft lantern patches,
/// light grain, edge vignette. Rendered asynchronously — at iPad sizes the
/// grain pass alone is thousands of paths and has no business blocking the
/// main thread on rotation or theme swaps.
struct PaintedSceneBackground: View {
    /// Fixed seed: the table should look identical on every launch.
    /// (`Color.hashValue` — used previously — is randomized per process.)
    private static let seed: UInt64 = 0x5EED_2026_0506

    var body: some View {
        // Capture theme colors in the body for reliable observation tracking.
        let bg0 = NeonPalette.bg0, bg1 = NeonPalette.bg1, bg2 = NeonPalette.bg2
        let warmA = NeonPalette.yellow, warmB = NeonPalette.orange

        Canvas(rendersAsynchronously: true) { ctx, size in
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [bg1, bg0, bg2]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            var rng = SeededRNG(seed: Self.seed)
            for _ in 0..<6 {
                let cx = rng.nextDouble() * size.width
                let cy = rng.nextDouble() * size.height
                let r = size.width * (0.3 + rng.nextDouble() * 0.4)
                let warm = rng.nextDouble() < 0.55
                let color = warm ? warmA : warmB
                let opacity = 0.04 + rng.nextDouble() * 0.05
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - r, y: cy - r,
                                           width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(colors: [color.opacity(opacity),
                                          color.opacity(0)]),
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius: r
                    )
                )
            }

            // Grain: 1/3 the previous density — visually indistinguishable
            // past arm's length, three times cheaper.
            let grainCount = Int(size.width * size.height / 660)
            for _ in 0..<grainCount {
                let x = rng.nextDouble() * size.width
                let y = rng.nextDouble() * size.height
                let r = 0.4 + rng.nextDouble() * 0.7
                let dark = rng.nextDouble() < 0.65
                let alpha = 0.02 + rng.nextDouble() * 0.03
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(dark ? .black.opacity(alpha)
                                      : .white.opacity(alpha * 0.6))
                )
            }

            let vMax = max(size.width, size.height)
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0),
                        Color.black.opacity(0.45)
                    ]),
                    center: CGPoint(x: size.width / 2, y: size.height / 2),
                    startRadius: 0,
                    endRadius: vMax * 0.7
                )
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Helpers

extension Color {
    /// Returns a slightly lighter version of this color in sRGB. `amount` is
    /// 0…1 (typical 0.05–0.15 for subtle shifts).
    func lighter(by amount: CGFloat) -> Color {
        adjusted(by: amount)
    }

    /// Returns a slightly darker version of this color.
    func darker(by amount: CGFloat) -> Color {
        adjusted(by: -amount)
    }

    private func adjusted(by amount: CGFloat) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        return Color(
            red:   Double(min(max(r + amount, 0), 1)),
            green: Double(min(max(g + amount, 0), 1)),
            blue:  Double(min(max(b + amount, 0), 1)),
            opacity: Double(a)
        )
    }
}

extension SeededRNG {
    mutating func nextDouble() -> Double {
        Double(next() & 0xFFFFFF) / Double(0xFFFFFF)
    }
}
