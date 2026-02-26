# MST

A comprehensive iOS productivity app for managing assignments, projects, habits, and focused work sessions built with SwiftUI and SwiftData.

## Overview

MST is a modern, native iOS application designed to help students and professionals manage their tasks, projects, habits, and focus time efficiently. Built entirely with Apple's latest frameworks, it features iOS 26's Liquid Glass UI design, Apple Intelligence (on-device AI), seamless data persistence, and intelligent progress tracking across multiple entity types.

## Features

### Assignment Management
- **Smart Task Tracking** - Create, edit, and manage individual assignments with detailed metadata
- **Target Tracking** - Set measurable targets with customizable units (hours, pages, reps, etc.)
- **Priority System** - Five priority levels (None, Low, Medium, High, Urgent) with color-coded indicators
- **Date Intelligence** - Automatic detection of overdue, due today, and due tomorrow assignments
- **Completion Tracking** - Mark assignments complete with haptic feedback and smooth animations

### Project & Goal Management
- **Long-term Projects** - Create projects with deadlines and break them down into manageable goals
- **Horizontal Timeline** - Visual timeline showing goals with sequential completion enforcement
- **Progress Tracking** - Visual progress indicators showing percentage of completed goals
- **Cascade Relationships** - Goals automatically linked to parent projects with inverse relationships
- **Auto-completion Logic** - Projects auto-complete when all goals are checked
- **Target Values** - Set measurable targets for individual goals

### Habit Tracking
- **Recurring Habits** - Create daily, weekly, or custom frequency habits
- **Streak Tracking** - Monitor current and longest streaks for motivation
- **Heatmap Calendar** - Scrollable calendar showing completion history with animated triangles
- **Progress Rings** - Concentric progress visualization for daily completion
- **Milestone System** - Set completion day targets (e.g., 60-day challenge)
- **Pause for Today** - Skip a day without breaking your streak
- **AI Journey Stories** - Apple Intelligence writes a personalized story paragraph after each check-in, with auto-generated scene images appearing inline

### Focus Timer
- **Single-Ring Countdown** - Clean countdown ring that drains from full to empty during active sessions
- **Dual-Ring Setup** - Interactive hour/minute rings with drag handles for time selection when idle or paused
- **Ambient Music** - 6 procedurally generated soundscapes (White Noise, Brown Noise, Rain, Nature, Lo-Fi, Piano) with volume control
- **Task Integration** - Select assignments or goals to focus on during sessions
- **Background Support** - Timer and ambient audio continue running when app is backgrounded
- **Screen Awake** - Optional setting to keep screen on during focus sessions
- **Completion Celebration** - Animated overlay with bounce effects, ripple, and live elapsed-time counter

### Apple Intelligence
- **AI Assistant** - On-device chatbot powered by FoundationModels with 15 tools for managing all entities
- **User Profile Summary** - AI automatically generates a profile of your focus areas, strengths, and patterns from conversations, viewable in Settings
- **Dynamic Home Title** - AI generates a fresh punny title each session using time-of-day, task count, and live weather
- **Habit Journey Stories** - Personalized narrative generated after each check-in; scene images auto-created with `ImageCreator` in the background; long-press to delete entries
- **Smart Notifications** - AI-written encouragement notifications for upcoming deadlines

### User Experience
- **Unified Dashboard** - Home view displaying assignments, projects, and habits in Liquid Glass cards
- **Interactive Glass Effects** - iOS 26 `.glassEffect(.regular.interactive())` with press feedback
- **Advanced Filtering** - Sort by due date, priority, creation date, subject, or alphabetically
- **Smart Filters** - Filter by completion status, priority level, or time period
- **Search Functionality** - Quickly find items by title or description
- **Swipe Actions** - Context-sensitive swipe gestures for edit, delete, and completion
- **Customizable Themes** - System, light, or dark mode with customizable accent colors
- **Gamification** - Points and streak milestone awards with animated capsule overlay

## Requirements

