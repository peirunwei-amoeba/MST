//
//  HabitReminderManager.swift
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

import Foundation
import UserNotifications
import SwiftData

struct HabitReminderManager {

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Cancel the 7 PM reminder for a habit that was just completed.
    static func cancelReminder(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["habit-\(habit.id.uuidString)"])
    }

    static func scheduleReminders(modelContext: ModelContext) {
        let center = UNUserNotificationCenter.current()

        // Remove all pending habit reminders first
        center.removePendingNotificationRequests(withIdentifiers: [])
        center.getPendingNotificationRequests { requests in
            let habitIds = requests.filter { $0.identifier.hasPrefix("habit-") }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: habitIds)
        }

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isTerminated }
        )
        guard let habits = try? modelContext.fetch(descriptor) else { return }

        for habit in habits {
            guard !habit.isCompletedToday else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Don't forget to complete your '\(habit.title)' habit today!"
            content.sound = .default

            // Schedule for 7 PM today
            var dateComponents = DateComponents()
            dateComponents.hour = 19
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.id.uuidString)",
                content: content,
                trigger: trigger
            )

            center.add(request) { _ in }
        }
    }
}
