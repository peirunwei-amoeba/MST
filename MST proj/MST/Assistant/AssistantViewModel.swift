//
//  AssistantViewModel.swift
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
import CoreLocation
import FoundationModels

// Thread-safe tracker for tool call activity with real-time callbacks
final class ToolCallTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(name: String, result: String)] = []

    // Callbacks set on MainActor before session.respond(); called via DispatchQueue.main
    var onCallStarted: ((String) -> Void)?
    var onCallCompleted: ((String, String) -> Void)?

    var calls: [(name: String, result: String)] {
        lock.withLock { _calls }
    }

    func startCall(name: String) {
        let cb = onCallStarted
        DispatchQueue.main.async { cb?(name) }
    }

    func record(name: String, result: String) {
        lock.withLock { _calls.append((name, result)) }
        let cb = onCallCompleted
        DispatchQueue.main.async { cb?(name, result) }
    }

    func clear() {
        lock.withLock { _calls.removeAll() }
    }
}

@Observable @MainActor
final class AssistantViewModel {
    var messages: [AssistantMessage] = []
    var inputText = ""
    var isGenerating = false

    private var session: LanguageModelSession?
    private let modelContext: ModelContext
    private let pointsManager: PointsManager
    private let focusTimerBridge: FocusTimerBridge
    private let themeManager: ThemeManager
    let tracker = ToolCallTracker()
    private var messageCount = 0
    private var streamingTask: Task<Void, Never>?

    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    init(modelContext: ModelContext, pointsManager: PointsManager, focusTimerBridge: FocusTimerBridge, themeManager: ThemeManager) {
        self.modelContext = modelContext
        self.pointsManager = pointsManager
        self.focusTimerBridge = focusTimerBridge
        self.themeManager = themeManager
        createSession()
    }

    private var systemInstructions: String {
        let agentName = themeManager.assistantName.isEmpty ? "Spark" : themeManager.assistantName
        let userName = themeManager.userName.isEmpty ? "the user" : themeManager.userName
        return """
        You are \(agentName), a friendly and concise productivity assistant for \(userName) in the MST app. \
        You help manage assignments, projects, and habits. \
        Keep responses concise and structured — use markdown formatting: **bold**, *italic*, `code`, bullet lists, headers.

        CRITICAL RULES — you MUST follow these every single time:
        1. NEVER state, list, or reference any assignments, habits, projects, or goals WITHOUT first calling the appropriate tool (getAssignments, getHabits, getProjects, getUpcomingSummary). If you haven't called the tool yet, call it NOW before responding. No exceptions.
        2. ALWAYS call getCurrentDate before creating or editing any item with a date.
        3. NEVER assume or hallucinate what the user has. Only reference data you received from tools.
        4. When asked about tasks, schedule, or progress, call the relevant tool immediately.
        5. When asked to create or complete items, use the write tools, then confirm what was done.

        Be encouraging about streaks and progress. \
        If asked about weather or location, use those tools. \
        For focus timer, use startFocusTimer. \
        Format responses clearly with markdown so headings, bold, bullets, and code are all visually distinct.
        """
    }

    private func createSession() {
        guard isAvailable else { return }

        let tools: [any Tool] = [
            GetCurrentDateTool(tracker: tracker),
            GetAssignmentsTool(modelContext: modelContext, tracker: tracker),
            GetProjectsTool(modelContext: modelContext, tracker: tracker),
            GetHabitsTool(modelContext: modelContext, tracker: tracker),
            GetUpcomingSummaryTool(modelContext: modelContext, tracker: tracker),
            CreateAssignmentTool(modelContext: modelContext, tracker: tracker),
            CreateProjectTool(modelContext: modelContext, tracker: tracker),
            CompleteAssignmentTool(modelContext: modelContext, pointsManager: pointsManager, tracker: tracker),
            CompleteHabitTodayTool(modelContext: modelContext, pointsManager: pointsManager, tracker: tracker),
            StartFocusTimerTool(focusTimerBridge: focusTimerBridge, tracker: tracker),
            GetWeatherTool(tracker: tracker),
            GetLocationTool(tracker: tracker)
        ]

        session = LanguageModelSession(tools: tools) {
            self.systemInstructions
        }
        messageCount = 0
    }

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating else { return }

        messages.append(AssistantMessage(role: .user, content: trimmed))
        inputText = ""
        isGenerating = true
        tracker.clear()
        messageCount += 1

        if messageCount > 8 { createSession() }

        guard let session else {
            messages.append(AssistantMessage(role: .assistant, content: "Apple Intelligence is not available on this device."))
            isGenerating = false
            return
        }

