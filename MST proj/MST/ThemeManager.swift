//
//  ThemeManager.swift
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
import Combine
import AudioToolbox

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case teal = "Teal"
    case indigo = "Indigo"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

enum TimerAlarmSound: String, CaseIterable, Identifiable {
    case none = "None"
    case bloom = "Bloom"
    case calypso = "Calypso"
    case chooChoo = "Choo Choo"
    case descent = "Descent"
    case fanfare = "Fanfare"
    case ladder = "Ladder"
    case minuet = "Minuet"
    case newsFlash = "News Flash"
    case noir = "Noir"
    case sherwoodForest = "Sherwood Forest"
    case spell = "Spell"
    case suspense = "Suspense"
    case telegraph = "Telegraph"
    case tiptoes = "Tiptoes"
    case typewriters = "Typewriters"
    case update = "Update"

    var id: String { rawValue }

    /// System sound ID for each tone
    var systemSoundID: SystemSoundID {
        switch self {
        case .none: return 0
        case .bloom: return 1334
        case .calypso: return 1335
        case .chooChoo: return 1336
        case .descent: return 1337
        case .fanfare: return 1338
        case .ladder: return 1339
        case .minuet: return 1340
        case .newsFlash: return 1341
        case .noir: return 1342
        case .sherwoodForest: return 1343
        case .spell: return 1344
        case .suspense: return 1345
        case .telegraph: return 1346
        case .tiptoes: return 1347
        case .typewriters: return 1348
        case .update: return 1349
        }
    }

    /// Play the alarm sound with vibration
    func play() {
        guard self != .none else { return }
        AudioServicesPlayAlertSound(systemSoundID)
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("selectedAccentColor") private var selectedAccentColorRaw: String = AccentColorOption.blue.rawValue
    @AppStorage("keepScreenOnDuringFocus") private var keepScreenOnDuringFocusRaw: Bool = true
    @AppStorage("timerAlarmSound") private var timerAlarmSoundRaw: String = TimerAlarmSound.fanfare.rawValue
    @AppStorage("assistantName") var assistantName: String = "Spark"
    @AppStorage("userName") var userName: String = ""
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var selectedTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .system }
        set {
            selectedThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var selectedAccentColorOption: AccentColorOption {
        get { AccentColorOption(rawValue: selectedAccentColorRaw) ?? .blue }
        set {
            selectedAccentColorRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var accentColor: Color {
        selectedAccentColorOption.color
    }

    var colorScheme: ColorScheme? {
        selectedTheme.colorScheme
    }

    var backgroundColor: Color {
        Color(.systemGroupedBackground)
    }

    var cardBackgroundColor: Color {
        Color(.secondarySystemGroupedBackground)
    }

    var keepScreenOnDuringFocus: Bool {
        get { keepScreenOnDuringFocusRaw }
        set {
            keepScreenOnDuringFocusRaw = newValue
            objectWillChange.send()
        }
    }

    var timerAlarmSound: TimerAlarmSound {
        get { TimerAlarmSound(rawValue: timerAlarmSoundRaw) ?? .fanfare }
        set {
            timerAlarmSoundRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
}

