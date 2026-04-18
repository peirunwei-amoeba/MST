//
//  AmbientMusicEngine.swift
//  MST
//
//  Copyright © 2025 Pei Runwei. All rights reserved.
//
//  This Source Code Form is subject to the terms of the PolyForm Strict
//  License 1.0.0. You may not use, modify, or distribute this file except
//  in compliance with the License. A copy of the License is located at:
//  https://polyformproject.org/licenses/strict/1.0.0
//
//  Required Notice: Copyright Pei Runwei (https://github.com/peirunwei-amoeba)
//

import AVFoundation
import Observation

// MARK: - Lo-Fi Ambient Music + Sound Effects Engine
// Translated from the lo-fi neo-soul Web Audio API implementation.
// Music: 72 BPM, 8-chord cycle (Cmaj9→Am11→Fmaj9→Dm9→Em7→Am9→Dm7→G13),
// with pad, electric-piano arp, sub-bass, drums, sparse melody, vinyl texture,
// stereo delay, and dynamics compressor.

@Observable @MainActor
final class AmbientMusicEngine {
    var isPlaying = false
    var isMuted = false
    var volume: Float = 0.6

    private var musicEngine: AVAudioEngine?
    private var musicPlayer: AVAudioPlayerNode?
    private var nextBuffer: AVAudioPCMBuffer?
    private var isPrerendering = false

    private var sfxEngine: AVAudioEngine?
    private var sfxMixer: AVAudioMixerNode?

    // MARK: - Public Music API

    func startMusic() {
        guard !isPlaying else { return }
        configureAudioSession()
        isPlaying = true

        Task.detached(priority: .userInitiated) { [weak self] in
            let sr: Float = 44100
            let buffer = Self.renderLoopBuffer(sampleRate: sr)
            await MainActor.run { [weak self] in
                self?.beginPlayback(buffer: buffer)
            }
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicEngine?.stop()
        musicEngine = nil
        musicPlayer = nil
        nextBuffer = nil
        isPrerendering = false
        isPlaying = false
    }

    func mute() {
        isMuted = true
        musicEngine?.mainMixerNode.outputVolume = 0
    }

    func unmute() {
        isMuted = false
        musicEngine?.mainMixerNode.outputVolume = volume
    }

    func toggleMute() { isMuted ? unmute() : mute() }

    func setVolume(_ v: Float) {
        volume = v
        if !isMuted { musicEngine?.mainMixerNode.outputVolume = v }
    }

    // MARK: - One-Shot Sound Effects

    func playCorrectSound() {
        // Bright ascending chime: C5 → E5 → G5, staggered 70ms
        let sr: Float = 44100
        let freqs: [Float] = [523.25, 659.25, 783.99]
        let totalLen = Int(0.5 * sr)
        var samples = [Float](repeating: 0, count: totalLen)

        for (k, freq) in freqs.enumerated() {
            let startIdx = Int(Float(k) * 0.07 * sr)
            let attackLen = Int(0.03 * sr)
            let duration = Int(0.38 * sr)
            var phase: Float = 0
            for i in 0..<duration {
                let idx = startIdx + i
                guard idx < totalLen else { break }
                let env: Float = i < attackLen
                    ? Float(i) / Float(attackLen) * 0.15
                    : 0.15 * max(0, powf(0.001, Float(i - attackLen) / Float(max(1, duration - attackLen))))
                samples[idx] += sinf(phase) * env
                phase += 2.0 * .pi * freq / sr
            }
        }
        playSFX(samples, sampleRate: sr)
    }

    func playWrongSound() {
        // Low descending sawtooth buzz: 280→160 Hz over 350ms
        let sr: Float = 44100
        let duration = Int(0.4 * sr)
        var samples = [Float](repeating: 0, count: duration)
        var phase: Float = 0

        for i in 0..<duration {
            let t = Float(i) / Float(duration)
            let freq = 280.0 - 120.0 * t  // 280→160 Hz
            let env = 0.12 * max(0, powf(0.001, t))
            let saw = phase / .pi - 1.0
            samples[i] += saw * env
            phase += 2.0 * .pi * freq / sr
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        }
        playSFX(samples, sampleRate: sr)
    }

    func playClickSound() {
        // Short sine click at 600 Hz, ~60ms
        let sr: Float = 44100
        let duration = Int(0.07 * sr)
        var samples = [Float](repeating: 0, count: duration)
        var phase: Float = 0

        for i in 0..<duration {
            let env = 0.06 * max(0, powf(0.001, Float(i) / Float(duration)))
            samples[i] = sinf(phase) * env
            phase += 2.0 * .pi * 600.0 / sr
        }
        playSFX(samples, sampleRate: sr)
    }

    // MARK: - Private: Playback

    private func beginPlayback(buffer: AVAudioPCMBuffer?) {
        guard let buffer else { isPlaying = false; return }

        let eng = AVAudioEngine()
        let player = AVAudioPlayerNode()
        eng.attach(player)
        eng.connect(player, to: eng.mainMixerNode, format: buffer.format)
        eng.mainMixerNode.outputVolume = 0  // start silent; fade in via applyMixerFadeIn

        do { try eng.start() } catch { isPlaying = false; return }

        musicEngine = eng
        musicPlayer = player
        scheduleBufferWithChaining(player: player, buffer: buffer)
        player.play()
        applyMixerFadeIn(engine: eng, targetVolume: isMuted ? 0 : volume, duration: 3.0)
        prefetchNextBuffer()
    }

    private func scheduleBufferWithChaining(player: AVAudioPlayerNode, buffer: AVAudioPCMBuffer) {
        player.scheduleBuffer(buffer, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isPlaying, let player = self.musicPlayer else { return }
                if let next = self.nextBuffer {
                    self.nextBuffer = nil
                    self.scheduleBufferWithChaining(player: player, buffer: next)
                    self.prefetchNextBuffer()
                } else {
                    // Fallback: reschedule same buffer seamlessly (no fade-in)
                    self.scheduleBufferWithChaining(player: player, buffer: buffer)
                }
            }
        }
    }

