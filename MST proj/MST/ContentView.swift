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
    @State private var selectedTab: Int = 0
    @State private var showCapsuleOnFocus: Bool = false

    private var isOnFocusTab: Bool { selectedTab == 1 }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                FocusView()
                    .tabItem {
                        Label("Focus", systemImage: "timer")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .tint(themeManager.accentColor)
            .preferredColorScheme(themeManager.colorScheme)

            if !isOnFocusTab {
                FloatingAIButton(showAssistant: $showAssistant)
            }

            // PointsCapsuleView: always visible on non-Focus tabs;
            // briefly appears on Focus tab when points are awarded.
            if !isOnFocusTab || showCapsuleOnFocus {
                PointsCapsuleView()
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                    .transition(.opacity)
            }
        }
        .onChange(of: pointsManager.awardAnimationID) { _, _ in
            guard isOnFocusTab else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                showCapsuleOnFocus = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showCapsuleOnFocus = false
                }
            }
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
        .fullScreenCover(isPresented: $showAssistant, onDismiss: {
            assistantViewModel?.generateConversationSummary()
        }) {
            if let vm = assistantViewModel {
                AssistantView(viewModel: vm)
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
