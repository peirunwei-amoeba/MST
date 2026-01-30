//
//  Goal.swift
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

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var targetDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    var sortOrder: Int
    var priorityRaw: String = "Default"
    var project: Project?
    var targetValue: Double?
    var targetUnitRaw: String = ""
    var pointsAwarded: Bool = false

    // Computed property for Priority enum
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    // Computed: Unit enum
    var targetUnit: TargetUnit {
        get { TargetUnit(rawValue: targetUnitRaw) ?? .none }
        set { targetUnitRaw = newValue.rawValue }
    }

    var formattedTarget: String? {
        guard let value = targetValue, targetUnit != .none else { return nil }
        return targetUnit.format(value)
    }

    init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        sortOrder: Int = 0,
        priority: Priority = .none,
        project: Project? = nil,
        targetValue: Double? = nil,
        targetUnit: TargetUnit = .none
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.sortOrder = sortOrder
        self.priorityRaw = priority.rawValue
        self.project = project
        self.targetValue = targetValue
        self.targetUnitRaw = targetUnit.rawValue
    }

    // MARK: - Computed Properties

    var isOverdue: Bool {
        !isCompleted && targetDate < Date()
    }

    var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetDate)
    }

    // MARK: - Methods

    func toggleCompletion() {
        isCompleted.toggle()
        completedDate = isCompleted ? Date() : nil

        if let project = project {
            if !isCompleted && project.isCompleted {
                // If a goal is unchecked and the parent project was completed, mark project as incomplete
                project.isCompleted = false
                project.completedDate = nil
            } else if isCompleted && !project.isCompleted {
                // If a goal is checked, check if all goals are now completed
                let allGoalsCompleted = project.goals.allSatisfy { $0.isCompleted }
                if allGoalsCompleted {
                    project.isCompleted = true
                    project.completedDate = Date()
                }
            }
        }
    }
}
