//
//  CompleteAssignmentTool.swift
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

struct CompleteAssignmentTool: Tool {
    let name = "completeAssignment"
    let description = "Mark an assignment as complete by matching its title. Awards points."

    @Generable
    struct Arguments {
        @Guide(description: "Title or partial title of the assignment to complete")
        var title: String
    }

    var modelContext: ModelContext
    var pointsManager: PointsManager
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        let descriptor = FetchDescriptor<Assignment>(sortBy: [SortDescriptor(\.dueDate)])
        let assignments = (try? modelContext.fetch(descriptor)) ?? []

        let searchTitle = arguments.title.lowercased()
        guard let match = assignments.first(where: {
            !$0.isCompleted && $0.title.lowercased().contains(searchTitle)
        }) else {
            let result = "No incomplete assignment found matching '\(arguments.title)'."
            tracker.record(name: name, result: result)
            return result
        }

        match.toggleCompletion()
        await pointsManager.awardAssignmentPoints(assignment: match, modelContext: modelContext)
        try? modelContext.save()

        let result = "Completed '\(match.title)'. +1 point!"
        tracker.record(name: name, result: result)
        return result
    }
}
