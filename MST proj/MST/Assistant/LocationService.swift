//
//  LocationService.swift
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

/// Shared async-friendly location manager singleton.
/// Must be accessed/created on MainActor; tools call `getCurrentLocation()` as async.
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var pendingContinuations: [CheckedContinuation<CLLocation, Error>] = []

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func getCurrentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw LocationError.denied
        }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Brief wait for the system authorization dialog
            try await Task.sleep(nanoseconds: 1_500_000_000)
        }
        let finalStatus = manager.authorizationStatus
        guard finalStatus == .authorizedWhenInUse || finalStatus == .authorizedAlways else {
            throw LocationError.denied
        }
        return try await withCheckedThrowingContinuation { cont in
            pendingContinuations.append(cont)
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let conts = pendingContinuations
            pendingContinuations.removeAll()
            conts.forEach { $0.resume(returning: location) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let conts = pendingContinuations
            pendingContinuations.removeAll()
            conts.forEach { $0.resume(throwing: error) }
        }
    }

    enum LocationError: LocalizedError {
        case denied
        var errorDescription: String? {
            "Location access denied. Please enable Location Services for MST in Settings."
        }
    }
}
