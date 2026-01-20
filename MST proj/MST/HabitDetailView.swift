//
//  HabitDetailView.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with target info
                headerSection

                // Statistics cards
                statisticsSection

                // Progress toward milestone
                milestoneSection

                // Year heatmap
                heatmapSection
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
        .navigationTitle(habit.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditSheet = true }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Large flame icon with streak
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 4) {
                Text(habit.formattedTarget)
                    .font(.title2.weight(.semibold))

                Text(habit.frequency.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if habit.isTerminated {
                    Text("Completed")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }

            if !habit.habitDescription.isEmpty {
                Text(habit.habitDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatisticCard(
                title: "Current Streak",
                value: "\(habit.currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )

            StatisticCard(
                title: "Best Streak",
                value: "\(habit.bestStreak)",
                subtitle: "days",
                icon: "trophy.fill",
                color: .yellow
            )

            StatisticCard(
                title: "Completion Rate",
                value: String(format: "%.0f", habit.completionRate),
                subtitle: "%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )

            StatisticCard(
                title: "Total Days",
                value: "\(habit.completedDaysCount)",
                subtitle: "completed",
                icon: "calendar",
                color: themeManager.accentColor
            )
        }
    }

    // MARK: - Milestone Section

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Milestone Progress")
                    .font(.headline)

                Spacer()

                if habit.hasReachedMilestone {
                    Label("Reached!", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(habit.completedDaysCount) of \(habit.maxCompletionDays) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(habit.milestoneProgress))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeManager.accentColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.secondary.opacity(0.2))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(habit.milestoneProgress / 100, 1.0))
                            .animation(.easeInOut(duration: 0.5), value: habit.milestoneProgress)
                    }
                }
                .frame(height: 12)

                if !habit.hasReachedMilestone {
                    Text("\(habit.daysRemaining) days to go!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        }
    }

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .padding(.horizontal, 4)

            HabitHeatmapView(habit: habit)
        }
    }
}

// MARK: - Statistic Card

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(title: "Read books", habitDescription: "Read for 30 minutes every day", targetValue: 30, unit: .minute))
    }
    .environmentObject(ThemeManager())
}
