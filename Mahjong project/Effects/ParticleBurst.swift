import SwiftUI

/// A soft pond-ripple, spawned at a point in board coordinates whenever a
/// pair clears. Two concentric rings spread outward and fade. Lives for ~0.9s.
struct BurstSpec: Identifiable, Equatable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let createdAt: Date = .now

    /// Single source of truth for the ripple duration. The prune pass in
    /// `ParticleBurstLayer` derives its cutoff from this — previously the two
    /// were independent magic numbers and pruning (0.8s) cut the animation
    /// (0.9s) short on every single ripple.
    static let lifetime: Double = 0.9
}

struct ParticleBurst: View {
    let spec: BurstSpec
    private var lifetime: Double { BurstSpec.lifetime }

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
        .onChange(of: bursts) { old, new in
            // Only schedule a prune when something was ADDED — pruning also
            // mutates the array, and reacting to our own removal would spawn
            // an endless chain of prune tasks.
            guard new.count > old.count else { return }
            Task { @MainActor in
                let margin = BurstSpec.lifetime + 0.15
                try? await Task.sleep(nanoseconds: UInt64(margin * 1_000_000_000))
                let cutoff = Date().addingTimeInterval(-BurstSpec.lifetime)
                bursts.removeAll { $0.createdAt < cutoff }
            }
        }
    }
}
