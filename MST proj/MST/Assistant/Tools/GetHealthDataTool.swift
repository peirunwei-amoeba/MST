//
//  GetHealthDataTool.swift
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
import HealthKit
import FoundationModels

struct GetHealthDataTool: Tool {
    let name = "getHealthData"
    let description = "Read today's health data: steps, latest heart rate, and active energy burned."

    @Generable
    struct Arguments {}

    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard HKHealthStore.isHealthDataAvailable() else {
            let result = "HealthKit is not available on this device."
            tracker.record(name: name, result: result)
            return ToolOutput(result)
        }

        let store = HKHealthStore()
        let stepType = HKQuantityType(.stepCount)
        let heartRateType = HKQuantityType(.heartRate)
        let energyType = HKQuantityType(.activeEnergyBurned)

        let typesToRead: Set<HKSampleType> = [stepType, heartRateType, energyType]

        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            let result = "Health data access not authorized."
            tracker.record(name: name, result: result)
            return ToolOutput(result)
        }

        var parts: [String] = []

        let steps = await queryTodaySum(store: store, type: stepType, unit: .count())
        if let steps {
            parts.append("Steps: \(Int(steps).formatted())")
        }

        let heartRate = await queryLatestSample(store: store, type: heartRateType)
        if let heartRate {
            let bpm = heartRate.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            parts.append("Heart rate: \(Int(bpm)) bpm")
        }

        let energy = await queryTodaySum(store: store, type: energyType, unit: .kilocalorie())
        if let energy {
            parts.append("Active energy: \(Int(energy)) cal")
        }

        let result: String
        if parts.isEmpty {
            result = "No health data available for today."
        } else {
            result = parts.joined(separator: " | ")
        }

        tracker.record(name: name, result: result)
        return ToolOutput(result)
    }

    private func queryTodaySum(store: HKHealthStore, type: HKQuantityType, unit: HKUnit) async -> Double? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func queryLatestSample(store: HKHealthStore, type: HKQuantityType) async -> HKQuantitySample? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            store.execute(query)
        }
    }
}
