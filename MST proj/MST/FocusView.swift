//
//  FocusView.swift
//  MST
//
//  Created by Claude on 1/23/26.
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Focus Task Type

enum FocusTaskType: String, CaseIterable {
    case assignment = "Assignment"
    case goal = "Goal"
    case habit = "Habit"

    var systemImage: String {
        switch self {
        case .assignment: return "doc.text"
        case .goal: return "flag"
        case .habit: return "repeat"
        }
    }
}

// MARK: - Focus Task (wrapper for selected task)

struct FocusTask: Identifiable, Equatable {
    let id: UUID
    let title: String
    let type: FocusTaskType
    let targetValue: Double?
    let unit: TargetUnit

    var isTimeUnit: Bool {
        unit == .hour || unit == .minute || unit == .second
    }

    var timeInMinutes: Int? {
        guard let value = targetValue, isTimeUnit else { return nil }
        switch unit {
        case .hour: return Int(value * 60)
        case .minute: return Int(value)
        case .second: return max(1, Int(value / 60))
        default: return nil
        }
    }

    static func == (lhs: FocusTask, rhs: FocusTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Main Focus View

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(filter: #Predicate<Assignment> { !$0.isCompleted }) private var assignments: [Assignment]
    @Query(filter: #Predicate<Goal> { !$0.isCompleted }) private var goals: [Goal]
    @Query(filter: #Predicate<Habit> { !$0.isTerminated }) private var habits: [Habit]

    // Timer state
    @State private var selectedMinutes: Int = 25
    @State private var remainingSeconds: Int = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timer: Timer?

    // Stopwatch state
    @State private var isStopwatchMode = false
    @State private var stopwatchSeconds: Int = 0

    // Task selection
    @State private var selectedTask: FocusTask?
    @State private var showingTaskPicker = false

    // Completion state
    @State private var showCompletionOverlay = false

    // Drag state for scroll picker
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0

    private let maxMinutes = 99
    private let minuteHeight: CGFloat = 80

    var body: some View {
        ZStack {
            // Background
            (isRunning ? Color.black : themeManager.backgroundColor)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: isRunning)

            VStack(spacing: 0) {
                // Task picker button
                taskPickerButton
                    .padding(.top, 60)

                Spacer()

                // Main timer display
                if isStopwatchMode {
                    stopwatchDisplay
                } else {
                    timerDisplay
                }

                Spacer()

                // Bottom exact time display
                exactTimeDisplay
                    .padding(.bottom, 40)
            }

            // Completion overlay
            if showCompletionOverlay {
                completionOverlay
            }
        }
        .onTapGesture {
            handleTap()
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerSheet(
                assignments: assignments,
                goals: goals,
                habits: habits,
                selectedTask: $selectedTask,
                onSelect: { task in
                    selectedTask = task
                    if let minutes = task.timeInMinutes {
                        selectedMinutes = min(minutes, maxMinutes)
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Task Picker Button

    private var taskPickerButton: some View {
        Button {
            showingTaskPicker = true
        } label: {
            HStack(spacing: 8) {
                if let task = selectedTask {
                    Image(systemName: task.type.systemImage)
                        .font(.subheadline)
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Select Task")
                        .font(.subheadline.weight(.medium))
                }

                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(isRunning ? .white.opacity(0.8) : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .disabled(isRunning)
        .opacity(isRunning ? 0.5 : 1)
    }

    // MARK: - Timer Display (Scroll Picker)

    private var timerDisplay: some View {
        GeometryReader { geometry in
            let centerY = geometry.size.height / 2

            ZStack {
                // Minutes scroll
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(1...maxMinutes, id: \.self) { minute in
                            Text("\(minute)")
                                .font(.system(size: 120, weight: .ultraLight, design: .rounded))
                                .foregroundStyle(displayMinute == minute ?
                                    (isRunning ? .white : themeManager.accentColor) :
                                    .secondary.opacity(0.3))
                                .frame(height: minuteHeight)
                                .id(minute)
                        }
                    }
                    .padding(.vertical, centerY - minuteHeight / 2)
                }
                .scrollTargetLayout()
                .scrollPosition(id: Binding(
                    get: { displayMinute },
                    set: { if let val = $0 { selectedMinutes = val } }
                ))
                .scrollTargetBehavior(.viewAligned)
                .disabled(isRunning)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in
                            if !isRunning {
                                // Haptic on scroll
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }
                        }
                )
            }
        }
        .frame(height: 300)
    }

    // Display minute (either selected or remaining)
    private var displayMinute: Int {
        if isRunning || isPaused {
            return min(max(1, (remainingSeconds + 59) / 60), maxMinutes)
        }
        return selectedMinutes
    }

    // MARK: - Stopwatch Display

    private var stopwatchDisplay: some View {
        VStack(spacing: 20) {
            // Big time display
            Text(formatStopwatchTime(stopwatchSeconds))
                .font(.system(size: 80, weight: .ultraLight, design: .rounded))
                .foregroundStyle(isRunning ? .white : themeManager.accentColor)
                .monospacedDigit()

            // Plus 5 minutes button
            Button {
                addFiveMinutes()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("5 min")
                }
                .font(.headline)
                .foregroundStyle(isRunning ? .white : themeManager.accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .frame(height: 300)
    }

    // MARK: - Exact Time Display

    private var exactTimeDisplay: some View {
        VStack(spacing: 4) {
            if isRunning || isPaused {
                if isStopwatchMode {
                    Text("Stopwatch Mode")
                        .font(.caption)
                        .foregroundStyle(isRunning ? .white.opacity(0.6) : .secondary)
                } else {
                    // Show exact remaining time
                    let hours = remainingSeconds / 3600
                    let minutes = (remainingSeconds % 3600) / 60
                    let seconds = remainingSeconds % 60

                    if hours > 0 {
                        Text(String(format: "%d:%02d:%02d", hours, minutes, seconds))
                            .font(.title3.weight(.medium).monospacedDigit())
                            .foregroundStyle(isRunning ? .white.opacity(0.8) : .secondary)
                    } else {
                        Text(String(format: "%02d:%02d", minutes, seconds))
                            .font(.title3.weight(.medium).monospacedDigit())
                            .foregroundStyle(isRunning ? .white.opacity(0.8) : .secondary)
                    }
                }
            } else {
                Text("Tap to start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if isPaused {
                Text("Paused - Tap to resume")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Confetti
                ConfettiView()
                    .allowsHitTesting(false)

                Spacer()

                // Task completed message
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

                // Completion checkmark (long-press to complete)
                CompletionCheckmark(
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
        .transition(.opacity)
    }

    // MARK: - Actions

    private func handleTap() {
        if showCompletionOverlay { return }

        if isStopwatchMode {
            if isRunning {
                pauseStopwatch()
            } else {
                startStopwatch()
            }
        } else {
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

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1

                // Check if we've gone below 1 minute - switch to stopwatch mode
                if remainingSeconds <= 0 {
                    timerCompleted()
                }
            }
        }
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

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1

                if remainingSeconds <= 0 {
                    timerCompleted()
                }
            }
        }
    }

    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false

        // Play completion sound and haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1407)

        withAnimation(.easeOut(duration: 0.3)) {
            showCompletionOverlay = true
        }
    }

    private func startStopwatch() {
        isRunning = true
        isPaused = false

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

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

    private func addFiveMinutes() {
        // Convert to timer mode with 5 minutes
        isStopwatchMode = false
        selectedMinutes = 5
        stopwatchSeconds = 0

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func completeTask() {
        // Mark the selected task as complete if applicable
        if let task = selectedTask {
            switch task.type {
            case .assignment:
                if let assignment = assignments.first(where: { $0.id == task.id }) {
                    assignment.toggleCompletion()
                }
            case .goal:
                if let goal = goals.first(where: { $0.id == task.id }) {
                    goal.toggleCompletion()
                }
            case .habit:
                if let habit = habits.first(where: { $0.id == task.id }) {
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

        // Reset state
        selectedTask = nil
        selectedMinutes = 25
        remainingSeconds = 0
        isStopwatchMode = false
        stopwatchSeconds = 0
    }

    private func formatStopwatchTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Task Picker Sheet

struct TaskPickerSheet: View {
    let assignments: [Assignment]
    let goals: [Goal]
    let habits: [Habit]
    @Binding var selectedTask: FocusTask?
    let onSelect: (FocusTask) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            List {
                // Assignments with time units
                if !timeAssignments.isEmpty {
                    Section("Assignments") {
                        ForEach(timeAssignments) { assignment in
                            TaskRow(
                                title: assignment.title,
                                subtitle: assignment.formattedTarget ?? "",
                                icon: "doc.text",
                                isSelected: selectedTask?.id == assignment.id
                            ) {
                                let task = FocusTask(
                                    id: assignment.id,
                                    title: assignment.title,
                                    type: .assignment,
                                    targetValue: assignment.targetValue,
                                    unit: assignment.targetUnit
                                )
                                onSelect(task)
                                dismiss()
                            }
                        }
                    }
                }

                // Goals with time units
                if !timeGoals.isEmpty {
                    Section("Goals") {
                        ForEach(timeGoals) { goal in
                            TaskRow(
                                title: goal.title,
                                subtitle: goal.formattedTarget ?? "",
                                icon: "flag",
                                isSelected: selectedTask?.id == goal.id
                            ) {
                                let task = FocusTask(
                                    id: goal.id,
                                    title: goal.title,
                                    type: .goal,
                                    targetValue: goal.targetValue,
                                    unit: goal.targetUnit
                                )
                                onSelect(task)
                                dismiss()
                            }
                        }
                    }
                }

                // Habits with time units
                if !timeHabits.isEmpty {
                    Section("Habits") {
                        ForEach(timeHabits) { habit in
                            TaskRow(
                                title: habit.title,
                                subtitle: habit.formattedTarget,
                                icon: "repeat",
                                isSelected: selectedTask?.id == habit.id
                            ) {
                                let task = FocusTask(
                                    id: habit.id,
                                    title: habit.title,
                                    type: .habit,
                                    targetValue: habit.targetValue,
                                    unit: habit.unit
                                )
                                onSelect(task)
                                dismiss()
                            }
                        }
                    }
                }

                // Other tasks (non-time units)
                Section("Other Tasks") {
                    ForEach(otherAssignments) { assignment in
                        TaskRow(
                            title: assignment.title,
                            subtitle: assignment.formattedTarget ?? "No time set",
                            icon: "doc.text",
                            isSelected: selectedTask?.id == assignment.id
                        ) {
                            let task = FocusTask(
                                id: assignment.id,
                                title: assignment.title,
                                type: .assignment,
                                targetValue: nil,
                                unit: .none
                            )
                            onSelect(task)
                            dismiss()
                        }
                    }

                    ForEach(otherGoals) { goal in
                        TaskRow(
                            title: goal.title,
                            subtitle: goal.formattedTarget ?? "No time set",
                            icon: "flag",
                            isSelected: selectedTask?.id == goal.id
                        ) {
                            let task = FocusTask(
                                id: goal.id,
                                title: goal.title,
                                type: .goal,
                                targetValue: nil,
                                unit: .none
                            )
                            onSelect(task)
                            dismiss()
                        }
                    }

                    ForEach(otherHabits) { habit in
                        TaskRow(
                            title: habit.title,
                            subtitle: habit.formattedTarget,
                            icon: "repeat",
                            isSelected: selectedTask?.id == habit.id
                        ) {
                            let task = FocusTask(
                                id: habit.id,
                                title: habit.title,
                                type: .habit,
                                targetValue: nil,
                                unit: .none
                            )
                            onSelect(task)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // Filter tasks with time units
    private var timeAssignments: [Assignment] {
        assignments.filter { isTimeUnit($0.targetUnit) }
    }

    private var timeGoals: [Goal] {
        goals.filter { isTimeUnit($0.targetUnit) }
    }

    private var timeHabits: [Habit] {
        habits.filter { isTimeUnit($0.unit) }
    }

    private var otherAssignments: [Assignment] {
        assignments.filter { !isTimeUnit($0.targetUnit) }
    }

    private var otherGoals: [Goal] {
        goals.filter { !isTimeUnit($0.targetUnit) }
    }

    private var otherHabits: [Habit] {
        habits.filter { !isTimeUnit($0.unit) }
    }

    private func isTimeUnit(_ unit: TargetUnit) -> Bool {
        unit == .hour || unit == .minute || unit == .second
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
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

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completion Checkmark (Long-press animated)

struct CompletionCheckmark: View {
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

            // Checkmark
            Image(systemName: "checkmark.circle")
                .font(.system(size: checkmarkSize, weight: .medium))
                .foregroundStyle(isHolding && holdProgress > 0 ? .green.opacity(0.4 + holdProgress * 0.6) : .white.opacity(0.8))
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
