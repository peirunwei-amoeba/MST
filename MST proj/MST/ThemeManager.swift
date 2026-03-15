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

enum NamedTheme: String, CaseIterable, Identifiable {
    case bayley = "Bayley"
    case hullet = "Hullet"
    case morrison = "Morrison"
    case buckley = "Buckley"
    case moor = "Moor"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .bayley:   return Color(hue: 0.128, saturation: 0.90, brightness: 0.95)
        case .hullet:   return Color(hue: 0.765, saturation: 0.80, brightness: 0.85)
        case .morrison: return Color(hue: 0.600, saturation: 0.85, brightness: 0.95)
        case .buckley:  return Color(hue: 0.380, saturation: 0.85, brightness: 0.82)
        case .moor:     return Color(hue: 0.000, saturation: 0.90, brightness: 0.90)
        }
    }

    var secondary: Color {
        switch self {
        case .bayley:   return Color(hue: 0.105, saturation: 0.85, brightness: 0.82)
        case .hullet:   return Color(hue: 0.765, saturation: 0.90, brightness: 0.50)
        case .morrison: return Color(hue: 0.575, saturation: 0.65, brightness: 0.85)
        case .buckley:  return Color(hue: 0.400, saturation: 0.65, brightness: 0.90)
        case .moor:     return Color(hue: 0.020, saturation: 0.70, brightness: 0.95)
        }
    }

    var tertiary: Color {
        switch self {
        case .bayley:   return Color(hue: 0.110, saturation: 0.95, brightness: 0.60)
        case .hullet:   return Color(hue: 0.765, saturation: 0.70, brightness: 0.18)
        case .morrison: return Color(hue: 0.630, saturation: 0.90, brightness: 0.50)
        case .buckley:  return Color(hue: 0.370, saturation: 0.95, brightness: 0.45)
        case .moor:     return Color(hue: 0.985, saturation: 0.95, brightness: 0.55)
        }
    }

    var iconName: String {
        switch self {
        case .bayley:   return "sun.max.fill"
        case .hullet:   return "moon.stars.fill"
        case .morrison: return "bolt.fill"
        case .buckley:  return "leaf.fill"
        case .moor:     return "flame.fill"
        }
    }

    /// Hullet forces dark mode; all other themes respect the AppTheme setting.
    var forcedColorScheme: ColorScheme? {
        self == .hullet ? .dark : nil
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
}

@MainActor
class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("selectedNamedTheme") private var selectedNamedThemeRaw: String = NamedTheme.bayley.rawValue
    @AppStorage("keepScreenOnDuringFocus") private var keepScreenOnDuringFocusRaw: Bool = true
    @AppStorage("timerAlarmSound") private var timerAlarmSoundRaw: String = TimerAlarmSound.fanfare.rawValue
    @AppStorage("assistantName") var assistantName: String = "Spark"
    @AppStorage("assistantIconName") var assistantIconName: String = "sparkles"
    @AppStorage("userName") var userName: String = ""
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userProfileSummary") var userProfileSummary: String = ""
    @AppStorage("focusSessionsCompleted") var focusSessionsCompleted: Int = 0
    @AppStorage("focusTotalMinutes") var focusTotalMinutes: Int = 0

    var selectedTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .system }
        set {
            selectedThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var selectedNamedTheme: NamedTheme {
        get { NamedTheme(rawValue: selectedNamedThemeRaw) ?? .bayley }
        set {
            selectedNamedThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var accentColor: Color {
        selectedNamedTheme.primary
    }

    var secondaryAccentColor: Color {
        selectedNamedTheme.secondary
    }

    var tertiaryAccentColor: Color {
        selectedNamedTheme.tertiary
    }

    var colorScheme: ColorScheme? {
        selectedNamedTheme.forcedColorScheme ?? selectedTheme.colorScheme
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

