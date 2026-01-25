//
//  HabitEntry.swift
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
