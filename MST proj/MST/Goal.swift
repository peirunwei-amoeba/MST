//
//  Goal.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
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
    var project: Project?

    init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        sortOrder: Int = 0,
        project: Project? = nil
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.sortOrder = sortOrder
        self.project = project
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
    }
}
