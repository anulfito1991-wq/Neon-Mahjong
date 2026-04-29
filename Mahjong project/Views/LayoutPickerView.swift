import SwiftUI

struct LayoutPickerView: View {
    var onPick: (BoardLayout) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 18) {
                HStack {
                    closeButton
                    Spacer()
                    Text("CHOOSE LAYOUT")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(NeonPalette.cyan)
                        .neonGlow(NeonPalette.cyan, radius: 6)
                    Spacer()
                    closeButton.opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(BoardLayout.all) { layout in
                            LayoutCard(layout: layout) { onPick(layout) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var closeButton: some View {
        Button(action: { onCancel(); SoundManager.shared.haptic(.button) }) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(NeonPalette.white)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(NeonPalette.bg0.opacity(0.7))
                        .overlay(Circle().stroke(NeonPalette.tileEdge, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct LayoutCard: View {
    let layout: BoardLayout
    var onTap: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.haptic(.button)
            onTap()
        } label: {
            HStack(spacing: 14) {
                LayoutPreview(layout: layout)
                    .frame(width: 96, height: 70)

                VStack(alignment: .leading, spacing: 4) {
                    Text(layout.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(NeonPalette.white)
                    Text(layout.subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(NeonPalette.textDim)
                    if let best = GameStats.shared.snapshot.bestTimeByLayout[layout.id] {
                        Text("Best: \(format(seconds: best))")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(NeonPalette.yellow)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NeonPalette.cyan)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NeonPalette.bg0.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(NeonPalette.cyan.opacity(0.45), lineWidth: 1)
                    )
            )
            .neonGlow(NeonPalette.cyan, radius: 6, intensity: 0.4)
        }
        .buttonStyle(.plain)
    }

    private func format(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// Tiny silhouette preview of a layout — fills a slot for each position, layered
/// so depth reads at a glance.
private struct LayoutPreview: View {
    let layout: BoardLayout

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width / CGFloat(layout.columns + 1),
                           geo.size.height / CGFloat(layout.rows + 1))
            let layerColors: [Color] = [
                NeonPalette.cyan.opacity(0.45),
                NeonPalette.pink.opacity(0.55),
                NeonPalette.yellow.opacity(0.7),
                NeonPalette.green.opacity(0.85)
            ]
            ZStack(alignment: .center) {
                ForEach(layout.positions.sorted { $0.layer < $1.layer }, id: \.self) { pos in
                    let color = layerColors[min(pos.layer, layerColors.count - 1)]
                    RoundedRectangle(cornerRadius: cell * 0.18, style: .continuous)
                        .fill(color)
                        .frame(width: cell * 0.92, height: cell * 0.92)
                        .position(
                            x: geo.size.width  / 2 + (CGFloat(pos.col) - CGFloat(layout.columns - 1) / 2) * cell + CGFloat(pos.layer) * 1.2,
                            y: geo.size.height / 2 + (CGFloat(pos.row) - CGFloat(layout.rows - 1) / 2) * cell - CGFloat(pos.layer) * 1.2
                        )
                }
            }
        }
    }
}
