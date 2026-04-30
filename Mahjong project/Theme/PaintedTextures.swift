import SwiftUI

/// Procedural "painted" surfaces rendered with `Canvas`. Each one targets the
/// active theme's palette so swapping themes restyles the painted surfaces
/// automatically. See `feedback_visual_polish_playbook.md` for the larger
/// design rationale (Tier 1: painted textures, Tier 2: painted backgrounds).

// MARK: - Tile face

/// A river-stone tile face: warm gradient + fine speckle grain + soft inner
/// shadow + 1px top highlight. Sits beneath the tile glyphs in `TileView`.
///
/// Drawn live with `Canvas` rather than pre-rendered to an `Image`. At ~50pt
/// tile size, 144 tiles all redrawing per frame is well within Metal's budget
/// and keeps theme-swap instant.
struct PaintedTileFace: View {
    /// Stable per-tile seed so each stone has a unique speckle pattern.
    let seed: UInt64
    /// Corner radius matches the surrounding `RoundedRectangle`.
    let cornerRadius: CGFloat

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let path = Path(roundedRect: rect, cornerRadius: cornerRadius,
                            style: .continuous)

            // Clip everything to the rounded rect so noise dots can't escape.
            ctx.clip(to: path)

            // 1. Base warm gradient — top slightly lighter (river-stone catches
            //    light from above), bottom slightly darker.
            let face = NeonPalette.tileFace
            ctx.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        face.lighter(by: 0.06),
                        face,
                        face.darker(by: 0.10)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // 2. Soft top-center highlight (light source from above).
            let hl = CGRect(x: -size.width * 0.2,
                            y: -size.height * 0.4,
                            width: size.width * 1.4,
                            height: size.height * 0.7)
            ctx.fill(
                Path(ellipseIn: hl),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.07),
                        Color.white.opacity(0.0)
                    ]),
                    center: CGPoint(x: hl.midX, y: hl.midY),
                    startRadius: 0,
                    endRadius: hl.width * 0.5
                )
            )

            // 3. Speckle grain — deterministic per tile.
            var rng = SeededRNG(seed: seed)
            let dotCount = Int(size.width * size.height / 40)  // ~density
            for _ in 0..<dotCount {
                let x = rng.nextDouble() * size.width
                let y = rng.nextDouble() * size.height
                let r = 0.3 + rng.nextDouble() * 0.8
                let dark = rng.nextDouble() < 0.55
                let alpha = 0.04 + rng.nextDouble() * 0.06
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(dark ? .black.opacity(alpha)
                                      : .white.opacity(alpha * 0.7))
                )
            }

            // 4. Inner shadow rim — gives the stone a sense of inset depth.
            //    Drawn by stroking the inset path with a blurred shadow.
            ctx.drawLayer { layer in
                layer.addFilter(.shadow(color: .black.opacity(0.45), radius: 2,
                                        x: 0, y: 1))
                let inset = path.strokedPath(.init(lineWidth: 1.2))
                layer.fill(inset, with: .color(.black.opacity(0.001)))
            }

            // 5. 1px top highlight — picks out the upper edge.
            var topEdge = Path()
            topEdge.move(to: CGPoint(x: cornerRadius, y: 0.5))
            topEdge.addLine(to: CGPoint(x: size.width - cornerRadius, y: 0.5))
            ctx.stroke(topEdge, with: .color(.white.opacity(0.18)),
                       lineWidth: 0.8)
        }
    }
}

// MARK: - Painted scene background

/// A "painted floor" background — replaces flat radial gradients with a
/// scene that has noise grain, soft warm patches, lantern light variation,
/// and an edge vignette. Drops in as a backdrop for menu / game / settings.
struct PaintedSceneBackground: View {
    var body: some View {
        // Stable across launches but varied across themes — re-seed when the
        // active theme changes so the paint pattern subtly shifts too.
        let seed = UInt64(bitPattern: Int64(NeonPalette.tileFace.hashValue))

        return Canvas(rendersAsynchronously: false) { ctx, size in
            // 1. Linear base gradient (warm dark → darker corners).
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [
                        NeonPalette.bg1,
                        NeonPalette.bg0,
                        NeonPalette.bg2
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            // 2. Large warm "lantern" patches — soft radial blobs of warmth
            //    scattered across the scene. Low frequency, low opacity.
            var rng = SeededRNG(seed: seed)
            for _ in 0..<6 {
                let cx = rng.nextDouble() * size.width
                let cy = rng.nextDouble() * size.height
                let r = size.width * (0.3 + rng.nextDouble() * 0.4)
                let warm = rng.nextDouble() < 0.55
                let color = warm ? NeonPalette.yellow : NeonPalette.orange
                let opacity = 0.04 + rng.nextDouble() * 0.05
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - r, y: cy - r,
                                           width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(colors: [
                            color.opacity(opacity),
                            color.opacity(0)
                        ]),
                        center: CGPoint(x: cx, y: cy),
                        startRadius: 0,
                        endRadius: r
                    )
                )
            }

            // 3. Sand-grain speckle — fine noise across the whole scene to
            //    kill the "vector gradient" plasticky feel.
            let grainCount = Int(size.width * size.height / 220)
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

            // 4. Edge vignette — pulls the eye to the centre.
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

private extension Color {
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
        // Round-trip through UIColor for component access.
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

private extension SeededRNG {
    mutating func nextDouble() -> Double {
        Double(next() & 0xFFFFFF) / Double(0xFFFFFF)
    }
}
