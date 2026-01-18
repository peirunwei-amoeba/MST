# MST

A comprehensive iOS productivity app for managing assignments, projects, and goals built with SwiftUI and SwiftData.

## Overview

MST is a modern, native iOS application designed to help students and professionals manage their tasks, projects, and long-term goals efficiently. Built entirely with Apple's latest frameworks, it features a beautiful glass-morphic UI design, seamless data persistence, and intelligent progress tracking across multiple entity types.

## Features

### Assignment Management
- **Smart Task Tracking** - Create, edit, and manage individual assignments with detailed metadata
- **Extended Properties** - Track tags, notes, estimated duration, and enable notifications per assignment
- **Priority System** - Five priority levels (None, Low, Medium, High, Urgent) with color-coded indicators
- **Date Intelligence** - Automatic detection of overdue, due today, and due tomorrow assignments
- **Completion Tracking** - Mark assignments complete with haptic feedback and smooth animations

### Project & Goal Management
- **Long-term Projects** - Create projects with deadlines and break them down into manageable goals
- **Progress Tracking** - Visual progress indicators showing percentage of completed goals
- **Cascade Relationships** - Goals automatically linked to parent projects with inverse relationships
- **Auto-completion Logic** - Projects auto-complete when all goals are checked, auto-uncheck when any goal is unchecked
- **Goal Reordering** - Drag-to-reorder goals within projects for custom prioritization
- **Next Goal Detection** - Automatically identifies the next incomplete goal based on target date

### User Experience
- **Unified Dashboard** - Home view displaying both assignments and projects in beautiful glass-effect cards
- **Advanced Filtering** - Sort by due date, priority, creation date, subject, or alphabetically
- **Smart Filters** - Filter by completion status, priority level, or time period
- **Search Functionality** - Quickly find assignments and projects by title or description
- **Swipe Actions** - Context-sensitive swipe gestures for edit, delete, and completion
- **Customizable Themes** - System, light, or dark mode with customizable accent colors
- **Color Customization** - Assign custom colors to both assignments and projects

## Requirements

- iOS 26.2 or later
- Xcode 15.0 or later
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

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Apple's native data persistence framework
- **SF Symbols** - System icons with animations
- **UIKit Integration** - Haptic feedback and system sounds

### Project Structure

```
MST proj/
├── MSTApp.swift                # App entry point with multi-model container
├── ContentView.swift           # Tab-based navigation
├── Assignment.swift            # SwiftData model for tasks
├── Project.swift               # SwiftData model for projects
├── Goal.swift                  # SwiftData model for project milestones
├── ThemeManager.swift          # Theme and appearance management
├── HomeView.swift              # Unified dashboard with glass-effect cards
├── AssignmentListView.swift   # Full assignment list with filters
├── ProjectListView.swift      # Project list with progress indicators
├── ProjectDetailView.swift    # Detailed project view with goal management
├── AddAssignmentView.swift    # Assignment creation form
├── EditAssignmentView.swift   # Assignment editing form
├── AddProjectView.swift       # Project creation form
├── EditProjectView.swift      # Project editing form
├── AssignmentRowView.swift    # Reusable assignment row component
└── SettingsView.swift         # Theme and app settings
```

### Key Components

**Data Models**:
- **Assignment Model** - SwiftData model with 13 properties including tags, notes, and estimated duration
- **Project Model** - SwiftData model with cascade delete relationship to goals and computed progress tracking
- **Goal Model** - SwiftData model with inverse relationship to projects and auto-completion logic
- **Priority Enum** - Shared enum with 5 levels, sort order, and color mapping

**Views**:
- **Theme Manager** - Observable class managing app appearance with `@AppStorage` persistence
- **Home View** - iOS 26 concentric glass-effect design showing assignments and projects
- **Assignment List** - Comprehensive list with 5 sorting and 5 filtering options
- **Project Detail** - Goal management with drag-to-reorder and inline editing capabilities

## Usage

### Managing Assignments

**Create**: Tap the "+" button and fill in details (title, description, due date, priority, subject, tags, notes, estimated duration)

**Complete**: Tap the checkbox or swipe right on any assignment

**Edit**: Tap on an assignment card or use swipe left for edit action

**Delete**: Swipe left and tap delete

**Filter & Sort**: Use the filter menu to view specific subsets and sort by various criteria

### Managing Projects

**Create**: Add a new project with a title, description, deadline, and subject

**Add Goals**: Within a project, create milestone goals with target dates and priorities

**Track Progress**: Visual progress ring shows percentage of completed goals

**Reorder Goals**: Drag goals to reorder them by priority or timeline

**Auto-completion**: When all goals are checked, the project automatically marks as complete

**Next Goal**: The app automatically highlights your next incomplete goal

### Customizing Appearance

1. Navigate to the Settings tab
2. Choose your preferred theme (System, Light, or Dark)
3. Select an accent color from the available options
4. Optionally assign custom colors to individual assignments and projects

## Development

### Data Flow

- `@Query` decorator for reactive SwiftData fetching across all three models
- `@Environment(\.modelContext)` for CRUD operations
- `@Bindable` for direct model property binding in edit views
- Closure callbacks for parent-child communication
- Cascade delete relationships (Project → Goals)
- Inverse relationships for bidirectional navigation (Goal ↔ Project)
- Auto-completion logic in `Goal.toggleCompletion()` that updates parent project state

### UI Patterns

- Glass morphism with `.ultraThinMaterial` and `.regularMaterial` backgrounds
- SF Symbol animations with `.contentTransition(.symbolEffect(.replace.magic(...)))`
- Haptic feedback with `UIImpactFeedbackGenerator` on completion actions
- System sounds (`AudioServicesPlaySystemSound`) for confirmation feedback
- Delayed animations for state transitions (completed items fade after ~1 second)
- Circular progress indicators for project goal completion percentage
- Color-coded priority indicators across all entity types
- Swipe gesture recognizers for contextual actions

## Technical Highlights

- **Pure SwiftUI** - No UIKit view controllers, fully declarative UI
- **SwiftData Relationships** - Sophisticated cascade and inverse relationships between entities
- **Computed Properties** - Reactive due date logic, progress calculations, and priority sorting
- **Enum-Driven Design** - Type-safe priority system with integrated sorting and color mapping
- **No Dependencies** - Zero third-party libraries, pure Apple frameworks
- **iOS 26.2+** - Leverages latest SwiftUI and SwiftData features

## Data Model Relationships

```
Assignment (standalone)
  ├─ Properties: 13 core + 5 computed
  └─ Enum: Priority (5 cases)

Project (parent)
  ├─ Properties: 9 core + 6 computed
  ├─ Relationship: goals → [Goal] (cascade delete)
  └─ Auto-completion based on goal states

Goal (child)
  ├─ Properties: 7 core + 3 computed
  ├─ Relationship: project → Project? (inverse)
  └─ Bidirectional sync with parent project
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[Add your license here]

## Acknowledgments

Built with Apple's native frameworks - SwiftUI and SwiftData. Features modern iOS 26 design patterns including glass morphism effects and SF Symbol animations.
