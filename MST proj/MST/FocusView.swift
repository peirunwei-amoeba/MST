//
//  FocusView.swift
//  MST
//
//  Created by Claude on 1/24/26.
//

import SwiftUI
import SwiftData
import AVFoundation
import UIKit

// MARK: - Enums

enum FocusMode {
    case countdown
    case stopwatch
}

enum FocusState: Equatable {
    case idle
    case selected
    case running(FocusMode)
    case paused(FocusMode)
    case completed
}

enum FocusableTask: Identifiable, Equatable {
    case assignment(Assignment)
    case goal(Goal)
    case habit(Habit)

    var id: UUID {
        switch self {
        case .assignment(let a): return a.id
        case .goal(let g): return g.id
        case .habit(let h): return h.id
        }
    }

    var title: String {
        switch self {
        case .assignment(let a): return a.title
        case .goal(let g): return g.title
        case .habit(let h): return h.title
        }
    }

    var iconName: String {
        switch self {
        case .assignment: return "book.fill"
        case .goal: return "flag.fill"
        case .habit: return "flame.fill"
        }
    }

    var isTimeBased: Bool {
        switch self {
        case .assignment(let a): return a.targetUnit.category == .time
        case .goal(let g): return g.targetUnit.category == .time
        case .habit(let h): return h.unit.category == .time
        }
    }

    var timeTargetMinutes: Int? {
        switch self {
        case .assignment(let a):
            guard let value = a.targetValue else { return nil }
            return a.targetUnit.toMinutes(value)
        case .goal(let g):
            guard let value = g.targetValue else { return nil }
            return g.targetUnit.toMinutes(value)
        case .habit(let h):
            return h.unit.toMinutes(h.targetValue)
        }
    }

    var formattedTarget: String? {
        switch self {
        case .assignment(let a): return a.formattedTarget
        case .goal(let g): return g.formattedTarget
        case .habit(let h): return h.formattedTarget
        }
    }

    static func == (lhs: FocusableTask, rhs: FocusableTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Haptic Manager

struct FocusHaptics {
    static func scrollSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    static func timerStart() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)
        AudioServicesPlaySystemSound(1104)
    }

    static func timerPause() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func timerComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1407)
    }

    static func confirmCompletion() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1407)
        }
    }

    static func taskSelected() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }
}

