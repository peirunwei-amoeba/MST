//
//  AssignmentRowView.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
//

import SwiftUI
import AVFoundation

struct AssignmentRowView: View {
    let assignment: Assignment
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Interactive completion checkbox with SF Symbol
            Button {
                if !assignment.isCompleted {
                    // Haptic feedback
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)

                    // System sound
                    AudioServicesPlaySystemSound(1407)
                }
                onToggleComplete()
            } label: {
                Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(assignment.isCompleted ? .green : .secondary.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
            }
            .buttonStyle(.plain)

            // Tappable content area
            Button {
                onTap()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(assignment.title)
                            .font(.headline)
                            .strikethrough(assignment.isCompleted)
                            .foregroundStyle(assignment.isCompleted ? .secondary : .primary)

                        // Subject and due date
                        HStack(spacing: 8) {
                            if !assignment.subject.isEmpty {
                                Text(assignment.subject)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }

                            Label(assignment.formattedDueDate, systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(dueDateColor)
                        }
                    }

                    Spacer()

                    // Priority indicator
                    priorityBadge

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var dueDateColor: Color {
        if assignment.isCompleted {
            return .secondary
        } else if assignment.isOverdue {
            return .red
        } else if assignment.isDueToday {
            return .orange
        } else if assignment.isDueTomorrow {
            return .yellow
        } else {
            return .secondary
        }
    }

    private var priorityBadge: some View {
        Group {
            switch assignment.priority {
            case .urgent:
                Image(systemName: "exclamationmark.2")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            case .high:
                Image(systemName: "exclamationmark")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            case .low:
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .medium, .none:
                EmptyView()
            }
        }
    }
}

#Preview {
    List {
        AssignmentRowView(
            assignment: Assignment(
                title: "Math Homework",
                dueDate: Date().addingTimeInterval(86400),
                priority: .high,
                subject: "Mathematics"
            ),
            onToggleComplete: {},
            onTap: {}
        )
        AssignmentRowView(
            assignment: Assignment(
                title: "Essay Draft",
                dueDate: Date(),
                priority: .urgent,
                subject: "English"
            ),
            onToggleComplete: {},
            onTap: {}
        )
        AssignmentRowView(
            assignment: Assignment(
                title: "Completed Task",
                dueDate: Date(),
                isCompleted: true,
                subject: "History"
            ),
            onToggleComplete: {},
            onTap: {}
        )
    }
}
