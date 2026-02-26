//
//  GetHabitsTool.swift
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

struct GetHabitsTool: Tool {
    let name = "getHabits"
    let description = "Fetch the user's habits with streak and completion info. Use filter to narrow results."

    @Generable
    struct Arguments {
        @Guide(description: "Filter: 'all', 'active', or 'completed-today'")
        var filter: String?
    }

    var modelContext: ModelContext
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdDate)])
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        let filter = arguments.filter ?? "active"
        let filtered: [Habit]
        switch filter.lowercased() {
        case "all":
            filtered = habits
        case "completed-today":
            filtered = habits.filter { $0.isCompletedToday }
        default:
            filtered = habits.filter { !$0.isTerminated }
        }

        if filtered.isEmpty {
            let result = "No habits found for filter '\(filter)'."
            tracker.record(name: name, result: result)
            return result
        }

        let lines = filtered.prefix(10).map { h in
            let todayStatus = h.isCompletedToday ? "[done today]" : ""
            return "- \(h.title) (streak: \(h.currentStreak) days, target: \(h.formattedTarget)) \(todayStatus)"
        }

        var result = lines.joined(separator: "\n")
        if filtered.count > 10 {
            result += "\n...and \(filtered.count - 10) more"
        }
        tracker.record(name: name, result: "\(filtered.count) habit(s) found")
        return result
    }
}
