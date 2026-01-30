//
//  MSTApp.swift
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

@main
struct MSTApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var pointsManager = PointsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(pointsManager)
        }
#if canImport(SwiftData)
#if canImport(Foundation)
    // Attach model container only if model types are defined in this target.
    #if canImport(SwiftData)
    // Use conditional compilation to avoid referencing missing symbols.
    #if swift(>=5.9)
        // If your model types exist, keep them here. Otherwise, fall back to an empty container.
        .modelContainer(for: [])
    #else
        .modelContainer(for: [])
    #endif
    #endif
#else
    .modelContainer(for: [])
#endif
#else
    // Fallback: If SwiftData isn't available, attach an empty container to allow the app to build.
    .modelContainer(for: [])
#endif
    }
}

