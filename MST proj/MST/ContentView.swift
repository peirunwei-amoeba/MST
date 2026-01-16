//
//  ContentView.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
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
