//
//  SettingsView.swift
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

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingChangelog = false

    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section("Appearance") {
                    // Theme picker
                    Picker("Theme", selection: Binding(
                        get: { themeManager.selectedTheme },
                        set: { themeManager.selectedTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.rawValue, systemImage: theme.iconName)
                                .tag(theme)
                        }
                    }

                    // Accent color picker
                    NavigationLink {
                        AccentColorPickerView()
                    } label: {
                        HStack {
                            Text("Accent Color")
                            Spacer()
                            Circle()
                                .fill(themeManager.accentColor)
                                .frame(width: 24, height: 24)
                        }
                    }
                }

                // Focus Timer Section
                Section("Focus Timer") {
                    Toggle("Keep Screen On During Focus", isOn: Binding(
                        get: { themeManager.keepScreenOnDuringFocus },
                        set: { themeManager.keepScreenOnDuringFocus = $0 }
                    ))

                    NavigationLink {
                        TimerSoundPickerView()
                    } label: {
                        HStack {
                            Text("Alarm Sound")
                            Spacer()
                            Text(themeManager.timerAlarmSound.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // About Section
                Section("About") {
                    Button {
                        showingChangelog = true
                    } label: {
                        HStack {
                            Label("Changelog", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(.primary)
                    }

                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingChangelog) {
                ChangelogView()
            }
        }
    }
}

// MARK: - Accent Color Picker View

struct AccentColorPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(AccentColorOption.allCases) { colorOption in
                    ColorOptionButton(
                        colorOption: colorOption,
                        isSelected: themeManager.selectedAccentColorOption == colorOption
                    ) {
                        themeManager.selectedAccentColorOption = colorOption
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorOptionButton: View {
    let colorOption: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(colorOption.color)
                        .frame(width: 50, height: 50)

                    if isSelected {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }
                }

                Text(colorOption.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? colorOption.color : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timer Sound Picker View

struct TimerSoundPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        List {
            ForEach(TimerAlarmSound.allCases) { sound in
                Button {
                    sound.play()
                    themeManager.timerAlarmSound = sound
                } label: {
                    HStack {
                        Text(sound.rawValue)
                            .foregroundStyle(.primary)

                        Spacer()

                        if themeManager.timerAlarmSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundStyle(themeManager.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Alarm Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Changelog View

struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(changelogEntries) { entry in
                    ChangelogEntryView(entry: entry)
                }
            }
            .navigationTitle("Changelog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var changelogEntries: [ChangelogEntry] {
        [
            ChangelogEntry(
                version: "1.0.0",
                date: "January 2026",
                changes: [
                    ChangeItem(type: .new, description: "Initial release"),
                    ChangeItem(type: .new, description: "Assignment tracking with due dates"),
                    ChangeItem(type: .new, description: "Priority levels for assignments"),
                    ChangeItem(type: .new, description: "Swipe to complete or delete"),
                    ChangeItem(type: .new, description: "Multiple sorting and filtering options"),
                    ChangeItem(type: .new, description: "Customizable themes and accent colors"),
                    ChangeItem(type: .new, description: "Search functionality")
                ]
            )
        ]
    }
}

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let changes: [ChangeItem]
}

struct ChangeItem: Identifiable {
    let id = UUID()
    let type: ChangeType
    let description: String
}

enum ChangeType: String {
    case new = "New"
    case improved = "Improved"
    case fixed = "Fixed"

    var color: Color {
        switch self {
        case .new: return .green
        case .improved: return .blue
        case .fixed: return .orange
        }
    }

    var icon: String {
        switch self {
        case .new: return "plus.circle.fill"
        case .improved: return "arrow.up.circle.fill"
        case .fixed: return "wrench.and.screwdriver.fill"
        }
    }
}

struct ChangelogEntryView: View {
    let entry: ChangelogEntry

    var body: some View {
        Section {
            ForEach(entry.changes) { change in
                HStack(spacing: 12) {
                    Image(systemName: change.type.icon)
                        .foregroundStyle(change.type.color)

                    Text(change.description)
                        .font(.subheadline)
                }
            }
        } header: {
            HStack {
                Text("Version \(entry.version)")
                    .font(.headline)
                Spacer()
                Text(entry.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .textCase(nil)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
