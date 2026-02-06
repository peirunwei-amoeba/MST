//
//  PointsLedger.swift
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
final class PointsLedger {
    @Attribute(.unique) var id: UUID
    var totalPointsEarned: Int
    var totalPointsSpent: Int

    var remainingPoints: Int {
        totalPointsEarned - totalPointsSpent
    }

    init(
        id: UUID = UUID(),
        totalPointsEarned: Int = 0,
        totalPointsSpent: Int = 0
    ) {
        self.id = id
        self.totalPointsEarned = totalPointsEarned
        self.totalPointsSpent = totalPointsSpent
    }
}
