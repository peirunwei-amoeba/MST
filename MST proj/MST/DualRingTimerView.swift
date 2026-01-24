//
//  DualRingTimerView.swift
//  MST
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

struct DualRingTimerView: View {
    @Binding var selectedMinutes: Int
    @Binding var selectedHours: Int
    let isRunning: Bool
    let isPaused: Bool
    let remainingSeconds: Int
    let accentColor: Color

    // Time display in center
    let displayTime: String
    let timeLabel: String

    // Ring dimensions - balanced for easier dragging
    private let outerRingWidth: CGFloat = 24  // Minutes - slightly thinner
    private let innerRingWidth: CGFloat = 28  // Hours - thicker for easier grip
    private let ringGap: CGFloat = 0  // No gap for truly fused look

    // Drag state
    @State private var isDraggingOuter: Bool = false
    @State private var isDraggingInner: Bool = false
    @State private var lastHapticMinute: Int = -1
    @State private var lastHapticSnap: Int = -1
    @State private var dragLock: DragLock = .none

    private enum DragLock {
        case none
        case outer  // Locked to minute ring
        case inner  // Locked to hour ring
    }

    // Computed ring progress (starts from top, goes clockwise)
    private var minuteProgress: Double {
        Double(selectedMinutes) / 60.0
    }

    private var hourProgress: Double {
        // Hours progress (0-3 hours mapped to full circle)
        let totalMinutes = selectedHours * 60 + selectedMinutes
        return min(1.0, Double(totalMinutes) / 180.0)  // 3 hours = 180 mins
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = (size / 2) - 30  // Leave room for labels
            let innerRadius = outerRadius - outerRingWidth / 2 - innerRingWidth / 2 - ringGap

            ZStack {
                // MARK: - Background Track (Single fused track)

                // Combined background track for fused appearance
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.15),
                        lineWidth: outerRingWidth + innerRingWidth + ringGap
                    )
                    .frame(width: (outerRadius + innerRadius), height: (outerRadius + innerRadius))

                // MARK: - Hour Ring (Inner) - Progress Arc

