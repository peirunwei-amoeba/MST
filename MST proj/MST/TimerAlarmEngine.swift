//
//  TimerAlarmEngine.swift
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
import UIKit

@Observable @MainActor
final class TimerAlarmEngine {

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var autoStopTask: Task<Void, Never>?

    func play(sound: TimerAlarmSound, withVibration: Bool) {
        stop()

        let newEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        newEngine.attach(player)

        let sampleRate = newEngine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        newEngine.connect(player, to: newEngine.mainMixerNode, format: format)

        guard let buffer = AlarmSynthesizer.buildBuffer(sound: sound, sampleRate: sampleRate, format: format) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try newEngine.start()
        } catch {
            return
        }

        engine = newEngine
        playerNode = player

        // Schedule 3 repetitions
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()

        if withVibration {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        let totalDuration = Double(buffer.frameLength) / sampleRate * 3.0 + 0.5
        autoStopTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(totalDuration))
            self?.stop()
        }
    }

    func stop() {
        autoStopTask?.cancel()
        autoStopTask = nil
        playerNode?.stop()
        engine?.stop()
        playerNode = nil
        engine = nil
    }
}

private struct AlarmNote {
    var frequency: Double
    var duration: Double
    var amplitude: Float
    var attackRatio: Double
    var decayRatio: Double
    var vibratoDepth: Double = 0
    var vibratoRate: Double = 0
}

private enum AlarmSynthesizer {

    static func buildBuffer(sound: TimerAlarmSound, sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let notes = notes(for: sound)
        let totalFrames = AVAudioFrameCount(notes.reduce(0.0) { $0 + $1.duration } * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return nil }
        buffer.frameLength = totalFrames

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        var frameOffset = 0
        for note in notes {
            if note.frequency == 0 {
                // Rest
                let frames = Int(note.duration * sampleRate)
                for i in 0..<frames {
                    if frameOffset + i < Int(totalFrames) {
                        channelData[frameOffset + i] = 0
                    }
                }
                frameOffset += frames
                continue
            }

            let frames = Int(note.duration * sampleRate)
            let attackFrames = Int(Double(frames) * note.attackRatio)
            let decayFrames = Int(Double(frames) * note.decayRatio)
            var sinePhase = 0.0
            var vibratoPhase = 0.0

            for i in 0..<frames {
                if frameOffset + i >= Int(totalFrames) { break }

                // Envelope
                let env: Float
                if i < attackFrames {
                    env = Float(i) / Float(max(attackFrames, 1))
                } else if i > frames - decayFrames {
                    env = Float(frames - i) / Float(max(decayFrames, 1))
                } else {
                    env = 1.0
                }

                // Vibrato
                let vibrato = note.vibratoDepth * sin(vibratoPhase * 2 * .pi)
                let freq = note.frequency * (1 + vibrato)

                // Sample
                let sample = note.amplitude * env * Float(sin(sinePhase * 2 * .pi))
                channelData[frameOffset + i] = sample

                sinePhase += freq / sampleRate
                if sinePhase >= 1 { sinePhase -= 1 }
                vibratoPhase += note.vibratoRate / sampleRate
                if vibratoPhase >= 1 { vibratoPhase -= 1 }
            }
            frameOffset += frames
        }

        return buffer
    }

