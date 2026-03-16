//
//  UpdateAppSettingsTool.swift
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
import Combine

struct UpdateAppSettingsTool: Tool {
    let name = "updateAppSetting"
    let description = """
    Update an app setting on behalf of the user. Use this when the user asks to change a setting, \
    theme, their name, the assistant's name, focus goals, or any other app preference.

    Available settings:
    - userName: The user's display name (any string)
    - assistantName: The AI assistant's name (any string)
    - theme: Color mode — "System", "Light", or "Dark"
    - namedTheme: Color scheme — "Bayley" (amber), "Hullet" (purple/dark), "Morrison" (blue), "Buckley" (green), "Moor" (red)
    - keepScreenOn: Keep screen on during focus — "true" or "false"
    - alarmSound: Timer alarm — "None", "Bloom", "Calypso", "Choo Choo", "Descent", "Fanfare", "Ladder", "Minuet", "News Flash", "Noir", "Sherwood Forest", "Spell", "Suspense", "Telegraph", "Tiptoes", "Typewriters", "Update"
    - dailyFocusEnabled: Enable daily focus goal — "true" or "false"
    - dailyFocusMinutes: Daily focus target in minutes (10–480)
    - assistantIcon: SF Symbol name for the AI assistant button icon (e.g. "sparkles", "brain", "star.fill")
    """

    @Generable
    struct Arguments {
        @Guide(description: "The setting name to update. One of: userName, assistantName, theme, namedTheme, keepScreenOn, alarmSound, dailyFocusEnabled, dailyFocusMinutes, assistantIcon")
        var setting: String

        @Guide(description: "The new value for the setting. See tool description for valid values per setting.")
        var value: String
    }

    var themeManager: ThemeManager
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)

        let setting = arguments.setting.lowercased().trimmingCharacters(in: .whitespaces)
        let value = arguments.value.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = await MainActor.run { () -> String in
            applySettingChange(setting: setting, value: value)
        }

        tracker.record(name: name, result: result)
        return result
    }

    @MainActor
    private func applySettingChange(setting: String, value: String) -> String {
        switch setting {
        case "username":
            guard !value.isEmpty else { return "Name cannot be empty." }
            themeManager.userName = value
            themeManager.objectWillChange.send()
            return "Updated your name to '\(value)'"

        case "assistantname":
            guard !value.isEmpty else { return "Assistant name cannot be empty." }
            themeManager.assistantName = value
            themeManager.objectWillChange.send()
            return "Updated assistant name to '\(value)'"

        case "theme":
            let capitalized = value.prefix(1).uppercased() + value.dropFirst().lowercased()
            if let theme = AppTheme(rawValue: capitalized) {
                themeManager.selectedTheme = theme
                return "Changed display mode to \(theme.rawValue)"
            }
            return "Unknown theme '\(value)'. Options: System, Light, Dark"

        case "namedtheme":
            if let theme = NamedTheme.allCases.first(where: { $0.rawValue.lowercased() == value.lowercased() }) {
                themeManager.selectedNamedTheme = theme
                return "Changed color theme to \(theme.rawValue)"
            }
            let options = NamedTheme.allCases.map(\.rawValue).joined(separator: ", ")
            return "Unknown theme '\(value)'. Options: \(options)"

        case "keepscreenon":
            let enabled = ["true", "yes", "1", "on"].contains(value.lowercased())
            themeManager.keepScreenOnDuringFocus = enabled
            return "Keep screen on during focus: \(enabled ? "enabled" : "disabled")"

        case "alarmsound":
            if let sound = TimerAlarmSound.allCases.first(where: { $0.rawValue.lowercased() == value.lowercased() }) {
                themeManager.timerAlarmSound = sound
                return "Set alarm sound to '\(sound.rawValue)'"
            }
            let options = TimerAlarmSound.allCases.map(\.rawValue).joined(separator: ", ")
            return "Unknown sound '\(value)'. Options: \(options)"

        case "dailyfocusenabled":
            let enabled = ["true", "yes", "1", "on"].contains(value.lowercased())
            themeManager.dailyFocusTargetEnabled = enabled
            return "Daily focus goal: \(enabled ? "enabled" : "disabled")"

        case "dailyfocusminutes":
            if let minutes = Int(value), minutes >= 10, minutes <= 480 {
                themeManager.dailyFocusTargetMinutes = minutes
                return "Set daily focus goal to \(minutes) minutes"
            }
            return "Invalid value '\(value)'. Must be a whole number between 10 and 480."

        case "assistanticon":
            guard !value.isEmpty else { return "Icon name cannot be empty." }
            themeManager.assistantIconName = value
            themeManager.objectWillChange.send()
            return "Updated assistant icon to '\(value)'"

        default:
            return "Unknown setting '\(setting)'. Available: userName, assistantName, theme, namedTheme, keepScreenOn, alarmSound, dailyFocusEnabled, dailyFocusMinutes, assistantIcon"
        }
    }
}
