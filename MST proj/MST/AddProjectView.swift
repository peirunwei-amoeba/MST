//
//  AddProjectView.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
//

import SwiftUI
import SwiftData

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var projectDescription = ""
    @State private var subject = ""
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var goalEntries: [GoalEntry] = []

    struct GoalEntry: Identifiable {
        let id = UUID()
        var title: String
        var targetDate: Date
        var targetTime: Date = Date()
        var priority: Priority = .none
        var hasTarget: Bool = false
        var targetValue: Double = 1.0
        var targetValueString: String = "1"
        var targetUnit: TargetUnit = .hour
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $title)

                    TextField("Subject (optional)", text: $subject)

                    TextField("Description", text: $projectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Timeline") {
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }

                Section {
                    ForEach($goalEntries) { $entry in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Goal title", text: $entry.title)

                            HStack {
                                DatePicker("Date", selection: $entry.targetDate, displayedComponents: .date)
                                    .labelsHidden()
                                DatePicker("Time", selection: $entry.targetTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()

                                Spacer()

                                Picker("Priority", selection: $entry.priority) {
                                    ForEach(Priority.allCases, id: \.self) { priority in
                                        HStack {
                                            Circle()
                                                .fill(priorityColor(for: priority))
                                                .frame(width: 10, height: 10)
                                            Text(priority.rawValue)
                                        }
                                        .tag(priority)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            // Target row
                            HStack {
                                Toggle("", isOn: $entry.hasTarget.animation(.easeInOut(duration: 0.2)))
                                    .labelsHidden()
                                Text("Target:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if entry.hasTarget {
                                    TextField("", text: $entry.targetValueString)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 50)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .onChange(of: entry.targetValueString) { _, newValue in
                                            if let doubleValue = Double(newValue) {
                                                entry.targetValue = doubleValue
                                            }
                                        }

                                    Picker("", selection: $entry.targetUnit) {
                                        ForEach(TargetUnit.allCases) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                } else {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteGoal)
                    .onMove(perform: moveGoal)

                    Button {
                        addGoalEntry()
                    } label: {
                        Label("Add Goal", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    if goalEntries.isEmpty {
                        Text("Add milestones to track your project progress")
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addProject()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
    }

    private func addGoalEntry() {
        let lastDate = goalEntries.last?.targetDate ?? Date()
        let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: lastDate) ?? lastDate
        goalEntries.append(GoalEntry(title: "", targetDate: min(nextDate, deadline)))
    }

    private func deleteGoal(at offsets: IndexSet) {
        goalEntries.remove(atOffsets: offsets)
    }

    private func moveGoal(from source: IndexSet, to destination: Int) {
        goalEntries.move(fromOffsets: source, toOffset: destination)
    }

    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .none: return .gray
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    private func addProject() {
        let project = Project(
            title: title.trimmingCharacters(in: .whitespaces),
            projectDescription: projectDescription,
            deadline: deadline,
            subject: subject.trimmingCharacters(in: .whitespaces)
        )

        // Create goals from entries
        for (index, entry) in goalEntries.enumerated() {
            if !entry.title.trimmingCharacters(in: .whitespaces).isEmpty {
                // Combine date and time
                let combinedDate = combineDateAndTime(date: entry.targetDate, time: entry.targetTime)

                let goal = Goal(
                    title: entry.title.trimmingCharacters(in: .whitespaces),
                    targetDate: combinedDate,
                    sortOrder: index,
                    priority: entry.priority,
                    project: project,
                    targetValue: entry.hasTarget ? entry.targetValue : nil,
                    targetUnit: entry.hasTarget ? entry.targetUnit : .none
                )
                project.goals.append(goal)
            }
        }

        modelContext.insert(project)
        dismiss()
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? date
    }
}

#Preview {
    AddProjectView()
        .modelContainer(for: [Project.self, Goal.self], inMemory: true)
}
