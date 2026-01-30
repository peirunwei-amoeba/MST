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

    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Assignment.self, inMemory: true)
        .environmentObject(ThemeManager())
}
