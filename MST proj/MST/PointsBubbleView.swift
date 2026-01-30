//
//  PointsBubbleView.swift
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

struct PointsBubbleView: View {
    @EnvironmentObject private var pointsManager: PointsManager
    @State private var showingDetail = false

    var body: some View {
        ZStack(alignment: .top) {
            Button {
                showingDetail = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.yellow)

                    Text("\(pointsManager.currentPoints)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular.interactive())
                .clipShape(Capsule())
            }
            .buttonStyle(GlassButtonStyle())
            .sheet(isPresented: $showingDetail) {
                PointsDetailView()
            }

            // Points earned overlay
            if pointsManager.showPointsEarned {
                PointsEarnedOverlay(points: pointsManager.pointsJustEarned)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
    }
}
