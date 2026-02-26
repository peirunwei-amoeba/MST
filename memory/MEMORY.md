# MST Project Memory

## Project Overview
iOS 26+ SwiftUI+SwiftData productivity app. No external dependencies.
Target: iOS 26.2+, Swift 6, uses Apple Intelligence (FoundationModels).

## Key Architecture Notes
- Entry: MSTApp.swift → ContentView (TabView: Home, Focus, Settings) + FloatingAIButton overlay
- AI Assistant: AssistantView (fullScreenCover) ← FloatingAIButton
- Xcode project uses PBXFileSystemSynchronizedRootGroup → new files added to MST/ folder are AUTO-INCLUDED in the build, no manual project.pbxproj editing needed
- GlassButtonStyle is defined in HomeView.swift, accessible throughout the module
- SourceKit cross-file "Cannot find type" errors are normal and resolve at build time

## Assistant System Architecture
- AssistantViewModel (@Observable @MainActor) owns ToolCallTracker + LanguageModelSession
- ToolCallTracker has onCallStarted/onCallCompleted callbacks dispatched via DispatchQueue.main for real-time tool card updates
- Tools call tracker.startCall(name:) at start → shows loading ring, then record() at end → shows result
- Word-by-word streaming simulation via streamText() in AssistantViewModel
- LocationService.swift is a @MainActor singleton for proper async CLLocationManager

## Tool Files Pattern
All 13 tools: GetCurrentDate, GetAssignments, GetProjects, GetHabits, GetUpcomingSummary,
CreateAssignment, CreateProject, CompleteAssignment, CompleteHabitToday, StartFocusTimer,
GetWeather, GetLocation, GetHealthData
Each calls tracker.startCall(name: name) at the TOP of call(), tracker.record() at the end.

## UI Patterns
- glassEffect(.regular.interactive(), in: ...) for buttons
- glassEffect(.regular, in: ...) for cards/containers
- AppStoreLoadingRing: Circle().trim(0.05, 0.75) with .linear(0.9).repeatForever animation
- ToolResultCardView shows: App Store ring (loading) → icon + rich content (done)
- Rich content: MapKit map (location), calendar tile (date), weather icon, health stats
- FloatingAIButton: .padding(.bottom, 115) aligns with Focus Start button height
- AssistantView: .ultraThinMaterial background + accent gradient overlay

## Common Issues
- symbolEffect can only be applied to Image(systemName:), not shapes like Circle()
- CLLocationManager needs @MainActor class with proper delegate for async auth flow
- authorizedWhenInUse shows macOS SourceKit warning but works fine on iOS target
