//
//  CreateAssignmentTool.swift
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

struct CreateAssignmentTool: Tool {
    let name = "createAssignment"
    let description = "Create a new assignment with a title and due date. Optionally set priority and subject."

    @Generable
    struct Arguments {
        @Guide(description: "Title of the assignment")
        var title: String

        @Guide(description: "Due date as ISO 8601 string (e.g. '2025-03-15T23:59:00Z') or relative like 'tomorrow', 'next monday'")
        var dueDate: String

        @Guide(description: "Priority: 'Default', 'Low', 'Medium', 'High', or 'Urgent'")
        var priority: String?

        @Guide(description: "Subject or category")
        var subject: String?
    }

    var modelContext: ModelContext
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        let parsedDate = parseDate(arguments.dueDate)
        let priority = Priority(rawValue: arguments.priority ?? "Default") ?? .none

        let assignment = Assignment(
            title: arguments.title,
            dueDate: parsedDate,
            priority: priority,
            subject: arguments.subject ?? ""
        )
        modelContext.insert(assignment)
        try? modelContext.save()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let result = "Created '\(arguments.title)' due \(formatter.string(from: parsedDate)) (\(priority.rawValue))"
        tracker.record(name: name, result: result)
        return result
    }

    private func parseDate(_ string: String) -> Date {
        let calendar = Calendar.current
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)

        switch lower {
        case "today":
            return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
        case "tomorrow":
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: tomorrow) ?? tomorrow
        case "next monday":
            return nextWeekday(2, from: Date())
        case "next tuesday":
            return nextWeekday(3, from: Date())
        case "next wednesday":
            return nextWeekday(4, from: Date())
        case "next thursday":
            return nextWeekday(5, from: Date())
        case "next friday":
            return nextWeekday(6, from: Date())
        case "next saturday":
            return nextWeekday(7, from: Date())
        case "next sunday":
            return nextWeekday(1, from: Date())
        case "next week":
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
            return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: nextWeek) ?? nextWeek
        default:
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: string) { return date }

            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: string) { return date }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: string) {
                return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
            }

            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: tomorrow) ?? tomorrow
        }
    }

    private func nextWeekday(_ weekday: Int, from date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday
        let next = calendar.nextDate(after: date, matching: components, matchingPolicy: .nextTime) ?? date
        return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: next) ?? next
    }
}
