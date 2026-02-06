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
    @State private var capsuleScale: CGFloat = 1.0

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

    private var capsuleContent: some View {
        // Single view tree — AnyLayout smoothly morphs between HStack ↔ VStack
        let layout = isExpanded
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 6))

        return layout {
            // Logo — always present, just changes size
            Image("MST Full")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: isExpanded ? 44 : 20,
                    height: isExpanded ? 44 : 20
                )
                .rotation3DEffect(
                    .degrees(logoRotation),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )

            // Text — crossfade between remaining count and +N
            ZStack {
                Text("\(pointsManager.getRemainingPoints(modelContext: modelContext))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .opacity(isExpanded ? 0 : 1)

                Text("+\(pointsManager.lastAwardedPoints)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.green)
                    .opacity(isExpanded ? 1 : 0)
            }
            .contentTransition(.numericText())
        }
        .padding(.horizontal, isExpanded ? 16 : 10)
        .padding(.vertical, isExpanded ? 16 : 6)
        .glassEffect(.regular.interactive())
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 24 : 20, style: .continuous))
        .scaleEffect(capsuleScale)
    }

    // MARK: - Award Animation (spin + pull up + smack down)

    private func triggerAwardAnimation() {
        // Phase 1: Spin logo + expand capsule + show +N
        withAnimation(.easeInOut(duration: 0.5)) {
            logoRotation += 360
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isExpanded = true
            capsuleScale = 1.15
        }

        // Phase 2: Smack down (spring back to normal scale)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                capsuleScale = 1.0
            }
        }

        // Phase 3: Collapse back to compact
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded = false

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
