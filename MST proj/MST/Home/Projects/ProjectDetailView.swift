//
//  ProjectDetailView.swift
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

            // Next goal date or project deadline
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)

                if let nextGoal = project.nextGoal {
                    Text("Next: \(nextGoal.formattedTargetDate)")
                        .font(.subheadline)
                        .foregroundStyle(nextGoal.isOverdue ? .red : .secondary)
                } else {
                    Text("Deadline: \(project.formattedDeadline)")
                        .font(.subheadline)
                        .foregroundStyle(project.isOverdue ? .red : .secondary)
                }

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
                ScrollView(.horizontal, showsIndicators: false) {
                    HorizontalTimelineView(
                        goals: project.sortedGoals,
                        onToggleComplete: { goal in
                            toggleGoalCompletion(goal)
                        }
                    )
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                }
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

        // Check if this is the last incomplete goal (project will be completed after this)
        let isLastGoal = !wasCompleted && project.goals.filter { !$0.isCompleted }.count == 1

        withAnimation {
            goal.toggleCompletion()
        }

        // If all goals are now completed, mark project as completed
        if isLastGoal {
            withAnimation {
                project.isCompleted = true
                project.completedDate = Date()
            }
        }
    }
}

// MARK: - Horizontal Timeline View

struct HorizontalTimelineView: View {
    let goals: [Goal]
    let onToggleComplete: (Goal) -> Void

    private let dotSize: CGFloat = 36
    private let columnWidth: CGFloat = 100  // Increased from 90 for better spacing
    private let lineHeight: CGFloat = 4

    // Check if a goal at index can be toggled (all previous must be complete, or it's already complete)
    private func canToggle(at index: Int) -> Bool {
        // Can always uncomplete (toggle off) a completed goal
        if goals[index].isCompleted { return true }
        // Can only complete if all previous goals are completed
        if index == 0 { return true }
        for i in 0..<index {
            if !goals[i].isCompleted { return false }
        }
        return true
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Connecting lines layer
            HStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    if index > 0 {
                        // Line is green when THIS goal (the one after the line) is completed
                        let lineIsGreen = goal.isCompleted
                        Rectangle()
                            .fill(lineIsGreen ? Color.green : Color.secondary.opacity(0.25))
                            .frame(width: columnWidth - dotSize, height: lineHeight)
                            .animation(.easeInOut(duration: 0.5), value: lineIsGreen)
                    }

                    // Spacer for the dot width
                    Color.clear
                        .frame(width: dotSize, height: lineHeight)
                }
            }
            .padding(.top, (dotSize - lineHeight) / 2)

            // Goals layer - dots with title and date
            HStack(alignment: .top, spacing: columnWidth - dotSize) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    GoalColumnView(
                        goal: goal,
                        dotSize: dotSize,
                        columnWidth: columnWidth,
                        isEnabled: canToggle(at: index),
                        onToggleComplete: {
                            onToggleComplete(goal)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Goal Column View

struct GoalColumnView: View {
    let goal: Goal
    let dotSize: CGFloat
    let columnWidth: CGFloat
    let isEnabled: Bool
    let onToggleComplete: () -> Void

    @State private var animatingCheckmark = false

    private var priorityColor: Color {
        switch goal.priority {
        case .none: return .gray
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Big checkmark button - colored by priority when incomplete
            Button {
                // Capture pre-toggle state BEFORE calling toggle
                let wasCompleted = goal.isCompleted

                // Call toggle to trigger state change
                onToggleComplete()

                // Trigger animation for completing (not uncompleting)
                if !wasCompleted && isEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            animatingCheckmark = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            animatingCheckmark = false
                        }
                    }
                }
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: dotSize))
                    .foregroundStyle(goal.isCompleted ? .green : (isEnabled ? priorityColor : priorityColor.opacity(0.4)))
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .scaleEffect(animatingCheckmark ? 1.35 : 1.0)
                    .rotationEffect(.degrees(animatingCheckmark ? 10 : 0))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)

            // Title - allow 2 lines with dynamic width
            VStack(spacing: 2) {
                Text(goal.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(goal.isCompleted ? .secondary : (isEnabled ? .primary : .secondary))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                // Target value/unit if present
                if let target = goal.formattedTarget {
                    Text(target)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.purple)
                }
            }
            .frame(width: columnWidth - 4, alignment: .center)  // Slightly smaller than column to prevent edge collision
            .fixedSize(horizontal: false, vertical: true)

            // Date
            Text(goal.formattedTargetDate)
                .font(.caption)
                .foregroundStyle(goal.isOverdue && !goal.isCompleted ? .red : .secondary)
                .frame(width: columnWidth, alignment: .center)
        }
        .frame(width: dotSize)
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
