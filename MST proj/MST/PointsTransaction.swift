//
//  PointsTransaction.swift
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
final class PointsTransaction {
    @Attribute(.unique) var id: UUID
    var sourceType: String
    var sourceId: UUID
    var periodKey: String
    var pointsAwarded: Int
    var awardedDate: Date
    var sourceTitle: String

    init(
        id: UUID = UUID(),
        sourceType: String,
        sourceId: UUID,
        periodKey: String,
        pointsAwarded: Int,
        awardedDate: Date = Date(),
        sourceTitle: String = ""
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.periodKey = periodKey
        self.pointsAwarded = pointsAwarded
        self.awardedDate = awardedDate
        self.sourceTitle = sourceTitle
    }
}
