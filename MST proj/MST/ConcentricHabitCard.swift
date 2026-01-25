//
//  ConcentricHabitCard.swift
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

struct ConcentricHabitCard: View {
    let habit: Habit
    var isRecentlyCompleted: Bool = false
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    // Long press animation states
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var completionBounce = false
    @State private var showRipple = false
    @State private var hapticTimer: Timer?
    @State private var holdStartTime: Date?

    private let holdDuration: Double = 1.2 // Total hold time required
    private let checkmarkSize: CGFloat = 56
    private let minimumHoldToShowProgress: Double = 0.06 // Only show progress after this delay

    var body: some View {
        Button { onTap() } label: {
            VStack(spacing: 12) {
                // Large checkmark with progress ring
                ZStack {
                    // Background ring (only show when not completed)
                    if !habit.isCompletedToday {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 3)
                            .frame(width: checkmarkSize + 10, height: checkmarkSize + 10)
                    }

                    // Progress ring (fills during hold) - only show if actually holding
                    if holdProgress > 0 && isHolding {
                        Circle()
                            .trim(from: 0, to: holdProgress)
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: checkmarkSize + 10, height: checkmarkSize + 10)
                            .rotationEffect(.degrees(-90))
                    }

                    // Ripple effect on completion
                    if showRipple {
                        Circle()
                            .stroke(Color.green.opacity(0.6), lineWidth: 3)
                            .frame(width: checkmarkSize + 10, height: checkmarkSize + 10)
                            .scaleEffect(showRipple ? 1.8 : 1.0)
                            .opacity(showRipple ? 0 : 1)
                    }

                    // Checkmark icon
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: checkmarkSize, weight: .medium))
                        .foregroundStyle(habit.isCompletedToday ? .green : (isHolding && holdProgress > 0) ? .green.opacity(0.4 + holdProgress * 0.6) : .secondary.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                        .scaleEffect(completionBounce ? 1.35 : (isHolding ? 1.0 + holdProgress * 0.2 : 1.0))
                        .rotationEffect(.degrees(completionBounce ? 10 : (isHolding ? holdProgress * 8 : 0)))
                }
                .contentShape(Circle())
                .onTapGesture {
                    // Tap to uncheck if already completed
                    if habit.isCompletedToday {
                        onToggleComplete()
                    }
                }
                .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 50) {
                    // Long press completed - only for checking (not unchecking)
                    if !habit.isCompletedToday {
                        completeHabit()
                    }
                } onPressingChanged: { pressing in
                    if habit.isCompletedToday { return } // Ignore for completed habits

                    if pressing {
                        startHolding()
                    } else {
                        // Released before completion
                        if !completionBounce {
                            cancelHolding()
                        }
                    }
                }

                VStack(spacing: 4) {
                    Text(habit.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 36)

                    Text(habit.formattedTarget)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Streak indicator
                    HStack(spacing: 2) {
                        if habit.currentStreak > 0 {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(habit.currentStreak)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        } else {
                            Text(" ")
                                .font(.caption2)
                        }
                    }
                    .frame(height: 14)
                }
            }
            .frame(width: 110, height: 150)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            .scaleEffect(isHolding && holdProgress > 0 ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(isRecentlyCompleted ? 0.6 : 1.0)
        .scaleEffect(isRecentlyCompleted ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.3), value: isRecentlyCompleted)
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

    private func completeHabit() {
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

        // Bounce animation (same as other checkmarks)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            completionBounce = true
        }

        // Ripple effect
        withAnimation(.easeOut(duration: 0.6)) {
            showRipple = true
        }

        // Reset after animation (same timing as other checkmarks)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                completionBounce = false
                holdProgress = 0
            }
            showRipple = false

            // Trigger the actual completion
            onToggleComplete()
        }
    }

    // MARK: - Progressive Haptic Feedback

    private func startHapticFeedback() {
        var pulseCount = 0
        let totalPulses = 16 // More pulses for intense feel
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

            // Progressively stronger haptics - ramps up intensity
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
    HStack(spacing: 12) {
        ConcentricHabitCard(
            habit: Habit(title: "Read books", targetValue: 30, unit: .minute),
            onTap: {},
            onToggleComplete: {}
        )

        ConcentricHabitCard(
            habit: Habit(title: "Exercise", targetValue: 1, unit: .hour),
            isRecentlyCompleted: true,
            onTap: {},
            onToggleComplete: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environmentObject(ThemeManager())
}
