//
//  CompleteHabitTodayTool.swift
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

struct CompleteHabitTodayTool: Tool {
    let name = "completeHabitToday"
    let description = "Mark a habit as completed for today by matching its title. Awards points."

    @Generable
    struct Arguments {
        @Guide(description: "Title or partial title of the habit to complete")
        var title: String
    }

    var modelContext: ModelContext
    var pointsManager: PointsManager
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdDate)])
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        let searchTitle = arguments.title.lowercased()
        guard let match = habits.first(where: {
            !$0.isTerminated && $0.title.lowercased().contains(searchTitle)
        }) else {
            let result = "No active habit found matching '\(arguments.title)'."
            tracker.record(name: name, result: result)
            return result
        }

        if match.isCompletedToday {
            let result = "'\(match.title)' is already completed for today."
            tracker.record(name: name, result: result)
            return result
        }

        match.completeToday()
        await pointsManager.awardHabitPoints(habit: match, modelContext: modelContext)
        try? modelContext.save()

        let streak = match.currentStreak
        let result = "Completed '\(match.title)' for today! Streak: \(streak) days. +1 point!"
        tracker.record(name: name, result: result)
        return result
    }
}
