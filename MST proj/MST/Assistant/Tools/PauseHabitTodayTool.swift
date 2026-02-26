//
//  PauseHabitTodayTool.swift
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

struct PauseHabitTodayTool: Tool {
    let name = "pauseHabitToday"
    let description = """
    Pause a specific habit for today only, so it won't count as missed. \
    ONLY use this for outdoor or physical activity habits (running, cycling, hiking, walking, swimming, sports, etc.) \
    when the user explicitly mentions they cannot do it today due to weather, injury, or a scheduling conflict. \
    The habit automatically resumes tomorrow. Do NOT use this for study or work habits.
    """

    @Generable struct Arguments {
        @Guide(description: "The exact title (or close match) of the outdoor activity habit to pause for today")
        var habitTitle: String
    }

    let modelContext: ModelContext
    let tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)

        let descriptor = FetchDescriptor<Habit>()
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        guard let habit = habits.first(where: {
            $0.title.localizedCaseInsensitiveCompare(arguments.habitTitle) == .orderedSame ||
            $0.title.localizedCaseInsensitiveContains(arguments.habitTitle)
        }) else {
            let result = "No habit found matching '\(arguments.habitTitle)'. Please check the habit name and try again."
            tracker.record(name: name, result: result)
            return result
        }

        if habit.isPausedToday {
            let result = "'\(habit.title)' is already paused for today."
            tracker.record(name: name, result: result)
            return result
        }

        habit.pauseForToday()
        try? modelContext.save()

        let result = "Paused '\(habit.title)' for today. No streak penalty — it will resume automatically tomorrow."
        tracker.record(name: name, result: result)
        return result
    }
}
