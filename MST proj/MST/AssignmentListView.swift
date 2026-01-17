//
//  AssignmentListView.swift
//  MST
//
//  Created by Runwei Pei on 12/1/26.
//

import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"
    case subject = "Subject"
    case createdDate = "Created Date"

    var systemImage: String {
        switch self {
        case .dueDate: return "calendar"
        case .priority: return "exclamationmark.triangle"
        case .title: return "textformat"
        case .subject: return "folder"
        case .createdDate: return "clock"
        }
    }
}

enum FilterOption: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"
    case overdue = "Overdue"
    case dueToday = "Due Today"
}

struct AssignmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assignments: [Assignment]

    @State private var showingAddSheet = false
    @State private var selectedAssignment: Assignment?
    @State private var sortOption: SortOption = .dueDate
    @State private var sortAscending = true
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""

    // For undo functionality
    @State private var recentlyCompletedAssignment: Assignment?
    @State private var showUndoToast = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredAndSortedAssignments.isEmpty {
                    emptyStateView
                } else {
                    assignmentList
                }
            }
            .navigationTitle("Assignments")
            .searchable(text: $searchText, prompt: "Search assignments")
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
                AddAssignmentView()
            }
            .sheet(item: $selectedAssignment) { assignment in
                EditAssignmentView(assignment: assignment)
            }
            .overlay(alignment: .bottom) {
                if showUndoToast {
                    undoToast
                }
            }
        }
    }

    // MARK: - Subviews

    private var assignmentList: some View {
        List {
            ForEach(filteredAndSortedAssignments) { assignment in
                AssignmentRowView(
                    assignment: assignment,
                    onToggleComplete: {
                        toggleCompletionWithUndo(assignment)
                    },
                    onTap: {
                        selectedAssignment = assignment
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteAssignment(assignment)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        toggleCompletionWithUndo(assignment)
                    } label: {
                        if assignment.isCompleted {
                            Label("Mark Incomplete", systemImage: "arrow.uturn.backward")
                        } else {
                            Label("Complete", systemImage: "checkmark")
                        }
                    }
                    .tint(assignment.isCompleted ? .orange : .green)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.35), value: filteredAndSortedAssignments.map { $0.id })
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
                    Text("Add Assignment")
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
        case .all: return "No Assignments"
        case .pending: return "No Pending Assignments"
        case .completed: return "No Completed Assignments"
        case .overdue: return "No Overdue Assignments"
        case .dueToday: return "Nothing Due Today"
        }
    }

    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        switch filterOption {
        case .all: return "tray"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        case .dueToday: return "sun.max"
        }
    }

    private var emptyStateDescription: String {
        if !searchText.isEmpty {
            return "No assignments match your search."
        }
        switch filterOption {
        case .all: return "Add your first assignment to get started."
        case .pending: return "All assignments are completed!"
        case .completed: return "Complete some assignments to see them here."
        case .overdue: return "Great job! Nothing is overdue."
        case .dueToday: return "No assignments are due today."
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
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
            ForEach(FilterOption.allCases, id: \.self) { option in
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

    private var undoToast: some View {
        HStack {
            Text("Marked as complete")
                .font(.subheadline)

            Spacer()

            Button("Undo") {
                undoCompletion()
            }
            .font(.subheadline.bold())
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Computed Properties

    private var filteredAndSortedAssignments: [Assignment] {
        var result = assignments

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { assignment in
                assignment.title.localizedCaseInsensitiveContains(searchText) ||
                assignment.subject.localizedCaseInsensitiveContains(searchText) ||
                assignment.assignmentDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply filter option
        switch filterOption {
        case .all:
            break
        case .pending:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        case .overdue:
            result = result.filter { $0.isOverdue }
        case .dueToday:
            result = result.filter { $0.isDueToday }
        }

        // Helper function to compare assignments by selected sort option
        func compareBySort(_ a: Assignment, _ b: Assignment) -> Bool {
            let comparison: Bool
            switch sortOption {
            case .dueDate:
                comparison = a.dueDate < b.dueDate
            case .priority:
                comparison = a.priority.sortOrder < b.priority.sortOrder
            case .title:
                comparison = a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            case .subject:
                comparison = a.subject.localizedCaseInsensitiveCompare(b.subject) == .orderedAscending
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

    private func deleteAssignment(_ assignment: Assignment) {
        modelContext.delete(assignment)
    }

    private func toggleCompletionWithUndo(_ assignment: Assignment) {
        let wasCompleted = assignment.isCompleted

        withAnimation(.easeInOut(duration: 0.35)) {
            assignment.toggleCompletion()
        }

        if !wasCompleted {
            // Just completed - show undo option
            recentlyCompletedAssignment = assignment
            withAnimation {
                showUndoToast = true
            }

            // Auto-hide after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showUndoToast = false
                }
                recentlyCompletedAssignment = nil
            }
        }
    }

    private func undoCompletion() {
        if let assignment = recentlyCompletedAssignment {
            withAnimation(.easeInOut(duration: 0.35)) {
                assignment.toggleCompletion()
            }
        }
        withAnimation {
            showUndoToast = false
        }
        recentlyCompletedAssignment = nil
    }
}

#Preview {
    AssignmentListView()
        .modelContainer(for: Assignment.self, inMemory: true)
}
