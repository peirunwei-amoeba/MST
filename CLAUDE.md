# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MST is an iOS productivity app built with SwiftUI and SwiftData. It targets iOS 26.2+ and uses no external dependencies. The app supports four core entities: Assignments (individual tasks), Projects (long-term goals with sub-goals), Goals (milestones within projects), and Habits (recurring tasks with streak tracking). Apple Intelligence (FoundationModels) powers the AI assistant, habit journey stories, and the dynamic home screen title.

## Build & Run

Open `MST proj/MST.xcodeproj` in Xcode and build/run with Cmd+R. No package manager setup required.

## Architecture

**Framework Stack**: SwiftUI + SwiftData + FoundationModels + ImagePlayground + HealthKit + WeatherKit + CoreLocation + UserNotifications + AVFoundation (procedural ambient audio)

**Entry Point**: `MSTApp.swift` initializes:
- `ThemeManager` as `@StateObject` passed via `.environmentObject()`
- `PointsManager` as `@StateObject` for gamification
- `FocusTimerBridge` as `@State` passed via `.environment()`
- `AmbientMusicEngine` as `@State` passed via `.environment()`
- SwiftData `.modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitJourneyEntry.self])`

**Navigation**: Tab-based via `ContentView.swift`
- Home tab → `HomeView` (unified dashboard showing assignments, projects, and habits)
- Focus tab → `FocusView` (single-ring countdown timer with ambient music and task selection)
- Settings tab → `SettingsView` (themes, focus timer settings, user profile, changelog)
- Floating AI button → `AssistantView` sheet (Apple Intelligence chatbot with 15 tools)

**Data Flow**:
- `@Query` decorator for reactive SwiftData fetching
- `@Environment(\.modelContext)` for CRUD operations
- `@Bindable` for direct model property binding in edit views
- `@Environment(\.scenePhase)` for background/foreground lifecycle handling
- Closure callbacks (`onTap`, `onToggleComplete`) for child-to-parent communication

## Directory Structure

```
MST proj/MST/
├── Models/
│   ├── Assignment.swift
│   ├── Project.swift
│   ├── Goal.swift
│   ├── Habit.swift
│   ├── Priority.swift
│   └── TargetUnit.swift
├── Home/
│   ├── HomeView.swift
│   ├── Assignments/
│   │   ├── AddAssignmentView.swift
│   │   ├── EditAssignmentView.swift
│   │   ├── AssignmentListView.swift
│   │   └── AssignmentRowView.swift
│   ├── Projects/
│   │   ├── AddProjectView.swift
│   │   ├── EditProjectView.swift
│   │   ├── ProjectListView.swift
│   │   └── ProjectDetailView.swift
│   └── Habits/
│       ├── AddHabitView.swift
│       ├── EditHabitView.swift
│       ├── EditHabitView.swift
│       ├── ConcentricHabitCard.swift
│       ├── HabitHeatmapView.swift
│       ├── HabitJourneyView.swift      # AI-generated story journal per habit
│       └── HabitJourneyEntry.swift     # SwiftData model for journey entries
├── Assistant/
│   ├── AssistantView.swift             # AI chatbot sheet (FoundationModels)
│   ├── AssistantViewModel.swift        # LanguageModelSession + 15 tools + conversation summary
│   ├── AssistantMessageView.swift      # Full markdown rendering
│   └── IconPickerView.swift            # SF symbol grid picker
├── Notifications/
│   ├── AIEncouragementManager.swift    # AI-generated push notifications
│   └── HabitReminderManager.swift      # Daily 7PM habit reminders
├── Services/
│   └── LocationService.swift          # CLLocationManager singleton wrapper
├── FocusView.swift
├── FocusTaskPickerView.swift
├── FocusCompletionOverlay.swift
├── FocusTimerBridge.swift
├── DualRingTimerView.swift
├── AmbientMusicEngine.swift           # Procedural audio engine (AVAudioEngine + AVAudioSourceNode)
├── PointsManager.swift
├── PointsCapsuleView.swift
├── ThemeManager.swift
├── SettingsView.swift
└── ContentView.swift
```

## Key Files

