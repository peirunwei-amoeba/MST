//
//  AddHabitView.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var title = ""
    @State private var habitDescription = ""
    @State private var targetValue: Double = 1.0
    @State private var selectedUnit: TargetUnit = .times
    @State private var frequency: HabitFrequency = .daily
    @State private var maxCompletionDays: Int = 60

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Title (e.g., Read books)", text: $title)

                    TextField("Description (optional)", text: $habitDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Goal") {
                    HStack {
                        Text("Target")
                        Spacer()
                        TextField("Value", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)

                        Picker("", selection: $selectedUnit) {
                            ForEach(TargetUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Label(freq.rawValue, systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }
                }

                Section {
                    Stepper("Milestone: \(maxCompletionDays) days", value: $maxCompletionDays, in: 7...365, step: 7)
                } footer: {
                    Text("After completing this many days, you'll be prompted to finish or continue the habit.")
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.largeTitle)
                                .foregroundStyle(themeManager.accentColor)

                            Text("Preview")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(selectedUnit.format(targetValue))
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addHabit() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addHabit() {
        let habit = Habit(
            title: title.trimmingCharacters(in: .whitespaces),
            habitDescription: habitDescription,
            targetValue: targetValue,
            unit: selectedUnit,
            frequency: frequency,
            maxCompletionDays: maxCompletionDays
        )
        modelContext.insert(habit)
        dismiss()
    }
}

#Preview {
    AddHabitView()
        .environmentObject(ThemeManager())
}
