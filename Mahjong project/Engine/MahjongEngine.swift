import Foundation

/// A board layout is a set of (col, row, layer) slots. Layers stack visually;
/// an upper-layer tile covers a lower-layer tile when their (col, row) match.
struct BoardLayout: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let positions: [TilePosition]
    let columns: Int
    let rows: Int

    var tileCount: Int { positions.count }
}

extension TilePosition: Sendable {}

extension BoardLayout {
    static let all: [BoardLayout] = [
        .neonPyramid,
        .shanghaiTurtle,
        .dragon,
        .sparkstone,
        .cathedral
    ]

    /// "Neon Pyramid" — 12×8 base + 10×4 mid + 4×2 top = 144 tiles. Default.
    static let neonPyramid: BoardLayout = BoardLayout(
        id: "neon_pyramid",
        name: "Neon Pyramid",
        subtitle: "144 tiles · classic",
        positions: pyramidPositions(),
        columns: 12, rows: 8
    )

    /// "Sparkstone" — 8×6 base + 6×3 mid + 3×2 top = 72 tiles. Quick play.
    static let sparkstone: BoardLayout = BoardLayout(
        id: "sparkstone",
        name: "Sparkstone",
        subtitle: "72 tiles · quick",
        positions: sparkstonePositions(),
        columns: 8, rows: 6
    )

    /// "Cathedral" — 10×8 + 8×6 + 6×2 + 4×1 = 144 tiles. Tall and narrow.
    static let cathedral: BoardLayout = BoardLayout(
        id: "cathedral",
        name: "Cathedral",
        subtitle: "144 tiles · tall",
        positions: cathedralPositions(),
        columns: 10, rows: 8
    )

    /// "Shanghai Turtle" — the iconic Mahjong layout. Diamond/turtle shell base
    /// (rows widening 8→14 then narrowing back to 8), with a 6×6 → 4×4 → 2×2
    /// stack on top. 144 tiles total.
    static let shanghaiTurtle: BoardLayout = BoardLayout(
        id: "shanghai_turtle",
        name: "Shanghai Turtle",
        subtitle: "144 tiles · iconic",
        positions: shanghaiTurtlePositions(),
        columns: 14, rows: 8
    )

    /// "Dragon" — long, low horizontal layout (14×6 base) for a snakier, more
    /// stretched silhouette. 144 tiles total.
    static let dragon: BoardLayout = BoardLayout(
        id: "dragon",
        name: "Dragon",
        subtitle: "144 tiles · wide",
        positions: dragonPositions(),
        columns: 14, rows: 6
    )

    // MARK: - Position builders

    private static func pyramidPositions() -> [TilePosition] {
        var positions: [TilePosition] = []
        // Layer 0: 12 cols × 8 rows
        for row in 0..<8 {
            for col in 0..<12 {
                positions.append(TilePosition(col: col, row: row, layer: 0))
            }
        }
        // Layer 1: 10 cols × 4 rows centered
        for row in 2..<6 {
            for col in 1..<11 {
                positions.append(TilePosition(col: col, row: row, layer: 1))
            }
        }
        // Layer 2: 4 cols × 2 rows centered
        for row in 3..<5 {
            for col in 4..<8 {
                positions.append(TilePosition(col: col, row: row, layer: 2))
            }
        }
        return positions
    }

    private static func sparkstonePositions() -> [TilePosition] {
        var positions: [TilePosition] = []
        // Layer 0: 8×6 = 48
        for row in 0..<6 {
            for col in 0..<8 {
                positions.append(TilePosition(col: col, row: row, layer: 0))
            }
        }
        // Layer 1: 6×3 = 18, centered
        for row in 1..<4 {
            for col in 1..<7 {
                positions.append(TilePosition(col: col, row: row, layer: 1))
            }
        }
        // Layer 2: 3×2 = 6, centered (cols 2-4, rows 2-3)
        for row in 2..<4 {
            for col in 2..<5 {
                positions.append(TilePosition(col: col, row: row, layer: 2))
            }
        }
        return positions
    }

