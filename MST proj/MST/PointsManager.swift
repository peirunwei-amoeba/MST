//
//  PointsManager.swift
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

import SwiftUI
import SwiftData
import Combine

@MainActor
class PointsManager: ObservableObject {

    // MARK: - Animation State

    var isShowingAward: Bool = false {
        willSet { objectWillChange.send() }
    }
    var lastAwardedPoints: Int = 0 {
        willSet { objectWillChange.send() }
    }
    var awardAnimationID: UUID = UUID() {
        willSet { objectWillChange.send() }
    }

    // MARK: - Streak Milestones

    static let streakMilestones: [(streak: Int, points: Int)] = [
        (3, 2), (5, 5), (10, 12), (15, 20), (25, 30), (50, 200), (100, 1000)
    ]

    // MARK: - Core Award Logic

    /// Awards points if not already awarded for this source+period combination.
    /// Returns true if points were actually awarded, false if already claimed.
    @discardableResult
    func awardPoints(
        sourceType: String,
        sourceId: UUID,
        periodKey: String,
        points: Int,
        sourceTitle: String,
        modelContext: ModelContext
    ) -> Bool {
        // Anti-double-dipping check
        let type = sourceType
        let sid = sourceId
        let pkey = periodKey
        let descriptor = FetchDescriptor<PointsTransaction>(
            predicate: #Predicate<PointsTransaction> {
                $0.sourceType == type &&
                $0.sourceId == sid &&
                $0.periodKey == pkey
            }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return false }

        // Create transaction
        let transaction = PointsTransaction(
            sourceType: sourceType,
            sourceId: sourceId,
            periodKey: periodKey,
            pointsAwarded: points,
            sourceTitle: sourceTitle
        )
        modelContext.insert(transaction)

        // Update ledger
        let ledger = getOrCreateLedger(modelContext: modelContext)
        ledger.totalPointsEarned += points

        // Trigger animation
        lastAwardedPoints = points
        awardAnimationID = UUID()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isShowingAward = true
        }

        // Auto-dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self?.isShowingAward = false
            }
        }

        return true
    }

    // MARK: - Convenience Methods

    func awardHabitPoints(habit: Habit, modelContext: ModelContext) {
        let periodKey: String
        if habit.frequency == .weekly {
            let calendar = Calendar.current
            let weekOfYear = calendar.component(.weekOfYear, from: Date())
            let year = calendar.component(.yearForWeekOfYear, from: Date())
            periodKey = "\(year)-W\(weekOfYear)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            periodKey = formatter.string(from: Date())
        }

        let awarded = awardPoints(
            sourceType: "habit",
            sourceId: habit.id,
            periodKey: periodKey,
            points: 1,
            sourceTitle: habit.title,
            modelContext: modelContext
        )

        // Check streak milestones if habit point was awarded
        if awarded {
            checkStreakMilestones(habit: habit, modelContext: modelContext)
        }
    }

    func awardAssignmentPoints(assignment: Assignment, modelContext: ModelContext) {
        awardPoints(
            sourceType: "assignment",
            sourceId: assignment.id,
            periodKey: "once",
            points: 1,
            sourceTitle: assignment.title,
            modelContext: modelContext
        )
    }

    func awardGoalPoints(goal: Goal, modelContext: ModelContext) {
        awardPoints(
            sourceType: "goal",
            sourceId: goal.id,
            periodKey: "once",
            points: 3,
            sourceTitle: goal.title,
            modelContext: modelContext
        )
    }

    // MARK: - Streak Milestones

    private func checkStreakMilestones(habit: Habit, modelContext: ModelContext) {
        let currentStreak = habit.currentStreak
        for milestone in Self.streakMilestones where currentStreak >= milestone.streak {
            awardPoints(
                sourceType: "streak",
                sourceId: habit.id,
                periodKey: "milestone-\(milestone.streak)",
                points: milestone.points,
                sourceTitle: "\(habit.title) (\(milestone.streak)-day streak)",
                modelContext: modelContext
            )
        }
    }

    // MARK: - Ledger Access

    func getOrCreateLedger(modelContext: ModelContext) -> PointsLedger {
        let descriptor = FetchDescriptor<PointsLedger>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let ledger = PointsLedger()
        modelContext.insert(ledger)
        return ledger
    }

    func getRemainingPoints(modelContext: ModelContext) -> Int {
        getOrCreateLedger(modelContext: modelContext).remainingPoints
    }
}