                Circle()
                    .trim(from: 0, to: hourProgress)
                    .stroke(
                        accentColor.opacity(0.5),
                        style: StrokeStyle(lineWidth: innerRingWidth, lineCap: .round)
                    )
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hourProgress)

                // MARK: - Minute Ring (Outer) - Progress Arc

                Circle()
                    .trim(from: 0, to: minuteProgress)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: outerRingWidth, lineCap: .round)
                    )
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: minuteProgress)

                // MARK: - Tick Marks for Minutes (every 5 minutes, small lines)

                ForEach(0..<60, id: \.self) { minute in
                    let isMajor = minute % 15 == 0
                    let isMedium = minute % 5 == 0 && !isMajor

                    if isMajor || isMedium {
                        let angle = Double(minute) / 60.0 * 360.0 - 90
                        let tickLength: CGFloat = isMajor ? 10 : 6
                        let tickWidth: CGFloat = isMajor ? 2 : 1.5

                        Rectangle()
                            .fill(Color.secondary.opacity(isMajor ? 0.4 : 0.25))
                            .frame(width: tickWidth, height: tickLength)
                            .offset(y: -(outerRadius + outerRingWidth / 2 + 4))
                            .rotationEffect(.degrees(angle))
                    }
                }

                // MARK: - Labels (60 at top, 15 at right, 30 at bottom, 45 at left)

                // Position labels correctly: 60 at top (0°), 15 at right (90°), 30 at bottom (180°), 45 at left (270°)
                let labelRadius = outerRadius + outerRingWidth / 2 + 22

                // 60 (top - 12 o'clock)
                Text("60")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .position(x: size / 2, y: size / 2 - labelRadius)

                // 15 (right - 3 o'clock)
                Text("15")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .position(x: size / 2 + labelRadius, y: size / 2)

                // 30 (bottom - 6 o'clock)
                Text("30")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .position(x: size / 2, y: size / 2 + labelRadius)

                // 45 (left - 9 o'clock)
                Text("45")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .position(x: size / 2 - labelRadius, y: size / 2)

                // MARK: - Drag Handles (subtle design)

                if !isRunning || isPaused {
                    // Minute handle (outer ring) - subtle white circle with accent border
                    let minuteAngle = (minuteProgress * 360.0 - 90) * .pi / 180
                    let minuteHandleX = cos(minuteAngle) * outerRadius
                    let minuteHandleY = sin(minuteAngle) * outerRadius

                    Circle()
                        .fill(Color.white)
                        .frame(width: outerRingWidth + 4, height: outerRingWidth + 4)
                        .overlay(
                            Circle()
                                .stroke(accentColor, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .position(x: size / 2 + minuteHandleX, y: size / 2 + minuteHandleY)
                        .scaleEffect(isDraggingOuter ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2), value: isDraggingOuter)

                    // Hour handle (inner ring) - smaller, more subtle
                    let hourAngle = (hourProgress * 360.0 - 90) * .pi / 180
                    let hourHandleX = cos(hourAngle) * innerRadius
                    let hourHandleY = sin(hourAngle) * innerRadius

                    Circle()
                        .fill(Color.white)
                        .frame(width: innerRingWidth + 4, height: innerRingWidth + 4)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.7), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
                        .position(x: size / 2 + hourHandleX, y: size / 2 + hourHandleY)
                        .scaleEffect(isDraggingInner ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2), value: isDraggingInner)
                }

                // MARK: - Center Time Display

                VStack(spacing: 2) {
                    Text(displayTime)
                        .font(.system(size: selectedHours > 0 || isRunning ? 52 : 72, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: displayTime)

                    Text(timeLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(2)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isRunning || isPaused else { return }
                        handleDrag(value: value, center: center, outerRadius: outerRadius, innerRadius: innerRadius)
                    }
                    .onEnded { _ in
                        isDraggingOuter = false
                        isDraggingInner = false
                        dragLock = .none  // Release lock when finger lifts
                    }
            )
        }
    }

    // MARK: - Drag Handling

    private func handleDrag(value: DragGesture.Value, center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat) {
        let location = value.location
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // Calculate angle from top (0 degrees = 12 o'clock), clockwise
        var angle = atan2(dx, -dy) * 180 / .pi
        if angle < 0 { angle += 360 }

        // Define zones - generous hit areas for easier dragging
        let outerZone = outerRadius - outerRingWidth - 8...outerRadius + outerRingWidth + 20
        let innerZone = innerRadius - innerRingWidth - 20...innerRadius + innerRingWidth + 20
        let centerZone = 0.0...(innerRadius - innerRingWidth - 20)

        // Determine initial lock if not already locked
        if dragLock == .none {
            if outerZone.contains(distance) {
                dragLock = .outer
            } else if innerZone.contains(distance) || centerZone.contains(distance) {
                dragLock = .inner
            }
        }

        // Handle drag based on lock (not current position)
        switch dragLock {
        case .outer:
            // Locked to outer ring (minutes)
            isDraggingOuter = true
            isDraggingInner = false

            let newMinutes = Int((angle / 360.0) * 60.0)
            let clampedMinutes = max(0, min(59, newMinutes))

            if clampedMinutes != selectedMinutes {
                selectedMinutes = clampedMinutes

                // Haptic feedback on minute change
                if clampedMinutes != lastHapticMinute {
                    UISelectionFeedbackGenerator().selectionChanged()
                    lastHapticMinute = clampedMinutes
                }
            }

        case .inner:
            // Locked to inner ring (hours with 15-min snapping)
            isDraggingOuter = false
            isDraggingInner = true

            // Convert angle to total minutes (0-180 for 3 hours max)
            let rawTotalMinutes = (angle / 360.0) * 180.0
            let snappedMinutes = snapToInterval(rawTotalMinutes, interval: 15)
            let clampedMinutes = max(0, min(180, snappedMinutes))

            let newHours = clampedMinutes / 60
            let newMins = clampedMinutes % 60

            if newHours != selectedHours || newMins != selectedMinutes {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    selectedHours = newHours
                    selectedMinutes = newMins
                }

                // Stronger haptic for snapping
                if clampedMinutes != lastHapticSnap {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    lastHapticSnap = clampedMinutes
                }
            }

        case .none:
            break
        }
    }

    private func snapToInterval(_ value: Double, interval: Int) -> Int {
        let rounded = Int((value / Double(interval)).rounded()) * interval
        return rounded
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var minutes = 23
        @State private var hours = 0

        var body: some View {
            VStack {
                DualRingTimerView(
                    selectedMinutes: $minutes,
                    selectedHours: $hours,
                    isRunning: false,
                    isPaused: false,
                    remainingSeconds: 0,
                    accentColor: .purple,
                    displayTime: "\(minutes)",
                    timeLabel: "MINS"
                )
                .frame(width: 320, height: 320)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