| File | Purpose |
|------|---------|
| `Assignment.swift` | SwiftData `@Model` for assignments with computed properties (`isOverdue`, `isDueToday`, etc.) and target tracking |
| `Project.swift` | SwiftData `@Model` for projects with cascade relationship to goals, progress tracking via `progressPercentage` |
| `Goal.swift` | SwiftData `@Model` for project milestones with inverse relationship to `Project`, auto-completion logic |
| `Habit.swift` | SwiftData `@Model` for habits with frequency, streak tracking, `pausedDates`, and completion history |
| `HabitJourneyEntry.swift` | SwiftData `@Model` for AI-generated story paragraphs; stores text + `imagePathsJSON` mapping markers to PNG files |
| `ThemeManager.swift` | `@Observable` class managing theme, accent color, focus settings, `userName`, `assistantIconName`, and `userProfileSummary` via `@AppStorage` |
| `HomeView.swift` | iOS 26 glass-effect cards; AI-generated nav title (FoundationModels + WeatherKit + CoreLocation) |
| `FocusView.swift` | Focus timer with single-ring countdown, ambient music, task selection, and background support |
| `FocusCompletionOverlay.swift` | Completion overlay with long-press confirm, ripple animation, and elapsed-time counter |
| `DualRingTimerView.swift` | Custom circular timer: single countdown ring when running, dual hour/minute rings with drag handles when idle/paused |
| `AmbientMusicEngine.swift` | `@Observable @MainActor` procedural audio engine with 6 vibes (White Noise, Brown Noise, Rain, Nature, Lo-Fi, Piano) via `AVAudioEngine` + `AVAudioSourceNode` |
| `ConcentricHabitCard.swift` | Glass-effect habit card with progress ring and bounce animation |
| `HabitHeatmapView.swift` | Scrollable calendar heatmap showing habit completion history |
| `HabitJourneyView.swift` | AI story journal per habit; auto-generates entry + background image after each check-in; context menu delete with image cleanup |
| `ProjectDetailView.swift` | Horizontal timeline view with sequential goal completion |
| `AssistantViewModel.swift` | `LanguageModelSession` with 15 tools; recreates session every 8 messages; persists history to UserDefaults; generates user profile summary on dismiss |
| `PointsManager.swift` | `@MainActor ObservableObject` managing gamification points, streak milestones, and award animations |
| `AIEncouragementManager.swift` | Schedules AI-generated encouragement notifications for items with due dates |

## Data Models

### Assignment
**Core Properties**: `id`, `title`, `assignmentDescription`, `dueDate`, `createdDate`, `isCompleted`, `completedDate`, `priority`, `subject`, `notes`, `notificationEnabled`, `targetValue`, `targetUnit`

**Computed**: `isOverdue`, `isDueToday`, `isDueTomorrow`, `timeUntilDue`, `formattedDueDate`

### Project
**Core Properties**: `id`, `title`, `projectDescription`, `createdDate`, `deadline`, `isCompleted`, `completedDate`, `subject`, `goals` (cascade delete relationship)

**Computed**: `progressPercentage`, `nextGoal`, `sortedGoals`, `completedGoalsCount`, `isOverdue`, `formattedDeadline`

### Goal
**Core Properties**: `id`, `title`, `targetDate`, `isCompleted`, `completedDate`, `sortOrder`, `priority`, `project` (inverse relationship), `targetValue`, `targetUnit`

**Computed**: `isOverdue`, `formattedTargetDate`, `formattedTarget`

**Special Logic**: `toggleCompletion()` auto-completes parent project when all goals are complete

### Habit
**Core Properties**: `id`, `title`, `habitDescription`, `createdDate`, `targetValue`, `unit`, `frequency`, `maxCompletionDays`, `completions` (array of completion records), `pausedDates: [Date]`

**Computed**: `currentStreak`, `longestStreak`, `todayProgress`, `isCompletedToday`, `completionPercentage`, `isPausedToday`

**Methods**: `pauseForToday()`, `unpauseToday()`

**Frequency Options**: `.daily`, `.weekly`, `.weekdays`, `.weekends`, `.custom`

### HabitJourneyEntry
**Core Properties**: `id`, `habitId`, `habitTitle`, `date`, `checkinNumber`, `storyText`, `imagePathsJSON`

**Computed**: `imagePaths: [String: String]`, `segments: [StorySegment]`

**Methods**: `imageFilePath(for:)`, `savedImageURL(for:)`, `saveImage(at:for:)`, `parse(_:) → [StorySegment]`

### TargetUnit Enum
Cases: `.none`, `.times`, `.hour`, `.minute`, `.km`, `.mile`, `.page`, `.chapter`, `.word`, `.item`, `.rep`, `.set`, `.cal`, `.custom`

**Methods**: `format(_ value: Double)` for display, `displayName` for picker labels

### Priority Enum
Cases: `.none`, `.low`, `.medium`, `.high`, `.urgent`

Properties: `sortOrder` (0-4), `color` (red/orange/yellow/green/gray)

## UI Patterns

