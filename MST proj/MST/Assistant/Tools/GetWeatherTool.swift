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
import CoreLocation
import FoundationModels

struct GetWeatherTool: Tool {
    let name = "getWeather"
    let description = "Get the current weather conditions including temperature, condition, high/low, humidity, and wind speed using the user's current location."

    @Generable
    struct Arguments {}

    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)
        do {
            let location = try await LocationService.shared.getCurrentLocation()
            let result = try await fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            tracker.record(name: name, result: result)
            return result
        } catch {
            let result = "Weather unavailable: \(error.localizedDescription)"
            tracker.record(name: name, result: result)
            return result
        }
    }

    // MARK: - Open-Meteo fetch (free, no API key)

    private func fetchWeather(latitude: Double, longitude: Double) async throws -> String {
        // Use Fahrenheit for US/imperial locales, Celsius otherwise
        let useImperial = Locale.current.measurementSystem == .us
        let tempUnit = useImperial ? "fahrenheit" : "celsius"
        let tempSymbol = useImperial ? "°F" : "°C"
        let windUnit = useImperial ? "mph" : "kmh"
        let windLabel = useImperial ? "mph" : "km/h"

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(format: "%.4f", latitude)),
            .init(name: "longitude", value: String(format: "%.4f", longitude)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            .init(name: "temperature_unit", value: tempUnit),
            .init(name: "wind_speed_unit", value: windUnit),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "1")
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = json["current"] as? [String: Any],
            let daily = json["daily"] as? [String: Any]
        else {
            throw URLError(.cannotParseResponse)
        }

        let temp        = current["temperature_2m"] as? Double ?? 0
        let feelsLike   = current["apparent_temperature"] as? Double ?? 0
        let humidity    = current["relative_humidity_2m"] as? Int ?? 0
        let wind        = current["wind_speed_10m"] as? Double ?? 0
        let code        = current["weather_code"] as? Int ?? 0

        let high = (daily["temperature_2m_max"] as? [Double])?.first ?? 0
        let low  = (daily["temperature_2m_min"] as? [Double])?.first ?? 0

        let condition = weatherDescription(for: code)

        return """
        \(condition), \(fmt(temp))\(tempSymbol) \
        (Feels like \(fmt(feelsLike))\(tempSymbol), \
        High: \(fmt(high))\(tempSymbol), Low: \(fmt(low))\(tempSymbol)), \
        Humidity: \(humidity)%, Wind: \(fmt(wind)) \(windLabel)
        """
    }

    private func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    // MARK: - WMO weather code → human-readable description

    private func weatherDescription(for code: Int) -> String {
        switch code {
        case 0:       return "Clear sky"
        case 1:       return "Mainly clear"
        case 2:       return "Partly cloudy"
        case 3:       return "Overcast"
        case 45, 48:  return "Foggy"
        case 51, 53:  return "Light drizzle"
        case 55:      return "Dense drizzle"
        case 56, 57:  return "Freezing drizzle"
        case 61, 63:  return "Rain"
        case 65:      return "Heavy rain"
        case 66, 67:  return "Freezing rain"
        case 71, 73:  return "Snow"
        case 75:      return "Heavy snow"
        case 77:      return "Snow grains"
        case 80, 81:  return "Rain showers"
        case 82:      return "Heavy rain showers"
        case 85, 86:  return "Snow showers"
        case 95:      return "Thunderstorm"
        case 96, 99:  return "Thunderstorm with hail"
        default:      return "Unknown conditions"
        }
    }
}
