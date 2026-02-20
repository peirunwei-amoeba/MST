//
//  AIEncouragementManager.swift
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
import FoundationModels
import UserNotifications
import SwiftData

struct AIEncouragementManager {

    /// Schedule AI-generated encouragement notifications for items with due dates.
    /// For assignments/projects: 2 hours before due, or 9 AM on due day.
    /// For habits: daily at 8 PM (new encouragement each day).
    static func scheduleEncouragements(modelContext: ModelContext, userName: String) async {
        guard SystemLanguageModel.default.availability == .available else { return }

        let center = UNUserNotificationCenter.current()
        let authorized = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            center.getNotificationSettings { settings in
                cont.resume(returning: settings.authorizationStatus == .authorized)
            }
        }
        guard authorized else { return }

        // Clear previous encouragement notifications
        let pending = await center.pendingNotificationRequests()
        let encouragementIds = pending.filter { $0.identifier.hasPrefix("ai-encourage-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: encouragementIds)

        let session = LanguageModelSession()
        let name = userName.isEmpty ? "you" : userName
        let calendar = Calendar.current
        let now = Date()
        let todayStr = formattedDate(now)

        // --- Assignments ---
        let assignmentDescriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate<Assignment> { !$0.isCompleted }
        )
        let assignments = (try? modelContext.fetch(assignmentDescriptor)) ?? []

        for assignment in assignments.prefix(5) {
            let dueDate = assignment.dueDate
            let daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: dueDate)).day ?? Int.max
            guard daysUntilDue >= 0 && daysUntilDue <= 2 else { continue }

            // Determine notification time
            let notificationDate: Date
            if daysUntilDue == 0 {
                // Due today — notify at 9 AM or 2 hours before (whichever is earlier and in future)
                let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
                let twoHoursBefore = dueDate.addingTimeInterval(-2 * 3600)
                notificationDate = twoHoursBefore > now ? twoHoursBefore : (nineAM > now ? nineAM : now.addingTimeInterval(300))
            } else {
                // Due tomorrow — notify at 9 AM today
                let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
                notificationDate = nineAM > now ? nineAM : now.addingTimeInterval(300)
            }

            guard notificationDate > now else { continue }

            let dueLabel = daysUntilDue == 0 ? "today" : "tomorrow"
            let subject = assignment.subject.isEmpty ? "" : " for \(assignment.subject)"
            let prompt = "Write a short motivational push notification (2 sentences max) for \(name) who needs to complete '\(assignment.title)'\(subject) due \(dueLabel). Be specific, warm, and energizing. No hashtags, no quotes around it, just the message."

            do {
                let response = try await session.respond(to: prompt)
                let body = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

                let content = UNMutableNotificationContent()
                content.title = daysUntilDue == 0 ? "Due today: \(assignment.title)" : "Due tomorrow: \(assignment.title)"
                content.body = body
                content.sound = .default

                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "ai-encourage-assignment-\(assignment.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            } catch {}
        }

        // --- Habits (daily encouragement at 8 PM) ---
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isTerminated }
        )
        let habits = (try? modelContext.fetch(habitDescriptor)) ?? []

        var eightPM = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        if eightPM <= now {
            eightPM = eightPM.addingTimeInterval(60 * 60 * 24) // tomorrow 8 PM
        }

        // Only schedule for top 3 active uncompleted habits
        for habit in habits.filter({ !$0.isCompletedToday }).prefix(3) {
            let streakText = habit.currentStreak > 0 ? " They're on a \(habit.currentStreak)-day streak!" : ""
            let prompt = "Write a short, energetic daily reminder (1-2 sentences) encouraging \(name) to do their '\(habit.title)' habit today.\(streakText) Make it feel personal and motivating. No hashtags. Date: \(todayStr)."

            do {
                let response = try await session.respond(to: prompt)
                let body = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

                let content = UNMutableNotificationContent()
                content.title = "🔥 \(habit.title)"
                content.body = body
                content.sound = .default

                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eightPM)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "ai-encourage-habit-\(habit.id.uuidString)-\(todayStr)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            } catch {}
        }
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
