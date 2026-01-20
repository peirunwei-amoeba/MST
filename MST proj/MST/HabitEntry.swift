//
//  HabitEntry.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import Foundation
import SwiftData

@Model
final class HabitEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var value: Double
    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.habit = habit
    }
}
