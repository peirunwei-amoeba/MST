//
//  ConcentricHabitCard.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import AVFoundation

struct ConcentricHabitCard: View {
    let habit: Habit
    var isRecentlyCompleted: Bool = false
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var animatingCheckmark = false

    var body: some View {
        Button { onTap() } label: {
            VStack(spacing: 12) {
                // Large checkmark button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        animatingCheckmark = true
                    }
                    onToggleComplete()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            animatingCheckmark = false
                        }
                    }
                } label: {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(habit.isCompletedToday ? .green : .secondary.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                        .scaleEffect(animatingCheckmark ? 1.35 : 1.0)
                        .rotationEffect(.degrees(animatingCheckmark ? 10 : 0))
                }
                .buttonStyle(.plain)

                VStack(spacing: 4) {
                    Text(habit.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(habit.formattedTarget)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Streak indicator
                    if habit.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(habit.currentStreak)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .frame(width: 110)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(isRecentlyCompleted ? 0.6 : 1.0)
        .scaleEffect(isRecentlyCompleted ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.3), value: isRecentlyCompleted)
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
