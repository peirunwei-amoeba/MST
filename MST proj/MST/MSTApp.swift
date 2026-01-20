//
//  MSTApp.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
//

import SwiftUI
import SwiftData

@main
struct MSTApp: App {
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
        .modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitEntry.self])
    }
}
