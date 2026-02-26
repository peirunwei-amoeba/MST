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

enum AmbientVibe: String, CaseIterable, Identifiable {
    case whiteNoise = "White Noise"
    case brownNoise = "Brown Noise"
    case rain = "Rain"
    case nature = "Nature"
    case lofi = "Lo-Fi"
    case piano = "Piano"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .whiteNoise: return "waveform"
        case .brownNoise: return "wind"
        case .rain: return "cloud.rain.fill"
        case .nature: return "leaf.fill"
        case .lofi: return "headphones"
        case .piano: return "pianokeys"
        }
    }
}

@Observable @MainActor
final class AmbientMusicEngine {
    var isPlaying = false
    var currentVibe: AmbientVibe?
    var volume: Float = 0.5

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    // Internal state for procedural generation (accessed from render thread)
    private let renderState = RenderState()

    func play(vibe: AmbientVibe) {
        stop()
        currentVibe = vibe

        configureAudioSession()

        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let state = renderState
        state.reset()
        state.sampleRate = Float(sampleRate)
        state.vibeIndex = AmbientVibe.allCases.firstIndex(of: vibe) ?? 0
        state.volume = volume

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let buffer = ablPointer.first?.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            let frames = Int(frameCount)
            state.render(into: buffer, frameCount: frames)
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume

        do {
            try engine.start()
            audioEngine = engine
            sourceNode = source
            isPlaying = true
        } catch {
            audioEngine = nil
            sourceNode = nil
        }
    }

    func stop() {
        audioEngine?.stop()
        if let source = sourceNode {
            audioEngine?.detach(source)
        }
        audioEngine = nil
        sourceNode = nil
        isPlaying = false
        currentVibe = nil
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioEngine?.mainMixerNode.outputVolume = newVolume
        renderState.volume = newVolume
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}

// MARK: - Render State (thread-safe, lock-free via atomic-like usage)

private final class RenderState: @unchecked Sendable {
    var sampleRate: Float = 44100
    var vibeIndex: Int = 0
    var volume: Float = 0.5

    // Brown noise state
    private var brownValue: Float = 0

    // Nature chirp state
    private var chirpPhase: Float = 0
    private var chirpFreq: Float = 0
    private var chirpRemaining: Int = 0
    private var chirpCooldown: Int = 0

    // Lo-Fi state
    private var lofiPhase: Float = 0
    private var lofiNoteFreq: Float = 220
    private var lofiNoteSamples: Int = 0
    private var lofiNoteRemaining: Int = 0
    private var lofiEnvelope: Float = 0

    // Piano state
    private struct PianoNote {
        var phase: Float = 0
        var freq: Float = 0
        var amplitude: Float = 0
        var decay: Float = 0.9999
    }
    private var pianoNotes: [PianoNote] = []
    private var pianoCooldown: Int = 0

    // Rain drop state
    private var dropAmplitude: Float = 0
    private var dropDecay: Float = 0.999

    // Pentatonic scale frequencies
    private let pentatonic: [Float] = [
        261.63, 293.66, 329.63, 392.00, 440.00,  // C4-A4
        523.25, 587.33, 659.25, 783.99, 880.00   // C5-A5
    ]

    func reset() {
        brownValue = 0
        chirpPhase = 0
        chirpFreq = 0
        chirpRemaining = 0
        chirpCooldown = Int.random(in: 8000...20000)
        lofiPhase = 0
        lofiNoteFreq = 220
        lofiNoteSamples = 0
        lofiNoteRemaining = 0
        lofiEnvelope = 0
        pianoNotes = []
        pianoCooldown = Int.random(in: 4000...12000)
        dropAmplitude = 0
        dropDecay = 0.999
    }

    func render(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        let vibe = AmbientVibe.allCases[vibeIndex]
        switch vibe {
        case .whiteNoise:
            renderWhiteNoise(into: buffer, frameCount: frameCount)
        case .brownNoise:
            renderBrownNoise(into: buffer, frameCount: frameCount)
        case .rain:
            renderRain(into: buffer, frameCount: frameCount)
        case .nature:
            renderNature(into: buffer, frameCount: frameCount)
        case .lofi:
            renderLoFi(into: buffer, frameCount: frameCount)
        case .piano:
            renderPiano(into: buffer, frameCount: frameCount)
        }
    }

    // MARK: - White Noise

    private func renderWhiteNoise(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            buffer[i] = Float.random(in: -1...1) * 0.3
        }
    }

