//
//  PointsStatsView.swift
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

struct PointsStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var pointsManager: PointsManager

    @Query(sort: \PointsTransaction.awardedDate, order: .reverse)
    private var allTransactions: [PointsTransaction]

    // Staggered appearance
    @State private var appearedSections: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    remainingPointsCard
                    earningsOverviewCard
                    breakdownCard
                    streakBonusesCard
                    recentHistoryCard
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                animateSections()
            }
        }
    }

    // MARK: - Remaining Points (Hero Card)

    private var remainingPointsCard: some View {
        VStack(spacing: 12) {
            Image("MST Full")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)

            Text("\(ledger.remainingPoints)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text("Points Available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .modifier(GlassCardModifier())
        .opacity(appearedSections.contains(0) ? 1 : 0)
        .offset(y: appearedSections.contains(0) ? 0 : 15)
    }

    // MARK: - Earnings Overview

    private var earningsOverviewCard: some View {
        VStack(spacing: 16) {
            Label("Overview", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                overviewItem(
                    title: "Total Earned",
                    value: "\(ledger.totalPointsEarned)",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )

                overviewItem(
                    title: "Total Spent",
                    value: "\(ledger.totalPointsSpent)",
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )
            }
        }
        .padding(20)
        .modifier(GlassCardModifier())
        .opacity(appearedSections.contains(1) ? 1 : 0)
        .offset(y: appearedSections.contains(1) ? 0 : 15)
    }

    private func overviewItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Breakdown by Source

    private var breakdownCard: some View {
        VStack(spacing: 16) {
            Label("Breakdown", systemImage: "chart.pie.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                breakdownRow(label: "Habits", icon: "flame.fill", color: .orange, points: pointsFor(type: "habit"))
                breakdownRow(label: "Assignments", icon: "book.fill", color: .blue, points: pointsFor(type: "assignment"))
                breakdownRow(label: "Goals", icon: "flag.fill", color: .purple, points: pointsFor(type: "goal"))
                breakdownRow(label: "Streak Bonuses", icon: "star.fill", color: .yellow, points: pointsFor(type: "streak"))
            }
        }
        .padding(20)
        .modifier(GlassCardModifier())
        .opacity(appearedSections.contains(2) ? 1 : 0)
        .offset(y: appearedSections.contains(2) ? 0 : 15)
    }

    private func breakdownRow(label: String, icon: String, color: Color, points: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(points) pts")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Streak Bonuses

    private var streakBonusesCard: some View {
        let streakTransactions = allTransactions.filter { $0.sourceType == "streak" }

        return VStack(spacing: 16) {
            Label("Streak Rewards", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if streakTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Complete habits consecutively to earn streak bonuses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(streakTransactions) { transaction in
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)

                            Text(transaction.sourceTitle)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            Text("+\(transaction.pointsAwarded)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Milestone reference table
            VStack(spacing: 6) {
                Text("Milestone Targets")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let milestones = PointsManager.streakMilestones
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                    ForEach(milestones, id: \.streak) { milestone in
                        let achieved = streakTransactions.contains { $0.periodKey == "milestone-\(milestone.streak)" }
                        VStack(spacing: 2) {
                            Text("\(milestone.streak)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(achieved ? .green : .primary)
                            Text("+\(milestone.points)")
                                .font(.caption2)
                                .foregroundStyle(achieved ? .green : .secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(achieved ? Color.green.opacity(0.1) : .clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(achieved ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .modifier(GlassCardModifier())
        .opacity(appearedSections.contains(3) ? 1 : 0)
        .offset(y: appearedSections.contains(3) ? 0 : 15)
    }

    // MARK: - Recent History

    private var recentHistoryCard: some View {
        let recentItems = Array(allTransactions.prefix(15))

        return VStack(spacing: 16) {
            Label("Recent Activity", systemImage: "clock.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if recentItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Complete tasks to start earning points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, transaction in
                        HStack {
                            Image(systemName: iconForType(transaction.sourceType))
                                .foregroundStyle(colorForType(transaction.sourceType))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.sourceTitle)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(transaction.awardedDate.formatted(.relative(presentation: .named)))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Text("+\(transaction.pointsAwarded)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 8)

                        if index < recentItems.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(20)
        .modifier(GlassCardModifier())
        .opacity(appearedSections.contains(4) ? 1 : 0)
        .offset(y: appearedSections.contains(4) ? 0 : 15)
    }

    // MARK: - Helpers

    private var ledger: PointsLedger {
        pointsManager.getOrCreateLedger(modelContext: modelContext)
    }

    private func pointsFor(type: String) -> Int {
        allTransactions.filter { $0.sourceType == type }.reduce(0) { $0 + $1.pointsAwarded }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "habit": return "flame.fill"
        case "assignment": return "book.fill"
        case "goal": return "flag.fill"
        case "streak": return "star.fill"
        default: return "circle.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "habit": return .orange
        case "assignment": return .blue
        case "goal": return .purple
        case "streak": return .yellow
        default: return .gray
        }
    }

    private func animateSections() {
        for i in 0..<5 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(i) * 0.08)) {
                appearedSections.insert(i)
            }
        }
    }
}

// MARK: - Glass Card Modifier (matches HomeView card style)

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
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
}

#Preview {
    PointsStatsView()
        .modelContainer(for: [PointsLedger.self, PointsTransaction.self], inMemory: true)
        .environmentObject(ThemeManager())
        .environmentObject(PointsManager())
}
