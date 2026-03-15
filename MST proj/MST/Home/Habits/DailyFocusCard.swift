//
//  DailyFocusCard.swift
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
import AudioToolbox

struct DailyFocusCard: View {
    let progress: Double        // 0.0 to 1.0+
    let todayMinutes: Int
    let targetMinutes: Int
    var isJustCompleted: Bool = false
    let onTap: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    @State private var completionBounce = false
    @State private var showRipple = false

    private let iconSize: CGFloat = 56
    private var isCompleted: Bool { progress >= 1.0 }

    var body: some View {
        Button { onTap() } label: {
            VStack(spacing: 12) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 3)
                        .frame(width: iconSize + 10, height: iconSize + 10)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(
                            isCompleted ? Color.green : themeManager.accentColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: iconSize + 10, height: iconSize + 10)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)

                    // Ripple effect on completion
                    if showRipple {
                        Circle()
                            .stroke(Color.green.opacity(0.6), lineWidth: 3)
                            .frame(width: iconSize + 10, height: iconSize + 10)
                            .scaleEffect(showRipple ? 1.8 : 1.0)
                            .opacity(showRipple ? 0 : 1)
                    }

                    // Icon: checkmark when complete, timer otherwise
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "timer")
                        .font(.system(size: isCompleted ? iconSize : iconSize * 0.65, weight: .medium))
                        .foregroundStyle(isCompleted ? Color.green : themeManager.accentColor.opacity(0.85))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                        .scaleEffect(completionBounce ? 1.35 : 1.0)
                }

                VStack(spacing: 4) {
                    Text("Focus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(height: 18)

                    Text("\(todayMinutes) / \(targetMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(isCompleted ? "Done!" : "\(Int(min(progress * 100, 100)))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isCompleted ? .green : themeManager.accentColor)
                        .frame(height: 14)
                }
            }
            .frame(width: 110, height: 170)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onChange(of: isJustCompleted) { _, newVal in
            if newVal { triggerCompletionAnimation() }
        }
    }

    private func triggerCompletionAnimation() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1407)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            completionBounce = true
        }
        withAnimation(.easeOut(duration: 0.6)) {
            showRipple = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                completionBounce = false
            }
            showRipple = false
        }
    }
}
