//
//  Assignment.swift
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
final class Assignment {
    @Attribute(.unique) var id: UUID
    var title: String
    var assignmentDescription: String
    var dueDate: Date
    var createdDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    var priority: Priority
    var subject: String
    var tags: [String]
    var notes: String
    var estimatedDuration: TimeInterval?
    var notificationEnabled: Bool
    var colorCode: String?
    var targetValue: Double?
    var targetUnitRaw: String = ""

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
        assignmentDescription: String = "",
        dueDate: Date,
        createdDate: Date = Date(),
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        priority: Priority = .none,
        subject: String = "",
        tags: [String] = [],
        notes: String = "",
        estimatedDuration: TimeInterval? = nil,
        notificationEnabled: Bool = true,
        colorCode: String? = nil,
        targetValue: Double? = nil,
        targetUnit: TargetUnit = .none
    ) {
        self.id = id
        self.title = title
        self.assignmentDescription = assignmentDescription
        self.dueDate = dueDate
        self.createdDate = createdDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.priority = priority
        self.subject = subject
        self.tags = tags
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.notificationEnabled = notificationEnabled
        self.colorCode = colorCode
        self.targetValue = targetValue
        self.targetUnitRaw = targetUnit.rawValue
    }

    // MARK: - Computed Properties

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    var isDueTomorrow: Bool {
        Calendar.current.isDateInTomorrow(dueDate)
    }

    var timeUntilDue: TimeInterval {
        dueDate.timeIntervalSinceNow
    }

    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }

    // MARK: - Methods

    func toggleCompletion() {
        isCompleted.toggle()
        completedDate = isCompleted ? Date() : nil
    }
}

// MARK: - Priority Enum

enum Priority: String, Codable, CaseIterable {
    case none = "Default"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        case .none: return 4
        }
    }

    var color: String {
        switch self {
        case .urgent: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "green"
        case .none: return "gray"
        }
    }
}
