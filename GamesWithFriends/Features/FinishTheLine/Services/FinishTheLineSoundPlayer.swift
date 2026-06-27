//
//  FinishTheLineSoundPlayer.swift
//  GamesWithFriends
//
//  Runtime-synthesized game audio for Finish the Line. Tones are rendered
//  into PCM buffers on demand and played through AVAudioEngine — no bundled
//  assets, no licensing exposure, fully offline. The correct-answer chime
//  rises in pitch with the player's streak so the whole room can hear
//  someone heating up.
//
//  All sounds degrade silently if the engine can't start (e.g., audio session
//  contention) — haptics remain the feedback floor.
//

import AVFoundation

@MainActor
final class FinishTheLineSoundPlayer {

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

    init() {
        guard let format else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    // MARK: - Public API

    /// Two-note rising chime; each streak step lifts the chime a semitone
    /// (capped) so consecutive answers audibly escalate.
    func playCorrect(streak: Int) {
        let step = Double(min(max(streak - 1, 0), 8))
        let base = 523.25 * pow(2.0, step / 12.0) // C5 rising a semitone per streak
        schedule([
            Tone(frequency: base, duration: 0.085, gain: 0.38),
            Tone(frequency: base * 1.2599, duration: 0.11, gain: 0.42), // major third up
        ])
    }

    /// Soft descending whiff — neutral, not punishing.
    func playSkip() {
        scheduleSweep(from: 330, to: 215, duration: 0.13, gain: 0.22)
    }

    /// Quiet clock tick for the Encore window.
    func playTick() {
        schedule([Tone(frequency: 1050, duration: 0.03, gain: 0.16)])
    }

    /// End-of-round buzzer.
    func playBuzzer() {
        schedule([Tone(frequency: 152, duration: 0.45, gain: 0.5)])
    }

    /// Rising swoosh when a streak ignites On Fire.
    func playIgnite() {
        scheduleSweep(from: 350, to: 920, duration: 0.26, gain: 0.34)
    }

    /// Three-note fanfare for beating the pass-the-phone target.
    func playFanfare() {
        schedule([
            Tone(frequency: 659.26, duration: 0.11, gain: 0.42), // E5
            Tone(frequency: 783.99, duration: 0.11, gain: 0.42), // G5
            Tone(frequency: 1046.50, duration: 0.28, gain: 0.46), // C6
        ])
    }

    // MARK: - Synthesis

    private struct Tone {
        let frequency: Double
        let duration: Double
        let gain: Double
    }

    private func ensureRunning() -> Bool {
        guard format != nil else { return false }
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                return false
            }
        }
        if !player.isPlaying {
            player.play()
        }
        return true
    }

    private func schedule(_ tones: [Tone]) {
        guard ensureRunning(), let format else { return }
        let sampleRate = format.sampleRate
        let totalDuration = tones.reduce(0) { $0 + $1.duration }
        let totalFrames = AVAudioFrameCount(totalDuration * sampleRate)
        guard totalFrames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = totalFrames

        var frameOffset = 0
        for tone in tones {
            let frames = Int(tone.duration * sampleRate)
            for i in 0..<frames where frameOffset + i < Int(totalFrames) {
                let t = Double(i) / sampleRate
                let value = sin(2 * .pi * tone.frequency * t)
                samples[frameOffset + i] = Float(value * envelope(at: t, duration: tone.duration) * tone.gain)
            }
            frameOffset += frames
        }

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func scheduleSweep(from startFrequency: Double, to endFrequency: Double, duration: Double, gain: Double) {
        guard ensureRunning(), let format else { return }
        let sampleRate = format.sampleRate
        let totalFrames = AVAudioFrameCount(duration * sampleRate)
        guard totalFrames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = totalFrames

        // Accumulate phase so the glide is continuous as frequency changes.
        var phase = 0.0
        for i in 0..<Int(totalFrames) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let frequency = startFrequency + (endFrequency - startFrequency) * progress
            phase += 2 * .pi * frequency / sampleRate
            samples[i] = Float(sin(phase) * envelope(at: t, duration: duration) * gain)
        }

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Short linear attack, exponential decay — keeps blips clicky-free.
    private func envelope(at t: Double, duration: Double) -> Double {
        let attack = 0.008
        let attackLevel = min(t / attack, 1.0)
        let decay = exp(-4.0 * t / duration)
        return attackLevel * decay
    }
}
