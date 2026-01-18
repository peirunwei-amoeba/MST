//
//  EditProjectView.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
//

import SwiftUI
import SwiftData

struct EditProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project

    @State private var newGoalTitle = ""
    @State private var newGoalDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $project.title)

                    TextField("Description", text: $project.projectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Timeline") {
                    DatePicker("Deadline", selection: $project.deadline, displayedComponents: .date)
                }

                Section("Status") {
                    Toggle("Completed", isOn: $project.isCompleted)
                        .onChange(of: project.isCompleted) { _, newValue in
                            project.completedDate = newValue ? Date() : nil
                        }

                    if project.isCompleted, let completedDate = project.completedDate {
                        HStack {
                            Text("Completed on")
                            Spacer()
                            Text(completedDate, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    ForEach(project.sortedGoals) { goal in
                        GoalEditRow(goal: goal)
                    }
                    .onDelete(perform: deleteGoals)

                    // Add new goal inline
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("New goal title", text: $newGoalTitle)
                        HStack {
                            DatePicker("Target date", selection: $newGoalDate, displayedComponents: .date)
                            Button {
                                addGoal()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Swipe left on a goal to delete it")
                }

                Section("Information") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(project.createdDate, style: .date)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Progress")
                        Spacer()
                        Text("\(project.completedGoalsCount)/\(project.goals.count) goals (\(Int(project.progressPercentage))%)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Project")
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

    private func addGoal() {
        let goal = Goal(
            title: newGoalTitle.trimmingCharacters(in: .whitespaces),
            targetDate: newGoalDate,
            sortOrder: project.goals.count,
            project: project
        )
        project.goals.append(goal)
        newGoalTitle = ""
        newGoalDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: newGoalDate) ?? newGoalDate
    }

    private func deleteGoals(at offsets: IndexSet) {
        let sortedGoals = project.sortedGoals
        for index in offsets {
            let goal = sortedGoals[index]
            if let projectIndex = project.goals.firstIndex(where: { $0.id == goal.id }) {
                let goalToDelete = project.goals[projectIndex]
                project.goals.remove(at: projectIndex)
                modelContext.delete(goalToDelete)
            }
        }
    }
}

// MARK: - Goal Edit Row

struct GoalEditRow: View {
    @Bindable var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(goal.isCompleted ? .green : .secondary)

                TextField("Goal title", text: $goal.title)
            }

            HStack {
                DatePicker("Target", selection: $goal.targetDate, displayedComponents: .date)
                    .labelsHidden()

                Spacer()

                Toggle("Done", isOn: $goal.isCompleted)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .onChange(of: goal.isCompleted) { _, newValue in
                        goal.completedDate = newValue ? Date() : nil
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EditProjectView(project: {
        let project = Project(
            title: "Sample Project",
            projectDescription: "This is a sample project",
            deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        )
        project.goals = [
            Goal(title: "Research", targetDate: Date(), isCompleted: true),
            Goal(title: "Design", targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
        ]
        return project
    }())
    .modelContainer(for: [Project.self, Goal.self], inMemory: true)
}
