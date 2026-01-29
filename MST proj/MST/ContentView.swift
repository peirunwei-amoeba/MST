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
    @Environment(FocusTimerManager.self) private var focusTimerManager

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }

            Tab("Focus", systemImage: "timer") {
                FocusView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tabViewBottomAccessory(isEnabled: focusTimerManager.isActive) {
            TimerAccessoryView()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(themeManager.accentColor)
        .preferredColorScheme(themeManager.colorScheme)
    }
}

// MARK: - Timer Accessory View

struct TimerAccessoryView: View {
    @Environment(FocusTimerManager.self) private var timerManager
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        switch placement {
        case .expanded:
            expandedContent
        default:
            inlineContent
        }
    }

    // Compact view for inline/minimized state - just the countdown
    private var inlineContent: some View {
        Label {
            Text(timerManager.formattedTimeRemaining)
                .monospacedDigit()
                .contentTransition(.numericText())
        } icon: {
            Image(systemName: timerManager.isPaused ? "pause.fill" : "timer")
        }
        .font(.caption.weight(.medium))
    }

    // Full view for expanded state - countdown + task name
    private var expandedContent: some View {
        HStack(spacing: 10) {
            Image(systemName: timerManager.isPaused ? "pause.circle.fill" : "timer")
                .font(.body)
                .foregroundStyle(timerManager.isPaused ? .orange : .accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(timerManager.formattedTimeRemaining)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if let title = timerManager.selectedTaskTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(timerManager.isPaused ? "Paused" : "Focusing")
                .font(.caption.weight(.medium))
                .foregroundStyle(timerManager.isPaused ? .orange : .green)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitEntry.self], inMemory: true)
        .environmentObject(ThemeManager())
        .environment(FocusTimerManager())
}
