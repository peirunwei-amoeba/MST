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
    case beacon = "Beacon"
    case bulletin = "Bulletin"
    case chimes = "Chimes"
    case circuit = "Circuit"
    case constellation = "Constellation"
    case cosmic = "Cosmic"
    case crystals = "Crystals"
    case hillside = "Hillside"
    case illuminate = "Illuminate"
    case nightOwl = "Night Owl"
    case opening = "Opening"
    case playtime = "Playtime"
    case presto = "Presto"
    case radar = "Radar"
    case radiate = "Radiate"
    case ripples = "Ripples"
    case sencha = "Sencha"
    case signal = "Signal"
    case silk = "Silk"
    case slowRise = "Slow Rise"
    case stargaze = "Stargaze"
    case summit = "Summit"
    case twinkle = "Twinkle"
    case uplift = "Uplift"
    case waves = "Waves"

    var id: String { rawValue }

    /// The file name in /System/Library/Audio/UISounds/
    var fileName: String {
        switch self {
        case .beacon: return "alarm_Beacon.caf"
        case .bulletin: return "alarm_Bulletin.caf"
        case .chimes: return "alarm_Chimes.caf"
        case .circuit: return "alarm_Circuit.caf"
        case .constellation: return "alarm_Constellation.caf"
        case .cosmic: return "alarm_Cosmic.caf"
        case .crystals: return "alarm_Crystals.caf"
        case .hillside: return "alarm_Hillside.caf"
        case .illuminate: return "alarm_Illuminate.caf"
        case .nightOwl: return "alarm_Night_Owl.caf"
        case .opening: return "alarm_Opening.caf"
        case .playtime: return "alarm_Playtime.caf"
        case .presto: return "alarm_Presto.caf"
        case .radar: return "alarm_Radar.caf"
        case .radiate: return "alarm_Radiate.caf"
        case .ripples: return "alarm_Ripples.caf"
        case .sencha: return "alarm_Sencha.caf"
        case .signal: return "alarm_Signal.caf"
        case .silk: return "alarm_Silk.caf"
        case .slowRise: return "alarm_Slow_Rise.caf"
        case .stargaze: return "alarm_Stargaze.caf"
        case .summit: return "alarm_Summit.caf"
        case .twinkle: return "alarm_Twinkle.caf"
        case .uplift: return "alarm_Uplift.caf"
        case .waves: return "alarm_Waves.caf"
        }
    }

    /// Play the alarm sound
    func play() {
        let path = "/System/Library/Audio/UISounds/\(fileName)"
        let url = URL(fileURLWithPath: path)
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}

@MainActor
class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("selectedAccentColor") private var selectedAccentColorRaw: String = AccentColorOption.blue.rawValue
    @AppStorage("keepScreenOnDuringFocus") private var keepScreenOnDuringFocusRaw: Bool = true
    @AppStorage("timerAlarmSound") private var timerAlarmSoundRaw: String = TimerAlarmSound.radar.rawValue

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
        get { TimerAlarmSound(rawValue: timerAlarmSoundRaw) ?? .radar }
        set {
            timerAlarmSoundRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
}

