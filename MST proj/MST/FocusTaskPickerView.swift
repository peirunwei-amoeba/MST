//
//  FocusTaskPickerView.swift
//  MST
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

struct FocusTaskPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTask: FocusTask?
    let assignments: [Assignment]
    let goals: [Goal]
    let habits: [Habit]
    let onSelect: (FocusTask) -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchText: String = ""

    private var filteredAssignments: [Assignment] {
        if searchText.isEmpty { return assignments }
        return assignments.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredGoals: [Goal] {
        if searchText.isEmpty { return goals }
        return goals.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredHabits: [Habit] {
        if searchText.isEmpty { return habits }
        return habits.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasAnyTasks: Bool {
        !assignments.isEmpty || !goals.isEmpty || !habits.isEmpty
    }

    private var hasFilteredTasks: Bool {
        !filteredAssignments.isEmpty || !filteredGoals.isEmpty || !filteredHabits.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !hasAnyTasks {
                        emptyStateView
                            .padding(.top, 60)
                    } else if !hasFilteredTasks {
                        noResultsView
                            .padding(.top, 60)
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
                .padding(.vertical, 16)
            }
            .searchable(text: $searchText, prompt: "Search tasks")
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if selectedTask != nil {
                        Button("Clear") {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTask = nil
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .foregroundStyle(themeManager.accentColor)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(32)
    }

    // MARK: - Task Section

    private func taskSection(title: String, icon: String, color: Color, tasks: [FocusTask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(tasks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            // Task cards with glass effect
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    taskCard(task)
                }
            }
        }
    }

    private func taskCard(_ task: FocusTask) -> some View {
        Button {
            onSelect(task)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            selectedTask?.id == task.id ? themeManager.accentColor : Color.secondary.opacity(0.3),
                            lineWidth: selectedTask?.id == task.id ? 2.5 : 2
                        )
                        .frame(width: 26, height: 26)

                    if selectedTask?.id == task.id {
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: selectedTask?.id == task.id)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Target info
                    if let value = task.targetValue, task.targetUnit != .none {
                        HStack(spacing: 6) {
                            Text(task.targetUnit.format(value))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if task.isTimeBasedUnit {
                                HStack(spacing: 2) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 9))
                                    Text("Auto")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(themeManager.accentColor)
                            }
                        }
                    }
                }

                Spacer()

                // Duration badge for time-based tasks
                if let duration = task.durationInMinutes {
                    Text(formatDuration(duration))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "tray")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("No Tasks Available")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Add assignments, goals, or habits\nto track your focus time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No results for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    Text("Focus View")
        .sheet(isPresented: .constant(true)) {
            FocusTaskPickerView(
                selectedTask: .constant(nil),
                assignments: [],
                goals: [],
                habits: [],
                onSelect: { _ in }
            )
            .environmentObject(ThemeManager())
        }
}