- **Liquid Glass**: `.glassEffect(.regular.interactive())` for iOS 26 interactive glass effects
- **GlassButtonStyle**: Custom `ButtonStyle` with scale/opacity press feedback for glass elements
- **SF Symbol animations**: `.contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))` for checkmarks
- **Bounce animations**: Spring animation with 0.05s delay after state change for completion feedback
- **Haptic feedback**: `UINotificationFeedbackGenerator` on completion
- **System sounds**: `AudioServicesPlaySystemSound(1407)` for confirmation tick
- **Staggered animations**: Delay-based scroll appearance for heatmap triangles
- **Background timer**: `@Environment(\.scenePhase)` + `timerEndTime` tracking for background persistence
- **Screen awake**: `UIApplication.shared.isIdleTimerDisabled` during focus sessions
- **Progress indicators**: Circular progress rings for habits and projects
- **Elapsed counter**: Focus completion overlay shows `+M:SS` counter via `.task` auto-cancelled on dismiss
- **AI nav title**: `HomeView` generates a punny 4–6 word title via `LanguageModelSession` + WeatherKit context; always `.title3.weight(.bold)`, quotes stripped
- **Habit Journey**: After each check-in, AI streams a story paragraph then auto-generates scene images via `ImageCreator` in background `Task`s; deduplication prevents multiple entries per day; long-press context menu to delete entries with disk image cleanup
- **Ambient Music**: Procedural audio via `AVAudioEngine` + `AVAudioSourceNode`; 6 vibes with volume control; auto-stops on timer completion/reset; `UIBackgroundModes: audio` for background playback

## Focus Timer

The Focus tab features a timer with two modes:
- **Countdown mode** (running): Single ring draining from full→empty based on `remainingSeconds / totalSeconds`
- **Setup mode** (idle/paused): Dual rings with drag handles, tick marks, and 15/30/45/60 labels for hour/minute selection
- Task/goal selection from incomplete items
- Background timer support (continues when app is backgrounded)
- Completion overlay with animated feedback
- Optional "Keep Screen On" setting in ThemeManager
- Ambient music with 6 procedural vibes (White Noise, Brown Noise, Rain, Nature, Lo-Fi, Piano) and volume slider

**Scene Phase Handling**:
```swift
.onChange(of: scenePhase) { _, newPhase in
    switch newPhase {
    case .active: // Recalculate remaining time from timerEndTime
    case .background: // Invalidate timer, keep timerEndTime
    }
}
```

## Common Patterns

**Target Values**: String-based TextField with "Value" placeholder, converted to Double on change
**Sorting Options**: Due date, priority, creation date, subject, alphabetical
**Filtering Options**: All, incomplete, completed, by priority level, by time period
**Swipe Actions**: Edit, delete, mark complete/incomplete
**Sequential Completion**: Goals in project timeline must be completed in order

## Apple Intelligence Integration

- **AssistantViewModel**: `LanguageModelSession` with 15 tools (CRUD for all entities, streak milestones, pause habit, user profile, etc.); session recreated every 8 messages to avoid context bloat; history persisted to UserDefaults key `"conversationHistory"` (max 60 messages); generates user profile summary on sheet dismiss via separate `LanguageModelSession`
- **User Profile Summary**: `generateConversationSummary()` creates a 3-5 sentence profile (focus areas, strengths, patterns) stored in `ThemeManager.userProfileSummary`; appended to system instructions for personalized responses; viewable in Settings; `GetUserSummaryTool` lets the AI access the profile
- **HabitJourneyView**: Generates story entry on first open after check-in (`@Binding var startGenerating`); deduplicates to one entry per day; feeds **all** previous entries as context; auto-generates scene images via `ImageCreator` in background without any popup; `ImageMarkerView` checks disk path first to prevent re-render flicker
- **AI Nav Title**: `generateAITitle()` in `HomeView` uses `LanguageModelSession`; strips quote characters from output; always renders at `.title3.weight(.bold)`
- **AIEncouragementManager**: Schedules AI-generated notification copy for assignments/habits approaching due dates

## Ambient Music Engine

`AmbientMusicEngine` is an `@Observable @MainActor` class using `AVAudioEngine` with `AVAudioSourceNode` for fully procedural audio generation (no bundled audio files).

**Vibes** (each has its own render function in `RenderState`):
- **White Noise**: Uniform random samples
- **Brown Noise**: Cumulative random walk with slight decay to center
- **Rain**: Filtered white noise base + random amplitude drop impacts
- **Nature**: Brown noise wind + occasional sine wave bird chirps at random frequencies
- **Lo-Fi**: Pentatonic sine waves with quadratic decay + detuned harmonics + noise bed
- **Piano**: Sine oscillators with harmonics and exponential decay at randomized pentatonic notes

**Integration**: Menu button in FocusView control bar; volume slider appears when playing; auto-stops on timer completion/reset; `UIBackgroundModes: audio` for background playback.

## Timer Alarm Sound

`TimerAlarmSound` enum provides two playback methods:
- `play()`: Uses `AudioServicesPlaySystemSound` (sound only, for preview in settings)
- `playWithVibration()`: Uses `AudioServicesPlayAlertSound` (sound + vibration, for timer completion)

## SourceKit False Positives

When editing Swift files outside Xcode, SourceKit reports "Cannot find X in scope" for all cross-file types. These are **not** real build errors — they resolve when Xcode compiles the full module. Ignore all such diagnostics.
