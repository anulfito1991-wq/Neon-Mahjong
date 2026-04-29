import Foundation

enum Wind: Int, CaseIterable, Codable, Hashable {
    case east, south, west, north

    var symbol: String {
        switch self {
        case .east:  return "E"
        case .south: return "S"
        case .west:  return "W"
        case .north: return "N"
        }
    }
}

enum Dragon: Int, CaseIterable, Codable, Hashable {
    case red, green, white

    var symbol: String {
        switch self {
        case .red:   return "中"
        case .green: return "發"
        case .white: return "白"
        }
    }
}

enum Flower: Int, CaseIterable, Codable, Hashable {
    case plum, orchid, chrysanthemum, bamboo

    var symbol: String {
        switch self {
        case .plum:           return "❀"
        case .orchid:         return "✿"
        case .chrysanthemum:  return "❁"
        case .bamboo:         return "❃"
        }
    }
}

enum Season: Int, CaseIterable, Codable, Hashable {
    case spring, summer, autumn, winter

    var symbol: String {
        switch self {
        case .spring: return "✦"
        case .summer: return "✧"
        case .autumn: return "✩"
        case .winter: return "✪"
        }
    }
}

enum TileKind: Hashable, Codable {
    case bamboo(Int)
    case dots(Int)
    case characters(Int)
    case wind(Wind)
    case dragon(Dragon)
    case flower(Flower)
    case season(Season)

    /// Mahjong matching: identical kinds match, plus any flower with any flower,
    /// and any season with any season.
    func matches(_ other: TileKind) -> Bool {
        switch (self, other) {
        case (.flower, .flower): return true
        case (.season, .season): return true
        default: return self == other
        }
    }

    /// The full 144-tile set, ordered so that taking any even prefix always
    /// yields valid pairs (every kind appears in pairs of 2 in this order).
    static func standardSet() -> [TileKind] {
        var tiles: [TileKind] = []
        // Round 1: pair of each suit value (54)
        for v in 1...9 {
            tiles.append(.bamboo(v));     tiles.append(.bamboo(v))
            tiles.append(.dots(v));       tiles.append(.dots(v))
            tiles.append(.characters(v)); tiles.append(.characters(v))
        }
        // Round 1: pair of each honor (14)
        for w in Wind.allCases   { tiles.append(.wind(w));   tiles.append(.wind(w)) }
        for d in Dragon.allCases { tiles.append(.dragon(d)); tiles.append(.dragon(d)) }
        // Bonus tiles (8) — flowers/seasons all match within their group
        for f in Flower.allCases { tiles.append(.flower(f)) }
        for s in Season.allCases { tiles.append(.season(s)) }
        // Round 2: another pair of each suit + honor (68)
        for v in 1...9 {
            tiles.append(.bamboo(v));     tiles.append(.bamboo(v))
            tiles.append(.dots(v));       tiles.append(.dots(v))
            tiles.append(.characters(v)); tiles.append(.characters(v))
        }
        for w in Wind.allCases   { tiles.append(.wind(w));   tiles.append(.wind(w)) }
        for d in Dragon.allCases { tiles.append(.dragon(d)); tiles.append(.dragon(d)) }
        return tiles
    }

    /// Returns a subset of the standard tile set sized to `count`. Pair-validity
    /// is preserved because `standardSet()` is ordered as adjacent pairs.
    static func tileSet(count: Int) -> [TileKind] {
        precondition(count.isMultiple(of: 2), "Tile count must be even")
        precondition(count <= 144, "Maximum 144 tiles available")
        return Array(standardSet().prefix(count))
    }
}

struct TilePosition: Hashable, Codable {
    let col: Int
    let row: Int
    let layer: Int
}

struct Tile: Identifiable, Hashable {
    let id: UUID
    let kind: TileKind
    let position: TilePosition

    init(id: UUID = UUID(), kind: TileKind, position: TilePosition) {
        self.id = id
        self.kind = kind
        self.position = position
    }
}

enum GamePhase: Hashable {
    case playing
    case won
    case stuck
}
