//
//  EditAssignmentView.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
//

import SwiftUI
import SwiftData

struct EditAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var assignment: Assignment

    @State private var dueDate: Date
    @State private var dueTime: Date

    init(assignment: Assignment) {
        self.assignment = assignment
        _dueDate = State(initialValue: assignment.dueDate)
        _dueTime = State(initialValue: assignment.dueDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Title", text: $assignment.title)

                    TextField("Description", text: $assignment.assignmentDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Due Date & Time") {
                    DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                        .onChange(of: dueDate) {
                            updateDueDate()
                        }

                    DatePicker("Time", selection: $dueTime, displayedComponents: .hourAndMinute)
                        .onChange(of: dueTime) {
                            updateDueDate()
                        }
                }

                Section("Organization") {
                    TextField("Subject", text: $assignment.subject)

                    Picker("Priority", selection: $assignment.priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }

                Section("Status") {
                    Toggle("Completed", isOn: $assignment.isCompleted)
                        .onChange(of: assignment.isCompleted) { _, newValue in
                            assignment.completedDate = newValue ? Date() : nil
                        }

                    if assignment.isCompleted, let completedDate = assignment.completedDate {
                        HStack {
                            Text("Completed on")
                            Spacer()
                            Text(completedDate, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle("Has target", isOn: hasTargetBinding)

                    if assignment.targetValue != nil {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("Value", value: targetValueBinding, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)

                            Picker("", selection: $assignment.targetUnit) {
                                ForEach(TargetUnit.allCases) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                    }
                } header: {
                    Text("Target")
                } footer: {
                    if assignment.targetValue != nil {
                        Text("e.g., Run 3 km, Study 2 hours")
                    }
                }

                Section("Additional") {
                    TextField("Notes", text: $assignment.notes, axis: .vertical)
                        .lineLimit(2...4)

                    Toggle("Enable Notifications", isOn: $assignment.notificationEnabled)
                }

                Section("Information") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(assignment.createdDate, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Assignment")
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

    private var hasTargetBinding: Binding<Bool> {
        Binding(
            get: { assignment.targetValue != nil },
            set: { newValue in
                if newValue {
                    assignment.targetValue = 1.0
                    assignment.targetUnit = .times
                } else {
                    assignment.targetValue = nil
                    assignment.targetUnit = .none
                }
            }
        )
    }

    private var targetValueBinding: Binding<Double> {
        Binding(
            get: { assignment.targetValue ?? 1.0 },
            set: { assignment.targetValue = $0 }
        )
    }

    private func updateDueDate() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        if let newDate = calendar.date(from: combined) {
            assignment.dueDate = newDate
        }
    }
}

#Preview {
    EditAssignmentView(assignment: Assignment(
        title: "Sample Assignment",
        dueDate: Date(),
        subject: "Mathematics"
    ))
    .modelContainer(for: Assignment.self, inMemory: true)
}
