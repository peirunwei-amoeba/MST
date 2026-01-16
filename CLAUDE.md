# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MST is an iOS homework/assignment tracking app built with SwiftUI and SwiftData. It targets iOS 26.2+ and uses no external dependencies.

## Build & Run

Open `MST proj/MST.xcodeproj` in Xcode and build/run with Cmd+R. No package manager setup required.

## Architecture

**Framework Stack**: SwiftUI + SwiftData (Apple's native persistence)

**Entry Point**: `MSTApp.swift` initializes:
- `ThemeManager` as `@StateObject` passed via `.environmentObject()`
- SwiftData `.modelContainer(for: Assignment.self)`

**Navigation**: Tab-based via `ContentView.swift`
- Home tab → `HomeView` (dashboard with compact assignment cards)
- Settings tab → `SettingsView` (themes, changelog)

**Data Flow**:
- `@Query` decorator for reactive SwiftData fetching
- `@Environment(\.modelContext)` for CRUD operations
- `@Bindable` for direct model property binding in edit views
- Closure callbacks (`onTap`, `onToggleComplete`) for child-to-parent communication

## Key Files

| File | Purpose |
|------|---------|
| `Assignment.swift` | SwiftData `@Model` with computed properties (`isOverdue`, `isDueToday`, etc.) |
| `ThemeManager.swift` | `@Observable` class managing theme (system/light/dark) and accent color, persisted via `@AppStorage` |
| `HomeView.swift` | iOS 26 "concentric" glass-effect card design with animated task completion |
| `AssignmentListView.swift` | Full list with sorting (5 options), filtering (5 options), search, swipe actions |

## UI Patterns

- **Glass morphism**: `.ultraThinMaterial`, `.regularMaterial` backgrounds
- **SF Symbol animations**: `.contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))` for checkbox
- **Haptic feedback**: `UIImpactFeedbackGenerator(style: .light)` on completion
- **System sounds**: `AudioServicesPlaySystemSound(1407)` for confirmation tick
- **Delayed removal**: Completed tasks stay visible ~1 second before animated fade-out on HomeView

## Assignment Model Properties

Core: `id`, `title`, `assignmentDescription`, `dueDate`, `isCompleted`, `priority`, `subject`

Computed: `isOverdue`, `isDueToday`, `isDueTomorrow`, `formattedDueDate`

Priority enum: `.low`, `.medium`, `.high`, `.urgent` (with `sortOrder` for sorting)
