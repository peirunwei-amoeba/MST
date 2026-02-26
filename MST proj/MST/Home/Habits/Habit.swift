//
//  Habit.swift
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
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var habitDescription: String
    var targetValue: Double
    var unitRaw: String
    var frequencyRaw: String
    var maxCompletionDays: Int
    var milestoneShown: Bool
    var isTerminated: Bool
    var terminatedDate: Date?
    var createdDate: Date
    var colorCode: String?

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry]

    // Computed: Unit enum
    var unit: TargetUnit {
        get { TargetUnit(rawValue: unitRaw) ?? .none }
        set { unitRaw = newValue.rawValue }
    }

    // Computed: Frequency enum
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        habitDescription: String = "",
        targetValue: Double = 1.0,
        unit: TargetUnit = .times,
        frequency: HabitFrequency = .daily,
        maxCompletionDays: Int = 60,
        milestoneShown: Bool = false,
        isTerminated: Bool = false,
        terminatedDate: Date? = nil,
        createdDate: Date = Date(),
        colorCode: String? = nil,
        entries: [HabitEntry] = []
    ) {
        self.id = id
        self.title = title
        self.habitDescription = habitDescription
        self.targetValue = targetValue
        self.unitRaw = unit.rawValue
        self.frequencyRaw = frequency.rawValue
        self.maxCompletionDays = maxCompletionDays
        self.milestoneShown = milestoneShown
        self.isTerminated = isTerminated
        self.terminatedDate = terminatedDate
        self.createdDate = createdDate
        self.colorCode = colorCode
        self.entries = entries
    }

    // MARK: - Computed Properties

    var formattedTarget: String {
        unit.format(targetValue)
    }

    /// Total completed days (non-consecutive)
    var completedDaysCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(entries.filter { $0.value >= targetValue }
            .map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    /// Days remaining to reach milestone
    var daysRemaining: Int {
        max(0, maxCompletionDays - completedDaysCount)
    }

    /// Has reached the milestone (60 days by default)
    var hasReachedMilestone: Bool {
        completedDaysCount >= maxCompletionDays
    }

    /// Just hit the milestone exactly (for showing celebration)
    var justHitMilestone: Bool {
        completedDaysCount == maxCompletionDays && !milestoneShown
    }

    /// Progress percentage toward milestone
    var milestoneProgress: Double {
        Double(completedDaysCount) / Double(maxCompletionDays) * 100
    }

    /// Current streak (consecutive days)
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        // Check if today is completed
        let todayEntry = entries.first { calendar.isDate($0.date, inSameDayAs: today) }
        let isTodayCompleted = (todayEntry?.value ?? 0) >= targetValue

        // If today not completed, start checking from yesterday
        if !isTodayCompleted {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        while true {
            let dayEntry = entries.first { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if let entry = dayEntry, entry.value >= targetValue {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        return streak
    }

    /// Best streak ever achieved
    var bestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = entries
            .filter { $0.value >= targetValue }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()

        guard !sortedDates.isEmpty else { return 0 }

        var maxStreak = 1
        var currentStreakCount = 1

        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day],
                from: sortedDates[i-1], to: sortedDates[i]).day ?? 0

            if daysBetween == 1 {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else if daysBetween > 1 {
                currentStreakCount = 1
            }
            // daysBetween == 0 means same day, skip
        }

        return maxStreak
    }

    /// Completion rate (completed days / total days since creation)
    var completionRate: Double {
        let calendar = Calendar.current
        let daysSinceCreation = calendar.dateComponents([.day],
            from: calendar.startOfDay(for: createdDate),
            to: calendar.startOfDay(for: Date())).day ?? 0

        guard daysSinceCreation > 0 else { return completedDaysCount > 0 ? 100 : 0 }
        return Double(completedDaysCount) / Double(daysSinceCreation + 1) * 100
    }

    /// Is completed for today
    var isCompletedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.contains {
            calendar.isDate($0.date, inSameDayAs: today) && $0.value >= targetValue
        }
    }

    /// Today's entry (if exists)
    var todayEntry: HabitEntry? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.first { calendar.isDate($0.date, inSameDayAs: today) }
    }

    // MARK: - Methods

    func completeToday(value: Double? = nil) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let existing = entries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            existing.value = value ?? targetValue
        } else {
            let entry = HabitEntry(date: today, value: value ?? targetValue, habit: self)
            entries.append(entry)
        }
    }

    func uncompleteToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        entries.removeAll { calendar.isDate($0.date, inSameDayAs: today) }
    }

    func terminate() {
        isTerminated = true
        terminatedDate = Date()
    }

    func markMilestoneShown() {
        milestoneShown = true
    }

    // MARK: - Today pause (stored in UserDefaults — no SwiftData schema change needed)

    private var pauseKey: String { "habitPausedDate_\(id.uuidString)" }

    private static let pauseDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Whether this habit is paused for today only.
    var isPausedToday: Bool {
        let todayStr = Self.pauseDateFormatter.string(from: Date())
        return UserDefaults.standard.string(forKey: pauseKey) == todayStr
    }

    /// Mark this habit as paused for today. Automatically expires at midnight.
    func pauseForToday() {
        let todayStr = Self.pauseDateFormatter.string(from: Date())
        UserDefaults.standard.set(todayStr, forKey: pauseKey)
    }

    /// Remove today's pause.
    func unpauseToday() {
        UserDefaults.standard.removeObject(forKey: pauseKey)
    }
}

// MARK: - HabitFrequency Enum

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"

    var systemImage: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        }
    }
}
