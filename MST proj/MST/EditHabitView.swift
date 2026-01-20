//
//  EditHabitView.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Title", text: $habit.title)

                    TextField("Description (optional)", text: $habit.habitDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Goal") {
                    HStack {
                        Text("Target")
                        Spacer()
                        TextField("Value", value: $habit.targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)

                        Picker("", selection: $habit.unit) {
                            ForEach(TargetUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    Picker("Frequency", selection: $habit.frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Label(freq.rawValue, systemImage: freq.systemImage)
                                .tag(freq)
                        }
                    }
                }

                Section {
                    Stepper("Milestone: \(habit.maxCompletionDays) days", value: $habit.maxCompletionDays, in: 7...365, step: 7)
                } footer: {
                    Text("After completing this many days, you'll be prompted to finish or continue the habit.")
                }

                Section("Status") {
                    Toggle("Terminated", isOn: $habit.isTerminated)
                        .onChange(of: habit.isTerminated) { _, newValue in
                            habit.terminatedDate = newValue ? Date() : nil
                        }

                    if habit.isTerminated, let terminatedDate = habit.terminatedDate {
                        HStack {
                            Text("Terminated on")
                            Spacer()
                            Text(terminatedDate, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Statistics") {
                    HStack {
                        Text("Completed Days")
                        Spacer()
                        Text("\(habit.completedDaysCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(habit.currentStreak) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Best Streak")
                        Spacer()
                        Text("\(habit.bestStreak) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Completion Rate")
                        Spacer()
                        Text(String(format: "%.1f%%", habit.completionRate))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Created")
                        Spacer()
                        Text(habit.createdDate, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EditHabitView(habit: Habit(title: "Read books", targetValue: 30, unit: .minute))
        .environmentObject(ThemeManager())
}
