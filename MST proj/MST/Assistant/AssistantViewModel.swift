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
import FoundationModels

// Thread-safe tracker for tool call activity
final class ToolCallTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(name: String, result: String)] = []

    var calls: [(name: String, result: String)] {
        lock.lock()
        defer { lock.unlock() }
        return _calls
    }

    func record(name: String, result: String) {
        lock.lock()
        _calls.append((name, result))
        lock.unlock()
    }

    func clear() {
        lock.lock()
        _calls.removeAll()
        lock.unlock()
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
    private let tracker = ToolCallTracker()
    private var messageCount = 0

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
        Keep responses short (2-3 sentences max unless listing items). \
        Use the available tools to read and modify the user's data. \
        When the user asks about their tasks, assignments, or what's due, use the appropriate tool. \
        When asked to create or complete items, use the write tools. \
        Always confirm actions taken. Be encouraging about streaks and progress. \
        If the user asks about weather, location, or health, use those tools. \
        For focus timer requests, use the startFocusTimer tool. \
        Today's date can be fetched with getCurrentDate. \
        Do not make up data — always use tools to get real information.
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
            GetLocationTool(tracker: tracker),
            GetHealthDataTool(tracker: tracker)
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

        // Recreate session if context is getting long
        if messageCount > 8 {
            createSession()
        }

        guard let session else {
            messages.append(AssistantMessage(role: .assistant, content: "Apple Intelligence is not available on this device."))
            isGenerating = false
            return
        }

        do {
            let response = try await session.respond(to: trimmed)

            // Build tool result cards from tracker
            let toolResults = tracker.calls.map { call in
                let info = toolInfoFor(call.name)
                return ToolResultInfo(
                    toolName: call.name,
                    icon: info.icon,
                    label: info.label,
                    resultText: call.result,
                    isExecuting: false
                )
            }

            messages.append(AssistantMessage(
                role: .assistant,
                content: response.content,
                toolResults: toolResults
            ))
        } catch {
            messages.append(AssistantMessage(
                role: .assistant,
                content: "Sorry, I encountered an error. Please try again."
            ))
        }

        isGenerating = false
    }

    func clearConversation() {
        messages.removeAll()
        createSession()
    }

    private func toolInfoFor(_ name: String) -> (icon: String, label: String) {
        switch name {
        case "getAssignments":
            return ("book.fill", "Fetched assignments")
        case "getProjects":
            return ("folder.fill", "Fetched projects")
        case "getHabits":
            return ("flame.fill", "Fetched habits")
        case "getUpcomingSummary":
            return ("list.bullet.clipboard", "Got summary")
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
            return ("calendar", "Got date")
        case "getWeather":
            return ("cloud.sun.fill", "Fetched weather")
        case "getLocation":
            return ("location.fill", "Got location")
        case "getHealthData":
            return ("heart.fill", "Read health data")
        default:
            return ("gearshape.fill", "Processed")
        }
    }
}
