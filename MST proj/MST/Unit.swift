//
//  Unit.swift
//  MST
//
//  Created by Claude on 1/20/26.
//

import Foundation
import SwiftUI

enum TargetUnit: String, Codable, CaseIterable, Identifiable {
    // Distance
    case kilometer = "km"
    case meter = "m"
    case mile = "mi"

    // Time
    case hour = "hr"
    case minute = "min"
    case second = "sec"

    // Count/Quantity
    case pages = "pages"
    case times = "times"
    case reps = "reps"
    case sets = "sets"

    // Volume
    case liter = "L"
    case milliliter = "mL"
    case cups = "cups"
    case glasses = "glasses"

    // Custom/None
    case none = ""

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kilometer: return "Kilometers"
        case .meter: return "Meters"
        case .mile: return "Miles"
        case .hour: return "Hours"
        case .minute: return "Minutes"
        case .second: return "Seconds"
        case .pages: return "Pages"
        case .times: return "Times"
        case .reps: return "Repetitions"
        case .sets: return "Sets"
        case .liter: return "Liters"
        case .milliliter: return "Milliliters"
        case .cups: return "Cups"
        case .glasses: return "Glasses"
        case .none: return "None"
        }
    }

    var category: UnitCategory {
        switch self {
        case .kilometer, .meter, .mile: return .distance
        case .hour, .minute, .second: return .time
        case .pages, .times, .reps, .sets: return .count
        case .liter, .milliliter, .cups, .glasses: return .volume
        case .none: return .none
        }
    }

    /// Format value with unit (e.g., "3 km", "30 min")
    func format(_ value: Double) -> String {
        if self == .none { return "" }
        let formattedValue = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "\(formattedValue) \(rawValue)"
    }
}

enum UnitCategory: String, CaseIterable {
    case distance = "Distance"
    case time = "Time"
    case count = "Count"
    case volume = "Volume"
    case none = "None"
}

// MARK: - Focus Timer Helpers

extension TargetUnit {
    /// Converts a value in this unit to minutes. Returns nil if not a time-based unit.
    func toMinutes(_ value: Double) -> Int? {
        guard category == .time else { return nil }
        switch self {
        case .hour: return Int(value * 60)
        case .minute: return Int(value)
        case .second: return max(1, Int(ceil(value / 60)))
        default: return nil
        }
    }
}
