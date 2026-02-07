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
    @State private var animatingBounce = false

    private var cornerRadius: CGFloat { isExpanded ? 28 : 16 }

    var body: some View {
        Button {
            if !isExpanded {
                showingStats = true
            }
        } label: {
            content
        }
        .buttonStyle(GlassButtonStyle())
        // topTrailing alignment: top-right corner stays pinned,
        // glass expands downward and to the left
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topTrailing
        )
        .onChange(of: pointsManager.awardAnimationID) { _, _ in
            triggerAwardAnimation()
        }
        .sheet(isPresented: $showingStats) {
            PointsStatsView()
        }
    }

    private var content: some View {
        Color.clear
            .frame(
                width: isExpanded ? 120 : 80,
                height: isExpanded ? 120 : 36
            )
            .overlay {
                ZStack {
                    // Compact pill content
                    compactContent
                        .opacity(isExpanded ? 0 : 1)

                    // Expanded island content
                    expandedContent
                        .opacity(isExpanded ? 1 : 0)
                }
            }
            .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
    }

    // MARK: - Compact Pill Content

    private var compactContent: some View {
        HStack(spacing: 6) {
            Image("MST Full")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)

            Text("\(pointsManager.getRemainingPoints(modelContext: modelContext))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Expanded Island Content

    private var expandedContent: some View {
        VStack(spacing: 8) {
            // Twist & smack only on the image
            Image("MST Full")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .scaleEffect(animatingBounce ? 1.35 : 1.0)
                .rotationEffect(.degrees(animatingBounce ? 10 : 0))

            Text("+\(pointsManager.lastAwardedPoints)")
                .font(.title3.weight(.bold))
                .foregroundStyle(.green)
        }
    }

    // MARK: - Award Animation (twist & smack on image only)

    private func triggerAwardAnimation() {
        // Phase 1: Expand glass downward-left
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isExpanded = true
        }

        // Phase 2: Twist & smack the image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animatingBounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    animatingBounce = false
                }
            }
        }

        // Phase 3: Collapse back to pill
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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
