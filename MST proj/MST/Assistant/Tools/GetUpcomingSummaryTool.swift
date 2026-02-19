//
//  GetUpcomingSummaryTool.swift
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
import SwiftData
import FoundationModels

struct GetUpcomingSummaryTool: Tool {
    let name = "getUpcomingSummary"
    let description = "Get a daily summary of overdue items, today's tasks, active habits, and streaks."

    @Generable
    struct Arguments {}

    var modelContext: ModelContext
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        var sections: [String] = []

        let assignmentDescriptor = FetchDescriptor<Assignment>(sortBy: [SortDescriptor(\.dueDate)])
        let assignments = (try? modelContext.fetch(assignmentDescriptor)) ?? []
        let incomplete = assignments.filter { !$0.isCompleted }
        let overdue = incomplete.filter { $0.isOverdue }
        let dueToday = incomplete.filter { $0.isDueToday }
        let dueTomorrow = incomplete.filter { $0.isDueTomorrow }

        if !overdue.isEmpty {
            sections.append("OVERDUE (\(overdue.count)): " + overdue.prefix(3).map { $0.title }.joined(separator: ", "))
        }
        if !dueToday.isEmpty {
            sections.append("Due today (\(dueToday.count)): " + dueToday.prefix(3).map { $0.title }.joined(separator: ", "))
        }
        if !dueTomorrow.isEmpty {
            sections.append("Due tomorrow (\(dueTomorrow.count)): " + dueTomorrow.prefix(3).map { $0.title }.joined(separator: ", "))
        }

        let projectDescriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.deadline)])
        let projects = (try? modelContext.fetch(projectDescriptor)) ?? []
        let activeProjects = projects.filter { !$0.isCompleted }
        if !activeProjects.isEmpty {
            let projectLines = activeProjects.prefix(3).map { "\($0.title) (\(String(format: "%.0f%%", $0.progressPercentage)))" }
            sections.append("Active projects (\(activeProjects.count)): " + projectLines.joined(separator: ", "))
        }

        let habitDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdDate)])
        let habits = (try? modelContext.fetch(habitDescriptor)) ?? []
        let activeHabits = habits.filter { !$0.isTerminated }
        let completedToday = activeHabits.filter { $0.isCompletedToday }
        let pendingHabits = activeHabits.filter { !$0.isCompletedToday }

        if !activeHabits.isEmpty {
            sections.append("Habits: \(completedToday.count)/\(activeHabits.count) done today")
        }
        if !pendingHabits.isEmpty {
            sections.append("Pending habits: " + pendingHabits.prefix(3).map { $0.title }.joined(separator: ", "))
        }

        let topStreaks = activeHabits.filter { $0.currentStreak > 0 }.sorted { $0.currentStreak > $1.currentStreak }.prefix(3)
        if !topStreaks.isEmpty {
            let streakLines = topStreaks.map { "\($0.title): \($0.currentStreak) days" }
            sections.append("Top streaks: " + streakLines.joined(separator: ", "))
        }

        let result: String
        if sections.isEmpty {
            result = "All clear! No pending tasks or habits."
        } else {
            result = sections.joined(separator: "\n")
        }

        tracker.record(name: name, result: "Summary generated")
        return result
    }
}