    /// Turtle shell silhouette: rows of width 8, 10, 12, 14, 14, 12, 10, 8 on
    /// the base, then a centered 6×6, 4×4, 2×2 pyramid on top. 88 + 36 + 16 + 4 = 144.
    private static func shanghaiTurtlePositions() -> [TilePosition] {
        var positions: [TilePosition] = []
        // Each row is centered horizontally in the 14-wide grid.
        let rowWidths = [8, 10, 12, 14, 14, 12, 10, 8]
        for (row, width) in rowWidths.enumerated() {
            let startCol = (14 - width) / 2
            for col in startCol..<(startCol + width) {
                positions.append(TilePosition(col: col, row: row, layer: 0))
            }
        }
        // Layer 1: 6×6 centered (cols 4-9, rows 1-6) = 36
        for row in 1..<7 {
            for col in 4..<10 {
                positions.append(TilePosition(col: col, row: row, layer: 1))
            }
        }
        // Layer 2: 4×4 centered (cols 5-8, rows 2-5) = 16
        for row in 2..<6 {
            for col in 5..<9 {
                positions.append(TilePosition(col: col, row: row, layer: 2))
            }
        }
        // Layer 3: 2×2 centered (cols 6-7, rows 3-4) = 4
        for row in 3..<5 {
            for col in 6..<8 {
                positions.append(TilePosition(col: col, row: row, layer: 3))
            }
        }
        return positions
    }

    /// Long horizontal stretch. 14×6 base + centered 10×4 + 6×2 + 4×2 = 144.
    private static func dragonPositions() -> [TilePosition] {
        var positions: [TilePosition] = []
        // Layer 0: full 14×6 = 84
        for row in 0..<6 {
            for col in 0..<14 {
                positions.append(TilePosition(col: col, row: row, layer: 0))
            }
        }
        // Layer 1: 10×4 centered (cols 2-11, rows 1-4) = 40
        for row in 1..<5 {
            for col in 2..<12 {
                positions.append(TilePosition(col: col, row: row, layer: 1))
            }
        }
        // Layer 2: 6×2 centered (cols 4-9, rows 2-3) = 12
        for row in 2..<4 {
            for col in 4..<10 {
                positions.append(TilePosition(col: col, row: row, layer: 2))
            }
        }
        // Layer 3: 4×2 centered (cols 5-8, rows 2-3) = 8
        for row in 2..<4 {
            for col in 5..<9 {
                positions.append(TilePosition(col: col, row: row, layer: 3))
            }
        }
        return positions
    }

    private static func cathedralPositions() -> [TilePosition] {
        var positions: [TilePosition] = []
        // Layer 0: 10×8 = 80
        for row in 0..<8 {
            for col in 0..<10 {
                positions.append(TilePosition(col: col, row: row, layer: 0))
            }
        }
        // Layer 1: 8×6 = 48 (cols 1-8, rows 1-6)
        for row in 1..<7 {
            for col in 1..<9 {
                positions.append(TilePosition(col: col, row: row, layer: 1))
            }
        }
        // Layer 2: 6×2 = 12 (cols 2-7, rows 3-4)
        for row in 3..<5 {
            for col in 2..<8 {
                positions.append(TilePosition(col: col, row: row, layer: 2))
            }
        }
        // Layer 3: 4×1 = 4 (cols 3-6, row 3)
        for col in 3..<7 {
            positions.append(TilePosition(col: col, row: 3, layer: 3))
        }
        return positions
    }
}

enum MahjongEngine {

    // MARK: - Free-tile detection

    /// A tile is free when:
    /// 1. No active tile covers it from the layer above (same col/row, layer+1)
    /// 2. At least one horizontal side at its own layer is empty.
    static func isFree(tile: Tile, activeByPosition: [TilePosition: Tile]) -> Bool {
        let above = TilePosition(col: tile.position.col,
                                 row: tile.position.row,
                                 layer: tile.position.layer + 1)
        if activeByPosition[above] != nil { return false }

        let left  = TilePosition(col: tile.position.col - 1,
                                 row: tile.position.row,
                                 layer: tile.position.layer)
        let right = TilePosition(col: tile.position.col + 1,
                                 row: tile.position.row,
                                 layer: tile.position.layer)
        let leftBlocked  = activeByPosition[left]  != nil
        let rightBlocked = activeByPosition[right] != nil
        return !(leftBlocked && rightBlocked)
    }

    static func freeTiles(active: [Tile]) -> [Tile] {
        let index = Dictionary(uniqueKeysWithValues: active.map { ($0.position, $0) })
        return active.filter { isFree(tile: $0, activeByPosition: index) }
    }

    // MARK: - Solvable board generation

