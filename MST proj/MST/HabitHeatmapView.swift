//
//  HabitHeatmapView.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

struct HabitHeatmapView: View {
    let habit: Habit

    private let rows = 7  // Days of week
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month labels
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // Month labels row
                    HStack(spacing: 0) {
                        ForEach(monthLabels, id: \.offset) { month in
                            Text(month.name)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .frame(width: CGFloat(month.weeks) * (cellSize + cellSpacing), alignment: .leading)
                        }
                    }
                    .padding(.leading, 24) // Offset for day labels

                    HStack(alignment: .top, spacing: 0) {
                        // Day of week labels
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { day in
                                Text(dayLabel(for: day))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, height: cellSize, alignment: .trailing)
                            }
                        }
                        .padding(.trailing, 4)

                        // Heatmap grid
                        LazyHGrid(
                            rows: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: rows),
                            spacing: cellSpacing
                        ) {
                            ForEach(Array(daysData.enumerated()), id: \.offset) { _, dayData in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorForDay(dayData))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .padding()
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(legendColor(for: level))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private struct DayData {
        let date: Date
        let isCompleted: Bool
        let value: Double
        let isFuture: Bool
    }

    private var daysData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get the start of the year view - go back to fill the first week
        guard let startDate = calendar.date(byAdding: .day, value: -364, to: today) else {
            return []
        }

        // Adjust to start on Sunday
        let weekday = calendar.component(.weekday, from: startDate)
        let adjustedStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: startDate) ?? startDate

        var result: [DayData] = []
        var currentDate = adjustedStart

        // Generate up to 53 weeks of data
        while currentDate <= today {
            let entry = habit.entries.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let value = entry?.value ?? 0
            let isCompleted = value >= habit.targetValue
            let isFuture = currentDate > today

            result.append(DayData(date: currentDate, isCompleted: isCompleted, value: value, isFuture: isFuture))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return result
    }

    private var monthLabels: [(name: String, weeks: Int, offset: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var months: [(name: String, weeks: Int, offset: Int)] = []
        var currentMonth = -1
        var weekCount = 0
        var offset = 0

        for (index, day) in daysData.enumerated() {
            let month = calendar.component(.month, from: day.date)

            if month != currentMonth {
                if currentMonth != -1 && weekCount > 0 {
                    months.append((formatter.string(from: calendar.date(from: DateComponents(month: currentMonth))!), weekCount, offset))
                }
                currentMonth = month
                weekCount = 0
                offset = index / 7
            }

            // Count weeks
            if index % 7 == 0 {
                weekCount += 1
            }
        }

        // Add the last month
        if weekCount > 0 {
            months.append((formatter.string(from: calendar.date(from: DateComponents(month: currentMonth))!), weekCount, offset))
        }

        return months
    }

    private func dayLabel(for index: Int) -> String {
        switch index {
        case 0: return "S"
        case 1: return "M"
        case 2: return "T"
        case 3: return "W"
        case 4: return "T"
        case 5: return "F"
        case 6: return "S"
        default: return ""
        }
    }

    private func colorForDay(_ day: DayData) -> Color {
        if day.isFuture {
            return Color.gray.opacity(0.1)
        }

        if !day.isCompleted && day.value == 0 {
            return Color.gray.opacity(0.15)
        }

        // Calculate intensity based on value relative to target
        let ratio = day.value / habit.targetValue

        if ratio >= 1.5 {
            return themeManager.accentColor.opacity(0.9)
        } else if ratio >= 1.0 {
            return themeManager.accentColor.opacity(0.7)
        } else if ratio >= 0.5 {
            return themeManager.accentColor.opacity(0.4)
        } else {
            return themeManager.accentColor.opacity(0.2)
        }
    }

    private func legendColor(for level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.15)
        case 1: return themeManager.accentColor.opacity(0.2)
        case 2: return themeManager.accentColor.opacity(0.4)
        case 3: return themeManager.accentColor.opacity(0.7)
        case 4: return themeManager.accentColor.opacity(0.9)
        default: return Color.gray.opacity(0.15)
        }
    }
}

#Preview {
    HabitHeatmapView(habit: Habit(title: "Read books", targetValue: 30, unit: .minute))
        .padding()
        .environmentObject(ThemeManager())
}
