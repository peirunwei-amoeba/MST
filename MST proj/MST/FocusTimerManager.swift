//
//  FocusTimerManager.swift
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

/// Shared timer state observable for the tab bar accessory.
/// FocusView owns the timer logic and syncs state to this manager.
/// ContentView reads from this to display the tab bar bottom accessory.
@Observable
class FocusTimerManager {
    var isRunning: Bool = false
    var isPaused: Bool = false
    var remainingSeconds: Int = 0
    var selectedTaskTitle: String?

    var isActive: Bool {
        isRunning || isPaused
    }

    var formattedTimeRemaining: String {
        let h = remainingSeconds / 3600
        let m = (remainingSeconds % 3600) / 60
        let s = remainingSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
