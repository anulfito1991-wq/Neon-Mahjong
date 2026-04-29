import SwiftUI

/// A short-lived neon burst of glowing dots, spawned at a point in board
/// coordinates whenever a pair clears. Lives for ~0.8s then vanishes.
struct BurstSpec: Identifiable, Equatable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let createdAt: Date = .now
}

struct ParticleBurst: View {
    let spec: BurstSpec
    let particleCount: Int = 12
    let radius: CGFloat = 38
    let lifetime: Double = 0.7

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                let angle = Double(i) / Double(particleCount) * 2 * .pi
                let dx = cos(angle) * Double(radius * progress)
                let dy = sin(angle) * Double(radius * progress)
                Circle()
                    .fill(spec.color)
                    .frame(width: 6, height: 6)
                    .offset(x: dx, y: dy)
                    .opacity(Double(1 - progress))
                    .shadow(color: spec.color.opacity(0.9), radius: 6)
                    .shadow(color: spec.color.opacity(0.6), radius: 12)
            }
            // Central flash
            Circle()
                .fill(spec.color.opacity(0.35))
                .frame(width: 30, height: 30)
                .scaleEffect(1 + 1.4 * progress)
                .opacity(Double(1 - progress))
                .blur(radius: 6)
        }
        .position(spec.position)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: lifetime)) {
                progress = 1
            }
        }
    }
}

/// Container view that overlays multiple bursts and auto-prunes stale ones.
struct ParticleBurstLayer: View {
    @Binding var bursts: [BurstSpec]

    var body: some View {
        ZStack {
            ForEach(bursts) { spec in
                ParticleBurst(spec: spec)
            }
        }
        .onChange(of: bursts) { _, _ in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                let cutoff = Date().addingTimeInterval(-0.8)
                bursts.removeAll { $0.createdAt < cutoff }
            }
        }
    }
}
