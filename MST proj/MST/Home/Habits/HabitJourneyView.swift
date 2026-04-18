//
//  HabitJourneyView.swift
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
import UIKit
import SwiftData
import FoundationModels
import ImagePlayground
import Combine

// MARK: - Main Journey View

struct HabitJourneyView: View {
    let habit: Habit
    /// Pass `true` when opening from a just-completed check-in so the view auto-generates.
    @Binding var startGenerating: Bool

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var habitEntries: [HabitJourneyEntry]

    @State private var isGenerating = false
    @State private var streamingText = ""
    @State private var generationTask: Task<Void, Never>?

    // Highlight the newest entry (just generated)
    @State private var newestEntryId: UUID?

    // Delete confirmation
    @State private var entryToDelete: HabitJourneyEntry?
    @State private var showDeleteConfirmation = false

    init(habit: Habit, startGenerating: Binding<Bool>) {
        self.habit = habit
        self._startGenerating = startGenerating
        let habitId = habit.id
        _habitEntries = Query(
            filter: #Predicate<HabitJourneyEntry> { $0.habitId == habitId },
            sort: \HabitJourneyEntry.checkinNumber
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [themeManager.accentColor.opacity(0.05), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 32) {
                            // Past entries
                            ForEach(Array(habitEntries.enumerated()), id: \.element.id) { index, entry in
                                if index > 0 {
                                    JourneyDividerView(
                                        style: JourneyDividerStyle(rawValue: entry.dividerStyle) ?? .mountain_pass
                                    )
                                }
                                JourneyEntryView(
                                    entry: entry,
                                    isHighlighted: entry.id == newestEntryId
                                )
                                .id(entry.id)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        entryToDelete = entry
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete Entry", systemImage: "trash")
                                    }
                                }
                            }

                            // Streaming new entry
                            if isGenerating {
                                StreamingEntryView(text: streamingText)
                                    .id("streaming")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black, location: 0.06),
                                .init(color: .black, location: 0.88),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            if isGenerating {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            } else if let last = habitEntries.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: isGenerating) { _, generating in
                        if generating {
                            withAnimation {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: streamingText) {
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                    .onChange(of: habitEntries.count) {
                        if let last = habitEntries.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Empty state
                if habitEntries.isEmpty && !isGenerating {
                    emptyState
                }
            }
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if startGenerating {
                startGenerating = false
                startStoryGeneration()
            }
        }
        .onDisappear {
            generationTask?.cancel()
        }
        .confirmationDialog("Delete this journal entry?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                }
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text("This will permanently remove the entry and its images.")
        }
    }

    // MARK: - Delete Entry

    private func deleteEntry(_ entry: HabitJourneyEntry) {
        // Delete all image files from disk
        let segments = HabitJourneyEntry.parse(entry.storyText)
        for segment in segments {
            if case .imageMarker(let marker) = segment {
                let fileURL = entry.imageFilePath(for: marker)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        modelContext.delete(entry)
        try? modelContext.save()
    }

    // MARK: - Story Generation

    func startStoryGeneration() {
        guard !isGenerating else { return }
        guard SystemLanguageModel.default.availability == .available else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if let lastEntry = habitEntries.last,
           Calendar.current.startOfDay(for: lastEntry.date) == today { return }

        isGenerating = true
        streamingText = ""

        generationTask = Task {
            do {
                let checkinNumber = habitEntries.count + 1
                let prompt = buildStoryPrompt(checkinNumber: checkinNumber)
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                guard !Task.isCancelled else { return }

                let fullText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

                // Stream the response word by word
                let words = fullText.components(separatedBy: " ")
                var built = ""
                for word in words {
                    guard !Task.isCancelled else { break }
                    built += (built.isEmpty ? "" : " ") + word
                    await MainActor.run { streamingText = built }
                    try? await Task.sleep(nanoseconds: 18_000_000)
                }

                guard !Task.isCancelled else { return }

                // Save the completed entry
                await MainActor.run {
                    let entry = HabitJourneyEntry(
                        habitId: habit.id,
                        habitTitle: habit.title,
                        date: Date(),
                        checkinNumber: checkinNumber,
                        storyText: fullText
                    )
                    modelContext.insert(entry)
                    try? modelContext.save()
                    newestEntryId = entry.id
                    streamingText = ""
                    isGenerating = false

                    // Spawn background image generation for each scene marker
                    let markers = HabitJourneyEntry.parse(fullText).compactMap { seg -> String? in
                        if case .imageMarker(let m) = seg { return m } else { return nil }
                    }
                    let savedEntry = entry
                    for marker in markers {
                        Task { await autoGenerateImage(for: savedEntry, marker: marker) }
                    }
                    // Pick divider style for this entry in background (displayed before next entry)
                    Task { await pickDividerStyle(for: savedEntry, storyText: fullText) }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    streamingText = ""
                }
            }
        }
    }

    private func buildStoryPrompt(checkinNumber: Int) -> String {
        let previousStory: String
        if habitEntries.isEmpty {
            previousStory = "(This is the very beginning of the quest. Begin the epic adventure — introduce the protagonist setting out on their legendary journey to seek the Grand Master of \(habit.title), who dwells in a mysterious realm beyond treacherous mountains, enchanted forests, and crystalline lakes.)"
        } else {
            previousStory = habitEntries.map { $0.storyText }.joined(separator: "\n\n")
        }

        let streakContext = habit.currentStreak > 1
            ? "After \(habit.currentStreak) days of treacherous travel, "
            : ""

        return """
        You are writing an epic fantasy adventure story. The protagonist is on a legendary quest to find the Grand Master of \(habit.title), who dwells in a mysterious realm beyond treacherous mountains, enchanted forests, and crystalline lakes.

        \(streakContext)the journey continues.

        Previous story:
        \(previousStory)

        Instructions:
        1. Write ONE passage (4–6 sentences) continuing the adventure seamlessly from where it left off.
        2. Describe vivid landscapes, creatures, challenges, discoveries, or dramatic moments.
        3. Continue any cliffhanger or atmosphere from the previous passage naturally.
        4. Embed 1–2 image scene placeholders using !snake_case_name format at vivid visual moments:
           - Place them WITHIN the narrative, between sentences or after a descriptive phrase
           - Never at the very start or end of the passage
           - Use descriptive, specific names: !misty_mountain_peak, !glowing_forest_canopy, !rushing_waterfall_mist
           - Choose moments where a reader would most want to SEE the scene
        5. NEVER write: "Day X", habit names, check-in numbers, "streak", "habit", "today you completed", or any meta-commentary.
        6. Write ONLY the story passage — no titles, no labels, no extra commentary.
        """
    }

    // MARK: - Divider Style Picker

    private func pickDividerStyle(for entry: HabitJourneyEntry, storyText: String) async {
        guard SystemLanguageModel.default.availability == .available else { return }
        let styleNames = JourneyDividerStyle.allCases.map { "\($0.rawValue): \($0.title)" }.joined(separator: ", ")
        let prompt = "Story passage: \"\(storyText.prefix(300))\"\n\nChoose the best matching divider style from: \(styleNames)\nReply with ONLY the rawValue (snake_case)."
        let session = LanguageModelSession()
        if let response = try? await session.respond(to: prompt) {
            let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if JourneyDividerStyle(rawValue: raw) != nil {
                await MainActor.run {
                    entry.dividerStyle = raw
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Background Image Generation

    private func autoGenerateImage(for entry: HabitJourneyEntry, marker: String) async {
        guard ImagePlaygroundViewController.isAvailable else { return }
        do {
            let creator = try await ImageCreator()
            let concepts: [ImagePlaygroundConcept] = [.text(marker.replacingOccurrences(of: "_", with: " "))]
            let style = creator.availableStyles.first ?? .illustration
            for try await image in creator.images(for: concepts, style: style, limit: 1) {
                let dest = entry.imageFilePath(for: marker)
                if let data = UIImage(cgImage: image.cgImage).pngData() {
                    try? data.write(to: dest)
                    await MainActor.run {
                        var paths = entry.imagePaths
                        paths[marker] = dest.path
                        entry.imagePaths = paths
                        try? modelContext.save()
                    }
                }
                break
            }
        } catch { /* silently fail */ }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.pages")
                .font(.system(size: 48))
                .foregroundStyle(themeManager.accentColor.opacity(0.7))

            Text("Your Journey Awaits")
                .font(.title3.weight(.semibold))

            Text("Complete this habit to start your story.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Past Entry View

private struct JourneyEntryView: View {
    let entry: HabitJourneyEntry
    let isHighlighted: Bool

    @State private var appeared = false

    var body: some View {
        // Story segments (text + inline images) — bare flowing text, no card
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(entry.segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let t):
                    Text(t)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                case .imageMarker(let marker):
                    ImageMarkerView(
                        marker: marker,
                        entry: entry,
                        savedURL: entry.savedImageURL(for: marker)
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Streaming Entry (live generation)

private struct StreamingEntryView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
                    .symbolEffect(.pulse, isActive: true)
                Text("Writing your story...")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
            }

            if text.isEmpty {
                TypingDotsView()
            } else {
                Text("\(text)▋")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TypingDotsView: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.35 : 1.0)
                    .opacity(phase == i ? 1.0 : 0.4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: phase)
            }
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}

// MARK: - Image Marker View

private struct ImageMarkerView: View {
    let marker: String
    let entry: HabitJourneyEntry
    let savedURL: URL?

    @State private var loadedImage: UIImage?

    var displayName: String {
        marker.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generating Scene")
                            .font(.subheadline.weight(.semibold))
                        Text(displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.purple.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .onAppear {
            // Skip if already loaded (prevents re-render flicker)
            if loadedImage != nil { return }

            // Check deterministic file path on disk first (more reliable than model dict)
            let diskURL = entry.imageFilePath(for: marker)
            if FileManager.default.fileExists(atPath: diskURL.path),
               let data = try? Data(contentsOf: diskURL) {
                loadedImage = UIImage(data: data)
                return
            }

            // Fall back to model's savedURL
            if let url = savedURL, let data = try? Data(contentsOf: url) {
                loadedImage = UIImage(data: data)
            }
        }
        .onChange(of: savedURL) {
            if loadedImage != nil { return }
            if let url = savedURL, let data = try? Data(contentsOf: url) {
                withAnimation(.easeIn(duration: 0.3)) {
                    loadedImage = UIImage(data: data)
                }
            }
        }
    }
}

// MARK: - Journey Divider Style

enum JourneyDividerStyle: String, CaseIterable {
    case mountain_pass
    case forest_path
    case river_crossing
    case starlit_night
    case ancient_gate
    case misty_fog
    case lightning_storm
    case underground_cave
    case desert_wind
    case enchanted_bridge
    case frozen_tundra
    case volcano_crossing

    var title: String {
        switch self {
        case .mountain_pass: return "Rocky Mountain Pass"
        case .forest_path: return "Ancient Forest Path"
        case .river_crossing: return "Rushing River Crossing"
        case .starlit_night: return "Starlit Night Sky"
        case .ancient_gate: return "Sacred Temple Gate"
        case .misty_fog: return "Misty Valley Fog"
        case .lightning_storm: return "Crashing Lightning Storm"
        case .underground_cave: return "Dark Underground Cave"
        case .desert_wind: return "Howling Desert Wind"
        case .enchanted_bridge: return "Glowing Enchanted Bridge"
        case .frozen_tundra: return "Endless Frozen Tundra"
        case .volcano_crossing: return "Fiery Volcano Crossing"
        }
    }

    var sfSymbol: String {
        switch self {
        case .mountain_pass: return "mountain.2.fill"
        case .forest_path: return "tree.fill"
        case .river_crossing: return "drop.fill"
        case .starlit_night: return "star.fill"
        case .ancient_gate: return "building.columns.fill"
        case .misty_fog: return "cloud.fill"
        case .lightning_storm: return "bolt.fill"
        case .underground_cave: return "circle.dotted"
        case .desert_wind: return "wind"
        case .enchanted_bridge: return "sparkles"
        case .frozen_tundra: return "snowflake"
        case .volcano_crossing: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .mountain_pass: return .gray
        case .forest_path: return .green
        case .river_crossing: return .blue
        case .starlit_night: return .indigo
        case .ancient_gate: return .brown
        case .misty_fog: return Color.secondary
        case .lightning_storm: return .yellow
        case .underground_cave: return .purple
        case .desert_wind: return .orange
        case .enchanted_bridge: return .cyan
        case .frozen_tundra: return .blue
        case .volcano_crossing: return .red
        }
    }

    static var defaultStyle: JourneyDividerStyle { .mountain_pass }
}

// MARK: - Journey Divider View

private struct JourneyDividerView: View {
    let style: JourneyDividerStyle

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Canvas { context, size in
                    let midY = size.height / 2
                    let centerX = size.width / 2
                    let badgeHalf: CGFloat = 16
                    let flareSize: CGFloat = 4.0
                    let diamondSpacing: CGFloat = 18
                    let diamondSize: CGFloat = 3.5
                    let dotSize: CGFloat = 1.8

                    let lineShading = GraphicsContext.Shading.color(Color.secondary.opacity(0.2))
                    let ornStroke = GraphicsContext.Shading.color(style.color.opacity(0.5))
                    let ornFill = GraphicsContext.Shading.color(style.color.opacity(0.45))

                    let leftEnd = centerX - badgeHalf - flareSize
                    let rightStart = centerX + badgeHalf + flareSize

                    // Baselines
                    var lLine = Path()
                    lLine.move(to: CGPoint(x: 0, y: midY))
                    lLine.addLine(to: CGPoint(x: leftEnd, y: midY))
                    var rLine = Path()
                    rLine.move(to: CGPoint(x: rightStart, y: midY))
                    rLine.addLine(to: CGPoint(x: size.width, y: midY))
                    context.stroke(lLine, with: lineShading, lineWidth: 0.5)
                    context.stroke(rLine, with: lineShading, lineWidth: 0.5)

                    // Flares at ends adjacent to badge
                    drawFlare(&context, at: CGPoint(x: leftEnd, y: midY), size: flareSize, shading: ornFill)
                    drawFlare(&context, at: CGPoint(x: rightStart, y: midY), size: flareSize, shading: ornFill)

                    // Left side diamonds + dots
                    var x: CGFloat = diamondSpacing / 2
                    var di = 0
                    while x < leftEnd - 6 {
                        let nearCenter = (leftEnd - x) < diamondSpacing * 2.5
                        let mult: CGFloat = nearCenter ? 1.4 : 1.0
                        drawDiamond(&context, at: CGPoint(x: x, y: midY), size: diamondSize * mult, shading: ornStroke)
                        if di > 0 {
                            drawDot(&context, at: CGPoint(x: x - diamondSpacing / 2, y: midY), size: dotSize, shading: ornFill)
                        }
                        x += diamondSpacing
                        di += 1
                    }

                    // Right side diamonds + dots (mirrored)
                    var rx: CGFloat = size.width - diamondSpacing / 2
                    var ri = 0
                    while rx > rightStart + 6 {
                        let nearCenter = (rx - rightStart) < diamondSpacing * 2.5
                        let mult: CGFloat = nearCenter ? 1.4 : 1.0
                        drawDiamond(&context, at: CGPoint(x: rx, y: midY), size: diamondSize * mult, shading: ornStroke)
                        if ri > 0 {
                            drawDot(&context, at: CGPoint(x: rx + diamondSpacing / 2, y: midY), size: dotSize, shading: ornFill)
                        }
                        rx -= diamondSpacing
                        ri += 1
                    }
                }
                .frame(height: 20)

                // Symbol badge
                Image(systemName: style.sfSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.color)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(style.color.opacity(0.3), lineWidth: 0.5))
            }

            Text(style.title)
                .font(.caption2)
                .italic()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func drawDiamond(_ ctx: inout GraphicsContext, at c: CGPoint, size: CGFloat, shading: GraphicsContext.Shading) {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - size))
        p.addLine(to: CGPoint(x: c.x + size, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y + size))
        p.addLine(to: CGPoint(x: c.x - size, y: c.y))
        p.closeSubpath()
        ctx.stroke(p, with: shading, lineWidth: 0.75)
    }

    private func drawDot(_ ctx: inout GraphicsContext, at c: CGPoint, size: CGFloat, shading: GraphicsContext.Shading) {
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - size / 2, y: c.y - size / 2, width: size, height: size)), with: shading)
    }

    private func drawFlare(_ ctx: inout GraphicsContext, at c: CGPoint, size: CGFloat, shading: GraphicsContext.Shading) {
        var h = Path()
        h.move(to: CGPoint(x: c.x - size, y: c.y))
        h.addLine(to: CGPoint(x: c.x + size, y: c.y))
        var v = Path()
        v.move(to: CGPoint(x: c.x, y: c.y - size * 0.6))
        v.addLine(to: CGPoint(x: c.x, y: c.y + size * 0.6))
        ctx.stroke(h, with: shading, lineWidth: 0.75)
        ctx.stroke(v, with: shading, lineWidth: 0.75)
    }
}
