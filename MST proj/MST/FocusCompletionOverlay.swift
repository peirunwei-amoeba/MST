//
//  FocusCompletionOverlay.swift
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

import SwiftUI
import AVFoundation

struct FocusCompletionOverlay: View {
    let taskTitle: String?
    let onComplete: () -> Void
    let onDismiss: () -> Void

    // Long press animation states
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var completionBounce = false
    @State private var showRipple = false
    @State private var hapticTimer: Timer?
    @State private var holdStartTime: Date?
    @State private var isCompleted = false

    private let holdDuration: Double = 1.2
    private let checkmarkSize: CGFloat = 120
    private let minimumHoldToShowProgress: Double = 0.06

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                VStack(spacing: 12) {
                    Text("Session Complete!")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white)

                    if let title = taskTitle {
                        Text(title)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }

                // Giant checkmark with progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 6)
                        .frame(width: checkmarkSize + 30, height: checkmarkSize + 30)

                    // Progress ring (fills during hold)
                    if holdProgress > 0 && isHolding {
                        Circle()
                            .trim(from: 0, to: holdProgress)
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: checkmarkSize + 30, height: checkmarkSize + 30)
                            .rotationEffect(.degrees(-90))
                    }

                    // Ripple effect on completion
                    if showRipple {
                        Circle()
                            .stroke(Color.green.opacity(0.6), lineWidth: 4)
                            .frame(width: checkmarkSize + 30, height: checkmarkSize + 30)
                            .scaleEffect(showRipple ? 2.0 : 1.0)
                            .opacity(showRipple ? 0 : 1)
                    }

                    // Checkmark icon
                    Image(systemName: completionBounce ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: checkmarkSize, weight: .medium))
                        .foregroundStyle(completionBounce ? .green : (isHolding && holdProgress > 0) ? .green.opacity(0.4 + holdProgress * 0.6) : .white.opacity(0.4))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                        .scaleEffect(completionBounce ? 1.35 : (isHolding ? 1.0 + holdProgress * 0.15 : 1.0))
                        .rotationEffect(.degrees(completionBounce ? 10 : (isHolding ? holdProgress * 8 : 0)))
                }
                .contentShape(Circle())
                .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 80) {
                    // Long press completed
                    completeSession()
                } onPressingChanged: { pressing in
                    if isCompleted { return }

                    if pressing {
                        startHolding()
                    } else {
                        if !completionBounce {
                            cancelHolding()
                        }
                    }
                }

                // Instructions
                Text(isHolding ? "Keep holding..." : "Hold to complete")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .animation(.easeInOut, value: isHolding)

                Spacer()

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Skip")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Holding Logic

    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true
        holdStartTime = Date()

        // Delay showing progress slightly to avoid flash on quick tap
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumHoldToShowProgress) {
            guard isHolding else { return }

            // Start progressive animation
            withAnimation(.linear(duration: holdDuration - minimumHoldToShowProgress)) {
                holdProgress = 1.0
            }

            // Start haptic feedback timer
            startHapticFeedback()
        }
    }

    private func cancelHolding() {
        isHolding = false
        holdStartTime = nil
        hapticTimer?.invalidate()
        hapticTimer = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            holdProgress = 0
        }
    }

    private func completeSession() {
        isCompleted = true
        hapticTimer?.invalidate()
        hapticTimer = nil
        isHolding = false
        holdStartTime = nil

        // Final celebration haptic and sound
        let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        heavyFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1407)
        }

        // Bounce animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            completionBounce = true
        }

        // Ripple effect
        withAnimation(.easeOut(duration: 0.8)) {
            showRipple = true
        }

        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                holdProgress = 0
            }
            showRipple = false

            // Trigger completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }

    // MARK: - Progressive Haptic Feedback

    private func startHapticFeedback() {
        var pulseCount = 0
        let totalPulses = 16
        let interval = (holdDuration - minimumHoldToShowProgress) / Double(totalPulses)

        // First haptic immediately
        let initialGenerator = UIImpactFeedbackGenerator(style: .light)
        initialGenerator.impactOccurred()

        hapticTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            guard isHolding else {
                timer.invalidate()
                return
            }

            pulseCount += 1

            // Progressively stronger haptics
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            let intensity: CGFloat

            if pulseCount <= 3 {
                style = .light
                intensity = 0.5 + CGFloat(pulseCount) * 0.1
            } else if pulseCount <= 7 {
                style = .medium
                intensity = 0.6 + CGFloat(pulseCount - 3) * 0.1
            } else if pulseCount <= 12 {
                style = .medium
                intensity = 0.8 + CGFloat(pulseCount - 7) * 0.04
            } else {
                style = .heavy
                intensity = 1.0
            }

            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred(intensity: intensity)

            if pulseCount >= totalPulses {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    FocusCompletionOverlay(
        taskTitle: "Read 30 pages",
        onComplete: {},
        onDismiss: {}
    )
}
