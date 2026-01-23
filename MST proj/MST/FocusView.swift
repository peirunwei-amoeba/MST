//
//  FocusView.swift
//  MST
//
//  Created by Claude on 1/23/26.
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Main Focus View

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    // Query all items (filter in computed properties to avoid complex predicates)
    @Query private var allAssignments: [Assignment]
    @Query private var allGoals: [Goal]
    @Query private var allHabits: [Habit]

    // Timer state
    @State private var selectedMinutes: Int = 25
    @State private var remainingSeconds: Int = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timer: Timer?

    // Stopwatch state (when timer hits 0, starts counting up)
    @State private var isStopwatchMode = false
    @State private var stopwatchSeconds: Int = 0

    // Task selection
    @State private var selectedTask: FocusTaskItem?
    @State private var showingTaskPicker = false

    // Completion state
    @State private var showCompletionOverlay = false

    // Scroll state for picker
    @State private var scrollPosition: Int? = 25

    private let maxMinutes = 99

    // Filtered data
    private var assignments: [Assignment] {
        allAssignments.filter { !$0.isCompleted }
    }

    private var goals: [Goal] {
        allGoals.filter { !$0.isCompleted }
    }

    private var habits: [Habit] {
        allHabits.filter { !$0.isTerminated }
    }

    var body: some View {
        ZStack {
            // Background color
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: isRunning)
                .animation(.easeInOut(duration: 0.3), value: isStopwatchMode)

            VStack(spacing: 0) {
                // Top bar with task picker
                HStack {
                    Spacer()
                    taskPickerButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Main display area
                mainDisplay

                Spacer()

                // Bottom time display
                bottomTimeDisplay
                    .padding(.bottom, 50)
            }

            // Completion overlay
            if showCompletionOverlay {
                completionOverlayView
                    .transition(.opacity)
            }
        }
        .onTapGesture {
            handleTap()
        }
        .sheet(isPresented: $showingTaskPicker) {
            taskPickerSheet
        }
    }

    // MARK: - Background Color

    private var backgroundColor: Color {
        if isStopwatchMode && isRunning {
            return Color(white: 0.1) // Dark background for running stopwatch
        }
        return Color(UIColor.systemBackground)
    }

    // MARK: - Task Picker Button

    private var taskPickerButton: some View {
        Button {
            if !isRunning {
                showingTaskPicker = true
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 44, height: 44)

                if let task = selectedTask {
                    Image(systemName: task.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isRunning)
        .opacity(isRunning ? 0.3 : 1)
    }

    // MARK: - Main Display

    private var mainDisplay: some View {
        Group {
            if isStopwatchMode {
                stopwatchDisplay
            } else {
                timerScrollDisplay
            }
        }
    }

    // MARK: - Timer Scroll Display

    private var timerScrollDisplay: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(1...maxMinutes, id: \.self) { minute in
                    MinuteCell(
                        minute: minute,
                        isRunning: isRunning,
                        isPaused: isPaused,
                        remainingSeconds: remainingSeconds,
                        selectedMinutes: selectedMinutes
                    )
                    .frame(height: 200)
                    .id(minute)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition)
        .disabled(isRunning)
        .onChange(of: scrollPosition) { oldValue, newValue in
            if let newMinute = newValue, !isRunning {
                selectedMinutes = newMinute
                // If we scroll while paused, clear the pause state
                if isPaused {
                    isPaused = false
                    remainingSeconds = 0
                }
                // Haptic feedback on scroll
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }
        }
        .onAppear {
            scrollPosition = selectedMinutes
        }
        .frame(height: 400)
    }

    // MARK: - Stopwatch Display

    private var stopwatchDisplay: some View {
        VStack(spacing: 20) {
            let minutes = stopwatchSeconds / 60

            if minutes >= 1 {
                // Show minutes as big number when over 1 minute
                Text("\(minutes)")
                    .font(.system(size: 180, weight: .thin, design: .rounded))
                    .foregroundStyle(isRunning ? Color.white : Color.primary.opacity(0.8))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 5, y: 8)
            } else {
                // Show plus sign when under 1 minute
                Image(systemName: "plus")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(isRunning ? Color.white.opacity(0.9) : Color.primary.opacity(0.6))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 5, y: 8)
            }
        }
        .frame(height: 400)
        .contentShape(Rectangle())
    }

    // MARK: - Bottom Time Display

    private var bottomTimeDisplay: some View {
        Group {
            if isStopwatchMode {
                // Stopwatch format: +hh:mm:ss
                let hours = stopwatchSeconds / 3600
                let minutes = (stopwatchSeconds % 3600) / 60
                let seconds = stopwatchSeconds % 60

                Text(String(format: "+%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.title2.weight(.medium).monospacedDigit())
                    .foregroundStyle(isRunning ? .white : .primary)
            } else if isRunning || isPaused {
                // Timer format: mm:ss
                let minutes = remainingSeconds / 60
                let seconds = remainingSeconds % 60

                // If remaining time > 99 minutes, show with hours
                if remainingSeconds > maxMinutes * 60 {
                    let hours = remainingSeconds / 3600
                    let mins = (remainingSeconds % 3600) / 60
                    let secs = remainingSeconds % 60
                    Text(String(format: "%d:%02d:%02d", hours, mins, secs))
                        .font(.title2.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                } else {
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.title2.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }
            } else {
                // Not running, not paused - show hint
                Text("Tap to start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func handleTap() {
        if showCompletionOverlay { return }

        if isStopwatchMode {
            // In stopwatch mode
            if isRunning {
                pauseStopwatch()
            } else {
                resumeStopwatch()
            }
        } else {
            // In timer mode
            if isRunning {
                pauseTimer()
            } else if isPaused {
                resumeTimer()
            } else {
                startTimer()
            }
        }
    }

    private func startTimer() {
        remainingSeconds = selectedMinutes * 60
        isRunning = true
        isPaused = false

        // Haptic and sound
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1104) // Tock sound

        startTimerLoop()
    }

    private func pauseTimer() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func resumeTimer() {
        isRunning = true
        isPaused = false

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        startTimerLoop()
    }

    private func startTimerLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                // Timer reached 0, switch to stopwatch mode
                switchToStopwatchMode()
            }
        }
    }

    private func switchToStopwatchMode() {
        timer?.invalidate()
        timer = nil

        isStopwatchMode = true
        stopwatchSeconds = 0
        isRunning = true
        isPaused = false

        // Haptic feedback for mode switch
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Start stopwatch
        startStopwatchLoop()
    }

    private func startStopwatchLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            stopwatchSeconds += 1
        }
    }

    private func pauseStopwatch() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func resumeStopwatch() {
        isRunning = true
        isPaused = false

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        startStopwatchLoop()
    }

    // MARK: - Task Picker Sheet

    private var taskPickerSheet: some View {
        NavigationStack {
            List {
                // Tasks with time units (prioritized)
                let timeAssignments = assignments.filter { isTimeUnit($0.targetUnit) }
                let timeGoals = goals.filter { isTimeUnit($0.targetUnit) }
                let timeHabits = habits.filter { isTimeUnit($0.unit) }

                if !timeAssignments.isEmpty || !timeGoals.isEmpty || !timeHabits.isEmpty {
                    Section("With Time Target") {
                        ForEach(timeAssignments) { assignment in
                            taskRow(
                                title: assignment.title,
                                subtitle: assignment.formattedTarget ?? "",
                                icon: "doc.text",
                                id: assignment.id,
                                targetValue: assignment.targetValue,
                                unit: assignment.targetUnit,
                                type: .assignment
                            )
                        }

                        ForEach(timeGoals) { goal in
                            taskRow(
                                title: goal.title,
                                subtitle: goal.formattedTarget ?? "",
                                icon: "flag",
                                id: goal.id,
                                targetValue: goal.targetValue,
                                unit: goal.targetUnit,
                                type: .goal
                            )
                        }

                        ForEach(timeHabits) { habit in
                            taskRow(
                                title: habit.title,
                                subtitle: habit.formattedTarget,
                                icon: "repeat",
                                id: habit.id,
                                targetValue: habit.targetValue,
                                unit: habit.unit,
                                type: .habit
                            )
                        }
                    }
                }

                // Other tasks
                let otherAssignments = assignments.filter { !isTimeUnit($0.targetUnit) }
                let otherGoals = goals.filter { !isTimeUnit($0.targetUnit) }
                let otherHabits = habits.filter { !isTimeUnit($0.unit) }

                if !otherAssignments.isEmpty || !otherGoals.isEmpty || !otherHabits.isEmpty {
                    Section("Other Tasks") {
                        ForEach(otherAssignments) { assignment in
                            taskRow(
                                title: assignment.title,
                                subtitle: assignment.formattedTarget ?? "No time set",
                                icon: "doc.text",
                                id: assignment.id,
                                targetValue: nil,
                                unit: .none,
                                type: .assignment
                            )
                        }

                        ForEach(otherGoals) { goal in
                            taskRow(
                                title: goal.title,
                                subtitle: goal.formattedTarget ?? "No time set",
                                icon: "flag",
                                id: goal.id,
                                targetValue: nil,
                                unit: .none,
                                type: .goal
                            )
                        }

                        ForEach(otherHabits) { habit in
                            taskRow(
                                title: habit.title,
                                subtitle: habit.formattedTarget,
                                icon: "repeat",
                                id: habit.id,
                                targetValue: nil,
                                unit: .none,
                                type: .habit
                            )
                        }
                    }
                }

                if assignments.isEmpty && goals.isEmpty && habits.isEmpty {
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: "checklist",
                        description: Text("Add assignments, goals, or habits to select them here.")
                    )
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingTaskPicker = false
                    }
                }

                if selectedTask != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            selectedTask = nil
                            showingTaskPicker = false
                        }
                    }
                }
            }
        }
    }

    private func taskRow(
        title: String,
        subtitle: String,
        icon: String,
        id: UUID,
        targetValue: Double?,
        unit: TargetUnit,
        type: FocusTaskType
    ) -> some View {
        Button {
            selectTask(
                id: id,
                title: title,
                icon: icon,
                targetValue: targetValue,
                unit: unit,
                type: type
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(themeManager.accentColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if selectedTask?.id == id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func selectTask(
        id: UUID,
        title: String,
        icon: String,
        targetValue: Double?,
        unit: TargetUnit,
        type: FocusTaskType
    ) {
        selectedTask = FocusTaskItem(
            id: id,
            title: title,
            icon: icon,
            targetValue: targetValue,
            unit: unit,
            type: type
        )

        // Auto-scroll to time if it's a time unit
        if let value = targetValue, isTimeUnit(unit) {
            let minutes = timeInMinutes(value: value, unit: unit)
            selectedMinutes = min(minutes, maxMinutes)
            scrollPosition = min(minutes, maxMinutes)
        }

        showingTaskPicker = false
    }

    private func isTimeUnit(_ unit: TargetUnit) -> Bool {
        unit == .hour || unit == .minute || unit == .second
    }

    private func timeInMinutes(value: Double, unit: TargetUnit) -> Int {
        switch unit {
        case .hour: return Int(value * 60)
        case .minute: return Int(value)
        case .second: return max(1, Int(value / 60))
        default: return 25
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlayView: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                ConfettiView()
                    .allowsHitTesting(false)

                Spacer()

                if let task = selectedTask {
                    Text(task.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("Time's Up!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                // Long-press checkmark
                FocusCompletionCheckmark(
                    onComplete: {
                        completeTask()
                    },
                    onDismiss: {
                        dismissCompletion()
                    }
                )

                Spacer()

                Text("Hold checkmark to complete task")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
    }

    private func completeTask() {
        if let task = selectedTask {
            switch task.type {
            case .assignment:
                if let assignment = allAssignments.first(where: { $0.id == task.id }) {
                    assignment.toggleCompletion()
                }
            case .goal:
                if let goal = allGoals.first(where: { $0.id == task.id }) {
                    goal.toggleCompletion()
                }
            case .habit:
                if let habit = allHabits.first(where: { $0.id == task.id }) {
                    habit.completeToday()
                }
            }
        }

        dismissCompletion()
    }

    private func dismissCompletion() {
        withAnimation(.easeOut(duration: 0.3)) {
            showCompletionOverlay = false
        }

        // Reset all state
        timer?.invalidate()
        timer = nil
        selectedTask = nil
        selectedMinutes = 25
        scrollPosition = 25
        remainingSeconds = 0
        isRunning = false
        isPaused = false
        isStopwatchMode = false
        stopwatchSeconds = 0
    }
}

// MARK: - Minute Cell

struct MinuteCell: View {
    let minute: Int
    let isRunning: Bool
    let isPaused: Bool
    let remainingSeconds: Int
    let selectedMinutes: Int

    private var displayMinute: Int {
        if isRunning || isPaused {
            return max(1, (remainingSeconds + 59) / 60)
        }
        return selectedMinutes
    }

    private var isCurrentMinute: Bool {
        minute == displayMinute
    }

    private var isActive: Bool {
        isRunning && isCurrentMinute
    }

    var body: some View {
        Text("\(minute)")
            .font(.system(size: 180, weight: .thin, design: .rounded))
            .foregroundStyle(foregroundStyle)
            .shadow(color: .black.opacity(isCurrentMinute ? 0.15 : 0.05), radius: 10, x: 5, y: 8)
    }

    @ViewBuilder
    private var foregroundStyle: some ShapeStyle {
        if isActive {
            LinearGradient(
                colors: [.blue, .cyan, .orange, .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isCurrentMinute {
            Color.primary.opacity(0.8)
        } else {
            Color.secondary.opacity(0.2)
        }
    }
}

// MARK: - Focus Task Item

struct FocusTaskItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let icon: String
    let targetValue: Double?
    let unit: TargetUnit
    let type: FocusTaskType

    static func == (lhs: FocusTaskItem, rhs: FocusTaskItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum FocusTaskType {
    case assignment
    case goal
    case habit
}

// MARK: - Focus Completion Checkmark

struct FocusCompletionCheckmark: View {
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var completionBounce = false
    @State private var showRipple = false
    @State private var hapticTimer: Timer?

    private let holdDuration: Double = 1.2
    private let checkmarkSize: CGFloat = 100
    private let minimumHoldToShowProgress: Double = 0.06

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: checkmarkSize + 16, height: checkmarkSize + 16)

            // Progress ring
            if holdProgress > 0 && isHolding {
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: checkmarkSize + 16, height: checkmarkSize + 16)
                    .rotationEffect(.degrees(-90))
            }

            // Ripple effect
            if showRipple {
                Circle()
                    .stroke(Color.green.opacity(0.6), lineWidth: 4)
                    .frame(width: checkmarkSize + 16, height: checkmarkSize + 16)
                    .scaleEffect(showRipple ? 1.8 : 1.0)
                    .opacity(showRipple ? 0 : 1)
            }

            // Checkmark icon
            Image(systemName: "checkmark.circle")
                .font(.system(size: checkmarkSize, weight: .medium))
                .foregroundStyle(
                    isHolding && holdProgress > 0 ?
                    Color.green.opacity(0.4 + holdProgress * 0.6) :
                    Color.white.opacity(0.8)
                )
                .scaleEffect(completionBounce ? 1.35 : (isHolding ? 1.0 + holdProgress * 0.2 : 1.0))
                .rotationEffect(.degrees(completionBounce ? 10 : (isHolding ? holdProgress * 8 : 0)))
        }
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 50) {
            completeAction()
        } onPressingChanged: { pressing in
            if pressing {
                startHolding()
            } else {
                if !completionBounce {
                    cancelHolding()
                }
            }
        }
    }

    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true

        DispatchQueue.main.asyncAfter(deadline: .now() + minimumHoldToShowProgress) {
            guard isHolding else { return }

            withAnimation(.linear(duration: holdDuration - minimumHoldToShowProgress)) {
                holdProgress = 1.0
            }

            startHapticFeedback()
        }
    }

    private func cancelHolding() {
        isHolding = false
        hapticTimer?.invalidate()
        hapticTimer = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            holdProgress = 0
        }
    }

    private func completeAction() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        isHolding = false

        withAnimation(.easeOut(duration: 0.15)) {
            holdProgress = 0
        }

        // Celebration haptic and sound
        let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        heavyFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1407)
        }

        // Bounce animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                completionBounce = true
            }

            withAnimation(.easeOut(duration: 0.6)) {
                showRipple = true
            }
        }

        // Call completion after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onComplete()
        }
    }

    private func startHapticFeedback() {
        var pulseCount = 0
        let totalPulses = 16
        let interval = (holdDuration - minimumHoldToShowProgress) / Double(totalPulses)

        let initialGenerator = UIImpactFeedbackGenerator(style: .light)
        initialGenerator.impactOccurred()

        hapticTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            guard isHolding else {
                timer.invalidate()
                return
            }

            pulseCount += 1

            let style: UIImpactFeedbackGenerator.FeedbackStyle
            let intensity: CGFloat

            if pulseCount <= 3 {
                style = .light
                intensity = 0.5 + CGFloat(pulseCount) * 0.1
            } else if pulseCount <= 7 {
                style = .medium
                intensity = 0.6 + CGFloat(pulseCount - 3) * 0.1
            } else if pulseCount <= 12 {
                style = .medium
                intensity = 0.8 + CGFloat(pulseCount - 7) * 0.04
            } else {
                style = .heavy
                intensity = 1.0
            }

            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred(intensity: intensity)

            if pulseCount >= totalPulses {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FocusView()
        .modelContainer(for: [Assignment.self, Goal.self, Habit.self], inMemory: true)
        .environmentObject(ThemeManager())
}
