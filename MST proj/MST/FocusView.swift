//
//  FocusView.swift
//  MST
//
//  Created by Claude on 1/23/26.
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Focus View States

enum FocusTimerState {
    case idle
    case countdownRunning
    case countdownPaused
    case stopwatchRunning
    case stopwatchPaused
    case completed
}

// MARK: - Main Focus View

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @Query private var allAssignments: [Assignment]
    @Query private var allGoals: [Goal]
    @Query private var allHabits: [Habit]

    // State
    @State private var timerState: FocusTimerState = .idle
    @State private var selectedMinutes: Int = 1
    @State private var remainingSeconds: Int = 0
    @State private var stopwatchSeconds: Int = 0
    @State private var timer: Timer?

    // Task selection
    @State private var selectedTask: FocusTaskItem?
    @State private var showingTaskPicker = false

    // Scroll
    @State private var scrollPosition: Int? = 1

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

    private var isRunning: Bool {
        timerState == .countdownRunning || timerState == .stopwatchRunning
    }

    private var isStopwatchMode: Bool {
        timerState == .stopwatchRunning || timerState == .stopwatchPaused || selectedMinutes == 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - full screen
                (isRunning ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: isRunning)

                // Main display - full screen, extends to all edges
                mainDisplay
                    .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                    .offset(y: -geometry.safeAreaInsets.top)

                // Floating elements on top - these stay in safe area
                VStack {
                    // Dropdown at top
                    taskDropdown
                        .padding(.top, geometry.safeAreaInsets.top + 10)

                    Spacer()

                    // Bottom time display
                    bottomTimeDisplay
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }

                // Completion overlay - only if task selected
                if timerState == .completed && selectedTask != nil {
                    completionOverlay
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture(perform: handleTap)
        .sheet(isPresented: $showingTaskPicker) {
            taskPickerSheet
        }
    }

    // MARK: - Liquid Glass Task Dropdown

    private var taskDropdown: some View {
        Button {
            if !isRunning {
                showingTaskPicker = true
            }
        } label: {
            HStack(spacing: 10) {
                if let task = selectedTask {
                    Image(systemName: task.icon)
                        .font(.subheadline.weight(.medium))
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.subheadline.weight(.medium))
                    Text("Select Task")
                        .font(.subheadline.weight(.medium))
                }

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isRunning ? .white.opacity(0.7) : .primary.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: Capsule())
        }
        .disabled(isRunning)
        .opacity(isRunning ? 0.5 : 1)
    }

    // MARK: - Main Display

    private var mainDisplay: some View {
        Group {
            switch timerState {
            case .idle, .countdownPaused:
                // Show scroll picker when idle OR paused (so user can change time)
                scrollPicker

            case .countdownRunning:
                countdownDisplay

            case .stopwatchRunning, .stopwatchPaused:
                stopwatchDisplay

            case .completed:
                EmptyView()
            }
        }
    }

    // MARK: - Scroll Picker
    // Numbers: 99 at top, 1 near bottom, + at very bottom

    private var scrollPicker: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Spacer at top - so first item can center
                        Color.clear.frame(height: geo.size.height / 2 - 160)

                        // 99 down to 1
                        ForEach((1...maxMinutes).reversed(), id: \.self) { minute in
                            numberCell(minute)
                        }

                        // Plus at bottom (stopwatch)
                        plusCell

                        // Spacer at bottom - extends well past bottom edge
                        Color.clear.frame(height: geo.size.height / 2 + 200)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollPosition, anchor: .center)
                .onChange(of: scrollPosition) { _, newValue in
                    if let value = newValue {
                        selectedMinutes = value
                        // If paused, update remaining time to new selection
                        if timerState == .countdownPaused {
                            remainingSeconds = value * 60
                        }
                        let gen = UISelectionFeedbackGenerator()
                        gen.selectionChanged()
                    }
                }
                .onAppear {
                    // Scroll to correct position on appear
                    let targetPosition = timerState == .countdownPaused ?
                        max(1, (remainingSeconds + 59) / 60) : selectedMinutes

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(targetPosition, anchor: .center)
                        scrollPosition = targetPosition
                    }
                }
            }
        }
    }

    private func numberCell(_ minute: Int) -> some View {
        let isSelected = scrollPosition == minute

        return Text("\(minute)")
            .font(.system(size: 220, weight: .bold))
            .scaleEffect(x: 1.0, y: 1.5) // Stretch vertically even more
            .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.12))
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.02), radius: 6, x: 3, y: 5)
            .frame(height: 320)
            .id(minute)
    }

    private var plusCell: some View {
        let isSelected = scrollPosition == 0

        return Image(systemName: "plus")
            .font(.system(size: 140, weight: .bold))
            // No stretch for plus icon - keep normal size
            .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.12))
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.02), radius: 6, x: 3, y: 5)
            .frame(height: 280)
            .id(0)
    }

    // MARK: - Countdown Display

    private var countdownDisplay: some View {
        let mins = max(1, (remainingSeconds + 59) / 60)
        let displayValue = min(mins, maxMinutes)

        return Text("\(displayValue)")
            .font(.system(size: 220, weight: .bold))
            .scaleEffect(x: 1.0, y: 1.5)
            .foregroundStyle(
                timerState == .countdownRunning ?
                AnyShapeStyle(LinearGradient(
                    colors: [.blue, .cyan, .orange, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )) :
                AnyShapeStyle(Color.primary)
            )
            .shadow(color: .black.opacity(0.1), radius: 6, x: 3, y: 5)
    }

    // MARK: - Stopwatch Display

    private var stopwatchDisplay: some View {
        let minutes = stopwatchSeconds / 60

        return Group {
            if minutes >= 1 {
                Text("\(minutes)")
                    .font(.system(size: 220, weight: .bold))
                    .scaleEffect(x: 1.0, y: 1.5)
                    .foregroundStyle(isRunning ? Color.white : Color.primary)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 3, y: 5)
            } else {
                // Plus icon - no stretch
                Image(systemName: "plus")
                    .font(.system(size: 140, weight: .bold))
                    .foregroundStyle(isRunning ? Color.white : Color.primary)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 3, y: 5)
            }
        }
    }

    // MARK: - Bottom Time Display

    private var bottomTimeDisplay: some View {
        Group {
            switch timerState {
            case .idle:
                if selectedMinutes == 0 {
                    Text("Tap to start stopwatch")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                } else {
                    Text("Tap to start")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                }

            case .countdownRunning, .countdownPaused:
                let h = remainingSeconds / 3600
                let m = (remainingSeconds % 3600) / 60
                let s = remainingSeconds % 60

                if h > 0 {
                    Text(String(format: "%d:%02d:%02d", h, m, s))
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isRunning ? .white : .primary.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                } else {
                    Text(String(format: "%02d:%02d", m, s))
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isRunning ? .white : .primary.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                }

            case .stopwatchRunning, .stopwatchPaused:
                let h = stopwatchSeconds / 3600
                let m = (stopwatchSeconds % 3600) / 60
                let s = stopwatchSeconds % 60
                Text(String(format: "+%02d:%02d:%02d", h, m, s))
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isRunning ? .white : .primary.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: Capsule())

            case .completed:
                EmptyView()
            }
        }
    }

    // MARK: - Handle Tap

    private func handleTap() {
        switch timerState {
        case .idle:
            startTimer()
        case .countdownRunning:
            pauseCountdown()
        case .countdownPaused:
            resumeCountdown()
        case .stopwatchRunning:
            pauseStopwatch()
        case .stopwatchPaused:
            resumeStopwatch()
        case .completed:
            break
        }
    }

    // MARK: - Timer Actions

    private func startTimer() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        AudioServicesPlaySystemSound(1104)

        if selectedMinutes == 0 {
            timerState = .stopwatchRunning
            stopwatchSeconds = 0
            startStopwatchLoop()
        } else {
            remainingSeconds = selectedMinutes * 60
            timerState = .countdownRunning
            startCountdownLoop()
        }
    }

    private func startCountdownLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer?.invalidate()
                timer = nil
                finishCountdown()
            }
        }
    }

    private func finishCountdown() {
        // Only show completion if task selected
        if selectedTask != nil {
            withAnimation(.easeOut(duration: 0.3)) {
                timerState = .completed
            }
        } else {
            // No task - just reset
            resetAll()
        }
    }

    private func pauseCountdown() {
        timer?.invalidate()
        timer = nil
        // Calculate current remaining minutes for scroll position
        let currentMinutes = max(1, (remainingSeconds + 59) / 60)
        selectedMinutes = currentMinutes
        // Set timerState first, then scroll position will be handled by onAppear
        timerState = .countdownPaused
        // Delay setting scroll position to ensure view updates first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            scrollPosition = currentMinutes
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func resumeCountdown() {
        timerState = .countdownRunning
        startCountdownLoop()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func startStopwatchLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            stopwatchSeconds += 1
        }
    }

    private func pauseStopwatch() {
        timer?.invalidate()
        timer = nil
        timerState = .stopwatchPaused
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func resumeStopwatch() {
        timerState = .stopwatchRunning
        startStopwatchLoop()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func resetAll() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        selectedTask = nil
        selectedMinutes = 1
        scrollPosition = 1
        remainingSeconds = 0
        stopwatchSeconds = 0
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.94)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                if let task = selectedTask {
                    Text(task.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Text("Complete!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Big exciting checkmark
                ExcitingCheckmark(
                    onComplete: {
                        completeTask()
                    }
                )

                Spacer()

                Button {
                    dismissWithoutComplete()
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 50)
            }

            // Confetti on top
            ConfettiView()
                .allowsHitTesting(false)
        }
    }

    private func completeTask() {
        guard let task = selectedTask else { return }

        switch task.type {
        case .assignment:
            if let item = allAssignments.first(where: { $0.id == task.id }) {
                item.toggleCompletion()
            }
        case .goal:
            if let item = allGoals.first(where: { $0.id == task.id }) {
                item.toggleCompletion()
            }
        case .habit:
            if let item = allHabits.first(where: { $0.id == task.id }) {
                item.completeToday()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetAll()
        }
    }

    private func dismissWithoutComplete() {
        withAnimation(.easeOut(duration: 0.3)) {
            resetAll()
        }
    }

    // MARK: - Task Picker Sheet

    private var taskPickerSheet: some View {
        NavigationStack {
            List {
                let timeAssignments = assignments.filter { isTimeUnit($0.targetUnit) }
                let timeGoals = goals.filter { isTimeUnit($0.targetUnit) }
                let timeHabits = habits.filter { isTimeUnit($0.unit) }

                if !timeAssignments.isEmpty || !timeGoals.isEmpty || !timeHabits.isEmpty {
                    Section("With Time Target") {
                        ForEach(timeAssignments) { a in
                            taskRow(a.title, a.formattedTarget ?? "", "doc.text", a.id, a.targetValue, a.targetUnit, .assignment)
                        }
                        ForEach(timeGoals) { g in
                            taskRow(g.title, g.formattedTarget ?? "", "flag", g.id, g.targetValue, g.targetUnit, .goal)
                        }
                        ForEach(timeHabits) { h in
                            taskRow(h.title, h.formattedTarget, "repeat", h.id, h.targetValue, h.unit, .habit)
                        }
                    }
                }

                let otherAssignments = assignments.filter { !isTimeUnit($0.targetUnit) }
                let otherGoals = goals.filter { !isTimeUnit($0.targetUnit) }
                let otherHabits = habits.filter { !isTimeUnit($0.unit) }

                if !otherAssignments.isEmpty || !otherGoals.isEmpty || !otherHabits.isEmpty {
                    Section("Other Tasks") {
                        ForEach(otherAssignments) { a in
                            taskRow(a.title, a.formattedTarget ?? "Set time", "doc.text", a.id, nil, .none, .assignment)
                        }
                        ForEach(otherGoals) { g in
                            taskRow(g.title, g.formattedTarget ?? "Set time", "flag", g.id, nil, .none, .goal)
                        }
                        ForEach(otherHabits) { h in
                            taskRow(h.title, h.formattedTarget, "repeat", h.id, nil, .none, .habit)
                        }
                    }
                }

                if assignments.isEmpty && goals.isEmpty && habits.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "checklist", description: Text("Add tasks first."))
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTaskPicker = false }
                }
            }
        }
    }

    private func taskRow(_ title: String, _ subtitle: String, _ icon: String, _ id: UUID, _ value: Double?, _ unit: TargetUnit, _ type: FocusTaskType) -> some View {
        Button {
            selectTask(title: title, icon: icon, id: id, value: value, unit: unit, type: type)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(themeManager.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.primary)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
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

    private func selectTask(title: String, icon: String, id: UUID, value: Double?, unit: TargetUnit, type: FocusTaskType) {
        selectedTask = FocusTaskItem(id: id, title: title, icon: icon, type: type)
        showingTaskPicker = false

        // If time-based, auto-start
        if let v = value, isTimeUnit(unit) {
            let mins = timeToMinutes(v, unit)
            selectedMinutes = min(mins, maxMinutes)
            scrollPosition = min(mins, maxMinutes)
            remainingSeconds = selectedMinutes * 60

            // Auto-start after small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                timerState = .countdownRunning
                startCountdownLoop()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                AudioServicesPlaySystemSound(1104)
            }
        }
    }

    private func isTimeUnit(_ unit: TargetUnit) -> Bool {
        unit == .hour || unit == .minute || unit == .second
    }

    private func timeToMinutes(_ value: Double, _ unit: TargetUnit) -> Int {
        switch unit {
        case .hour: return Int(value * 60)
        case .minute: return Int(value)
        case .second: return max(1, Int(value / 60))
        default: return 1
        }
    }
}

