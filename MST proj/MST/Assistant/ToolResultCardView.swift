//
//  ToolResultCardView.swift
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
import MapKit
import CoreLocation

// MARK: - Draw-on progress ring with icon

struct ToolProgressRing: View {
    let iconName: String
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var rotation: Double = 0
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0

    var body: some View {
        ZStack {
            // Faint background track
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 2)

            // Draw-on comet arc — spins continuously
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    themeManager.accentColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation - 90))

            // Tool icon in center, appears after a moment
            Image(systemName: iconName)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(themeManager.accentColor)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
        }
        .onAppear {
            // Spin the arc continuously
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // Draw the icon in with a spring
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }
}

// MARK: - Tool Result Card

struct ToolResultCardView: View {
    let toolResult: ToolResultInfo
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var contentVisible = false
    @State private var iconDrawn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 10) {
                // Icon / loading ring
                ZStack {
                    if toolResult.isExecuting {
                        ToolProgressRing(iconName: toolResult.icon)
                            .transition(.opacity)
                    } else {
                        Image(systemName: toolResult.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(themeManager.accentColor)
                            .symbolEffect(.drawOn, options: .nonRepeating)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 20, height: 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: toolResult.isExecuting)

                Text(toolResult.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .contentTransition(.interpolate)

                Spacer()

                if toolResult.isExecuting {
                    Text("Running")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.green)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toolResult.isExecuting)

            // Rich content revealed after execution
            if !toolResult.isExecuting && contentVisible {
                richContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.trailing, 32)
        .onChange(of: toolResult.isExecuting) { _, newValue in
            if !newValue {
                iconDrawn = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                    contentVisible = true
                }
            }
        }
        .onAppear {
            if !toolResult.isExecuting {
                contentVisible = true
                iconDrawn = true
            }
        }
    }

    // MARK: Rich content switcher

    @ViewBuilder
    private var richContent: some View {
        if let coordinate = toolResult.coordinate {
            locationCard(coordinate: coordinate, name: toolResult.locationName)
        } else if let date = toolResult.calendarDate {
            calendarCard(date: date)
        } else if toolResult.toolName == "getWeather", let text = toolResult.resultText, !text.isEmpty {
            weatherCard(text: text)
        } else if let text = toolResult.resultText, !text.isEmpty {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Weather card

    @ViewBuilder
    private func weatherCard(text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: weatherSymbol(for: text))
                .font(.system(size: 30))
                .foregroundStyle(themeManager.accentColor)
                .symbolEffect(.variableColor.cumulative, isActive: true)
                .frame(width: 40)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func weatherSymbol(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("sunny") || lower.contains("clear") { return "sun.max.fill" }
        if lower.contains("thunder") || lower.contains("storm") { return "cloud.bolt.fill" }
        if lower.contains("snow") || lower.contains("blizzard") { return "snowflake" }
        if lower.contains("rain") || lower.contains("drizzle") { return "cloud.rain.fill" }
        if lower.contains("fog") || lower.contains("mist") { return "cloud.fog.fill" }
        if lower.contains("partly") || lower.contains("scattered") { return "cloud.sun.fill" }
        if lower.contains("cloud") || lower.contains("overcast") { return "cloud.fill" }
        return "thermometer.medium"
    }

    // MARK: Location card with embedded map

    @ViewBuilder
    private func locationCard(coordinate: CLLocationCoordinate2D, name: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let name, !name.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(themeManager.accentColor)
                    Text(name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )))) {
                Marker("", coordinate: coordinate)
                    .tint(.red)
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)
        }
    }

    // MARK: Calendar card

    @ViewBuilder
    private func calendarCard(date: Date) -> some View {
        HStack(spacing: 12) {
            // Date tile
            VStack(spacing: 3) {
                Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(themeManager.accentColor)
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52, height: 60)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Time info
            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted(.dateTime.year()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(date.formatted(.dateTime.hour().minute()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(TimeZone.current.identifier)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }
}

