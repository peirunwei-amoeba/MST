//
//  Project.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
//

import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    var projectDescription: String
    var createdDate: Date
    var deadline: Date
    var isCompleted: Bool
    var completedDate: Date?
    var colorCode: String?
    var subject: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Goal.project) var goals: [Goal]

    init(
        id: UUID = UUID(),
        title: String,
        projectDescription: String = "",
        createdDate: Date = Date(),
        deadline: Date,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        colorCode: String? = nil,
        subject: String = "",
        goals: [Goal] = []
    ) {
        self.id = id
        self.title = title
        self.projectDescription = projectDescription
        self.createdDate = createdDate
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.colorCode = colorCode
        self.subject = subject
        self.goals = goals
    }

    // MARK: - Computed Properties

    var progressPercentage: Double {
        guard !goals.isEmpty else { return 0 }
        let completedCount = goals.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(goals.count) * 100
    }

    var nextGoal: Goal? {
        goals
            .filter { !$0.isCompleted }
            .sorted { $0.targetDate < $1.targetDate }
            .first
    }

    var sortedGoals: [Goal] {
        goals.sorted { $0.targetDate < $1.targetDate }
    }

    var completedGoalsCount: Int {
        goals.filter { $0.isCompleted }.count
    }

    var isOverdue: Bool {
        !isCompleted && deadline < Date()
    }

    var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: deadline)
    }

    // MARK: - Methods

    func toggleCompletion() {
        isCompleted.toggle()
        completedDate = isCompleted ? Date() : nil
    }
}
