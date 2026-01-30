//
//  PointsDetailView.swift
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
import SwiftData

struct PointsDetailView: View {
    @EnvironmentObject private var pointsManager: PointsManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Assignment> { $0.pointsAwarded })
    private var awardedAssignments: [Assignment]

    @Query(filter: #Predicate<Goal> { $0.pointsAwarded })
    private var awardedGoals: [Goal]

    @Query(filter: #Predicate<HabitEntry> { $0.pointsAwarded })
    private var awardedHabitEntries: [HabitEntry]

    var body: some View {
        NavigationStack {
            List {
                // Hero section
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)

                        Text("\(pointsManager.currentPoints)")
                            .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())

                        Text("Current Points")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }

                // Breakdown
                Section("Breakdown") {
                    HStack {
                        Label("Assignments", systemImage: "book.fill")
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(awardedAssignments.count) pts")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Goals", systemImage: "flag.fill")
                            .foregroundStyle(.purple)
                        Spacer()
                        Text("\(awardedGoals.count * 3) pts")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Habits", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("\(awardedHabitEntries.count) pts")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                // Lifetime
                Section("Lifetime") {
                    HStack {
                        Label("Total Earned", systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(pointsManager.totalPointsEarned) pts")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                // Coming soon
                Section("Spending") {
                    HStack {
                        Label("Coming soon", systemImage: "sparkles")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
