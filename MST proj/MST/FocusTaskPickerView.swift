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
        ZStack {
            // Dimmed background - tap to dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPicker()
                }

            // Bottom sheet card
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    // Header
                    HStack {
                        Text("Select Task")
                            .font(.title3.weight(.semibold))
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)

                        TextField("Search tasks...", text: $searchText)
                            .font(.body)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Task list
                    ScrollView {
                        VStack(spacing: 20) {
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
                        .padding(.bottom, 40)
                    }
                    .frame(maxHeight: 400)
                }
                .glassEffect(.regular)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismissPicker()
                    }
                }
        )
    }

    private func dismissPicker() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
        }
    }

    // MARK: - Task Section

    private func taskSection(title: String, icon: String, color: Color, tasks: [FocusTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("(\(tasks.count))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)

            // Task rows
            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    taskRow(task)

                    if index < tasks.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func taskRow(_ task: FocusTask) -> some View {
        Button {
            onSelect(task)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(selectedTask?.id == task.id ? themeManager.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if selectedTask?.id == task.id {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 14, height: 14)
                    }
                }

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
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(themeManager.accentColor)
                            }
                        }
                    }
                }

                Spacer()

                // Duration badge for time-based tasks
                if let duration = task.durationInMinutes {
                    Text(formatDuration(duration))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(themeManager.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
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
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 6) {
                Text("No Tasks Available")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Add assignments, goals, or habits\nto track your focus time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No results for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        @State private var selectedTask: FocusTask?

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
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
