//
//  UserProfileData.swift
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

import SwiftData
import Foundation

@Model
final class UserProfileData {
    var id: UUID = UUID()
    var name: String = ""
    var birthday: Date = Date()
    var gender: String = ""
    var educationSystem: String = ""
    var gradeLevel: String = ""
    var interests: [String] = []
    var createdDate: Date = Date()

    init(
        name: String = "",
        birthday: Date = Date(),
        gender: String = "",
        educationSystem: String = "",
        gradeLevel: String = "",
        interests: [String] = []
    ) {
        self.name = name
        self.birthday = birthday
        self.gender = gender
        self.educationSystem = educationSystem
        self.gradeLevel = gradeLevel
        self.interests = interests
    }
}
