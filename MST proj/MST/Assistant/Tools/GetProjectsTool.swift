//
//  GetProjectsTool.swift
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

struct GetProjectsTool: Tool {
    let name = "getProjects"
    let description = "Fetch the user's projects with their goals and progress. Use filter to narrow results."

    @Generable
    struct Arguments {
        @Guide(description: "Filter: 'all' or 'incomplete'")
        var filter: String?
    }

    var modelContext: ModelContext
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.deadline)])
        let projects = (try? modelContext.fetch(descriptor)) ?? []

        let filter = arguments.filter ?? "incomplete"
        let filtered: [Project]
        switch filter.lowercased() {
        case "all":
            filtered = projects
        default:
            filtered = projects.filter { !$0.isCompleted }
        }

        if filtered.isEmpty {
            let result = "No projects found for filter '\(filter)'."
            tracker.record(name: name, result: result)
            return result
        }

        let lines = filtered.prefix(10).map { p in
            let progress = String(format: "%.0f%%", p.progressPercentage)
            let next = p.nextGoal.map { " Next: \($0.title)" } ?? ""
            let overdue = p.isOverdue ? " [OVERDUE]" : ""
            return "- \(p.title) (\(progress), \(p.completedGoalsCount)/\(p.goals.count) goals)\(next)\(overdue)"
        }

        var result = lines.joined(separator: "\n")
        if filtered.count > 10 {
            result += "\n...and \(filtered.count - 10) more"
        }
        tracker.record(name: name, result: "\(filtered.count) project(s) found")
        return result
    }
}
