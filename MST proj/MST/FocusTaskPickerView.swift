//
//  FocusTaskPickerView.swift
//  MST
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

struct FocusTaskPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedTask: FocusTask?
    let assignments: [Assignment]
    let goals: [Goal]
    let habits: [Habit]
    let onSelect: (FocusTask) -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchText: String = ""

    private var filteredAssignments: [Assignment] {
        if searchText.isEmpty {
            return assignments
        }
        return assignments.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredGoals: [Goal] {
        if searchText.isEmpty {
            return goals
        }
        return goals.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredHabits: [Habit] {
        if searchText.isEmpty {
            return habits
        }
        return habits.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasAnyTasks: Bool {
        !assignments.isEmpty || !goals.isEmpty || !habits.isEmpty
    }

    private var hasFilteredTasks: Bool {
        !filteredAssignments.isEmpty || !filteredGoals.isEmpty || !filteredHabits.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            // Floating picker card
            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Header
                HStack {
                    Text("Select Task")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    if selectedTask != nil {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTask = nil
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text("Clear")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(themeManager.accentColor)
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)

                    TextField("Search tasks...", text: $searchText)
                        .font(.body)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Task list
                ScrollView {
                    VStack(spacing: 16) {
                        if !hasAnyTasks {
                            emptyStateView
                        } else if !hasFilteredTasks {
                            noResultsView
                        } else {
                            // Assignments section
                            if !filteredAssignments.isEmpty {
                                taskSection(
                                    title: "Assignments",
                                    icon: "book.fill",
                                    color: .blue,
                                    tasks: filteredAssignments.map { .assignment($0) }
                                )
                            }

                            // Goals section
                            if !filteredGoals.isEmpty {
                                taskSection(
                                    title: "Project Goals",
                                    icon: "flag.fill",
                                    color: .purple,
                                    tasks: filteredGoals.map { .goal($0) }
                                )
                            }

                            // Habits section
                            if !filteredHabits.isEmpty {
                                taskSection(
                                    title: "Habits",
                                    icon: "flame.fill",
                                    color: .orange,
                                    tasks: filteredHabits.map { .habit($0) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: 400)
            }
            .glassEffect(.regular)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Task Section

    private func taskSection(title: String, icon: String, color: Color, tasks: [FocusTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 2) {
                ForEach(tasks) { task in
                    taskRow(task)
                }
            }
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func taskRow(_ task: FocusTask) -> some View {
        Button {
            onSelect(task)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: selectedTask?.id == task.id ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selectedTask?.id == task.id ? themeManager.accentColor : .secondary.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Target info
                    if let value = task.targetValue, task.targetUnit != .none {
                        HStack(spacing: 4) {
                            Text(task.targetUnit.format(value))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if task.isTimeBasedUnit {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundStyle(themeManager.accentColor)
                            }
                        }
                    }
                }

                Spacer()

                // Time indicator for time-based tasks
                if let duration = task.durationInMinutes {
                    Text(formatDuration(duration))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 4) {
                Text("No Tasks Available")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Add assignments, goals, or habits to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No results for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        @State private var selectedTask: FocusTask?

        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()

                if isPresented {
                    FocusTaskPickerView(
                        isPresented: $isPresented,
                        selectedTask: $selectedTask,
                        assignments: [],
                        goals: [],
                        habits: [],
                        onSelect: { _ in }
                    )
                }
            }
            .environmentObject(ThemeManager())
        }
    }

    return PreviewWrapper()
}
