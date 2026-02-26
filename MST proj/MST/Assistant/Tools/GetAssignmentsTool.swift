//
//  GetAssignmentsTool.swift
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

struct GetAssignmentsTool: Tool {
    let name = "getAssignments"
    let description = "Fetch the user's assignments. Returns titles, due dates, priorities, and completion status. Use filter to narrow results."

    @Generable
    struct Arguments {
        @Guide(description: "Filter: 'all', 'incomplete', 'overdue', or 'today'")
        var filter: String?
    }

    var modelContext: ModelContext
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        let descriptor = FetchDescriptor<Assignment>(sortBy: [SortDescriptor(\.dueDate)])
        let assignments = (try? modelContext.fetch(descriptor)) ?? []

        let filter = arguments.filter ?? "incomplete"
        let filtered: [Assignment]
        switch filter.lowercased() {
        case "all":
            filtered = assignments
        case "overdue":
            filtered = assignments.filter { $0.isOverdue }
        case "today":
            filtered = assignments.filter { $0.isDueToday }
        default:
            filtered = assignments.filter { !$0.isCompleted }
        }

        if filtered.isEmpty {
            let result = "No assignments found for filter '\(filter)'."
            tracker.record(name: name, result: result)
            return result
        }

        let lines = filtered.prefix(10).map { a in
            let status = a.isCompleted ? "[done]" : (a.isOverdue ? "[OVERDUE]" : "")
            let priority = a.priority != .none ? " (\(a.priority.rawValue))" : ""
            return "- \(a.title)\(priority) — due \(a.formattedDueDate) \(status)"
        }

        var result = lines.joined(separator: "\n")
        if filtered.count > 10 {
            result += "\n...and \(filtered.count - 10) more"
        }
        tracker.record(name: name, result: "\(filtered.count) assignment(s) found")
        return result
    }
}

