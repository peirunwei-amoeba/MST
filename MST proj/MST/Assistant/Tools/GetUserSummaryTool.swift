//
//  GetUserSummaryTool.swift
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
import FoundationModels

struct GetUserSummaryTool: Tool {
    let name = "getUserSummary"
    let description = "Get a profile summary of the user based on past conversations, including their focus areas, strengths, and patterns."

    @Generable
    struct Arguments {}

    var themeManager: ThemeManager
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        let summary = await themeManager.userProfileSummary
        let result = summary.isEmpty ? "No user profile summary available yet." : summary
        tracker.record(name: name, result: result)
        return result
    }
}
