//
//  GetLocationTool.swift
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

struct GetLocationTool: Tool {
    let name = "getLocation"
    let description = "Get the user's current city and coordinates via location services."

    @Generable
    struct Arguments {}

    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()

        guard let location = locationManager.location else {
            let result = "Unable to get current location. Please ensure location services are enabled."
            tracker.record(name: name, result: result)
            return result
        }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? "Unknown city"
                let state = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                let lat = String(format: "%.4f", location.coordinate.latitude)
                let lon = String(format: "%.4f", location.coordinate.longitude)
                let result = "\(city), \(state), \(country) (\(lat), \(lon))"
                tracker.record(name: name, result: result)
                return result
            }
        } catch {
            // Fall back to coordinates only
        }

        let lat = String(format: "%.4f", location.coordinate.latitude)
        let lon = String(format: "%.4f", location.coordinate.longitude)
        let result = "Coordinates: \(lat), \(lon)"
        tracker.record(name: name, result: result)
        return result
    }
}
