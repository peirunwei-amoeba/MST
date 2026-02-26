//
//  ContentView.swift
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

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var pointsManager: PointsManager
    @Environment(FocusTimerBridge.self) private var focusTimerBridge
    @Environment(\.modelContext) private var modelContext
    @State private var showAssistant = false
    @State private var assistantViewModel: AssistantViewModel?

    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                FocusView()
                    .tabItem {
                        Label("Focus", systemImage: "timer")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(themeManager.accentColor)
            .preferredColorScheme(themeManager.colorScheme)

            FloatingAIButton(showAssistant: $showAssistant)

            // Single shared PointsCapsuleView — lives here so it is never duplicated
            // across tabs, preventing phantom award animations on tab switches.
            PointsCapsuleView()
                .padding(.trailing, 20)
                .padding(.top, 60)
        }
        .onAppear {
            if assistantViewModel == nil {
                assistantViewModel = AssistantViewModel(
                    modelContext: modelContext,
                    pointsManager: pointsManager,
                    focusTimerBridge: focusTimerBridge,
                    themeManager: themeManager
                )
            }
        }
        .onChange(of: showAssistant) { _, isShowing in
            if isShowing && assistantViewModel == nil {
                assistantViewModel = AssistantViewModel(
                    modelContext: modelContext,
                    pointsManager: pointsManager,
                    focusTimerBridge: focusTimerBridge,
                    themeManager: themeManager
                )
            }
        }
        .sheet(isPresented: $showAssistant, onDismiss: {
            assistantViewModel?.generateConversationSummary()
        }) {
            if let vm = assistantViewModel {
                AssistantView(viewModel: vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Assignment.self, inMemory: true)
        .environmentObject(ThemeManager())
        .environmentObject(PointsManager())
        .environment(FocusTimerBridge())
}
