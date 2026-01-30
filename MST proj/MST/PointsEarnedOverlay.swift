//
//  PointsEarnedOverlay.swift
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

struct PointsEarnedOverlay: View {
    let points: Int
    @State private var isAnimating = false
    @State private var lottieIsPlaying = true

    var body: some View {
        VStack(spacing: 6) {
            LottieView(
                animationName: "tick_animation",
                loopMode: .playOnce,
                animationSpeed: 1.5,
                isPlaying: $lottieIsPlaying
            )
            .frame(width: 40, height: 40)

            Text("+\(points)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .scaleEffect(isAnimating ? 1.0 : 0.3)
        .offset(y: isAnimating ? 50 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}