        // Add streaming placeholder message
        let streamingMsg = AssistantMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(streamingMsg)
        let msgId = streamingMsg.id

        // Wire up real-time tool card callbacks
        tracker.onCallStarted = { [weak self] name in
            guard let self else { return }
            let info = self.toolInfoFor(name)
            let card = ToolResultInfo(
                toolName: name,
                icon: info.icon,
                label: info.label,
                resultText: nil,
                isExecuting: true
            )
            if let idx = self.messages.firstIndex(where: { $0.id == msgId }) {
                self.messages[idx].toolResults.append(card)
            }
        }

        tracker.onCallCompleted = { [weak self] name, result in
            guard let self,
                  let msgIdx = self.messages.firstIndex(where: { $0.id == msgId }),
                  let cardIdx = self.messages[msgIdx].toolResults.firstIndex(where: { $0.toolName == name && $0.isExecuting })
            else { return }

            self.messages[msgIdx].toolResults[cardIdx].isExecuting = false
            self.messages[msgIdx].toolResults[cardIdx].resultText = result
            self.messages[msgIdx].toolResults[cardIdx].label = self.toolInfoFor(name).label

            // Enrich location cards with map data
            if name == "getLocation" {
                if let (coord, placeName) = self.parseCoordinates(from: result) {
                    self.messages[msgIdx].toolResults[cardIdx].coordinate = coord
                    self.messages[msgIdx].toolResults[cardIdx].locationName = placeName
                }
            }
            // Enrich date cards
            if name == "getCurrentDate" {
                self.messages[msgIdx].toolResults[cardIdx].calendarDate = Date()
            }
        }

        do {
            let response = try await session.respond(to: trimmed)

            // Animate text word-by-word for streaming feel
            if let msgIdx = messages.firstIndex(where: { $0.id == msgId }) {
                await streamText(response.content, into: msgIdx)
                messages[msgIdx].isStreaming = false
            }
        } catch {
            if let msgIdx = messages.firstIndex(where: { $0.id == msgId }) {
                messages[msgIdx].content = "Sorry, I ran into an issue. Please try again."
                messages[msgIdx].isStreaming = false
            }
        }

        tracker.onCallStarted = nil
        tracker.onCallCompleted = nil
        isGenerating = false
    }

    private func streamText(_ text: String, into idx: Int) async {
        let words = text.components(separatedBy: " ")
        var accumulated = ""
        // Speed: fast for long responses, slower for short
        let delay: UInt64 = words.count > 120 ? 8_000_000 : (words.count > 50 ? 15_000_000 : 22_000_000)
        for word in words {
            guard !Task.isCancelled else { break }
            accumulated += (accumulated.isEmpty ? "" : " ") + word
            messages[idx].content = accumulated
            try? await Task.sleep(nanoseconds: delay)
        }
    }

    func clearConversation() {
        messages.removeAll()
        createSession()
    }

    // MARK: - Coordinate parsing

    private func parseCoordinates(from result: String) -> (CLLocationCoordinate2D, String?)? {
        guard let openParen = result.lastIndex(of: "("),
              let closeParen = result.lastIndex(of: ")") else { return nil }
        let inner = result[result.index(after: openParen)..<closeParen]
        let parts = inner.split(separator: ",")
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces))
        else { return nil }
        let name = result.components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (CLLocationCoordinate2D(latitude: lat, longitude: lon), name)
    }

    // MARK: - Tool metadata

    func toolInfoFor(_ name: String) -> (icon: String, label: String) {
        switch name {
        case "getAssignments":
            return ("book.fill", "Fetched assignments")
        case "getProjects":
            return ("folder.fill", "Fetched projects")
        case "getHabits":
            return ("flame.fill", "Fetched habits")
        case "getUpcomingSummary":
            return ("list.bullet.clipboard.fill", "Got summary")
        case "createAssignment":
            return ("plus.circle.fill", "Created assignment")
        case "createProject":
            return ("plus.circle.fill", "Created project")
        case "completeAssignment":
            return ("checkmark.circle.fill", "Completed assignment")
        case "completeHabitToday":
            return ("checkmark.circle.fill", "Completed habit")
        case "startFocusTimer":
            return ("timer", "Set focus timer")
        case "getCurrentDate":
            return ("calendar", "Got date & time")
        case "getWeather":
            return ("cloud.sun.fill", "Fetched weather")
        case "getLocation":
            return ("location.fill", "Got location")
        default:
            return ("gearshape.fill", "Processed")
        }
    }
}