- iOS 26.2 or later
- Xcode 16.0 or later
- No external dependencies

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MST.git
   ```

2. Open the project in Xcode:
   ```bash
   cd MST
   open "MST proj/MST.xcodeproj"
   ```

3. Build and run the project with `Cmd+R`

## Architecture

### Technology Stack

- **SwiftUI** - Modern declarative UI framework with iOS 26 Liquid Glass effects
- **SwiftData** - Apple's native data persistence framework
- **FoundationModels** - On-device Apple Intelligence for AI assistant and content generation
- **ImagePlayground** - Background scene image generation via `ImageCreator`
- **WeatherKit** - Live weather context for AI title generation
- **CoreLocation** - Location access for WeatherKit queries
- **UserNotifications** - AI-written encouragement push notifications
- **SF Symbols** - System icons with `.symbolEffect` animations
- **AVFoundation** - Procedural ambient audio engine via `AVAudioEngine` + `AVAudioSourceNode`
- **UIKit Integration** - Haptic feedback, system sounds, and idle timer control

### Project Structure

```
MST proj/MST/
├── MSTApp.swift                    # App entry point with multi-model container
├── ContentView.swift               # Tab navigation + floating AI button
├── ThemeManager.swift              # Theme, accent color, focus settings, userName, userProfileSummary
├── SettingsView.swift              # App settings with focus timer toggle
├── PointsManager.swift             # Gamification points and award animations
├── PointsCapsuleView.swift         # Floating points overlay
├── Models/
│   ├── Assignment.swift            # SwiftData model for tasks
│   ├── Project.swift               # SwiftData model for projects
│   ├── Goal.swift                  # SwiftData model for milestones
│   ├── Habit.swift                 # SwiftData model for habits
│   ├── Priority.swift              # Priority enum with colors
│   └── TargetUnit.swift            # Unit enum for targets
├── Home/
│   ├── HomeView.swift              # Unified dashboard; AI nav title
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
│       ├── ConcentricHabitCard.swift
│       ├── HabitHeatmapView.swift
│       ├── HabitJourneyView.swift  # AI story journal + auto image generation
│       └── HabitJourneyEntry.swift # SwiftData model for story entries
├── Assistant/
│   ├── AssistantView.swift         # AI chatbot sheet
│   ├── AssistantViewModel.swift    # LanguageModelSession + 15 tools + user profile summary
│   ├── AssistantMessageView.swift  # Full markdown rendering
│   └── IconPickerView.swift        # SF symbol grid picker
├── Notifications/
│   ├── AIEncouragementManager.swift
│   └── HabitReminderManager.swift
├── Services/
│   └── LocationService.swift
├── FocusView.swift                 # Focus timer main view + ambient music controls
├── FocusTaskPickerView.swift       # Task/goal selection for focus
├── FocusCompletionOverlay.swift    # Completion overlay + elapsed counter
├── FocusTimerBridge.swift          # Observable bridge for cross-tab timer state
├── DualRingTimerView.swift         # Single countdown ring (running) / dual setup rings (idle)
└── AmbientMusicEngine.swift        # Procedural audio engine (6 vibes, AVAudioEngine)
```

### Key Components

**Data Models**:
- **Assignment Model** - SwiftData model with target tracking and priority
- **Project Model** - SwiftData model with cascade delete relationship to goals
- **Goal Model** - SwiftData model with inverse relationship to projects
- **Habit Model** - SwiftData model with frequency, streak tracking, and completions
- **TargetUnit Enum** - 14 unit types with formatting methods
- **Priority Enum** - 5 levels with sort order and color mapping

**Views**:
- **Theme Manager** - Observable class managing theme, accent color, and `keepScreenOnDuringFocus`
- **Home View** - iOS 26 Liquid Glass cards with `GlassButtonStyle` for press feedback
- **Focus View** - Single-ring countdown timer with ambient music and background support via scene phase handling
- **Habit Heatmap** - Scrollable calendar with staggered triangle animations
- **Project Detail** - Horizontal timeline with sequential goal completion

## Usage

### Managing Assignments

**Create**: Tap the "+" button and fill in details (title, description, due date, priority, subject, target)

**Complete**: Tap the checkbox or swipe right on any assignment

**Edit**: Tap on an assignment card or use swipe left for edit action

**Delete**: Swipe left and tap delete

**Filter & Sort**: Use the filter menu to view specific subsets and sort by various criteria

### Managing Projects

**Create**: Add a new project with a title, description, deadline, and subject

**Add Goals**: Within a project, create milestone goals with target dates, priorities, and optional targets

**Track Progress**: Visual progress ring shows percentage of completed goals

**Sequential Completion**: Goals must be completed in timeline order (previous goals must be done first)

**Auto-completion**: When all goals are checked, the project automatically marks as complete

### Managing Habits

**Create**: Set up a habit with title, target value, unit, and frequency (daily/weekly/custom)

**Track**: Tap the habit card to log completion for the day

**View History**: Scroll through the heatmap calendar to see completion patterns

**Milestones**: Set a target number of days (e.g., 60-day challenge)

### Using Focus Timer

1. Navigate to the Focus tab
2. Drag the outer ring to set minutes, inner ring for hours
3. Optionally select a task or goal to focus on
4. Tap the waveform button to choose ambient music (White Noise, Brown Noise, Rain, Nature, Lo-Fi, Piano)
5. Tap Start to begin — the timer switches to a clean single-ring countdown
6. Timer and ambient audio continue even when app is backgrounded
7. Complete the session for celebration animation

### Customizing Settings

1. Navigate to the Settings tab
2. Choose your preferred theme (System, Light, or Dark)
3. Select an accent color from the available options
4. Toggle "Keep Screen On During Focus" for uninterrupted timer sessions

## Development

### Data Flow

- `@Query` decorator for reactive SwiftData fetching across all four models
- `@Environment(\.modelContext)` for CRUD operations
- `@Environment(\.scenePhase)` for background/foreground lifecycle handling
- `@Bindable` for direct model property binding in edit views
- Closure callbacks for parent-child communication
- Cascade delete relationships (Project → Goals)
- Inverse relationships for bidirectional navigation (Goal ↔ Project)
- Auto-completion logic in `Goal.toggleCompletion()` that updates parent project state

### UI Patterns

- **Liquid Glass**: `.glassEffect(.regular.interactive())` for iOS 26 interactive glass effects
- **GlassButtonStyle**: Custom `ButtonStyle` for press feedback on glass elements
- SF Symbol animations with `.contentTransition(.symbolEffect(.replace.magic(...)))`
- Spring animations with staggered delays for completion feedback
- Haptic feedback with `UINotificationFeedbackGenerator` on completion
- System sounds (`AudioServicesPlaySystemSound(1407)`) for confirmation tick
- `UIApplication.shared.isIdleTimerDisabled` for screen awake during focus
- Circular progress indicators for habits and project goal completion
- Staggered scroll animations for heatmap triangles

## Technical Highlights

- **Pure SwiftUI** - No UIKit view controllers, fully declarative UI
- **iOS 26 Liquid Glass** - Native `.glassEffect(.regular.interactive())` for modern glass UI
- **On-Device Apple Intelligence** - `FoundationModels` for zero-latency, privacy-preserving AI features
- **Background Image Generation** - `ImageCreator` auto-generates habit journey scene images without popups
- **Procedural Ambient Audio** - `AVAudioEngine` + `AVAudioSourceNode` generates 6 soundscapes entirely in code (no bundled audio files)
- **SwiftData Relationships** - Sophisticated cascade and inverse relationships between entities
- **Background Timer** - Scene phase handling for timer persistence across app states
- **Computed Properties** - Reactive due date logic, streak calculations, and progress tracking
- **Enum-Driven Design** - Type-safe priority and unit systems with formatting methods
- **No Dependencies** - Zero third-party libraries, pure Apple frameworks
- **iOS 26.2+** - Leverages latest SwiftUI, SwiftData, Liquid Glass, and FoundationModels features

## Data Model Relationships

```
Assignment (standalone)
  ├─ Properties: title, description, dueDate, priority, subject, targetValue, targetUnit
  ├─ Computed: isOverdue, isDueToday, formattedDueDate
  └─ Enum: Priority (5 cases), TargetUnit (14 cases)

Project (parent)
  ├─ Properties: title, description, deadline, subject, isCompleted
  ├─ Relationship: goals → [Goal] (cascade delete)
  ├─ Computed: progressPercentage, nextGoal, sortedGoals
  └─ Auto-completion based on goal states

Goal (child)
  ├─ Properties: title, targetDate, priority, sortOrder, targetValue, targetUnit
  ├─ Relationship: project → Project? (inverse)
  ├─ Computed: isOverdue, formattedTarget
  └─ Sequential completion enforcement

Habit (standalone)
  ├─ Properties: title, description, targetValue, unit, frequency, maxCompletionDays
  ├─ Relationship: completions → [HabitCompletion]
  ├─ Computed: currentStreak, longestStreak, todayProgress, isCompletedToday
  └─ Enum: HabitFrequency (daily, weekly, weekdays, weekends, custom)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the PolyForm Strict License 1.0.0. See LICENSE file for details.

## Acknowledgments

Built with Apple's native frameworks - SwiftUI, SwiftData, FoundationModels, and AVFoundation. Features iOS 26 Liquid Glass design patterns with interactive effects, SF Symbol animations, and procedurally generated ambient audio.