// MARK: - Focus Task Item

struct FocusTaskItem: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let type: FocusTaskType
}

enum FocusTaskType {
    case assignment, goal, habit
}

// MARK: - Exciting Checkmark (Matches Habits Animation)

struct ExcitingCheckmark: View {
    let onComplete: () -> Void

    // Long press animation states (matching ConcentricHabitCard)
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var completionBounce = false
    @State private var showRipple = false
    @State private var hapticTimer: Timer?
    @State private var holdStartTime: Date?

    private let holdDuration: Double = 1.2 // Same as habits
    private let checkmarkSize: CGFloat = 120
    private let minimumHoldToShowProgress: Double = 0.06

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                .frame(width: checkmarkSize + 16, height: checkmarkSize + 16)

            // Progress ring (fills during hold) - only show if actually holding
            if holdProgress > 0 && isHolding {
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: checkmarkSize + 16, height: checkmarkSize + 16)
                    .rotationEffect(.degrees(-90))
            }

            // Ripple effect on completion
            if showRipple {
                Circle()
                    .stroke(Color.green.opacity(0.6), lineWidth: 4)
                    .frame(width: checkmarkSize + 16, height: checkmarkSize + 16)
                    .scaleEffect(showRipple ? 1.8 : 1.0)
                    .opacity(showRipple ? 0 : 1)
            }

            // Checkmark icon
            Image(systemName: completionBounce ? "checkmark.circle.fill" : "circle")
                .font(.system(size: checkmarkSize, weight: .medium))
                .foregroundStyle(
                    completionBounce ? .green :
                    (isHolding && holdProgress > 0) ? .green.opacity(0.4 + holdProgress * 0.6) :
                    .white.opacity(0.5)
                )
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                .scaleEffect(completionBounce ? 1.35 : (isHolding ? 1.0 + holdProgress * 0.2 : 1.0))
                .rotationEffect(.degrees(completionBounce ? 10 : (isHolding ? holdProgress * 8 : 0)))
        }
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 50) {
            // Long press completed
            completeCheckmark()
        } onPressingChanged: { pressing in
            if pressing {
                startHolding()
            } else {
                // Released before completion
                if !completionBounce {
                    cancelHolding()
                }
            }
        }
    }

    // MARK: - Holding Logic (matching ConcentricHabitCard)

    private func startHolding() {
        guard !isHolding else { return }
        isHolding = true
        holdStartTime = Date()

        // Delay showing progress slightly to avoid flash on quick tap
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumHoldToShowProgress) {
            guard isHolding else { return }

            // Start progressive animation
            withAnimation(.linear(duration: holdDuration - minimumHoldToShowProgress)) {
                holdProgress = 1.0
            }

            // Start haptic feedback timer
            startHapticFeedback()
        }
    }

    private func cancelHolding() {
        isHolding = false
        holdStartTime = nil
        hapticTimer?.invalidate()
        hapticTimer = nil

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            holdProgress = 0
        }
    }

    private func completeCheckmark() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        isHolding = false
        holdStartTime = nil

        // Final celebration haptic and sound
        let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        heavyFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1407)
        }

        // Bounce animation (same as habits checkmarks)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            completionBounce = true
        }

        // Ripple effect
        withAnimation(.easeOut(duration: 0.6)) {
            showRipple = true
        }

        // Reset after animation (same timing as habits checkmarks)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                holdProgress = 0
            }
            showRipple = false

            // Trigger the actual completion
            onComplete()
        }
    }

    // MARK: - Progressive Haptic Feedback (matching ConcentricHabitCard)

    private func startHapticFeedback() {
        var pulseCount = 0
        let totalPulses = 16 // Same as habits
        let interval = (holdDuration - minimumHoldToShowProgress) / Double(totalPulses)

        // First haptic immediately
        let initialGenerator = UIImpactFeedbackGenerator(style: .light)
        initialGenerator.impactOccurred()

        hapticTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            guard isHolding else {
                timer.invalidate()
                return
            }

            pulseCount += 1

            // Progressively stronger haptics - ramps up intensity
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
