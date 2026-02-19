//
//  MSTApp.swift
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

@main
struct MSTApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var pointsManager = PointsManager()
    @State private var focusTimerBridge = FocusTimerBridge()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(pointsManager)
                .environment(focusTimerBridge)
                .onAppear {
                    HabitReminderManager.requestNotificationPermission()
                }
        }
        .modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitEntry.self, PointsLedger.self, PointsTransaction.self])
    }
}
