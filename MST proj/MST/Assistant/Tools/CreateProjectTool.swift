//
//  CreateProjectTool.swift
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

struct CreateProjectTool: Tool {
    let name = "createProject"
    let description = "Create a new project with a title, deadline, and optional goals. Goals should be comma-separated."

    @Generable
    struct Arguments {
        @Guide(description: "Title of the project")
        var title: String

        @Guide(description: "Deadline as ISO 8601 string or relative like 'next month', '2025-06-01'")
        var deadline: String

        @Guide(description: "Comma-separated list of goal titles")
        var goals: String?

        @Guide(description: "Subject or category")
        var subject: String?
    }

    var modelContext: ModelContext
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> ToolOutput {
        let parsedDeadline = parseDate(arguments.deadline)

        let project = Project(
            title: arguments.title,
            deadline: parsedDeadline,
            subject: arguments.subject ?? ""
        )
        modelContext.insert(project)

        if let goalsString = arguments.goals, !goalsString.isEmpty {
            let goalTitles = goalsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let totalGoals = goalTitles.count
            for (index, goalTitle) in goalTitles.enumerated() where !goalTitle.isEmpty {
                let interval = parsedDeadline.timeIntervalSince(Date()) / Double(totalGoals)
                let targetDate = Date().addingTimeInterval(interval * Double(index + 1))
                let goal = Goal(
                    title: goalTitle,
                    targetDate: targetDate,
                    sortOrder: index,
                    project: project
                )
                modelContext.insert(goal)
                project.goals.append(goal)
            }
        }

        try? modelContext.save()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let goalCount = project.goals.count
        let goalText = goalCount > 0 ? " with \(goalCount) goals" : ""
        let result = "Created project '\(arguments.title)'\(goalText), deadline \(formatter.string(from: parsedDeadline))"
        tracker.record(name: name, result: result)
        return ToolOutput(result)
    }

    private func parseDate(_ string: String) -> Date {
        let calendar = Calendar.current
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)

        switch lower {
        case "next week":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        case "next month":
            return calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case "next year":
            return calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        default:
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: string) { return date }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: string) { return date }

            return calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        }
    }
}
