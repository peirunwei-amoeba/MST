//
//  PointsAwarder.swift
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

enum PointsAwarder {

    /// Award 1 point for completing an assignment (Focus-only).
    /// Guarded by `pointsAwarded` flag — once per assignment.
    @MainActor
    static func awardForAssignment(_ assignment: Assignment, manager: PointsManager) {
        guard !assignment.pointsAwarded else { return }
        assignment.pointsAwarded = true
        manager.awardPoints(1)
    }

    /// Award 3 points for completing a goal.
    /// Guarded by `pointsAwarded` flag — once per goal.
    @MainActor
    static func awardForGoal(_ goal: Goal, manager: PointsManager) {
        guard !goal.pointsAwarded else { return }
        goal.pointsAwarded = true
        manager.awardPoints(3)
    }

    /// Award 1 point for completing a habit.
    /// Checks frequency-based cooldown:
    /// - `.daily` → only first completion per day
    /// - `.weekly` → only first completion per week
    /// Then marks today's entry as `pointsAwarded`.
    @MainActor
    static func awardForHabit(_ habit: Habit, manager: PointsManager) {
        switch habit.frequency {
        case .daily:
            guard habit.canAwardPointsToday else { return }
        case .weekly:
            guard habit.canAwardPointsThisWeek else { return }
        }

        // Mark today's entry as points-awarded
        if let todayEntry = habit.todayEntry {
            todayEntry.pointsAwarded = true
        }

        manager.awardPoints(1)
    }
}

