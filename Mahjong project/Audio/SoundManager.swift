import AVFoundation
import UIKit

/// Self-contained audio + haptics. No audio assets — all tones synthesized in
/// memory once at init and cached as PCM buffers. Settings respected.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    enum Effect {
        case select
        case match
        case mismatch
        case hint
        case shuffle
        case win
        case stuck
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var isReady = false

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationHaptic = UINotificationFeedbackGenerator()

    private init() {
        prepareEngine()
        prepareBuffers()
    }

    // MARK: - Engine

    private func prepareEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        mixer.outputVolume = 0.6
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient,
                                                            mode: .default,
                                                            options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.play()
            isReady = true
        } catch {
            isReady = false
        }
    }

    private func prepareBuffers() {
        // Crisp, short tones with exponential decay envelopes.
        buffers[.select]   = synth(notes: [(880, 0.06)],            decay: 6, volume: 0.35)
        buffers[.match]    = synth(notes: [(660, 0.08), (880, 0.10), (1320, 0.16)], decay: 5, volume: 0.45)
        buffers[.mismatch] = synth(notes: [(220, 0.12), (160, 0.18)], decay: 5, volume: 0.4)
        buffers[.hint]     = synth(notes: [(523, 0.06), (659, 0.06), (784, 0.10)], decay: 6, volume: 0.4)
        buffers[.shuffle]  = synth(notes: [(440, 0.05), (550, 0.05), (660, 0.05), (770, 0.10)], decay: 5, volume: 0.4)
        buffers[.win]      = synth(notes: [(523, 0.10), (659, 0.10), (784, 0.10), (1047, 0.20)], decay: 3, volume: 0.55)
        buffers[.stuck]    = synth(notes: [(330, 0.16), (260, 0.20)], decay: 4, volume: 0.45)
    }

    /// Builds a buffer that plays each (frequency, duration) note in sequence
    /// with an exponential decay envelope.
    private func synth(notes: [(freq: Double, dur: Double)],
                       decay: Double,
                       volume: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44_100.0
        let totalSamples = notes.reduce(0) { $0 + Int($1.dur * sampleRate) } + Int(0.05 * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples))!
        buffer.frameLength = AVAudioFrameCount(totalSamples)
        let channel = buffer.floatChannelData![0]

        var cursor = 0
        for note in notes {
            let n = Int(note.dur * sampleRate)
            for i in 0..<n {
                let t = Double(i) / sampleRate
                let env = exp(-decay * t / max(note.dur, 0.001))
                let s = sin(2.0 * .pi * note.freq * t) * env * volume
                channel[cursor + i] = Float(s)
            }
            cursor += n
        }
        // Tail of silence so the buffer has clean release.
        let tail = totalSamples - cursor
        for i in 0..<tail { channel[cursor + i] = 0 }
        return buffer
    }

    // MARK: - Playback

    func play(_ effect: Effect) {
        if ScreenshotMode.isActive { return }
        guard AppSettings.shared.soundEnabled, isReady, let buffer = buffers[effect] else { return }
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    // MARK: - Haptics

    func haptic(_ kind: HapticKind) {
        if ScreenshotMode.isActive { return }
        guard AppSettings.shared.hapticsEnabled else { return }
        switch kind {
        case .select:   lightHaptic.impactOccurred(intensity: 0.6)
        case .match:    mediumHaptic.impactOccurred()
        case .mismatch: notificationHaptic.notificationOccurred(.error)
        case .win:      notificationHaptic.notificationOccurred(.success)
        case .stuck:    notificationHaptic.notificationOccurred(.warning)
        case .button:   rigidHaptic.impactOccurred(intensity: 0.5)
        }
    }

    enum HapticKind {
        case select, match, mismatch, win, stuck, button
    }
}
