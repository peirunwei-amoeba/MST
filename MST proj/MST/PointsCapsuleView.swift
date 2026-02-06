//
//  PointsCapsuleView.swift
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
import SwiftData

struct PointsCapsuleView: View {
    @EnvironmentObject private var pointsManager: PointsManager
    @Environment(\.modelContext) private var modelContext

    @State private var showingStats = false

    // Animation states
    @State private var isExpanded = false
    @State private var logoRotation: Double = 0
    @State private var logoScale: CGFloat = 1.0
    @State private var jiggleAngle: Double = 0
    @State private var showPlusLabel = false

    var body: some View {
        Button {
            if !isExpanded {
                showingStats = true
            }
        } label: {
            capsuleContent
        }
        .buttonStyle(GlassButtonStyle())
        .onChange(of: pointsManager.awardAnimationID) { _, _ in
            triggerAwardAnimation()
        }
        .sheet(isPresented: $showingStats) {
            PointsStatsView()
        }
    }

    @ViewBuilder
    private var capsuleContent: some View {
        HStack(spacing: isExpanded ? 10 : 6) {
            // SVG tick mark logo
            Image("Image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: isExpanded ? 32 : 20,
                    height: isExpanded ? 32 : 20
                )
                .rotation3DEffect(
                    .degrees(logoRotation),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .scaleEffect(logoScale)

            // Points count
            VStack(spacing: isExpanded ? 2 : 0) {
                Text("\(pointsManager.getRemainingPoints(modelContext: modelContext))")
                    .font(isExpanded ? .title2.weight(.bold) : .subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pointsManager.getRemainingPoints(modelContext: modelContext))

                // Show awarded points during expansion
                if showPlusLabel && pointsManager.lastAwardedPoints > 0 {
                    Text("+\(pointsManager.lastAwardedPoints)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
        }
        .padding(.horizontal, isExpanded ? 18 : 10)
        .padding(.vertical, isExpanded ? 12 : 6)
        .glassEffect(.regular.interactive())
        .clipShape(Capsule())
        .rotationEffect(.degrees(jiggleAngle))
        .scaleEffect(isExpanded ? 1.05 : 1.0)
    }

    // MARK: - Award Animation (Dynamic Island inspired)

    private func triggerAwardAnimation() {
        // Phase 1: Expand capsule
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isExpanded = true
            logoScale = 1.2
        }

        // Phase 2: Show +N label with pop
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
            showPlusLabel = true
        }

        // Phase 3: Spin/twirl the SVG logo (full Y-axis rotation)
        withAnimation(.easeInOut(duration: 0.7)) {
            logoRotation += 360
        }

        // Phase 4: Jiggle the expanded capsule
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(
                .spring(response: 0.08, dampingFraction: 0.25)
                .repeatCount(8, autoreverses: true)
            ) {
                jiggleAngle = 3.5
            }
        }

        // Phase 5: Settle jiggle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                jiggleAngle = 0
                logoScale = 1.0
            }
        }

        // Phase 6: Collapse back to compact
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded = false
                showPlusLabel = false
            }
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

#Preview {
    PointsCapsuleView()
        .modelContainer(for: [PointsLedger.self, PointsTransaction.self], inMemory: true)
        .environmentObject(PointsManager())
}