    static func notes(for sound: TimerAlarmSound) -> [AlarmNote] {
        switch sound {
        case .none:
            return []
        case .bloom:
            return [
                AlarmNote(frequency: 523, duration: 0.25, amplitude: 0.6, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 659, duration: 0.25, amplitude: 0.65, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 784, duration: 0.4, amplitude: 0.7, attackRatio: 0.1, decayRatio: 0.5),
            ]
        case .calypso:
            return [
                AlarmNote(frequency: 392, duration: 0.18, amplitude: 0.6, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 440, duration: 0.18, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 523, duration: 0.18, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 659, duration: 0.3, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.5),
            ]
        case .chooChoo:
            return [
                AlarmNote(frequency: 440, duration: 0.2, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.3),
                AlarmNote(frequency: 294, duration: 0.2, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.3),
                AlarmNote(frequency: 440, duration: 0.2, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.3),
                AlarmNote(frequency: 294, duration: 0.2, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.3),
            ]
        case .descent:
            return [
                AlarmNote(frequency: 784, duration: 0.25, amplitude: 0.7, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 659, duration: 0.25, amplitude: 0.65, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 523, duration: 0.4, amplitude: 0.6, attackRatio: 0.1, decayRatio: 0.5),
            ]
        case .fanfare:
            return [
                AlarmNote(frequency: 523, duration: 0.15, amplitude: 0.5, attackRatio: 0.05, decayRatio: 0.3),
                AlarmNote(frequency: 659, duration: 0.15, amplitude: 0.6, attackRatio: 0.05, decayRatio: 0.3),
                AlarmNote(frequency: 784, duration: 0.15, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.3),
                AlarmNote(frequency: 1047, duration: 0.35, amplitude: 0.8, attackRatio: 0.05, decayRatio: 0.5),
            ]
        case .ladder:
            return [
                AlarmNote(frequency: 523, duration: 0.15, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.35),
                AlarmNote(frequency: 587, duration: 0.15, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.35),
                AlarmNote(frequency: 659, duration: 0.15, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.35),
                AlarmNote(frequency: 698, duration: 0.25, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.45),
            ]
        case .minuet:
            return [
                AlarmNote(frequency: 659, duration: 0.2, amplitude: 0.65, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 587, duration: 0.2, amplitude: 0.6, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 523, duration: 0.35, amplitude: 0.6, attackRatio: 0.1, decayRatio: 0.5),
            ]
        case .newsFlash:
            return [
                AlarmNote(frequency: 880, duration: 0.15, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.35),
                AlarmNote(frequency: 0, duration: 0.1, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 880, duration: 0.25, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.4),
            ]
        case .noir:
            return [
                AlarmNote(frequency: 196, duration: 0.3, amplitude: 0.7, attackRatio: 0.15, decayRatio: 0.5),
                AlarmNote(frequency: 156, duration: 0.5, amplitude: 0.65, attackRatio: 0.1, decayRatio: 0.6),
            ]
        case .sherwoodForest:
            return [
                AlarmNote(frequency: 523, duration: 0.25, amplitude: 0.65, attackRatio: 0.1, decayRatio: 0.4),
                AlarmNote(frequency: 784, duration: 0.4, amplitude: 0.7, attackRatio: 0.1, decayRatio: 0.5),
            ]
        case .spell:
            return [
                AlarmNote(frequency: 1047, duration: 0.1, amplitude: 0.55, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 1319, duration: 0.1, amplitude: 0.6, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 1568, duration: 0.1, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 1760, duration: 0.1, amplitude: 0.65, attackRatio: 0.05, decayRatio: 0.4),
                AlarmNote(frequency: 2093, duration: 0.2, amplitude: 0.7, attackRatio: 0.05, decayRatio: 0.5),
            ]
        case .suspense:
            return [
                AlarmNote(frequency: 392, duration: 0.7, amplitude: 0.6, attackRatio: 0.15, decayRatio: 0.4, vibratoDepth: 0.008, vibratoRate: 5.0),
            ]
        case .telegraph:
            return [
                AlarmNote(frequency: 880, duration: 0.1, amplitude: 0.7, attackRatio: 0.02, decayRatio: 0.2),
                AlarmNote(frequency: 0, duration: 0.08, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 880, duration: 0.1, amplitude: 0.7, attackRatio: 0.02, decayRatio: 0.2),
                AlarmNote(frequency: 0, duration: 0.12, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 880, duration: 0.3, amplitude: 0.7, attackRatio: 0.02, decayRatio: 0.3),
            ]
        case .tiptoes:
            return [
                AlarmNote(frequency: 659, duration: 0.18, amplitude: 0.28, attackRatio: 0.08, decayRatio: 0.5),
                AlarmNote(frequency: 0, duration: 0.07, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 659, duration: 0.18, amplitude: 0.28, attackRatio: 0.08, decayRatio: 0.5),
                AlarmNote(frequency: 0, duration: 0.07, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 659, duration: 0.25, amplitude: 0.28, attackRatio: 0.08, decayRatio: 0.5),
            ]
        case .typewriters:
            return [
                AlarmNote(frequency: 880, duration: 0.12, amplitude: 0.65, attackRatio: 0.02, decayRatio: 0.3),
                AlarmNote(frequency: 0, duration: 0.08, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 880, duration: 0.12, amplitude: 0.65, attackRatio: 0.02, decayRatio: 0.3),
                AlarmNote(frequency: 0, duration: 0.12, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 587, duration: 0.12, amplitude: 0.6, attackRatio: 0.02, decayRatio: 0.3),
                AlarmNote(frequency: 0, duration: 0.08, amplitude: 0, attackRatio: 0, decayRatio: 0),
                AlarmNote(frequency: 587, duration: 0.12, amplitude: 0.6, attackRatio: 0.02, decayRatio: 0.3),
            ]
        case .update:
            return [
                AlarmNote(frequency: 523, duration: 0.2, amplitude: 0.65, attackRatio: 0.08, decayRatio: 0.4),
                AlarmNote(frequency: 659, duration: 0.3, amplitude: 0.7, attackRatio: 0.08, decayRatio: 0.5),
            ]
        }
    }
}
