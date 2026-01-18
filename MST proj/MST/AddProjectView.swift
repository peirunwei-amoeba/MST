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
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var goalEntries: [GoalEntry] = []

    struct GoalEntry: Identifiable {
        let id = UUID()
        var title: String
        var targetDate: Date
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $title)

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
                            DatePicker("Target date", selection: $entry.targetDate, displayedComponents: .date)
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

    private func addProject() {
        let project = Project(
            title: title.trimmingCharacters(in: .whitespaces),
            projectDescription: projectDescription,
            deadline: deadline
        )

        // Create goals from entries
        for (index, entry) in goalEntries.enumerated() {
            if !entry.title.trimmingCharacters(in: .whitespaces).isEmpty {
                let goal = Goal(
                    title: entry.title.trimmingCharacters(in: .whitespaces),
                    targetDate: entry.targetDate,
                    sortOrder: index,
                    project: project
                )
                project.goals.append(goal)
            }
        }

        modelContext.insert(project)
        dismiss()
    }
}

#Preview {
    AddProjectView()
        .modelContainer(for: [Project.self, Goal.self], inMemory: true)
}
