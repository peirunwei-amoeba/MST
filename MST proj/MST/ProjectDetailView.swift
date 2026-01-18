//
//  ProjectDetailView.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with progress
                headerSection

                // Timeline
                timelineSection
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectView(project: project)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(project.completedGoalsCount) of \(project.goals.count) goals")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(project.progressPercentage))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.accentColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.secondary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.accentColor)
                            .frame(width: geometry.size.width * (project.progressPercentage / 100), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Project description
            if !project.projectDescription.isEmpty {
                Text(project.projectDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Deadline info
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text("Deadline: \(project.formattedDeadline)")
                    .font(.subheadline)
                    .foregroundStyle(project.isOverdue ? .red : .secondary)

                Spacer()

                if project.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                } else if project.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Timeline")
                .font(.title3.weight(.semibold))
                .padding(.bottom, 16)

            if project.goals.isEmpty {
                emptyGoalsView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(project.sortedGoals.enumerated()), id: \.element.id) { index, goal in
                        GoalTimelineRow(
                            goal: goal,
                            isLast: index == project.goals.count - 1,
                            onToggleComplete: {
                                toggleGoalCompletion(goal)
                            }
                        )
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }

    private var emptyGoalsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.pattern.checkered")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No goals yet")
                .font(.headline)

            Text("Add milestones to track your progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingEditSheet = true
            } label: {
                Label("Add Goals", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(themeManager.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private func toggleGoalCompletion(_ goal: Goal) {
        let wasCompleted = goal.isCompleted

        if !wasCompleted {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1407)
        }

        withAnimation {
            goal.toggleCompletion()
        }
    }
}

// MARK: - Goal Timeline Row

struct GoalTimelineRow: View {
    let goal: Goal
    let isLast: Bool
    let onToggleComplete: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator with connecting line
            VStack(spacing: 0) {
                Button {
                    onToggleComplete()
                } label: {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(goal.isCompleted ? .green : .secondary.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                }
                .buttonStyle(.plain)

                if !isLast {
                    Rectangle()
                        .fill(goal.isCompleted ? Color.green.opacity(0.5) : Color.secondary.opacity(0.2))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            // Goal content
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                    .strikethrough(goal.isCompleted, color: .secondary)

                HStack(spacing: 8) {
                    Text(goal.formattedTargetDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if goal.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    } else if goal.isOverdue {
                        Text("Overdue")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 20)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: {
            let project = Project(
                title: "Sample Project",
                projectDescription: "This is a sample project description",
                deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
            )
            project.goals = [
                Goal(title: "Research", targetDate: Date(), isCompleted: true),
                Goal(title: "Design", targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, isCompleted: true),
                Goal(title: "Implementation", targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!),
                Goal(title: "Testing", targetDate: Calendar.current.date(byAdding: .day, value: 21, to: Date())!),
                Goal(title: "Launch", targetDate: Calendar.current.date(byAdding: .day, value: 28, to: Date())!)
            ]
            return project
        }())
        .environmentObject(ThemeManager())
    }
}
