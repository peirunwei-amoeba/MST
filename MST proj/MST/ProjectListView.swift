//
//  ProjectListView.swift
//  MST
//
//  Created by Runwei Pei on 1/18/26.
//

import SwiftUI
import SwiftData

enum ProjectSortOption: String, CaseIterable {
    case deadline = "Deadline"
    case title = "Title"
    case progress = "Progress"
    case createdDate = "Created Date"

    var systemImage: String {
        switch self {
        case .deadline: return "calendar"
        case .title: return "textformat"
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
                project.projectDescription.localizedCaseInsensitiveContains(searchText)
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

    @EnvironmentObject private var themeManager: ThemeManager

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

                    Spacer()

                    if project.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if project.isOverdue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // Timeline with connected dots and titles
                ProjectTimelinePreview(project: project)

                // Progress and deadline
                HStack {
                    // Progress
                    Text("\(project.completedGoalsCount)/\(project.goals.count) goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Deadline
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(project.formattedDeadline)
                            .font(.caption)
                    }
                    .foregroundStyle(project.isOverdue ? .red : .secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Project Timeline Preview (with connected dots and titles)

struct ProjectTimelinePreview: View {
    let project: Project

    // Count consecutive completed goals from the start
    private var consecutiveCompletedCount: Int {
        var count = 0
        for goal in project.sortedGoals {
            if goal.isCompleted {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    var body: some View {
        if project.goals.isEmpty {
            Text("No goals defined")
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        } else {
            GeometryReader { geometry in
                let goals = Array(project.sortedGoals.prefix(5))
                let dotSpacing = min(geometry.size.width / CGFloat(max(goals.count, 1)), 70)
                let consecutiveCount = min(consecutiveCompletedCount, goals.count)
                let progressWidth = consecutiveCount > 0 ? dotSpacing * CGFloat(consecutiveCount - 1) + 8 : 0

                ZStack(alignment: .leading) {
                    // Background line (grey)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: dotSpacing * CGFloat(goals.count - 1) + 8, height: 3)
                        .offset(x: 4)

                    // Progress line (green) - only for consecutive completed goals from start
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: progressWidth, height: 3)
                        .offset(x: 4)
                        .animation(.easeInOut(duration: 0.5), value: consecutiveCount)

                    // Dots with titles
                    HStack(spacing: 0) {
                        ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(goal.isCompleted ? Color.green : Color.secondary.opacity(0.4))
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(goal.isCompleted ? Color.green : Color.secondary.opacity(0.6), lineWidth: 1)
                                    )

                                Text(goal.title)
                                    .font(.system(size: 8))
                                    .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                                    .lineLimit(1)
                                    .frame(width: dotSpacing - 4)
                            }
                            .frame(width: dotSpacing)
                        }

                        if project.goals.count > 5 {
                            Text("+\(project.goals.count - 5)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                }
            }
            .frame(height: 36)
        }
    }
}

#Preview {
    ProjectListView()
        .modelContainer(for: [Project.self, Goal.self], inMemory: true)
        .environmentObject(ThemeManager())
}