    // MARK: - Brown Noise

    private func renderBrownNoise(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            brownValue += Float.random(in: -1...1) * 0.02
            brownValue = max(-1, min(1, brownValue)) * 0.998 // slight decay to center
            buffer[i] = brownValue * 0.5
        }
    }

    // MARK: - Rain

    private func renderRain(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            // Base rain (filtered white noise)
            var sample = Float.random(in: -1...1) * 0.15

            // Random drop impacts
            if Float.random(in: 0...1) < 0.001 {
                dropAmplitude = Float.random(in: 0.3...0.7)
                dropDecay = Float.random(in: 0.995...0.9995)
            }

            if dropAmplitude > 0.01 {
                sample += Float.random(in: -1...1) * dropAmplitude
                dropAmplitude *= dropDecay
            }

            buffer[i] = sample * 0.4
        }
    }

    // MARK: - Nature

    private func renderNature(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            // Brown noise base (wind)
            brownValue += Float.random(in: -1...1) * 0.015
            brownValue = max(-1, min(1, brownValue)) * 0.998
            var sample = brownValue * 0.3

            // Occasional bird chirp
            if chirpCooldown > 0 {
                chirpCooldown -= 1
            } else if chirpRemaining <= 0 {
                chirpFreq = Float.random(in: 1800...4000)
                chirpRemaining = Int.random(in: 800...2000)
                chirpPhase = 0
            }

            if chirpRemaining > 0 {
                let env = Float(chirpRemaining) / 2000.0
                sample += sin(chirpPhase) * env * 0.08
                chirpPhase += (2.0 * .pi * chirpFreq) / sampleRate
                chirpFreq *= 1.0001 // slight frequency rise
                chirpRemaining -= 1
                if chirpRemaining == 0 {
                    chirpCooldown = Int.random(in: 15000...40000)
                }
            }

            buffer[i] = sample
        }
    }

    // MARK: - Lo-Fi

    private func renderLoFi(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            // Noise bed
            var sample = Float.random(in: -1...1) * 0.04

            // Trigger new note
            if lofiNoteRemaining <= 0 {
                lofiNoteFreq = pentatonic[Int.random(in: 0..<pentatonic.count)] * 0.5
                lofiNoteSamples = Int.random(in: Int(sampleRate * 0.8)...Int(sampleRate * 2.0))
                lofiNoteRemaining = lofiNoteSamples
                lofiPhase = 0
                lofiEnvelope = 1.0
            }

            // Sine wave with soft decay
            let t = Float(lofiNoteSamples - lofiNoteRemaining) / Float(lofiNoteSamples)
            lofiEnvelope = max(0, 1.0 - t * t) // quadratic decay
            sample += sin(lofiPhase) * lofiEnvelope * 0.25
            // Add slight detuning harmonic
            sample += sin(lofiPhase * 2.003) * lofiEnvelope * 0.05

            lofiPhase += (2.0 * .pi * lofiNoteFreq) / sampleRate
            lofiNoteRemaining -= 1

            buffer[i] = sample
        }
    }

    // MARK: - Piano

    private func renderPiano(into buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            var sample: Float = 0

            // Trigger new note
            if pianoCooldown > 0 {
                pianoCooldown -= 1
            } else {
                let freq = pentatonic[Int.random(in: 0..<pentatonic.count)]
                let note = PianoNote(
                    phase: 0,
                    freq: freq,
                    amplitude: Float.random(in: 0.15...0.3),
                    decay: 0.99995
                )
                pianoNotes.append(note)
                pianoCooldown = Int.random(in: Int(sampleRate * 0.5)...Int(sampleRate * 2.5))
            }

            // Render active notes
            var j = 0
            while j < pianoNotes.count {
                let phase = pianoNotes[j].phase
                let amp = pianoNotes[j].amplitude

                // Sine with harmonics for piano-like timbre
                sample += sin(phase) * amp
                sample += sin(phase * 2.0) * amp * 0.3
                sample += sin(phase * 3.0) * amp * 0.1

                pianoNotes[j].phase += (2.0 * .pi * pianoNotes[j].freq) / sampleRate
                pianoNotes[j].amplitude *= pianoNotes[j].decay

                if pianoNotes[j].amplitude < 0.001 {
                    pianoNotes.remove(at: j)
                } else {
                    j += 1
                }
            }

            buffer[i] = sample
        }
    }
}
