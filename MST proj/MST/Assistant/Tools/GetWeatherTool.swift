//
//  GetWeatherTool.swift
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

import Foundation
import WeatherKit
import CoreLocation
import FoundationModels

struct GetWeatherTool: Tool {
    let name = "getWeather"
    let description = "Get the current weather conditions including temperature, condition, high/low, and humidity."

    @Generable
    struct Arguments {}

    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        do {
            let location = try await LocationService.shared.getCurrentLocation()
            let weather = try await WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            let daily = weather.dailyForecast.first

            let temp = current.temperature
            let condition = current.condition.description
            let humidity = Int(current.humidity * 100)
            let high = daily?.highTemperature
            let low = daily?.lowTemperature

            var result = "\(condition), \(temp.formatted())"
            if let high, let low {
                result += " (High: \(high.formatted()), Low: \(low.formatted()))"
            }
            result += ", Humidity: \(humidity)%"

            tracker.record(name: name, result: result)
            return result
        } catch {
            let result = "Weather unavailable: \(error.localizedDescription)"
            tracker.record(name: name, result: result)
            return result
        }
    }
}
