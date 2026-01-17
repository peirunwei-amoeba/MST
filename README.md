# MST

An iOS homework and assignment tracking app built with SwiftUI and SwiftData.

## Overview

MST is a modern, native iOS application designed to help students manage their assignments and homework efficiently. Built entirely with Apple's latest frameworks, it features a beautiful glass-morphic UI design and seamless data persistence.

## Features

- **Smart Assignment Tracking** - Create, edit, and manage assignments with due dates, priorities, and subjects
- **Intelligent Dashboard** - Home view with compact cards showing today's and upcoming assignments
- **Advanced Filtering** - Sort by due date, priority, or subject; filter by completion status, priority level, or time period
- **Priority Management** - Four priority levels (Low, Medium, High, Urgent) with visual indicators
- **Completion Tracking** - Mark assignments as complete with haptic feedback and smooth animations
- **Customizable Themes** - System, light, or dark mode with customizable accent colors
- **Search Functionality** - Quickly find assignments by title or description
- **Swipe Actions** - Quick access to edit, delete, and complete actions

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
├── MSTApp.swift          # App entry point
├── ContentView.swift     # Tab-based navigation
├── Assignment.swift      # SwiftData model
├── ThemeManager.swift    # Theme and appearance management
├── HomeView.swift        # Dashboard with glass-effect cards
├── AssignmentListView.swift  # Full assignment list with filters
└── ...
```

### Key Components

- **Assignment Model** - SwiftData model with computed properties for due date logic
- **Theme Manager** - Observable class managing app appearance with persistence
- **Home View** - iOS 26 concentric glass-effect design with animated completions
- **Assignment List** - Comprehensive list with 5 sorting and 5 filtering options

## Usage

### Creating an Assignment

1. Tap the "+" button in the navigation bar
2. Enter assignment details (title, description, due date, priority, subject)
3. Save to add to your assignment list

### Managing Assignments

- **Mark Complete** - Tap the checkbox or swipe right
- **Edit** - Tap on an assignment card or use swipe actions
- **Delete** - Swipe left and tap delete
- **Filter** - Use the filter menu to view specific subsets
- **Sort** - Choose from multiple sorting options

### Customizing Appearance

1. Navigate to the Settings tab
2. Choose your preferred theme (System, Light, or Dark)
3. Select an accent color from the available options

## Development

### Data Flow

- `@Query` decorator for reactive SwiftData fetching
- `@Environment(\.modelContext)` for CRUD operations
- `@Bindable` for direct model property binding
- Closure callbacks for parent-child communication

### UI Patterns

- Glass morphism with `.ultraThinMaterial` and `.regularMaterial`
- SF Symbol animations with `.contentTransition(.symbolEffect(...))`
- Haptic feedback on interactions
- System sounds for confirmations
- Delayed animations for state transitions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[Add your license here]

## Acknowledgments

Built with Apple's native frameworks - SwiftUI and SwiftData
