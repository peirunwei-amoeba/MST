//
//  FocusView.swift
//  MST
//
//  Copyright © 2025 Pei Runwei. All rights reserved.
//
//  This Source Code Form is subject to the terms of the PolyForm Strict
//  License 1.0.0. You may not use, modify, or distribute this file except
//  in compliance with the License. A copy of the License is located at:
//  https://polyformproject.org/licenses/strict/1.0.0
//
//  Required Notice: Copyright Pei Runwei (https://github.com/peirunwei-amoeba)
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Glass Button Style (for Focus tab controls)

struct FocusGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - FocusTask Enum

enum FocusTask: Identifiable, Equatable {
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

    var targetValue: Double? {
        switch self {
        case .assignment(let a): return a.targetValue
        case .goal(let g): return g.targetValue
        case .habit(let h): return h.targetValue
        }
    }

    var targetUnit: TargetUnit {
        switch self {
        case .assignment(let a): return a.targetUnit
        case .goal(let g): return g.targetUnit
        case .habit(let h): return h.unit
        }
    }

    var isTimeBasedUnit: Bool {
        targetUnit.category == .time
    }

    var durationInMinutes: Int? {
        guard let value = targetValue, isTimeBasedUnit else { return nil }
        switch targetUnit {
        case .hour: return Int(value * 60)
        case .minute: return Int(value)
        case .second: return max(1, Int(value / 60))
        default: return nil
        }
    }

    var icon: String {
        switch self {
        case .assignment: return "book.fill"
        case .goal: return "flag.fill"
        case .habit: return "flame.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .assignment: return .blue
        case .goal: return .purple
        case .habit: return .orange
        }
    }