    /// Generates a guaranteed-solvable arrangement by playing the game in reverse:
    /// repeatedly drop a matched pair into two free slots, building bottom-up.
    /// A slot is free during placement iff nothing is yet placed above it AND
    /// it has at least one open horizontal neighbor at its layer.
    static func generateSolvableBoard(layout: BoardLayout, seed: UInt64? = nil) -> [Tile] {
        let tileSet = TileKind.tileSet(count: layout.positions.count)
        precondition(tileSet.count == layout.positions.count, "Tile/slot count mismatch")

        var rng: any RandomNumberGenerator = seed.map { SeededRNG(seed: $0) } ?? SystemRandomNumberGenerator()

        // Build pairs from the tile set (kind-pairs, with bonus pooled).
        var pairs = makePairs(from: tileSet, rng: &rng)
        pairs.shuffle(using: &rng)

        // Sort slots bottom-layer first; placement walks the queue and picks the
        // first two free slots for each pair.
        var slotQueue = layout.positions.sorted { lhs, rhs in
            if lhs.layer != rhs.layer { return lhs.layer < rhs.layer }
            if lhs.row   != rhs.row   { return lhs.row   < rhs.row }
            return lhs.col < rhs.col
        }

        var placed: [TilePosition: Tile] = [:]
        var output: [Tile] = []

        while !slotQueue.isEmpty {
            guard let firstIdx = slotQueue.firstIndex(where: { isSlotFree($0, placed: placed) }) else {
                // Layout pathology — shouldn't happen with our layouts; bail safely.
                let s = slotQueue.removeFirst()
                if let pair = popPair(&pairs) {
                    placed[s] = Tile(kind: pair.0, position: s)
                    output.append(placed[s]!)
                }
                continue
            }
            let firstSlot = slotQueue.remove(at: firstIdx)
            guard let secondIdx = slotQueue.firstIndex(where: { isSlotFree($0, placed: placed) }) else {
                break
            }
            let secondSlot = slotQueue.remove(at: secondIdx)
            guard let pair = popPair(&pairs) else { break }
            let t1 = Tile(kind: pair.0, position: firstSlot)
            let t2 = Tile(kind: pair.1, position: secondSlot)
            placed[firstSlot] = t1
            placed[secondSlot] = t2
            output.append(t1); output.append(t2)
        }
        return output
    }

    private static func isSlotFree(_ slot: TilePosition,
                                   placed: [TilePosition: Tile]) -> Bool {
        let above = TilePosition(col: slot.col, row: slot.row, layer: slot.layer + 1)
        if placed[above] != nil { return false }
        let left  = TilePosition(col: slot.col - 1, row: slot.row, layer: slot.layer)
        let right = TilePosition(col: slot.col + 1, row: slot.row, layer: slot.layer)
        return !(placed[left] != nil && placed[right] != nil)
    }

    private static func makePairs(from tiles: [TileKind],
                                  rng: inout any RandomNumberGenerator) -> [(TileKind, TileKind)] {
        var regular: [TileKind: Int] = [:]
        var flowers: [TileKind] = []
        var seasons: [TileKind] = []
        for t in tiles {
            switch t {
            case .flower: flowers.append(t)
            case .season: seasons.append(t)
            default: regular[t, default: 0] += 1
            }
        }
        var pairs: [(TileKind, TileKind)] = []
        for (kind, count) in regular {
            precondition(count.isMultiple(of: 2), "Tile counts must be even")
            for _ in 0..<(count / 2) { pairs.append((kind, kind)) }
        }
        flowers.shuffle(using: &rng)
        seasons.shuffle(using: &rng)
        for i in stride(from: 0, to: flowers.count, by: 2) where i + 1 < flowers.count {
            pairs.append((flowers[i], flowers[i + 1]))
        }
        for i in stride(from: 0, to: seasons.count, by: 2) where i + 1 < seasons.count {
            pairs.append((seasons[i], seasons[i + 1]))
        }
        return pairs
    }

    private static func popPair(_ pairs: inout [(TileKind, TileKind)]) -> (TileKind, TileKind)? {
        pairs.isEmpty ? nil : pairs.removeLast()
    }
}

/// Splittable seeded RNG — used so a given puzzle (e.g. daily) can be reproduced.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEAD_BEEF_CAFE_F00D : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z &>> 31)
    }
}
