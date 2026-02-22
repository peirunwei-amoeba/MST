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
import SwiftData
import FoundationModels
import ImagePlayground

// MARK: - Main Journey View

struct HabitJourneyView: View {
    let habit: Habit
    /// Pass `true` when opening from a just-completed check-in so the view auto-generates.
    var startGenerating: Bool = false

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var habitEntries: [HabitJourneyEntry]

    @State private var isGenerating = false
    @State private var streamingText = ""
    @State private var generationTask: Task<Void, Never>?

    // Image Playground state
    @State private var pendingImageMarker: String?
    @State private var pendingEntryId: UUID?
    @State private var showImagePlayground = false

    // Highlight the newest entry (just generated)
    @State private var newestEntryId: UUID?

    init(habit: Habit, startGenerating: Bool = false) {
        self.habit = habit
        self.startGenerating = startGenerating
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
                        LazyVStack(alignment: .leading, spacing: 24) {
                            // Past entries
                            ForEach(habitEntries) { entry in
                                JourneyEntryView(
                                    entry: entry,
                                    isHighlighted: entry.id == newestEntryId,
                                    onGenerateImage: { marker in
                                        pendingImageMarker = marker
                                        pendingEntryId = entry.id
                                        showImagePlayground = true
                                    }
                                )
                                .id(entry.id)
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
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.88),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
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

                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Day \(habit.completedDaysCount) of \(habit.maxCompletionDays)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .imagePlaygroundSheet(
            isPresented: $showImagePlayground,
            concepts: imageConcepts,
            onCompletion: { url in
                if let marker = pendingImageMarker, let entryId = pendingEntryId {
                    saveGeneratedImage(url: url, marker: marker, entryId: entryId)
                }
                pendingImageMarker = nil
                pendingEntryId = nil
            },
            onCancellation: {
                pendingImageMarker = nil
                pendingEntryId = nil
            }
        )
        .onAppear {
            if startGenerating {
                startStoryGeneration()
            }
        }
        .onDisappear {
            generationTask?.cancel()
        }
    }

    // MARK: - Image Playground concepts

    private var imageConcepts: [ImagePlaygroundConcept] {
        guard let marker = pendingImageMarker else { return [] }
        let description = marker.replacingOccurrences(of: "_", with: " ")
        return [.text(description)]
    }

    // MARK: - Save generated image

    private func saveGeneratedImage(url: URL, marker: String, entryId: UUID) {
        if let entry = habitEntries.first(where: { $0.id == entryId }) {
            entry.saveImage(at: url, for: marker)
            try? modelContext.save()
        }
    }

    // MARK: - Story Generation

    func startStoryGeneration() {
        guard !isGenerating else { return }
        guard SystemLanguageModel.default.availability == .available else { return }

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
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let timeOfDay = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"
        let dayOfWeek = calendar.weekdaySymbols[calendar.component(.weekday, from: Date()) - 1]

        let habitContext = habit.habitDescription.isEmpty
            ? "'\(habit.title)'"
            : "'\(habit.title)' (\(habit.habitDescription))"

        let streakContext = habit.currentStreak > 1
            ? " They are on a \(habit.currentStreak)-day streak."
            : ""

        let previousStory: String
        if habitEntries.isEmpty {
            previousStory = "(This is the very first check-in. Start an inspiring new story.)"
        } else {
            let last3 = habitEntries.suffix(3).map { "Day \($0.checkinNumber): \($0.storyText)" }.joined(separator: "\n\n")
            previousStory = last3
        }

        return """
        You are writing a vivid, emotionally resonant personal journal story about someone's journey with their \(habitContext) habit.

        Context:
        - This is check-in #\(checkinNumber)
        - It is \(dayOfWeek) \(timeOfDay)\(streakContext)
        - Total days completed: \(habit.completedDaysCount)

        Previous story entries:
        \(previousStory)

        Instructions:
        1. Write ONE paragraph (4–6 sentences) continuing this journey from the previous entries.
        2. Include vivid sensory details, emotions, challenges, and moments of growth.
        3. Make it personal and inspiring. Reference the streak and progress naturally.
        4. At EXACTLY ONE natural point in the narrative, embed an image scene placeholder using the format: !word_word_word
           (2–4 descriptive words joined by underscores, no spaces, no special characters, lowercase only)
           Example: !morning_mist_over_lake or !determined_runner_sunrise
        5. The placeholder should describe a visual scene that perfectly captures that story moment.
        6. Write ONLY the paragraph — no titles, no labels, no extra commentary.
        """
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
    let onGenerateImage: (String) -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Entry header
            HStack {
                Label("Day \(entry.checkinNumber)", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)

                Spacer()

                Text(relativeDate(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Story segments (text + inline images)
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
                            savedURL: entry.savedImageURL(for: marker),
                            onGenerate: { onGenerateImage(marker) }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.orange.opacity(0.5), lineWidth: 1.5)
                    }
                }
                .shadow(color: .black.opacity(isHighlighted ? 0.08 : 0.04), radius: isHighlighted ? 12 : 6)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
                (Text(text) + Text("▋").foregroundColor(.secondary))
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.purple.opacity(0.3), lineWidth: 1)
                )
        }
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
    let savedURL: URL?
    let onGenerate: () -> Void

    @State private var loadedImage: UIImage?
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

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
                Button(action: onGenerate) {
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 18))
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Generate Scene")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if supportsImagePlayground {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not available")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.purple.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!supportsImagePlayground)
            }
        }
        .onAppear {
            if let url = savedURL, let data = try? Data(contentsOf: url) {
                loadedImage = UIImage(data: data)
            }
        }
        .onChange(of: savedURL) {
            if let url = savedURL, let data = try? Data(contentsOf: url) {
                withAnimation(.easeIn(duration: 0.3)) {
                    loadedImage = UIImage(data: data)
                }
            }
        }
    }
}
