//
//  PointsManager.swift
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
import Combine
import SwiftUI

@MainActor
class PointsManager: ObservableObject {
    @Published var totalPointsEarned: Int = 0
    @Published var currentPoints: Int = 0
    @Published var showPointsEarned: Bool = false
    @Published var pointsJustEarned: Int = 0

    private let store = NSUbiquitousKeyValueStore.default

    private let totalKey = "points_totalEarned"
    private let currentKey = "points_current"

    init() {
        loadFromStore()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )

        store.synchronize()
    }

    private func loadFromStore() {
        totalPointsEarned = Int(store.longLong(forKey: totalKey))
        currentPoints = Int(store.longLong(forKey: currentKey))
    }

    private func saveToStore() {
        store.set(Int64(totalPointsEarned), forKey: totalKey)
        store.set(Int64(currentPoints), forKey: currentKey)
        store.synchronize()
    }

    @objc private func storeDidChange(_ notification: Notification) {
        Task { @MainActor in
            self.loadFromStore()
        }
    }

    func awardPoints(_ amount: Int) {
        totalPointsEarned += amount
        currentPoints += amount
        saveToStore()

        pointsJustEarned = amount
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showPointsEarned = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.showPointsEarned = false
            }
        }
    }

    func spendPoints(_ amount: Int) -> Bool {
        guard currentPoints >= amount else { return false }
        currentPoints -= amount
        saveToStore()
        return true
    }
}