// MARK: - Main Focus View

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(filter: #Predicate<Assignment> { !$0.isCompleted }, sort: \Assignment.dueDate)
    private var assignments: [Assignment]

    @Query(filter: #Predicate<Goal> { !$0.isCompleted }, sort: \Goal.targetDate)
    private var goals: [Goal]

    @Query(sort: \Habit.createdDate)
    private var habits: [Habit]

    // Timer state
    @State private var focusState: FocusState = .idle
    @State private var selectedMinutes: Int = 1
    @State private var remainingSeconds: Int = 60
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    // Task selection
    @State private var selectedTask: FocusableTask?
    @State private var showingTaskDropdown = false
    @State private var actualTargetMinutes: Int? // For tasks > 99 min

    // Completion overlay
    @State private var showCompletionOverlay = false

    // Scroll tracking
    @State private var scrollPosition: Int? = 1
    @State private var lastScrollPosition: Int = 1

    private let maxMinutes = 99

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                (isStopwatchRunning ? Color.black.opacity(0.95) : Color(.systemBackground))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: isStopwatchRunning)

                // Main scrollable timer
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // 99 at top, 1 at bottom, then stopwatch (0)
                        ForEach((0...maxMinutes).reversed(), id: \.self) { number in
                            Timer3DNumberView(
                                number: number,
                                displayValue: displayValueFor(number),
                                isRunning: isTimerRunning,
                                isStopwatch: number == 0,
                                geometry: geometry
                            )
                            .id(number)
                            .frame(height: geometry.size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)
                .ignoresSafeArea()
                .onChange(of: scrollPosition) { oldValue, newValue in
                    handleScrollChange(from: oldValue, to: newValue)
                }
                .onTapGesture {
                    handleTap()
                }

                // Task dropdown (top)
                VStack {
                    FocusTaskDropdown(
                        selectedTask: $selectedTask,
                        showingDropdown: $showingTaskDropdown,
                        assignments: assignments,
                        goals: goals,
                        habits: todayIncompleteHabits,
                        onTaskSelected: handleTaskSelection
                    )
                    .padding(.top, 60)
                    .padding(.horizontal, 20)

                    Spacer()
                }

                // Time display capsule (bottom)
                VStack {
                    Spacer()

                    if shouldShowTimeCapsule {
                        FocusTimeDisplayCapsule(
                            isStopwatch: isStopwatchMode,
                            seconds: isStopwatchMode ? elapsedSeconds : remainingSeconds,
                            showHours: actualTargetMinutes != nil && actualTargetMinutes! > 99
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 50)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shouldShowTimeCapsule)

                // Completion overlay
                if showCompletionOverlay {
                    FocusCompletionOverlay(
                        task: selectedTask,
                        onConfirm: handleCompletionConfirm,
                        onDismiss: resetToIdle
                    )
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isTimerRunning: Bool {
        if case .running = focusState { return true }
        return false
    }

    private var isStopwatchMode: Bool {
        scrollPosition == 0 || selectedMinutes == 0
    }

    private var isStopwatchRunning: Bool {
        if case .running(.stopwatch) = focusState { return true }
        return false
    }

    private var shouldShowTimeCapsule: Bool {
        switch focusState {
        case .running, .paused:
            return true
        default:
            return false
        }
    }

    private var todayIncompleteHabits: [Habit] {
        habits.filter { !$0.isCompletedToday }
    }

    // MARK: - Display Logic

    private func displayValueFor(_ number: Int) -> String {
        // Stopwatch mode
        if number == 0 {
            if case .running(.stopwatch) = focusState {
                if elapsedSeconds < 60 {
                    return "\(elapsedSeconds)"
                } else {
                    return "\(elapsedSeconds / 60)"
                }
            }
            return "+"
        }

        // Countdown mode - show selected minutes or current countdown minute
        if isTimerRunning && selectedMinutes == number {
            // Show actual remaining minutes during countdown
            let remainingMins = (remainingSeconds + 59) / 60
            return "\(max(1, remainingMins))"
        }

        return "\(number)"
    }

    // MARK: - Scroll Handling

    private func handleScrollChange(from oldValue: Int?, to newValue: Int?) {
        guard let newValue = newValue else { return }

        // If paused and user scrolls to new position, clear paused state
        if case .paused = focusState {
            if newValue != lastScrollPosition {
                // User scrolled to new time, reset
                timer?.invalidate()
                timer = nil
                focusState = .idle
                actualTargetMinutes = nil
            }
        }

        if newValue != lastScrollPosition {
            FocusHaptics.scrollSelection()
            lastScrollPosition = newValue
            selectedMinutes = newValue

            // Update remaining seconds for new selection (only if not running)
            if case .idle = focusState {
                remainingSeconds = newValue * 60
            } else if case .selected = focusState {
                remainingSeconds = newValue * 60
            }

            focusState = .selected
        }
    }

    // MARK: - Tap Handling

    private func handleTap() {
        // Don't handle taps if dropdown is open
        guard !showingTaskDropdown else { return }

        switch focusState {
        case .idle, .selected:
            startTimer()

        case .running(let mode):
            pauseTimer(mode: mode)

        case .paused(let mode):
            resumeTimer(mode: mode)

        case .completed:
            break
        }
    }

    // MARK: - Timer Control

    private func startTimer() {
        let mode: FocusMode = selectedMinutes == 0 ? .stopwatch : .countdown

        if mode == .countdown {
            remainingSeconds = selectedMinutes * 60
            // If we have an actual target > 99, use that instead
            if let actual = actualTargetMinutes, actual > maxMinutes {
                remainingSeconds = actual * 60
            }
        } else {
            elapsedSeconds = 0
        }

        focusState = .running(mode)
        FocusHaptics.timerStart()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timerTick(mode: mode)
        }
    }

    private func pauseTimer(mode: FocusMode) {
        timer?.invalidate()
        timer = nil
        focusState = .paused(mode)
        FocusHaptics.timerPause()
    }

    private func resumeTimer(mode: FocusMode) {
        focusState = .running(mode)
        FocusHaptics.timerStart()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timerTick(mode: mode)
        }
    }

    private func timerTick(mode: FocusMode) {
        if mode == .countdown {
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                // Timer complete
                timer?.invalidate()
                timer = nil
                focusState = .completed
                FocusHaptics.timerComplete()

                if selectedTask != nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showCompletionOverlay = true
                    }
                } else {
                    // No task selected, just reset after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        resetToIdle()
                    }
                }
            }
        } else {
            // Stopwatch
            elapsedSeconds += 1
        }
    }

    // MARK: - Task Selection

    private func handleTaskSelection(_ task: FocusableTask) {
        selectedTask = task
        showingTaskDropdown = false
        FocusHaptics.taskSelected()

        // Auto-scroll if time-based
        if task.isTimeBased, let minutes = task.timeTargetMinutes {
            if minutes > maxMinutes {
                // Task time exceeds max, show 99 but track actual
                actualTargetMinutes = minutes
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scrollPosition = maxMinutes
                    selectedMinutes = maxMinutes
                }
                remainingSeconds = minutes * 60
            } else {
                actualTargetMinutes = nil
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scrollPosition = minutes
                    selectedMinutes = minutes
                }
                remainingSeconds = minutes * 60
            }
            focusState = .selected
        }
        // If not time-based, don't auto-scroll - let user pick
    }

    // MARK: - Completion

    private func handleCompletionConfirm() {
        FocusHaptics.confirmCompletion()

        // Mark task as completed
        if let task = selectedTask {
            switch task {
            case .assignment(let assignment):
                assignment.isCompleted = true
                assignment.completedDate = Date()
            case .goal(let goal):
                goal.toggleCompletion()
            case .habit(let habit):
                habit.completeToday()
            }
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showCompletionOverlay = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            resetToIdle()
        }
    }

    private func resetToIdle() {
        timer?.invalidate()
        timer = nil
        focusState = .idle
        selectedTask = nil
        actualTargetMinutes = nil
        elapsedSeconds = 0
        showCompletionOverlay = false

        // Reset to position 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            scrollPosition = 1
            selectedMinutes = 1
            remainingSeconds = 60
        }
    }
}

