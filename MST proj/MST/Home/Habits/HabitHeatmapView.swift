//
//  HabitHeatmapView.swift
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

struct HabitHeatmapView: View {
    let habit: Habit

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var hasAppeared = false

    private let monthLetters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    private let cellSize: CGFloat = 18
    private let spacing: CGFloat = 6

    var body: some View {
        VStack(spacing: 16) {
            // Month headers
            HStack(spacing: spacing) {
                ForEach(0..<12, id: \.self) { month in
                    Text(monthLetters[month])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: cellSize)
                }
            }

            // Days grid (31 rows x 12 columns)
            VStack(spacing: spacing) {
                ForEach(1...31, id: \.self) { day in
                    HStack(spacing: spacing) {
                        ForEach(0..<12, id: \.self) { month in
                            dayCell(day: day, month: month + 1)
                        }
                    }
                }
            }

            // Year label
            Text(String(currentYear))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            // Trigger the staggered animation when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    @ViewBuilder
    private func dayCell(day: Int, month: Int) -> some View {
        let status = dayStatus(day: day, month: month)
        // Stagger animation based on position
        let delay = Double(day + month * 31) * 0.003

        Group {
            switch status {
            case .completed:
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(themeManager.accentColor)
                    .scaleEffect(hasAppeared ? 1.0 : 0.3)
                    .opacity(hasAppeared ? 1.0 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay), value: hasAppeared)
            case .missed:
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .opacity(hasAppeared ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.3).delay(delay), value: hasAppeared)
            case .future:
                Circle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 6, height: 6)
                    .opacity(hasAppeared ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.3).delay(delay), value: hasAppeared)
            case .invalid:
                Color.clear
            }
        }
        .frame(width: cellSize, height: cellSize)
        .animation(.easeInOut(duration: 0.3), value: status)
    }

    private enum DayStatus: Equatable {
        case completed
        case missed
        case future
        case invalid // Day doesn't exist in that month (e.g., Feb 30)
    }

    private func dayStatus(day: Int, month: Int) -> DayStatus {
        let calendar = Calendar.current
        let year = currentYear

        // Check if this day exists in this month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        guard let date = calendar.date(from: components),
              calendar.component(.month, from: date) == month else {
            return .invalid
        }

        let today = calendar.startOfDay(for: Date())
        let dateStart = calendar.startOfDay(for: date)

        // Future dates
        if dateStart > today {
            return .future
        }

        // Check if habit was created after this date
        let habitCreatedDate = calendar.startOfDay(for: habit.createdDate)
        if dateStart < habitCreatedDate {
            return .future // Show as faded for dates before habit was created
        }

        // Check if completed on this day
        let entry = habit.entries.first { calendar.isDate($0.date, inSameDayAs: date) }
        if let entry = entry, entry.value >= habit.targetValue {
            return .completed
        }

        return .missed
    }
}

#Preview {
    HabitHeatmapView(habit: Habit(title: "Read books", targetValue: 30, unit: .minute))
        .padding()
        .environmentObject(ThemeManager())
}
