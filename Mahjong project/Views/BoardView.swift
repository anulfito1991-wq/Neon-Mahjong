import SwiftUI

/// Renders all active tiles on the board, layer by layer, with a slight
/// per-layer offset to suggest 3D depth. Spawns particle bursts when tiles
/// disappear so matches feel snappy.
struct BoardView: View {
    @Bindable var vm: GameViewModel

    @State private var lastActiveSnapshot: [UUID: TilePosition] = [:]
    @State private var bursts: [BurstSpec] = []
    @State private var cachedMetrics: Metrics?

    var body: some View {
        GeometryReader { geo in
            let metrics = boardMetrics(in: geo.size)
            ZStack(alignment: .topLeading) {
                // Subtle "table" backdrop behind the tiles.
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(NeonPalette.purple.opacity(0.35), lineWidth: 1)
                    )
                    .neonGlow(NeonPalette.purple, radius: 18, intensity: 0.4)
                    .frame(width: metrics.boardSize.width + 36,
                           height: metrics.boardSize.height + 36)
                    .offset(x: metrics.boardOrigin.x - 18,
                            y: metrics.boardOrigin.y - 18)

                ForEach(vm.activeTiles.sorted(by: layerOrder), id: \.id) { tile in
                    let pos = tilePoint(for: tile.position, metrics: metrics)
                    TileView(
                        tile: tile,
                        size: metrics.tileSize,
                        isSelected: vm.selectedID == tile.id,
                        isHinted: vm.hintIDs.contains(tile.id),
                        isMismatched: vm.mismatchIDs.contains(tile.id),
                        isFree: vm.isFree(tile),
                        onTap: { vm.tap(tileID: tile.id) }
                    )
                    .position(x: pos.x, y: pos.y)
                    .zIndex(Double(tile.position.layer) * 100
                            + Double(tile.position.row)
                            + Double(tile.position.col) * 0.01)
                    .transition(.scale.combined(with: .opacity))
                }

                ParticleBurstLayer(bursts: $bursts)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: vm.activeIDs)
            .onAppear {
                cachedMetrics = metrics
                refreshSnapshot()
            }
            .onChange(of: geo.size) { _, _ in
                cachedMetrics = boardMetrics(in: geo.size)
            }
            .onChange(of: vm.activeIDs) { oldValue, newValue in
                spawnBurstsForRemoved(oldValue: oldValue, newValue: newValue)
                refreshSnapshot()
            }
        }
    }

    private func layerOrder(_ a: Tile, _ b: Tile) -> Bool {
        if a.position.layer != b.position.layer { return a.position.layer < b.position.layer }
        if a.position.row   != b.position.row   { return a.position.row < b.position.row }
        return a.position.col < b.position.col
    }

    private func refreshSnapshot() {
        lastActiveSnapshot = Dictionary(uniqueKeysWithValues:
            vm.activeTiles.map { ($0.id, $0.position) }
        )
    }

    private func spawnBurstsForRemoved(oldValue: Set<UUID>, newValue: Set<UUID>) {
        let removed = oldValue.subtracting(newValue)
        guard !removed.isEmpty, let metrics = cachedMetrics else { return }
        for id in removed {
            guard let pos = lastActiveSnapshot[id],
                  let tile = vm.tile(id: id) else { continue }
            let point = tilePoint(for: pos, metrics: metrics)
            bursts.append(BurstSpec(position: point, color: tile.kind.neonColor))
        }
    }

    private struct Metrics {
        let tileSize: CGSize
        let boardSize: CGSize
        let boardOrigin: CGPoint
        let layerOffset: CGSize
    }

    private func boardMetrics(in container: CGSize) -> Metrics {
        let cols = vm.session.layout.columns
        let rows = vm.session.layout.rows
        let offsetX: CGFloat = 5
        let offsetY: CGFloat = 5
        let layers = 4
        let maxOffsetX = CGFloat(layers - 1) * offsetX
        let maxOffsetY = CGFloat(layers - 1) * offsetY

        let availW = max(container.width - 24 - maxOffsetX, 1)
        let availH = max(container.height - 24 - maxOffsetY, 1)
        let tileAspect: CGFloat = 0.78
        let widthByCols = availW / CGFloat(cols)
        let widthByRows = availH * tileAspect / CGFloat(rows)
        let tileW = floor(min(widthByCols, widthByRows))
        let tileH = floor(tileW / tileAspect)
        let boardW = tileW * CGFloat(cols)
        let boardH = tileH * CGFloat(rows)
        let originX = (container.width  - boardW - maxOffsetX) / 2
        let originY = (container.height - boardH - maxOffsetY) / 2

        return Metrics(
            tileSize: CGSize(width: tileW, height: tileH),
            boardSize: CGSize(width: boardW + maxOffsetX, height: boardH + maxOffsetY),
            boardOrigin: CGPoint(x: originX, y: originY),
            layerOffset: CGSize(width: offsetX, height: offsetY)
        )
    }

    private func tilePoint(for pos: TilePosition, metrics: Metrics) -> CGPoint {
        let layerDX = metrics.layerOffset.width  * CGFloat(pos.layer)
        let layerDY = metrics.layerOffset.height * CGFloat(pos.layer)
        let x = metrics.boardOrigin.x + (CGFloat(pos.col) + 0.5) * metrics.tileSize.width  + layerDX
        let y = metrics.boardOrigin.y + (CGFloat(pos.row) + 0.5) * metrics.tileSize.height - layerDY
        return CGPoint(x: x, y: y)
    }
}
