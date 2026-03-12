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
            AppRootView()
                .environmentObject(themeManager)
                .environmentObject(pointsManager)
                .environment(focusTimerBridge)
                .onAppear {
                    HabitReminderManager.requestNotificationPermission()
                }
        }
        .modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitEntry.self, PointsLedger.self, PointsTransaction.self, HabitJourneyEntry.self])
    }
}

/// Wrapper that schedules AI encouragement notifications using the SwiftData model context.
private struct AppRootView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContentView()
            .task {
                let lastScheduled = UserDefaults.standard.object(forKey: "lastEncouragementSchedule") as? Date
                let shouldSchedule = lastScheduled.map { Calendar.current.isDateInToday($0) == false } ?? true
                if shouldSchedule {
                    UserDefaults.standard.set(Date(), forKey: "lastEncouragementSchedule")
                    // Small delay to avoid slowing down app launch
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await AIEncouragementManager.scheduleEncouragements(
                        modelContext: modelContext,
                        userName: themeManager.userName
                    )
                }
            }
    }
}
