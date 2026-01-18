//
//  HomeView.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
//

import SwiftUI
import SwiftData
import AVFoundation

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Assignment.dueDate) private var assignments: [Assignment]
    @Query(sort: \Project.deadline) private var projects: [Project]
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingAddSheet = false
    @State private var selectedAssignment: Assignment?
    @State private var showingAllAssignments = false
    @State private var recentlyCompletedIds: Set<UUID> = []

    // Project-related state
    @State private var showingAddProjectSheet = false
    @State private var selectedProject: Project?
    @State private var showingAllProjects = false
    @State private var recentlyCompletedGoalIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Upcoming assignments section
                    assignmentSection

                    // Projects section
                    projectSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Welcome")
            .sheet(isPresented: $showingAddSheet) {
                AddAssignmentView()
            }
            .sheet(item: $selectedAssignment) { assignment in
                EditAssignmentView(assignment: assignment)
            }
            .sheet(isPresented: $showingAllAssignments) {
                NavigationStack {
                    AssignmentListView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingAllAssignments = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingAddProjectSheet) {
                AddProjectView()
            }
            .sheet(item: $selectedProject) { project in
                NavigationStack {
                    ProjectDetailView(project: project)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    selectedProject = nil
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingAllProjects) {
                NavigationStack {
                    ProjectListView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingAllProjects = false
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Assignment Section (iOS 26 Concentric Style)

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Label("Upcoming", systemImage: "book.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    showingAllAssignments = true
                } label: {
                    Text("See All")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.accentColor)
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.accentColor)
                        .padding(12)
                        .glassEffect(.regular)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 4)

            // Assignment cards - concentric layered design
            Group {
                if visibleAssignments.isEmpty {
                    emptyAssignmentCard
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Outer container with glass effect
                    VStack(spacing: 0) {
                    ForEach(Array(visibleAssignments.prefix(4).enumerated()), id: \.element.id) { index, assignment in
                        let isRecentlyCompleted = recentlyCompletedIds.contains(assignment.id)

                        ConcentricAssignmentRow(
                            assignment: assignment,
                            onTap: {
                                selectedAssignment = assignment
                            },
                            onToggleComplete: {
                                completeAssignmentWithDelay(assignment)
                            },
                            isRecentlyCompleted: isRecentlyCompleted
                        )
                        .opacity(isRecentlyCompleted ? 0.6 : 1.0)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(x: -20))
                        ))

                        if index < min(visibleAssignments.count - 1, 3) {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

                if visibleAssignments.count > 4 {
                    Button {
                        showingAllAssignments = true
                    } label: {
                        HStack {
                            Text("+ \(visibleAssignments.count - 4) more")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(themeManager.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 8)
                }
            }
            }
            .animation(.easeInOut(duration: 0.4), value: visibleAssignments.isEmpty)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }

    private var emptyAssignmentCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 4) {
                Text("All caught up!")
                    .font(.headline)

                Text("No upcoming assignments")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Assignment", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(themeManager.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var upcomingAssignments: [Assignment] {
        assignments.filter { !$0.isCompleted }
    }

    // Include recently completed assignments temporarily so animation can play
    private var visibleAssignments: [Assignment] {
        assignments.filter { !$0.isCompleted || recentlyCompletedIds.contains($0.id) }
    }

    private func completeAssignmentWithDelay(_ assignment: Assignment) {
        let wasCompleted = assignment.isCompleted

        if !wasCompleted {
            // About to complete - keep it visible temporarily
            recentlyCompletedIds.insert(assignment.id)

            // Toggle completion with animation
            withAnimation {
                assignment.toggleCompletion()
            }

            // Remove from visible list after 1 second, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    _ = recentlyCompletedIds.remove(assignment.id)
                }
            }
        } else {
            // Unchecking - just toggle immediately
            withAnimation {
                assignment.toggleCompletion()
            }
        }
    }

    // MARK: - Project Section (iOS 26 Concentric Style)

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Label("Projects", systemImage: "folder.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    showingAllProjects = true
                } label: {
                    Text("See All")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.accentColor)
                }

                Button {
                    showingAddProjectSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.accentColor)
                        .padding(12)
                        .glassEffect(.regular)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 4)

            // Project cards - concentric layered design
            Group {
                if visibleProjects.isEmpty {
                    emptyProjectCard
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(visibleProjects.prefix(3).enumerated()), id: \.element.id) { index, project in
                            ConcentricProjectRow(
                                project: project,
                                onTap: {
                                    selectedProject = project
                                },
                                onToggleNextGoal: {
                                    completeNextGoalWithDelay(project)
                                }
                            )

                            if index < min(visibleProjects.count - 1, 2) {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

                    if visibleProjects.count > 3 {
                        Button {
                            // Could add a "See All Projects" sheet here in the future
                        } label: {
                            HStack {
                                Text("+ \(visibleProjects.count - 3) more")
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(themeManager.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: visibleProjects.isEmpty)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }

    private var emptyProjectCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(themeManager.accentColor)
            }

            VStack(spacing: 4) {
                Text("No projects yet")
                    .font(.headline)

                Text("Track long-term goals with timelines")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingAddProjectSheet = true
            } label: {
                Label("Add Project", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(themeManager.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var visibleProjects: [Project] {
        projects.filter { !$0.isCompleted }
    }

    private func completeNextGoalWithDelay(_ project: Project) {
        guard let nextGoal = project.nextGoal else { return }

        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1407)

        withAnimation {
            nextGoal.toggleCompletion()
        }
    }
}

// MARK: - Concentric Project Row (iOS 26 Style)

struct ConcentricProjectRow: View {
    let project: Project
    let onTap: () -> Void
    let onToggleNextGoal: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    private let maxVisibleGoals = 5
    private let dotSize: CGFloat = 20
    private let columnWidth: CGFloat = 48
    private let mainCheckmarkSize: CGFloat = 28

    // Next incomplete goal for the main checkmark and date display
    private var nextGoal: Goal? {
        project.nextGoal
    }

    // Date to display - next goal's target date, or project deadline if all complete
    private var displayDate: String {
        if let next = nextGoal {
            return next.formattedTargetDate
        }
        return project.formattedDeadline
    }

    // Is the displayed date overdue?
    private var isDisplayDateOverdue: Bool {
        if let next = nextGoal {
            return next.isOverdue
        }
        return project.isOverdue
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Main checkmark button for next goal
                Button {
                    onToggleNextGoal()
                } label: {
                    Image(systemName: nextGoal != nil ? "circle" : "checkmark.circle.fill")
                        .font(.system(size: mainCheckmarkSize))
                        .foregroundStyle(nextGoal != nil ? Color.secondary.opacity(0.5) : Color.green)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                }
                .buttonStyle(.plain)
                .disabled(nextGoal == nil)

                VStack(alignment: .leading, spacing: 8) {
                    // Project title row
                    HStack {
                        Text(project.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        // Next goal's target date (or project deadline if all complete)
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(displayDate)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(isDisplayDateOverdue ? .red : .secondary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }

                    // Timeline with connected dots and title captions
                    if !project.goals.isEmpty {
                        timelineView
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var timelineView: some View {
        let goals = Array(project.sortedGoals.prefix(maxVisibleGoals))

        // Helper to check if all goals up to (and including) index are completed
        func allCompletedUpTo(_ index: Int) -> Bool {
            for i in 0...index {
                if !goals[i].isCompleted { return false }
            }
            return true
        }

        return ZStack(alignment: .topLeading) {
            // Connecting lines layer
            HStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    if index > 0 {
                        // Line is green only if ALL goals before this one are completed
                        let lineIsGreen = allCompletedUpTo(index - 1)
                        Rectangle()
                            .fill(lineIsGreen ? Color.green : Color.secondary.opacity(0.3))
                            .frame(height: 3)
                            .frame(width: columnWidth - dotSize)
                            .animation(.easeInOut(duration: 0.5), value: lineIsGreen)
                    }

                    // Spacer for the dot width
                    Color.clear
                        .frame(width: dotSize, height: 3)
                }
            }
            .padding(.top, (dotSize - 3) / 2)

            // Dots and titles layer
            HStack(alignment: .top, spacing: columnWidth - dotSize) {
                ForEach(goals) { goal in
                    VStack(spacing: 4) {
                        // Checkmark dot
                        Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: dotSize))
                            .foregroundStyle(goal.isCompleted ? .green : .secondary.opacity(0.5))
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))

                        // Title caption centered under dot (keep font size at 9)
                        Text(goal.title)
                            .font(.system(size: 9))
                            .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                            .lineLimit(1)
                            .frame(width: columnWidth, alignment: .center)
                    }
                    .frame(width: dotSize)
                }

                if project.goals.count > maxVisibleGoals {
                    Text("+\(project.goals.count - maxVisibleGoals)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - Concentric Assignment Row (iOS 26 Style)

struct ConcentricAssignmentRow: View {
    let assignment: Assignment
    let onTap: () -> Void
    let onToggleComplete: () -> Void
    var isRecentlyCompleted: Bool = false

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                // Completion button with SF Symbol checkmark.circle
                Button {
                    if !assignment.isCompleted {
                        // Trigger haptic feedback
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.success)

                        // Play system confirmation sound
                        AudioServicesPlaySystemSound(1407)
                    }
                    onToggleComplete()
                } label: {
                    Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(assignment.isCompleted ? .green : .secondary.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Priority indicator pill
                        if assignment.priority == .urgent || assignment.priority == .high {
                            HStack(spacing: 3) {
                                Image(systemName: assignment.priority == .urgent ? "exclamationmark.2" : "exclamationmark")
                                    .font(.system(size: 9, weight: .bold))
                                Text(assignment.priority.rawValue)
                                    .font(.caption2.weight(.semibold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(priorityColor.opacity(0.15))
                            .foregroundStyle(priorityColor)
                            .clipShape(Capsule())
                        }

                        // Subject pill
                        if !assignment.subject.isEmpty {
                            Text(assignment.subject)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(themeManager.accentColor.opacity(0.12))
                                .foregroundStyle(themeManager.accentColor)
                                .clipShape(Capsule())
                        }

                        // Due date
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(relativeDueDate)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(dueDateColor)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var relativeDueDate: String {
        if assignment.isOverdue {
            return "Overdue"
        } else if assignment.isDueToday {
            return "Today"
        } else if assignment.isDueTomorrow {
            return "Tomorrow"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: assignment.dueDate, relativeTo: Date())
        }
    }

    private var dueDateColor: Color {
        if assignment.isOverdue {
            return .red
        } else if assignment.isDueToday {
            return .orange
        } else if assignment.isDueTomorrow {
            return .yellow
        } else {
            return .secondary
        }
    }

    private var priorityColor: Color {
        switch assignment.priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Assignment.self, Project.self, Goal.self], inMemory: true)
        .environmentObject(ThemeManager())
}