// MARK: - 3D Number View

struct Timer3DNumberView: View {
    let number: Int
    let displayValue: String
    let isRunning: Bool
    let isStopwatch: Bool
    let geometry: GeometryProxy

    private var fontSize: CGFloat {
        min(geometry.size.width * 0.7, geometry.size.height * 0.55)
    }

    var body: some View {
        ZStack {
            // Layer 1: Deep shadow
            Text(displayValue)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.25))
                .offset(x: 12, y: 12)
                .blur(radius: 8)

            // Layer 2: Mid shadow
            Text(displayValue)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.15))
                .offset(x: 6, y: 6)
                .blur(radius: 2)

            // Layer 3: Main text with gradient
            Text(displayValue)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(mainGradient)

            // Layer 4: Prismatic highlight
            Text(displayValue)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(prismaticGradient)
                .mask(
                    LinearGradient(
                        colors: [.white.opacity(0.9), .clear, .white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Layer 5: Top bevel highlight
            Text(displayValue)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(isRunning ? 0.15 : 0.5))
                .offset(x: -2, y: -2)
                .mask(
                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: isRunning)
    }

    private var mainGradient: AnyShapeStyle {
        if isRunning {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.3, blue: 0.6),
                        Color(red: 0.6, green: 0.3, blue: 0.2),
                        Color(red: 0.8, green: 0.4, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        .white.opacity(0.95),
                        Color(white: 0.85),
                        Color(white: 0.75)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var prismaticGradient: LinearGradient {
        LinearGradient(
            colors: [
                .red.opacity(0.2),
                .orange.opacity(0.2),
                .yellow.opacity(0.2),
                .green.opacity(0.2),
                .cyan.opacity(0.2),
                .blue.opacity(0.2),
                .purple.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Task Dropdown

struct FocusTaskDropdown: View {
    @Binding var selectedTask: FocusableTask?
    @Binding var showingDropdown: Bool
    let assignments: [Assignment]
    let goals: [Goal]
    let habits: [Habit]
    let onTaskSelected: (FocusableTask) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingDropdown.toggle()
                }
                if showingDropdown {
                    FocusHaptics.scrollSelection()
                }
            } label: {
                HStack(spacing: 10) {
                    if let task = selectedTask {
                        Image(systemName: task.iconName)
                            .foregroundStyle(.secondary)
                        Text(task.title)
                            .lineLimit(1)
                    } else {
                        Image(systemName: "target")
                            .foregroundStyle(.secondary)
                        Text("Select Task")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showingDropdown ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            // Expandable content
            if showingDropdown {
                Divider()
                    .padding(.horizontal, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Assignments section
                        if !assignments.isEmpty {
                            taskSection(
                                title: "Assignments",
                                icon: "book.fill",
                                tasks: assignments.map { FocusableTask.assignment($0) }
                            )
                        }

                        // Goals section
                        if !goals.isEmpty {
                            taskSection(
                                title: "Goals",
                                icon: "flag.fill",
                                tasks: goals.map { FocusableTask.goal($0) }
                            )
                        }

                        // Habits section
                        if !habits.isEmpty {
                            taskSection(
                                title: "Habits",
                                icon: "flame.fill",
                                tasks: habits.map { FocusableTask.habit($0) }
                            )
                        }

                        if assignments.isEmpty && goals.isEmpty && habits.isEmpty {
                            Text("No tasks available")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 280)
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func taskSection(title: String, icon: String, tasks: [FocusableTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)

            ForEach(tasks) { task in
                Button {
                    onTaskSelected(task)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)

                            if let target = task.formattedTarget {
                                Text(target)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if task.isTimeBased {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Time Display Capsule

struct FocusTimeDisplayCapsule: View {
    let isStopwatch: Bool
    let seconds: Int
    let showHours: Bool

    private var formattedTime: String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60

        if isStopwatch {
            if hours > 0 {
                return String(format: "+%d:%02d:%02d", hours, mins, secs)
            } else {
                return String(format: "+%02d:%02d", mins, secs)
            }
        } else {
            if hours > 0 || showHours {
                return String(format: "%d:%02d:%02d", hours, mins, secs)
            } else {
                return String(format: "%02d:%02d", mins, secs)
            }
        }
    }

    var body: some View {
        Text(formattedTime)
            .font(.system(.title3, design: .monospaced).weight(.semibold))
            .foregroundStyle(isStopwatch ? .white : .primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Completion Overlay

struct FocusCompletionOverlay: View {
    let task: FocusableTask?
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    @State private var checkmarkScale: CGFloat = 0.3
    @State private var checkmarkOpacity: Double = 0
    @State private var showGlow = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss without completing
                    onDismiss()
                }

            VStack(spacing: 32) {
                Spacer()

                // Giant checkmark button
                Button {
                    onConfirm()
                } label: {
                    ZStack {
                        // Glow effect
                        if showGlow {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 220, height: 220)
                                .blur(radius: 50)
                        }

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 160))
                            .foregroundStyle(.green)
                            .shadow(color: .green.opacity(0.5), radius: 30)
                    }
                }
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)

                if let task = task {
                    VStack(spacing: 8) {
                        Text("Complete")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("\"\(task.title)\"")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 40)
                }

                Text("Tap checkmark to confirm")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                showGlow = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FocusView()
        .modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitEntry.self], inMemory: true)
        .environmentObject(ThemeManager())
}
