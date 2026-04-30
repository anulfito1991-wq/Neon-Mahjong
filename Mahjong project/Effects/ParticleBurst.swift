import SwiftUI

/// A soft pond-ripple, spawned at a point in board coordinates whenever a
/// pair clears. Two concentric rings spread outward and fade. Lives for ~0.9s.
struct BurstSpec: Identifiable, Equatable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let createdAt: Date = .now
}

struct ParticleBurst: View {
    let spec: BurstSpec
    let lifetime: Double = 0.9

    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            // Outer ring — wider, fainter
            Circle()
                .stroke(spec.color.opacity(0.55), lineWidth: 2)
                .frame(width: 24, height: 24)
                .scaleEffect(1 + 3.4 * progress)
                .opacity(Double(1 - progress))

            // Inner ring — tighter, slightly brighter, lags behind
            Circle()
                .stroke(spec.color.opacity(0.75), lineWidth: 1.5)
                .frame(width: 18, height: 18)
                .scaleEffect(1 + 2.2 * progress)
                .opacity(Double(1 - progress * 0.85))

            // Soft center glow that fades quickly
            Circle()
                .fill(spec.color.opacity(0.20))
                .frame(width: 22, height: 22)
                .scaleEffect(1 + 0.5 * progress)
                .opacity(Double(1 - progress))
                .blur(radius: 4)
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
