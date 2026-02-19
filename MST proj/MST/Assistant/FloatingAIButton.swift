//
//  FloatingAIButton.swift
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
import FoundationModels

struct FloatingAIButton: View {
    @Binding var showAssistant: Bool
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        if SystemLanguageModel.default.availability == .available {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showAssistant = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(themeManager.accentColor)
                            .frame(width: 52, height: 52)
                            .glassEffect(.regular.interactive(), in: Circle())
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.trailing, 20)
                    // Aligned to match the Focus tab Start button vertical center:
                    // Tab bar ≈83 pt + controlButtons.padding(.bottom, 32) + half button height
                    .padding(.bottom, 115)
                }
            }
        }
    }
}
