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

    // Ring dimensions - fused appearance (minimal gap)
    private let outerRingWidth: CGFloat = 20
    private let innerRingWidth: CGFloat = 14
    private let ringGap: CGFloat = 2  // Minimal gap for fused look

    // Drag state
    @State private var isDraggingOuter: Bool = false
    @State private var isDraggingInner: Bool = false
    @State private var lastHapticMinute: Int = -1
    @State private var lastHapticHour: Int = -1

    // Computed ring progress
    private var minuteProgress: Double {
        Double(selectedMinutes) / 60.0
    }

    private var hourProgress: Double {
        // Total time in minutes / max time (239 minutes = 3h59m)
        let totalMinutes = selectedHours * 60 + selectedMinutes
        return min(1.0, Double(totalMinutes) / 239.0)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = (size / 2) - outerRingWidth / 2 - 10
            let innerRadius = outerRadius - outerRingWidth / 2 - ringGap - innerRingWidth / 2

            ZStack {
                // MARK: - Background Tracks (Fused appearance)

                // Combined track background for fused look
                let combinedWidth = outerRingWidth + ringGap + innerRingWidth
                let combinedRadius = (outerRadius + innerRadius) / 2

                Circle()
                    .stroke(Color.secondary.opacity(0.08), lineWidth: combinedWidth)
                    .frame(width: combinedRadius * 2, height: combinedRadius * 2)

                // Outer ring track (minutes) - slightly more visible
                Circle()
                    .stroke(Color.secondary.opacity(0.12), lineWidth: outerRingWidth)
                    .frame(width: outerRadius * 2, height: outerRadius * 2)

                // Inner ring track (hours)
                Circle()
                    .stroke(Color.secondary.opacity(0.1), lineWidth: innerRingWidth)
                    .frame(width: innerRadius * 2, height: innerRadius * 2)

                // MARK: - Progress Arcs

                // Outer ring progress (minutes) - starts from top
                Circle()
                    .trim(from: 0, to: minuteProgress)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: outerRingWidth, lineCap: .round)
                    )
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: minuteProgress)

                // Inner ring progress (hours) - gradient effect
                Circle()
                    .trim(from: 0, to: hourProgress)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.6), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: innerRingWidth, lineCap: .round)
                    )
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hourProgress)

                // MARK: - Tick Marks

                // Minute tick marks (every 15 minutes)
                ForEach([0, 15, 30, 45], id: \.self) { minute in
                    let angle = Double(minute) / 60.0 * 360.0 - 90
                    let tickLength: CGFloat = minute == 0 ? 12 : 8

                    // Tick mark
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 2, height: tickLength)
                        .offset(y: -outerRadius - outerRingWidth / 2 - 4)
                        .rotationEffect(.degrees(angle))

                    // Label
                    let labelRadius = outerRadius + outerRingWidth / 2 + 20
                    let labelAngle = (angle + 90) * .pi / 180
                    let labelX = cos(labelAngle) * labelRadius
                    let labelY = sin(labelAngle) * labelRadius

                    Text(minute == 0 ? "60" : "\(minute)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .position(x: size / 2 + labelX, y: size / 2 + labelY)
                }

                // MARK: - Drag Handles

                // Minute handle (outer ring)
                if !isRunning || isPaused {
                    let minuteAngle = minuteProgress * 360.0 - 90
                    let handleX = cos(minuteAngle * .pi / 180) * outerRadius
                    let handleY = sin(minuteAngle * .pi / 180) * outerRadius

                    Circle()
                        .fill(Color.white)
                        .frame(width: outerRingWidth + 8, height: outerRingWidth + 8)
                        .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(accentColor, lineWidth: 3)
                        )
                        .position(x: size / 2 + handleX, y: size / 2 + handleY)
                        .scaleEffect(isDraggingOuter ? 1.15 : 1.0)
                        .animation(.spring(response: 0.2), value: isDraggingOuter)
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

        // Calculate angle from top (0 degrees = 12 o'clock)
        var angle = atan2(dy, dx) * 180 / .pi + 90
        if angle < 0 { angle += 360 }

        // Determine which ring we're dragging based on distance
        let outerRingInner = outerRadius - outerRingWidth
        let outerRingOuter = outerRadius + outerRingWidth
        let innerRingInner = innerRadius - innerRingWidth
        let innerRingOuter = innerRadius + innerRingWidth

        if distance >= outerRingInner - 20 && distance <= outerRingOuter + 20 {
            // Dragging outer ring (minutes)
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
        } else if distance >= innerRingInner - 15 && distance <= innerRingOuter + 15 {
            // Dragging inner ring (hours with 15-min snapping)
            isDraggingOuter = false
            isDraggingInner = true

            // Convert angle to total minutes (0-239 for 3h59m max)
            let rawTotalMinutes = (angle / 360.0) * 239.0
            let snappedMinutes = snapToInterval(rawTotalMinutes, interval: 15)
            let clampedMinutes = max(0, min(239, snappedMinutes))

            let newHours = clampedMinutes / 60
            let newMins = clampedMinutes % 60

            if newHours != selectedHours || newMins != selectedMinutes {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    selectedHours = newHours
                    selectedMinutes = newMins
                }

                // Stronger haptic for snapping
                if newHours != lastHapticHour || (clampedMinutes % 15 == 0) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    lastHapticHour = newHours
                }
            }
        } else if distance < innerRingInner - 15 {
            // Inside inner ring - fine-tune minutes
            isDraggingOuter = true
            isDraggingInner = false

            let newMinutes = Int((angle / 360.0) * 60.0)
            let clampedMinutes = max(0, min(59, newMinutes))

            if clampedMinutes != selectedMinutes {
                selectedMinutes = clampedMinutes

                if clampedMinutes != lastHapticMinute {
                    UISelectionFeedbackGenerator().selectionChanged()
                    lastHapticMinute = clampedMinutes
                }
            }
        }
    }

    private func snapToInterval(_ value: Double, interval: Int) -> Int {
        let rounded = Int((value / Double(interval)).rounded()) * interval
        return rounded
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var minutes = 25
        @State private var hours = 1

        var body: some View {
            VStack {
                DualRingTimerView(
                    selectedMinutes: $minutes,
                    selectedHours: $hours,
                    isRunning: false,
                    isPaused: false,
                    remainingSeconds: 0,
                    accentColor: .purple
                )
                .frame(width: 280, height: 280)

                Text("\(hours)h \(minutes)m")
                    .font(.title)
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}
