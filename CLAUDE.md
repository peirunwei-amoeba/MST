# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MST is an iOS homework/assignment tracking app built with SwiftUI and SwiftData. It targets iOS 26.2+ and uses no external dependencies. The app supports three core entities: Assignments (individual tasks), Projects (long-term goals with sub-goals), and Goals (milestones within projects).

## Build & Run

Open `MST proj/MST.xcodeproj` in Xcode and build/run with Cmd+R. No package manager setup required.

## Architecture

**Framework Stack**: SwiftUI + SwiftData (Apple's native persistence)

**Entry Point**: `MSTApp.swift` initializes:
- `ThemeManager` as `@StateObject` passed via `.environmentObject()`
- SwiftData `.modelContainer(for: [Assignment.self, Project.self, Goal.self])`

**Navigation**: Tab-based via `ContentView.swift`
- Home tab → `HomeView` (unified dashboard showing assignments and projects)
- Settings tab → `SettingsView` (themes, changelog)

**Data Flow**:
- `@Query` decorator for reactive SwiftData fetching
- `@Environment(\.modelContext)` for CRUD operations
- `@Bindable` for direct model property binding in edit views
- Closure callbacks (`onTap`, `onToggleComplete`) for child-to-parent communication

## Key Files

| File | Purpose |
|------|---------|
| `Assignment.swift` | SwiftData `@Model` for assignments with computed properties (`isOverdue`, `isDueToday`, etc.) and extended properties (`tags`, `notes`, `estimatedDuration`, `notificationEnabled`) |
| `Project.swift` | SwiftData `@Model` for projects with cascade relationship to goals, progress tracking via `progressPercentage` |
| `Goal.swift` | SwiftData `@Model` for project milestones with inverse relationship to `Project`, auto-completion logic for parent projects |
| `ThemeManager.swift` | `@Observable` class managing theme (system/light/dark) and accent color, persisted via `@AppStorage` |
| `HomeView.swift` | iOS 26 "concentric" glass-effect card design with animated task completion |
| `AssignmentListView.swift` | Full assignment list with sorting (5 options), filtering (5 options), search, swipe actions |
| `ProjectListView.swift` | Project list with progress indicators and goal breakdowns |
| `ProjectDetailView.swift` | Detailed project view showing all goals with drag-to-reorder and inline editing |

## Data Models

### Assignment
**Core Properties**: `id`, `title`, `assignmentDescription`, `dueDate`, `createdDate`, `isCompleted`, `completedDate`, `priority`, `subject`, `tags`, `notes`, `estimatedDuration`, `notificationEnabled`, `colorCode`

**Computed**: `isOverdue`, `isDueToday`, `isDueTomorrow`, `timeUntilDue`, `formattedDueDate`

### Project
**Core Properties**: `id`, `title`, `projectDescription`, `createdDate`, `deadline`, `isCompleted`, `completedDate`, `colorCode`, `subject`, `goals` (cascade delete relationship)

**Computed**: `progressPercentage`, `nextGoal`, `sortedGoals`, `completedGoalsCount`, `isOverdue`, `formattedDeadline`

### Goal
**Core Properties**: `id`, `title`, `targetDate`, `isCompleted`, `completedDate`, `sortOrder`, `priorityRaw`, `project` (inverse relationship)

**Computed**: `priority` (enum wrapper for `priorityRaw`), `isOverdue`, `formattedTargetDate`

**Special Logic**: `toggleCompletion()` auto-completes parent project when all goals are complete, and uncompletes parent when any goal is unchecked

### Priority Enum
Cases: `.none`, `.low`, `.medium`, `.high`, `.urgent`

Properties: `sortOrder` (0-4), `color` (red/orange/yellow/green/gray)

## UI Patterns

- **Glass morphism**: `.ultraThinMaterial`, `.regularMaterial` backgrounds
- **SF Symbol animations**: `.contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))` for checkbox
- **Haptic feedback**: `UIImpactFeedbackGenerator(style: .light)` on completion
- **System sounds**: `AudioServicesPlaySystemSound(1407)` for confirmation tick
- **Delayed removal**: Completed tasks stay visible ~1 second before animated fade-out on HomeView
- **Progress indicators**: Circular progress rings for projects showing goal completion percentage

## Common Patterns

**Sorting Options**: Due date, priority, creation date, subject, alphabetical
**Filtering Options**: All, incomplete, completed, by priority level, by time period
**Swipe Actions**: Edit, delete, mark complete/incomplete
**Color Customization**: Both assignments and projects support custom color codes
