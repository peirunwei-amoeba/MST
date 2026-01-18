//
//  ProjectListView.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
//

import SwiftUI
import SwiftData
import AVFoundation

enum ProjectSortOption: String, CaseIterable {
    case deadline = "Deadline"
    case title = "Title"
    case subject = "Subject"
    case progress = "Progress"
    case createdDate = "Created Date"

    var systemImage: String {
        switch self {
        case .deadline: return "calendar"
        case .title: return "textformat"
        case .subject: return "folder"
        case .progress: return "chart.bar"
        case .createdDate: return "clock"
        }
    }
}

enum ProjectFilterOption: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case overdue = "Overdue"
}

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]

    @State private var showingAddSheet = false
    @State private var selectedProject: Project?
    @State private var sortOption: ProjectSortOption = .deadline
    @State private var sortAscending = true
    @State private var filterOption: ProjectFilterOption = .all
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if filteredAndSortedProjects.isEmpty {
                    emptyStateView
                } else {
                    projectList
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }

                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showingAddSheet) {
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
        }
    }

    // MARK: - Subviews

    private var projectList: some View {
        List {
            ForEach(filteredAndSortedProjects) { project in
                ProjectRowView(
                    project: project,
                    onTap: {
                        selectedProject = project
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteProject(project)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        withAnimation {
                            project.toggleCompletion()
                        }
                    } label: {
                        if project.isCompleted {
                            Label("Mark Active", systemImage: "arrow.uturn.backward")
                        } else {
                            Label("Complete", systemImage: "checkmark")
                        }
                    }
                    .tint(project.isCompleted ? .orange : .green)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.35), value: filteredAndSortedProjects.map { $0.id })
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(emptyStateTitle, systemImage: emptyStateIcon)
        } description: {
            Text(emptyStateDescription)
        } actions: {
            if filterOption == .all && searchText.isEmpty {
                Button {
                    showingAddSheet = true
                } label: {
                    Text("Add Project")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results"
        }
        switch filterOption {
        case .all: return "No Projects"
        case .active: return "No Active Projects"
        case .completed: return "No Completed Projects"
        case .overdue: return "No Overdue Projects"
        }
    }

    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        switch filterOption {
        case .all: return "folder"
        case .active: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        }
    }

    private var emptyStateDescription: String {
        if !searchText.isEmpty {
            return "No projects match your search."
        }
        switch filterOption {
        case .all: return "Add your first project to get started."
        case .active: return "All projects are completed!"
        case .completed: return "Complete some projects to see them here."
        case .overdue: return "Great job! Nothing is overdue."
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(ProjectSortOption.allCases, id: \.self) { option in
                Button {
                    if sortOption == option {
                        sortAscending.toggle()
                    } else {
                        sortOption = option
                        sortAscending = true
                    }
                } label: {
                    HStack {
                        Label(option.rawValue, systemImage: option.systemImage)
                        if sortOption == option {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        }
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(ProjectFilterOption.allCases, id: \.self) { option in
                Button {
                    filterOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if filterOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: filterOption == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }

    // MARK: - Computed Properties

    private var filteredAndSortedProjects: [Project] {
        var result = projects

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { project in
                project.title.localizedCaseInsensitiveContains(searchText) ||
                project.projectDescription.localizedCaseInsensitiveContains(searchText) ||
                project.subject.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply filter option
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        case .overdue:
            result = result.filter { $0.isOverdue }
        }

        // Helper function to compare projects by selected sort option
        func compareBySort(_ a: Project, _ b: Project) -> Bool {
            let comparison: Bool
            switch sortOption {
            case .deadline:
                comparison = a.deadline < b.deadline
            case .title:
                comparison = a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            case .subject:
                // Empty subjects sort last
                if a.subject.isEmpty && !b.subject.isEmpty {
                    return !sortAscending
                }
                if !a.subject.isEmpty && b.subject.isEmpty {
                    return sortAscending
                }
                comparison = a.subject.localizedCaseInsensitiveCompare(b.subject) == .orderedAscending
            case .progress:
                comparison = a.progressPercentage < b.progressPercentage
            case .createdDate:
                comparison = a.createdDate < b.createdDate
            }
            return sortAscending ? comparison : !comparison
        }

        // Separate into uncompleted and completed groups
        let uncompleted = result.filter { !$0.isCompleted }.sorted(by: compareBySort)
        let completed = result.filter { $0.isCompleted }.sorted(by: compareBySort)

        // Return uncompleted first, then completed
        return uncompleted + completed
    }

    // MARK: - Actions

    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
    }
}

// MARK: - Project Row View

struct ProjectRowView: View {
    let project: Project
    let onTap: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    private let maxVisibleGoals = 5
    private let dotSize: CGFloat = 22
    private let columnWidth: CGFloat = 56

    // Date to display - next goal's target date, or project deadline if all complete
    private var displayDate: String {
        if let next = project.nextGoal {
            return next.formattedTargetDate
        }
        return project.formattedDeadline
    }

    // Is the displayed date overdue?
    private var isDisplayDateOverdue: Bool {
        if let next = project.nextGoal {
            return next.isOverdue
        }
        return project.isOverdue
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Title and status
                HStack {
                    Text(project.title)
                        .font(.headline)
                        .foregroundStyle(project.isCompleted ? .secondary : .primary)

                    // Subject pill
                    if !project.subject.isEmpty {
                        Text(project.subject)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(themeManager.accentColor.opacity(0.12))
                            .foregroundStyle(themeManager.accentColor)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if project.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if project.isOverdue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // Timeline with interactive checkmarks
                if !project.goals.isEmpty {
                    timelineView
                }

                // Progress and deadline
                HStack {
                    Text("\(project.completedGoalsCount)/\(project.goals.count) goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(displayDate)
                            .font(.caption)
                    }
                    .foregroundStyle(isDisplayDateOverdue ? .red : .secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    
    }

    private var timelineView: some View {
        let goals = Array(project.sortedGoals.prefix(maxVisibleGoals))
        let lineWidth: CGFloat = columnWidth - dotSize

        return ZStack(alignment: .topLeading) {
            // Lines layer - connects checkmark centers
            HStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    if index > 0 {
                        Rectangle()
                            .fill(goal.isCompleted ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: lineWidth, height: 3)
                            .animation(.easeInOut(duration: 0.5), value: goal.isCompleted)
                    }
                    Color.clear
                        .frame(width: dotSize, height: 3)
                }
            }
            .padding(.top, (dotSize - 3) / 2)

            // Goals layer - checkmarks with titles
            HStack(alignment: .top, spacing: lineWidth) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    VStack(spacing: 4) {
                        Button {
                            toggleGoal(goal, at: index, in: goals)
                        } label: {
                            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: dotSize))
                                .foregroundStyle(goal.isCompleted ? .green : canToggle(index, in: goals) ? goalPriorityColor(goal) : goalPriorityColor(goal).opacity(0.4))
                                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canToggle(index, in: goals))

                        Text(goal.title)
                            .font(.system(size: 9))
                            .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: columnWidth)
                    }
                    .frame(width: dotSize)
                }

                if project.goals.count > maxVisibleGoals {
                    Text("+\(project.goals.count - maxVisibleGoals)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, (dotSize - 10) / 2)
                }
            }
        }
    }

    private func canToggle(_ index: Int, in goals: [Goal]) -> Bool {
        if goals[index].isCompleted { return true }
        if index == 0 { return true }
        for i in 0..<index {
            if !goals[i].isCompleted { return false }
        }
        return true
    }

    private func toggleGoal(_ goal: Goal, at index: Int, in goals: [Goal]) {
        guard canToggle(index, in: goals) else { return }

        if !goal.isCompleted {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1407)
        }

        withAnimation {
            goal.toggleCompletion()
        }
    }

    private func goalPriorityColor(_ goal: Goal) -> Color {
        switch goal.priority {
        case .none: return .gray
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

#Preview {
    ProjectListView()
        .modelContainer(for: [Project.self, Goal.self], inMemory: true)
        .environmentObject(ThemeManager())
}
