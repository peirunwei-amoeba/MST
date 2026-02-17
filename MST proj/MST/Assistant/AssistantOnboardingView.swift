//
//  AssistantOnboardingView.swift
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

struct AssistantOnboardingView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var agentName = "Spark"
    @State private var userName = ""

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {} // prevent dismiss on background tap

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(themeManager.accentColor)
                    .symbolEffect(.bounce, value: true)

                Text("Meet Your Assistant")
                    .font(.title2.weight(.bold))

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What would you like to call me?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Agent name", text: $agentName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("And what's your name?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Your name", text: $userName)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Button {
                    themeManager.assistantName = agentName.isEmpty ? "Spark" : agentName
                    themeManager.userName = userName
                    themeManager.hasCompletedOnboarding = true
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.accentColor, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(agentName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(28)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
        }
    }
}