    private func prefetchNextBuffer() {
        guard !isPrerendering else { return }
        isPrerendering = true
        Task.detached(priority: .background) { [weak self] in
            let buf = Self.renderLoopBuffer(sampleRate: 44100)
            await MainActor.run { [weak self] in
                guard let self, self.isPlaying else { return }
                self.nextBuffer = buf
                self.isPrerendering = false
            }
        }
    }

    private func applyMixerFadeIn(engine: AVAudioEngine, targetVolume: Float, duration: Double) {
        let steps = 60
        let stepDuration = duration / Double(steps)
        var step = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak engine] timer in
            guard let engine else { timer.invalidate(); return }
            step += 1
            engine.mainMixerNode.outputVolume = Float(step) / Float(steps) * targetVolume
            if step >= steps { timer.invalidate() }
        }
    }

    private func playSFX(_ samples: [Float], sampleRate: Float) {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channelData = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        for i in 0..<samples.count { channelData[i] = samples[i] }

        // Lazy-init a shared SFX engine
        if sfxEngine == nil {
            let eng = AVAudioEngine()
            let mixer = AVAudioMixerNode()
            eng.attach(mixer)
            eng.connect(mixer, to: eng.mainMixerNode, format: nil)
            try? eng.start()
            sfxEngine = eng
            sfxMixer = mixer
        }

        guard let eng = sfxEngine else { return }
        let player = AVAudioPlayerNode()
        eng.attach(player)
        eng.connect(player, to: eng.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil) {
            DispatchQueue.main.async { [weak eng] in eng?.detach(player) }
        }
        player.play()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: - Pre-Render Loop Buffer (runs off main thread)

    nonisolated private static func renderLoopBuffer(sampleRate: Float) -> AVAudioPCMBuffer? {
        // ── Timing ──────────────────────────────────────────────────────────
        let bpm: Float = 72
        let beatDur = 60.0 / bpm
        let barDur  = beatDur * 4.0
        let chordDur = barDur * 2.0

        let chords: [[Float]] = [
            [130.81, 164.81, 196.00, 246.94, 293.66],   // Cmaj9
            [110.00, 130.81, 164.81, 196.00, 261.63],   // Am11
            [174.61, 220.00, 261.63, 329.63, 392.00],   // Fmaj9
            [146.83, 174.61, 220.00, 261.63, 329.63],   // Dm9
            [164.81, 196.00, 246.94, 293.66],            // Em7
            [110.00, 130.81, 164.81, 196.00, 246.94],   // Am9
            [146.83, 174.61, 220.00, 261.63],            // Dm7
            [98.00, 123.47, 146.83, 174.61, 220.00, 329.63] // G13
        ]
        let bassNotes: [Float] = [65.41, 55.00, 87.31, 73.42, 82.41, 55.00, 73.42, 49.00]
        let melodyPools: [[Float]] = [
            [523.25, 587.33, 659.25, 783.99, 880.00],
            [440.00, 523.25, 587.33, 659.25, 783.99],
            [349.23, 440.00, 523.25, 587.33, 659.25],
            [293.66, 349.23, 440.00, 523.25, 587.33],
            [329.63, 392.00, 440.00, 523.25, 659.25],
            [440.00, 523.25, 587.33, 659.25, 783.99],
            [293.66, 349.23, 440.00, 523.25, 587.33],
            [392.00, 440.00, 523.25, 587.33, 783.99]
        ]
        let arpPatterns: [[Float]] = [
            [0, 1.5, 3, 4.5, 5.5, 7],
            [0, 2, 3.5, 5, 6, 7.5],
            [0.5, 1.5, 3, 4, 5.5, 7],
            [0, 1, 2.5, 4, 5.5, 6.5],
            [0, 1.5, 2.5, 4, 5, 7]
        ]

        let cycleDur = Float(chords.count) * chordDur
        let numSamples = Int(cycleDur * sampleRate)
        let beatSamples  = Int(beatDur * sampleRate)
        let barSamples   = Int(barDur  * sampleRate)
        let chordSamples = Int(chordDur * sampleRate)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)),
              let data = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = AVAudioFrameCount(numSamples)
        for i in 0..<numSamples { data[i] = 0 }

        // ── Render each chord ────────────────────────────────────────────────
        for (ci, chord) in chords.enumerated() {
            let cs = ci * chordSamples

            // Pad: two detuned triangle oscillators per chord note
            for freq in chord {
                for detuneCents: Float in [-4, 4] {
                    let dr = powf(2.0, detuneCents / 1200.0)
                    renderPad(into: data, total: numSamples,
                              freq: freq * dr, perNote: Float(chord.count),
                              start: cs, dur: chordSamples, sr: sampleRate)
                }
            }

            // Bass
            renderBass(into: data, total: numSamples,
                       freq: bassNotes[ci], start: cs, dur: chordSamples, sr: sampleRate)

            // Drums — 8 beats per chord (2 bars × 4 beats)
            for beat in 0..<8 {
                let t = cs + beat * beatSamples
                if beat == 0 || beat == 4 { renderKick(into: data, total: numSamples, start: t, sr: sampleRate) }
                if beat == 3 && Float.random(in: 0...1) > 0.3 { renderKick(into: data, total: numSamples, start: t, sr: sampleRate) }
                if beat == 6 && Float.random(in: 0...1) > 0.6 { renderKick(into: data, total: numSamples, start: t + beatSamples / 2, sr: sampleRate) }
                if beat == 2 || beat == 6 { renderSnare(into: data, total: numSamples, start: t, sr: sampleRate) }
                renderHihat(into: data, total: numSamples, start: t, open: beat % 4 == 0, sr: sampleRate)
                if Float.random(in: 0...1) > 0.4 {
                    renderHihat(into: data, total: numSamples,
                                start: t + Int(Float(beatSamples) * 0.5 + 0.035 * sampleRate),
                                open: false, sr: sampleRate)
                }
                if Float.random(in: 0...1) > 0.7 {
                    renderHihat(into: data, total: numSamples, start: t + beatSamples / 4, open: false, sr: sampleRate)
                }
            }

            // Arp
            let pat = arpPatterns[ci % arpPatterns.count]
            for (ni, beatOff) in pat.enumerated() {
                let noteStart = cs + Int(beatOff * Float(beatSamples))
                let vel = Float.random(in: 0.6...1.0)
                renderArp(into: data, total: numSamples,
                          freq: chord[ni % chord.count], start: noteStart, velocity: vel, sr: sampleRate)
            }

            // Melody: sparse ~40% on second bar of each chord
            if Float.random(in: 0...1) < 0.4 {
                renderMelody(into: data, total: numSamples,
                             pool: melodyPools[ci], start: cs + barSamples,
                             barSamples: barSamples, beatSamples: beatSamples, sr: sampleRate)
            }
        }

        // Vinyl texture (entire loop)
        renderVinyl(into: data, total: numSamples)

        // Post-process: delay → compressor → master gain
        applyDelay(into: data, total: numSamples, sampleRate: sampleRate)
        applyCompressor(into: data, total: numSamples)

        for i in 0..<numSamples { data[i] *= 0.30 }

        return buffer
    }

    // MARK: - Pad (warm triangle + rising lowpass, long ADSR)

    nonisolated private static func renderPad(into buf: UnsafeMutablePointer<Float>, total: Int,
                                   freq: Float, perNote: Float,
                                   start: Int, dur: Int, sr: Float) {
        var phase: Float = 0
        var filterState: Float = 0
        let attackSamples = Int(1.2 * sr)
        let releaseSamples = Int(1.0 * sr)
        let sustainSamples = max(0, dur - attackSamples - releaseSamples)
        let peakGain: Float = 0.06 / perNote

        for i in 0..<dur {
            let idx = start + i
            guard idx < total else { break }

            // Triangle waveform
            let norm = (phase / (2.0 * .pi)).truncatingRemainder(dividingBy: 1.0)
            let raw: Float = norm < 0.5 ? 4.0 * norm - 1.0 : 3.0 - 4.0 * norm

            // Sweeping lowpass: opens from 600→900 Hz, closes back to 500 Hz
            let filterTarget: Float
            let openLen = Int(1.5 * sr)
            if i < openLen {
                filterTarget = 600 + 400 * Float(i) / Float(openLen)
            } else {
                filterTarget = max(500, 1000 - 500 * Float(i - openLen) / Float(max(1, dur - openLen)))
            }
            let coeff = min(1.0, filterTarget * 2.0 * .pi / sr)
            filterState += (raw - filterState) * coeff

            // ADSR envelope
            let env: Float
            if i < attackSamples {
                env = Float(i) / Float(attackSamples) * peakGain
            } else if i < attackSamples + sustainSamples {
                env = peakGain * 0.833
            } else {
                let t = Float(i - attackSamples - sustainSamples) / Float(max(1, releaseSamples))
                env = peakGain * 0.833 * max(0, 1.0 - t)
            }

            buf[idx] += filterState * env

            phase += 2.0 * .pi * freq / sr
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        }
    }

    // MARK: - Bass (sine with pitch slide + soft clip + lowpass)

    nonisolated private static func renderBass(into buf: UnsafeMutablePointer<Float>, total: Int,
                                    freq: Float, start: Int, dur: Int, sr: Float) {
        var phase: Float = 0
        var filterState: Float = 0
        let attackSamples = Int(0.06 * sr)
        let sustainEnd = Int(Float(dur) * 0.7)
        let slideLen = Int(0.08 * sr)
        let filterCoeff = min(1.0, 200.0 * 2.0 * .pi / sr)

        for i in 0..<dur {
            let idx = start + i
            guard idx < total else { break }

            // Pitch slide: freq*1.02 → freq over first 80ms
            let progress = Float(min(i, slideLen)) / Float(slideLen)
            let currentFreq = freq * (1.02 - 0.02 * progress)

            let raw = sinf(phase)

            // Soft clip (arctan-ish: x*(π+2)/(π+2|x|))
            let clipped = raw * (Float.pi + 2) / (Float.pi + 2 * abs(raw))

            // Lowpass at 200 Hz
            filterState += (clipped - filterState) * filterCoeff

            // Envelope
            let env: Float
            if i < attackSamples {
                env = Float(i) / Float(attackSamples) * 0.14
            } else if i < sustainEnd {
                env = 0.10
            } else {
                let t = Float(i - sustainEnd) / Float(max(1, dur - sustainEnd))
                env = 0.10 * max(0, 1.0 - t)
            }

            buf[idx] += filterState * env

            phase += 2.0 * .pi * currentFreq / sr
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        }
    }

    // MARK: - Electric Piano Arp (sine fundamental + 2nd harmonic)

    nonisolated private static func renderArp(into buf: UnsafeMutablePointer<Float>, total: Int,
                                   freq: Float, start: Int, velocity: Float, sr: Float) {
        let vol = 0.04 * velocity
        let durSamples = Int(2.0 * sr)
        let attackSamples = Int(0.008 * sr)
        let halfDecay = Int(0.4 * sr)

        var phase1: Float = 0
        var phase2: Float = 0

        for i in 0..<durSamples {
            let idx = start + i
            guard idx >= 0 && idx < total else {
                if idx >= total { break }
                continue
            }

            // Envelope: fast attack, two-stage exponential decay
            let env: Float
            if i < attackSamples {
                env = Float(i) / Float(attackSamples) * vol
            } else if i < halfDecay {
                let t = Float(i - attackSamples) / Float(max(1, halfDecay - attackSamples))
                env = vol - (vol - vol * 0.3) * t
            } else {
                let t = Float(i - halfDecay) / Float(max(1, durSamples - halfDecay))
                env = vol * 0.3 * max(0, powf(0.001, t))
            }

            buf[idx] += (sinf(phase1) + sinf(phase2) * 0.15) * env

            phase1 += 2.0 * .pi * freq / sr
            phase2 += 2.0 * .pi * (freq * 2) / sr
            if phase1 > 2.0 * .pi { phase1 -= 2.0 * .pi }
            if phase2 > 2.0 * .pi { phase2 -= 2.0 * .pi }
        }
    }

    // MARK: - Melody (sparse pentatonic sine notes)

    nonisolated private static func renderMelody(into buf: UnsafeMutablePointer<Float>, total: Int,
                                      pool: [Float], start: Int,
                                      barSamples: Int, beatSamples: Int, sr: Float) {
        let halfBeat = beatSamples / 2
        let offsets = [0, halfBeat, beatSamples, halfBeat + beatSamples,
                       beatSamples * 2, halfBeat + beatSamples * 2,
                       beatSamples * 3, halfBeat + beatSamples * 3]
        let numNotes = Int.random(in: 2...4)
        let chosen = offsets.shuffled().prefix(numNotes).sorted()

        var lastIdx = Int.random(in: 0..<pool.count)

        for offset in chosen {
            let noteStart = start + offset
            if noteStart >= start + barSamples - Int(0.5 * sr) { continue }
            let step = Int.random(in: 0...2) - 1
            lastIdx = max(0, min(pool.count - 1, lastIdx + step))
            let freq = pool[lastIdx]

            let noteDur = Int(1.8 * sr)
            let noteVol = Float.random(in: 0.018...0.030)
            let attackLen = Int(0.01 * sr)
            let halfDecay = Int(0.5 * sr)
            var phase: Float = 0

            for i in 0..<noteDur {
                let idx = noteStart + i
                guard idx >= 0 && idx < total else {
                    if idx >= total { break }
                    continue
                }
                let env: Float
                if i < attackLen {
                    env = Float(i) / Float(attackLen) * noteVol
                } else if i < halfDecay {
                    let t = Float(i - attackLen) / Float(max(1, halfDecay - attackLen))
                    env = noteVol * (1.0 - 0.6 * t)
                } else {
                    let t = Float(i - halfDecay) / Float(max(1, noteDur - halfDecay))
                    env = noteVol * 0.4 * max(0, powf(0.001, t))
                }
                buf[idx] += sinf(phase) * env
                phase += 2.0 * .pi * freq / sr
            }
        }
    }

    // MARK: - Drums

    nonisolated private static func renderKick(into buf: UnsafeMutablePointer<Float>, total: Int,
                                    start: Int, sr: Float) {
        let durSamples  = Int(0.4  * sr)
        let sweepLen    = Int(0.12 * sr)  // freq sweep: 150 → 40 Hz
        let gainRampEnd = Int(0.35 * sr)  // gain ramp: 0.22 → 0.001
        let clickLen    = Int(0.015 * sr)
        var kickPhase: Float = 0

        for i in 0..<durSamples {
            let idx = start + i
            guard idx >= 0 && idx < total else {
                if idx >= total { break }
                continue
            }

            // Exponential frequency sweep (matches JS exponentialRampToValueAtTime)
            // freq = 150 * (40/150)^(i/sweepLen)
            let freq: Float = i < sweepLen
                ? 150.0 * powf(40.0 / 150.0, Float(i) / Float(sweepLen))
                : 40.0

            // Exponential gain decay: 0.22 → 0.001 over 350ms (matches JS)
            let env: Float = i < gainRampEnd
                ? 0.22 * powf(0.001 / 0.22, Float(i) / Float(gainRampEnd))
                : 0.001

            buf[idx] += sinf(kickPhase) * env
            kickPhase += 2.0 * .pi * freq / sr
            if kickPhase > 2.0 * .pi { kickPhase -= 2.0 * .pi }

            // Click transient: square at 800 Hz, exponential decay 0.06 → 0.001 over 15ms
            if i < clickLen {
                let clickEnv = 0.06 * powf(0.001 / 0.06, Float(i) / Float(max(1, clickLen)))
                let cPhase = Float(i) * 2.0 * .pi * 800.0 / sr
                buf[idx] += (cPhase.truncatingRemainder(dividingBy: 2.0 * .pi) < .pi ? 1.0 : -1.0) * clickEnv
            }
        }
    }

    nonisolated private static func renderHihat(into buf: UnsafeMutablePointer<Float>, total: Int,
                                     start: Int, open: Bool, sr: Float) {
        let dur = open ? Int(0.2 * sr) : Int(0.06 * sr)
        let vol = Float.random(in: 0.025...0.040)

        for i in 0..<dur {
            let idx = start + i
            guard idx >= 0 && idx < total else {
                if idx >= total { break }
                continue
            }
            let env = max(0, powf(0.001, Float(i) / Float(max(1, dur))))
            buf[idx] += Float.random(in: -1...1) * vol * env
        }
    }

    nonisolated private static func renderSnare(into buf: UnsafeMutablePointer<Float>, total: Int,
                                     start: Int, sr: Float) {
        // Noise body
        let noiseDur = Int(0.15 * sr)
        for i in 0..<noiseDur {
            let idx = start + i
            guard idx >= 0 && idx < total else {
                if idx >= total { break }
                continue
            }
            let env = 0.08 * max(0, powf(0.001, Float(i) / Float(noiseDur)))
            buf[idx] += Float.random(in: -1...1) * env
        }
        // Triangle tone body at 180 Hz
        let toneDur = Int(0.08 * sr)
        var phase: Float = 0
        for i in 0..<toneDur {
            let idx = start + i
            guard idx >= 0 && idx < total else {
                if idx >= total { break }
                continue
            }
            let env = 0.08 * max(0, powf(0.001, Float(i) / Float(toneDur)))
            let norm = (phase / (2.0 * .pi)).truncatingRemainder(dividingBy: 1.0)
            let tri = norm < 0.5 ? 4.0 * norm - 1.0 : 3.0 - 4.0 * norm
            buf[idx] += tri * env
            phase += 2.0 * .pi * 180.0 / sr
        }
    }

    // MARK: - Vinyl Texture

    nonisolated private static func renderVinyl(into buf: UnsafeMutablePointer<Float>, total: Int) {
        for i in 0..<total {
            buf[i] += Float.random(in: -1...1) * 0.006
        }
    }

    // MARK: - Stereo Delay (ping-pong collapsed to mono)

    nonisolated private static func applyDelay(into buf: UnsafeMutablePointer<Float>, total: Int, sampleRate: Float) {
        let delayLen = Int(0.375 * sampleRate)
        var delayBuf = [Float](repeating: 0, count: delayLen)
        var writePos = 0
        let feedback: Float = 0.22
        let wet: Float = 0.35

        // Low-pass on delay tail at ~2200 Hz (as in JS)
        var lpState: Float = 0
        let lpCoeff = min(1.0, 2200.0 * 2.0 * .pi / sampleRate)

        for i in 0..<total {
            let delayed = delayBuf[writePos]
            lpState += (delayed - lpState) * lpCoeff
            let newDelay = buf[i] * wet + lpState * feedback
            delayBuf[writePos] = newDelay
            buf[i] += lpState * wet
            writePos = (writePos + 1) % delayLen
        }
    }

    // MARK: - Dynamics Compressor

    nonisolated private static func applyCompressor(into buf: UnsafeMutablePointer<Float>, total: Int) {
        let threshold: Float = powf(10, -18.0 / 20.0)
        let ratio: Float = 4.0
        let sampleRate: Float = 44100
        let attackCoeff  = 1.0 - expf(-1.0 / (0.003 * sampleRate))
        let releaseCoeff = 1.0 - expf(-1.0 / (0.15  * sampleRate))
        var envelope: Float = 0

        for i in 0..<total {
            let level = abs(buf[i])
            envelope += (level > envelope ? attackCoeff : releaseCoeff) * (level - envelope)
            if envelope > threshold {
                let excess = envelope / threshold
                buf[i] *= threshold * powf(excess, 1.0 / ratio) / envelope
            }
        }
    }
}
