//
//  MilestoneCompletionView.swift
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

struct MilestoneCompletionView: View {
    let habit: Habit
    let onComplete: () -> Void
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showContent = false
    @State private var showButtons = false
    @State private var trophyScale: CGFloat = 0.5
    @State private var trophyRotation: Double = -30

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.1),
                    Color.yellow.opacity(0.05),
                    themeManager.backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Confetti
            ConfettiView(particleCount: 150)

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Trophy icon with animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                        .scaleEffect(trophyScale)
                        .rotationEffect(.degrees(trophyRotation))
                }

                // Congratulations text
                VStack(spacing: 16) {
                    Text("Congratulations!")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("You've completed")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("\(habit.maxCompletionDays) days")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.accentColor)

                    Text("of \(habit.title)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    Button {
                        onComplete()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Complete Habit")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    Button {
                        onContinue()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.forward.circle")
                            Text("Continue Habit")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Text("Continue to keep building your streak beyond \(habit.maxCompletionDays) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 30)
            }
        }
        .onAppear {
            // Animate trophy entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                trophyScale = 1.0
                trophyRotation = 0
            }

            // Animate content
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }

            // Animate buttons
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                showButtons = true
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    MilestoneCompletionView(
        habit: Habit(title: "Read books", targetValue: 30, unit: .minute, maxCompletionDays: 60),
        onComplete: {},
        onContinue: {}
    )
    .environmentObject(ThemeManager())
}