    static func == (lhs: FocusTask, rhs: FocusTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - FocusView

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(FocusTimerManager.self) private var timerManager

    // Data queries
    @Query(filter: #Predicate<Assignment> { !$0.isCompleted })
    private var incompleteAssignments: [Assignment]

    @Query(filter: #Predicate<Goal> { !$0.isCompleted })
    private var incompleteGoals: [Goal]

    @Query(filter: #Predicate<Habit> { !$0.isTerminated })
    private var activeHabits: [Habit]

    // Timer state
    @State private var selectedMinutes: Int = 25
    @State private var selectedHours: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var timer: Timer?
    @State private var timerEndTime: Date?  // Track when timer should end (for background support)

    // Scene phase for background handling
    @Environment(\.scenePhase) private var scenePhase

    // Task state
    @State private var selectedTask: FocusTask?
    @State private var showTaskPicker: Bool = false
    @State private var exactTimeMinutes: Int = 0

    // Completion state
    @State private var showCompletionOverlay: Bool = false

    // Computed properties
    private var totalSelectedMinutes: Int {
        selectedHours * 60 + selectedMinutes
    }

    private var isOverMaxTime: Bool {
        exactTimeMinutes > 239
    }

    private var displayTime: String {
        if isOverMaxTime && !isRunning {
            let hours = exactTimeMinutes / 60
            let mins = exactTimeMinutes % 60
            return "\(hours):\(String(format: "%02d", mins))"
        } else if isRunning || isPaused {
            let hours = remainingSeconds / 3600
            let mins = (remainingSeconds % 3600) / 60
            let secs = remainingSeconds % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, mins, secs)
            } else {
                return String(format: "%d:%02d", mins, secs)
            }
        } else {
            if selectedHours > 0 {
                return "\(selectedHours):\(String(format: "%02d", selectedMinutes))"
            } else {
                return "\(selectedMinutes)"
            }
        }
    }

    private var timeLabel: String {
        if isOverMaxTime && !isRunning {
            return "HOURS"
        } else if isRunning || isPaused {
            return ""
        } else if selectedHours > 0 {
            return "HOURS"
        } else {
            return "MINS"
        }
    }

    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Task picker button at top
                taskPickerButton
                    .padding(.top, 16)

                Spacer()

                // Dual ring timer with time display inside
                DualRingTimerView(
                    selectedMinutes: $selectedMinutes,
                    selectedHours: $selectedHours,
                    isRunning: isRunning,
                    isPaused: isPaused,
                    remainingSeconds: remainingSeconds,
                    accentColor: themeManager.accentColor,
                    displayTime: displayTime,
                    timeLabel: timeLabel
                )
                .frame(width: 320, height: 320)
                .disabled(isRunning && !isPaused)

                Spacer()

                // Control buttons
                controlButtons
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)


            // Completion overlay
            if showCompletionOverlay {
                FocusCompletionOverlay(
                    taskTitle: selectedTask?.title,
                    hasTask: selectedTask != nil,
                    alarmSound: themeManager.timerAlarmSound,
                    onComplete: {
                        markTaskComplete()
                    },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCompletionOverlay = false
                        }
                        resetTimer()
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showTaskPicker) {
            FocusTaskPickerView(
                selectedTask: $selectedTask,
                assignments: incompleteAssignments,
                goals: incompleteGoals,
                habits: activeHabits.filter { !$0.isCompletedToday },
                onSelect: { task in
                    selectTask(task)
                }
            )
        }
        .animation(.easeInOut(duration: 0.4), value: showCompletionOverlay)
        .onChange(of: isRunning) { _, _ in
            updateIdleTimerState()
        }
        .onChange(of: isPaused) { _, _ in
            updateIdleTimerState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onDisappear {
            // Re-enable idle timer when leaving the view
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Background Timer Support

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App returned to foreground - recalculate timer if running
            if isRunning, let endTime = timerEndTime {
                let now = Date()
                if now >= endTime {
                    // Timer should have completed in background
                    remainingSeconds = 0
                    timerCompleted()
                } else {
                    // Update remaining time based on end time
                    let remaining = Int(endTime.timeIntervalSince(now))
                    remainingSeconds = max(0, remaining)
                    timerManager.remainingSeconds = remainingSeconds

                    // Update the ring positions
                    let totalMins = remainingSeconds / 60
                    selectedHours = totalMins / 60
                    selectedMinutes = totalMins % 60

                    // Restart the timer
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        if remainingSeconds > 0 {
                            remainingSeconds -= 1
                            timerManager.remainingSeconds = remainingSeconds
                            let totalMins = remainingSeconds / 60
                            let newHours = totalMins / 60
                            let newMins = totalMins % 60
                            if newHours != selectedHours || newMins != selectedMinutes {
                                withAnimation(.linear(duration: 0.5)) {
                                    selectedHours = newHours
                                    selectedMinutes = newMins
                                }
                            }
                        } else {
                            timerCompleted()
                        }
                    }
                }
            }
        case .background:
            // App going to background - timer will stop but we have timerEndTime saved
            timer?.invalidate()
            timer = nil
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Idle Timer Management

    private func updateIdleTimerState() {
        let shouldDisableIdleTimer = themeManager.keepScreenOnDuringFocus && (isRunning || isPaused)
        UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
    }

    // MARK: - Task Picker Button

    private var taskPickerButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showTaskPicker.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                if let task = selectedTask {
                    Image(systemName: task.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(task.iconColor)

                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.accentColor)

                    Text("Add Task")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(showTaskPicker ? 180 : 0))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .glassEffect(.regular.interactive())
            .clipShape(Capsule())
        }
        .buttonStyle(FocusGlassButtonStyle())
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 20) {
            if isRunning || isPaused {
                // Reset button
                Button {
                    resetTimer()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                        .glassEffect(.regular.interactive())
                        .clipShape(Circle())
                }
                .buttonStyle(FocusGlassButtonStyle())
            }

            // Main start/pause button
            Button {
                if isRunning {
                    pauseTimer()
                } else if isPaused {
                    resumeTimer()
                } else {
                    startTimer()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))

                    Text(isRunning ? "Pause" : (isPaused ? "Resume" : "Start"))
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
                .glassEffect(.regular.interactive())
                .clipShape(Capsule())
            }
            .buttonStyle(FocusGlassButtonStyle())
            .disabled(totalSelectedMinutes == 0 && !isPaused)
            .opacity(totalSelectedMinutes == 0 && !isPaused ? 0.5 : 1)
        }
    }

    // MARK: - Timer Functions

    private func syncTimerManager() {
        timerManager.isRunning = isRunning
        timerManager.isPaused = isPaused
        timerManager.remainingSeconds = remainingSeconds
        timerManager.selectedTaskTitle = selectedTask?.title
    }

    private func startTimer() {
        remainingSeconds = totalSelectedMinutes * 60
        isRunning = true
        isPaused = false

        // Set the end time for background tracking
        timerEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        syncTimerManager()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                timerManager.remainingSeconds = remainingSeconds

                // Update ring positions smoothly every minute
                let totalMins = remainingSeconds / 60
                let newHours = totalMins / 60
                let newMins = totalMins % 60

                if newHours != selectedHours || newMins != selectedMinutes {
                    withAnimation(.linear(duration: 0.5)) {
                        selectedHours = newHours
                        selectedMinutes = newMins
                    }
                }
            } else {
                timerCompleted()
            }
        }
    }

    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = true
        timerEndTime = nil  // Clear end time when paused

        syncTimerManager()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func resumeTimer() {
        isRunning = true
        isPaused = false

        // Set the end time for background tracking
        timerEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        syncTimerManager()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                timerManager.remainingSeconds = remainingSeconds

                let totalMins = remainingSeconds / 60
                let newHours = totalMins / 60
                let newMins = totalMins % 60

                if newHours != selectedHours || newMins != selectedMinutes {
                    withAnimation(.linear(duration: 0.5)) {
                        selectedHours = newHours
                        selectedMinutes = newMins
                    }
                }
            } else {
                timerCompleted()
            }
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timerEndTime = nil
        remainingSeconds = 0
        syncTimerManager()

        // Reset to default or task time
        if let task = selectedTask, let duration = task.durationInMinutes {
            if duration > 239 {
                selectedHours = 3
                selectedMinutes = 59
                exactTimeMinutes = duration
            } else {
                selectedHours = duration / 60
                selectedMinutes = duration % 60
                exactTimeMinutes = 0
            }
        } else {
            selectedHours = 0
            selectedMinutes = 25
            exactTimeMinutes = 0
        }
    }

    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        syncTimerManager()

        // Haptic burst and alarm sound
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        themeManager.timerAlarmSound.play()

        // Show completion overlay
        withAnimation(.easeInOut(duration: 0.4)) {
            showCompletionOverlay = true
        }
    }

    // MARK: - Task Selection

    private func selectTask(_ task: FocusTask) {
        selectedTask = task
        timerManager.selectedTaskTitle = task.title

        if let duration = task.durationInMinutes {
            exactTimeMinutes = duration

            if duration > 239 {
                // Over max: show max on rings, exact in center
                selectedHours = 3
                selectedMinutes = 59
            } else {
                selectedHours = duration / 60
                selectedMinutes = duration % 60
                exactTimeMinutes = 0
            }

            UISelectionFeedbackGenerator().selectionChanged()
        }
        // Non-time units: don't change timer, let user adjust manually
        // Sheet dismisses itself via dismiss() in FocusTaskPickerView
    }

    private func markTaskComplete() {
        guard let task = selectedTask else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCompletionOverlay = false
            }
            resetTimer()
            return
        }

        switch task {
        case .assignment(let assignment):
            assignment.toggleCompletion()
        case .goal(let goal):
            goal.toggleCompletion()
        case .habit(let habit):
            habit.completeToday()
        }

        // Reset state
        selectedTask = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            showCompletionOverlay = false
        }

        // Reset timer to defaults
        selectedHours = 0
        selectedMinutes = 25
        exactTimeMinutes = 0
        syncTimerManager()
    }
}

#Preview {
    NavigationStack {
        FocusView()
    }
    .modelContainer(for: [Assignment.self, Project.self, Goal.self, Habit.self, HabitEntry.self], inMemory: true)
    .environmentObject(ThemeManager())
    .environment(FocusTimerManager())
}
