//
//  HabitListView.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import SwiftData

enum HabitSortOption: String, CaseIterable {
    case streak = "Streak"
    case createdDate = "Created Date"
    case completionRate = "Completion Rate"
    case title = "Title"

    var systemImage: String {
        switch self {
        case .streak: return "flame"
        case .createdDate: return "clock"
        case .completionRate: return "chart.bar"
        case .title: return "textformat"
        }
    }
}

enum HabitFilterOption: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case terminated = "Completed"
}

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingAddSheet = false
    @State private var selectedHabit: Habit?
    @State private var sortOption: HabitSortOption = .streak
    @State private var sortAscending = false
    @State private var filterOption: HabitFilterOption = .all
    @State private var searchText = ""

    var body: some View {
        List {
            if filteredAndSortedHabits.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredAndSortedHabits) { habit in
                    HabitRowView(habit: habit)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedHabit = habit
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggleHabitCompletion(habit)
                            } label: {
                                Label(
                                    habit.isCompletedToday ? "Undo" : "Complete",
                                    systemImage: habit.isCompletedToday ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                            .tint(habit.isCompletedToday ? .orange : .green)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search habits")
        .navigationTitle("Habits")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    // Sort options
                    Section("Sort by") {
                        ForEach(HabitSortOption.allCases, id: \.self) { option in
                            Button {
                                if sortOption == option {
                                    sortAscending.toggle()
                                } else {
                                    sortOption = option
                                    sortAscending = false
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
                    }

                    // Filter options
                    Section("Filter") {
                        ForEach(HabitFilterOption.allCases, id: \.self) { option in
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
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddHabitView()
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationStack {
                HabitDetailView(habit: habit)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                selectedHabit = nil
                            }
                        }
                    }
            }
        }
    }

    private var filteredAndSortedHabits: [Habit] {
        var result = habits

        // Filter
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isTerminated }
        case .terminated:
            result = result.filter { $0.isTerminated }
        }

        // Search
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.habitDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
        result.sort { habit1, habit2 in
            let comparison: Bool
            switch sortOption {
            case .streak:
                comparison = habit1.currentStreak > habit2.currentStreak
            case .createdDate:
                comparison = habit1.createdDate > habit2.createdDate
            case .completionRate:
                comparison = habit1.completionRate > habit2.completionRate
            case .title:
                comparison = habit1.title.localizedCompare(habit2.title) == .orderedAscending
            }
            return sortAscending ? !comparison : comparison
        }

        return result
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(emptyStateTitle, systemImage: "flame")
        } description: {
            Text(emptyStateDescription)
        } actions: {
            if filterOption == .all && searchText.isEmpty {
                Button("Add Habit") {
                    showingAddSheet = true
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
        case .all: return "No Habits"
        case .active: return "No Active Habits"
        case .terminated: return "No Completed Habits"
        }
    }

    private var emptyStateDescription: String {
        if !searchText.isEmpty {
            return "Try a different search term"
        }
        switch filterOption {
        case .all: return "Add a habit to start tracking"
        case .active: return "All habits have been completed"
        case .terminated: return "No habits have been completed yet"
        }
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }

    private func toggleHabitCompletion(_ habit: Habit) {
        if habit.isCompletedToday {
            habit.uncompleteToday()
        } else {
            habit.completeToday()
        }
    }
}

// MARK: - Habit Row View

struct HabitRowView: View {
    let habit: Habit
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(habit.isCompletedToday ? .green : .secondary.opacity(0.5))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.title)
                        .font(.body.weight(.medium))
                        .strikethrough(habit.isTerminated)
                        .foregroundStyle(habit.isTerminated ? .secondary : .primary)

                    if habit.isTerminated {
                        Text("Completed")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    // Target
                    Text(habit.formattedTarget)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Streak
                    if habit.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("\(habit.currentStreak)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.orange)
                    }

                    // Progress toward milestone
                    Text("\(habit.completedDaysCount)/\(habit.maxCompletionDays) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Completion rate indicator
            CircularProgressView(progress: habit.milestoneProgress / 100, color: themeManager.accentColor)
                .frame(width: 36, height: 36)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            Text("\(Int(progress * 100))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        HabitListView()
    }
    .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
    .environmentObject(ThemeManager())
}
