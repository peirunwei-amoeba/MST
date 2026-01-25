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

@MainActor
class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("selectedAccentColor") private var selectedAccentColorRaw: String = AccentColorOption.blue.rawValue

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
}

