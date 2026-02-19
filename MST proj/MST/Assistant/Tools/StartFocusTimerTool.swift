//
//  StartFocusTimerTool.swift
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

struct StartFocusTimerTool: Tool {
    let name = "startFocusTimer"
    let description = "Set a focus timer for a specified number of minutes. The timer will appear on the Focus tab."

    @Generable
    struct Arguments {
        @Guide(description: "Number of minutes for the focus timer (1-239)")
        var minutes: Int
    }

    var focusTimerBridge: FocusTimerBridge
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        let minutes = max(1, min(239, arguments.minutes))
        await MainActor.run {
            focusTimerBridge.requestedMinutes = minutes
            focusTimerBridge.shouldAutoStart = true
        }
        let result = "Focus timer set to \(minutes) minutes and starting now. You can manage it on the Focus tab."
        tracker.record(name: name, result: result)
        return result
    }
}

