//
//  AddAssignmentView.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
//

import SwiftUI
import SwiftData

struct AddAssignmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var assignmentDescription = ""
    @State private var dueDate = Date()
    @State private var dueTime = Date()
    @State private var priority: Priority = .medium
    @State private var subject = ""
    @State private var notes = ""
    @State private var notificationEnabled = true

    // For navigating to edit after creation
    var onAssignmentCreated: ((Assignment) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Title", text: $title)

                    TextField("Description", text: $assignmentDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Due Date & Time") {
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                }

                Section("Organization") {
                    TextField("Subject", text: $subject)

                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }

                Section("Additional") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)

                    Toggle("Enable Notifications", isOn: $notificationEnabled)
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAssignment()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addAssignment() {
        let combinedDueDate = combineDateAndTime(date: dueDate, time: dueTime)

        let assignment = Assignment(
            title: title.trimmingCharacters(in: .whitespaces),
            assignmentDescription: assignmentDescription,
            dueDate: combinedDueDate,
            priority: priority,
            subject: subject,
            notes: notes,
            notificationEnabled: notificationEnabled
        )

        modelContext.insert(assignment)
        onAssignmentCreated?(assignment)
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
    AddAssignmentView()
        .modelContainer(for: Assignment.self, inMemory: true)
}
