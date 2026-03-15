//
//  DailyFocusTargetEditorView.swift
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

struct DailyFocusTargetEditorView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private let presets = [30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Focus Goal") {
                    Toggle("Enable Daily Focus Goal", isOn: Binding(
                        get: { themeManager.dailyFocusTargetEnabled },
                        set: { themeManager.dailyFocusTargetEnabled = $0 }
                    ))

                    if themeManager.dailyFocusTargetEnabled {
                        Stepper(
                            "Target: \(themeManager.dailyFocusTargetMinutes) min",
                            value: Binding(
                                get: { themeManager.dailyFocusTargetMinutes },
                                set: { themeManager.dailyFocusTargetMinutes = $0 }
                            ),
                            in: 10...480,
                            step: 5
                        )

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.self) { preset in
                                    Button("\(preset)m") {
                                        themeManager.dailyFocusTargetMinutes = preset
                                    }
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        themeManager.dailyFocusTargetMinutes == preset
                                            ? themeManager.accentColor.opacity(0.15)
                                            : Color.secondary.opacity(0.1)
                                    )
                                    .foregroundStyle(
                                        themeManager.dailyFocusTargetMinutes == preset
                                            ? themeManager.accentColor
                                            : .secondary
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }

                if themeManager.dailyFocusTargetEnabled {
                    Section("Today's Progress") {
                        let todayMin = themeManager.todayFocusSeconds / 60
                        let progress = themeManager.todayFocusProgress

                        HStack {
                            Text("Focus Time Today")
                            Spacer()
                            Text("\(todayMin) / \(themeManager.dailyFocusTargetMinutes) min")
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: min(progress, 1.0))
                            .tint(progress >= 1.0 ? .green : themeManager.accentColor)
                    }
                }
            }
            .navigationTitle("Daily Focus Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
