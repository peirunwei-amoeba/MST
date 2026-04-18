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
import Combine

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

    private var profileWasUpdatedInSession = false

    init(modelContext: ModelContext, pointsManager: PointsManager, focusTimerBridge: FocusTimerBridge, themeManager: ThemeManager) {
        self.modelContext = modelContext
        self.pointsManager = pointsManager
        self.focusTimerBridge = focusTimerBridge
        self.themeManager = themeManager
        loadConversationHistory()
        createSession()
        seedProfileFromSwiftData()
    }

    // MARK: - Multi-Chat Persistence

    private static let chatSessionsKey = "chatSessionsV2"
    private static let activeChatKey = "activeChatIdV2"
    private static let maxSavedMessages = 60
    private static let maxChats = 30

    private(set) var currentChatId: UUID = UUID()
    private(set) var allChatSessions: [ChatSession] = []

    private func loadConversationHistory() {
        allChatSessions = Self.loadAllChats()

        // Restore last active chat id
        if let idStr = UserDefaults.standard.string(forKey: Self.activeChatKey),
           let id = UUID(uuidString: idStr),
           let session = allChatSessions.first(where: { $0.id == id }) {
            currentChatId = id
            messages = session.messages
        } else if let latest = allChatSessions.first {
            // Fall back to most-recent chat
            currentChatId = latest.id
            messages = latest.messages
        }
        // Otherwise start fresh with empty messages
    }

    static func loadAllChats() -> [ChatSession] {
        guard let data = UserDefaults.standard.data(forKey: chatSessionsKey),
              let sessions = try? JSONDecoder().decode([ChatSession].self, from: data)
        else { return [] }
        return sessions
    }

    func saveConversationHistory() {
        let trimmed = Array(messages.filter { !$0.isStreaming }.suffix(Self.maxSavedMessages))
        let existingAiTitle = allChatSessions.first(where: { $0.id == currentChatId })?.aiTitle
        let session = ChatSession(id: currentChatId, createdDate: Date(), messages: trimmed, aiTitle: existingAiTitle)

        if let idx = allChatSessions.firstIndex(where: { $0.id == currentChatId }) {
            allChatSessions[idx] = session
        } else {
            allChatSessions.insert(session, at: 0)
        }
        allChatSessions = Array(allChatSessions.prefix(Self.maxChats))

        if let data = try? JSONEncoder().encode(allChatSessions) {
            UserDefaults.standard.set(data, forKey: Self.chatSessionsKey)
        }
        UserDefaults.standard.set(currentChatId.uuidString, forKey: Self.activeChatKey)
        generateChatTitle(for: currentChatId)
    }

    func newChat() {
        if !messages.isEmpty { saveConversationHistory() }
        currentChatId = UUID()
        messages = []
        createSession()
    }

    func loadChat(_ session: ChatSession) {
        if !messages.isEmpty { saveConversationHistory() }
        currentChatId = session.id
        messages = session.messages
        createSession()
        UserDefaults.standard.set(currentChatId.uuidString, forKey: Self.activeChatKey)
    }

    func deleteChat(id: UUID) {
        allChatSessions.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(allChatSessions) {
            UserDefaults.standard.set(data, forKey: Self.chatSessionsKey)
        }
        if id == currentChatId {
            currentChatId = UUID()
            messages = []
            createSession()
        }
    }

    private var systemInstructions: String {
        let agentName = themeManager.assistantName.isEmpty ? "Spark" : themeManager.assistantName
        let userName = themeManager.userName.isEmpty ? "the user" : themeManager.userName
        var base = """
        You are \(agentName), a friendly and concise productivity assistant for \(userName) in the MST app. \
        You help manage assignments, projects, and habits. \
        Keep responses concise and structured — use markdown formatting: **bold**, *italic*, `code`, bullet lists, headers.

        CRITICAL RULES — you MUST follow these every single time:
        1. NEVER state, list, or reference any assignments, habits, projects, or goals WITHOUT first calling the appropriate tool (getAssignments, getHabits, getProjects, getUpcomingSummary). If you haven't called the tool yet, call it NOW before responding. No exceptions.
        2. ALWAYS call getCurrentDate before creating or editing any item with a date.
        3. NEVER assume or hallucinate what the user has. Only reference data you received from tools.
        4. When asked about tasks, schedule, or progress, call the relevant tool immediately.
        5. When asked to create or complete items, use the write tools, then confirm what was done.
        6. ONLY use pauseHabitToday for outdoor or physical activity habits (running, cycling, hiking, sports). NEVER suggest pausing study, reading, or work habits. Only pause if the user explicitly says they cannot do an outdoor activity today.
        7. At the start of each new conversation, call getUserSummary to recall what you know about this user.
        8. When the user shares personal information (name, age, school, interests, struggles, goals), IMMEDIATELY call updateUserProfile with the relevant section BEFORE responding.
        9. NEVER replace the entire profile — only update one section at a time using updateUserProfile.
        10. Update the profile incrementally — one insight per call, the most important one first.
        11. After updating the profile, continue the conversation naturally without mentioning the update.

        Be encouraging about streaks and progress. \
        If asked about weather or location, use those tools. \
        For focus timer, use startFocusTimer. \
        When the user asks to change a setting (theme, name, alarm, focus goal, etc.), use updateAppSetting immediately. \
        Format responses clearly with markdown so headings, bold, bullets, and code are all visually distinct.
        \(themeManager.userProfileSummary.isEmpty ? "" : "\nUser profile:\n\(themeManager.userProfileSummary)")
        """
        if !messages.isEmpty {
            let history = messages.suffix(40)
                .map { "\($0.role == .user ? "User" : "Assistant"): \($0.content)" }
                .joined(separator: "\n")
            base += "\n\nPrevious conversation context (already happened — do NOT repeat greetings):\n\(history)"
        }
        return base
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
            PauseHabitTodayTool(modelContext: modelContext, tracker: tracker),
            StartFocusTimerTool(focusTimerBridge: focusTimerBridge, tracker: tracker),
            GetWeatherTool(tracker: tracker),
            GetLocationTool(tracker: tracker),
            GetUserSummaryTool(themeManager: themeManager, tracker: tracker),
            UpdateUserProfileTool(themeManager: themeManager, tracker: tracker),
            UpdateAppSettingsTool(themeManager: themeManager, tracker: tracker)
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

        // Detect if profile was updated this turn
        if tracker.calls.contains(where: { $0.name == "updateUserProfile" }) {
            profileWasUpdatedInSession = true
        }

        isGenerating = false
        saveConversationHistory()
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

    // MARK: - Chat Title Generation

    private func generateChatTitle(for chatId: UUID) {
        guard isAvailable else { return }
        guard let idx = allChatSessions.firstIndex(where: { $0.id == chatId }) else { return }
        guard allChatSessions[idx].aiTitle == nil else { return }
        let userMessages = allChatSessions[idx].messages.filter { $0.role == .user }
        guard userMessages.count >= 2 else { return }

        let transcript = allChatSessions[idx].messages.suffix(20)
            .map { "\($0.role == .user ? "User" : "Assistant"): \($0.content)" }
            .joined(separator: "\n")

        Task {
            do {
                let titleSession = LanguageModelSession()
                let prompt = """
                Summarize this conversation in 4-6 words as a chat title. No quotes, no punctuation at end. Just the title.

                \(transcript)
                """
                let response = try await titleSession.respond(to: prompt)
                let title = String(response.content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
                await MainActor.run {
                    guard let i = self.allChatSessions.firstIndex(where: { $0.id == chatId }) else { return }
                    self.allChatSessions[i].aiTitle = title
                    if let data = try? JSONEncoder().encode(self.allChatSessions) {
                        UserDefaults.standard.set(data, forKey: Self.chatSessionsKey)
                    }
                }
            } catch { /* silently fail */ }
        }
    }

    // MARK: - Conversation Summary

    func generateConversationSummary() {
        guard isAvailable else { return }
        // Don't overwrite structured profile if it was updated via tool this session
        guard !profileWasUpdatedInSession else { return }
        let userMessages = messages.filter { $0.role == .user }
        guard userMessages.count >= 4 else { return }

        let recentMessages = messages.suffix(20).map { "\($0.role == .user ? "User" : "Assistant"): \($0.content)" }.joined(separator: "\n")
        let existingSummary = themeManager.userProfileSummary

        Task {
            do {
                let summarySession = LanguageModelSession()
                let prompt = """
                Based on the following conversation between a user and their productivity assistant, \
                create a concise 3-5 sentence profile summary of the user. \
                Cover their focus areas, strengths, areas for improvement, and any patterns you notice.

                \(existingSummary.isEmpty ? "" : "Existing profile summary (update and refine this):\n\(existingSummary)\n\n")Current conversation:
                \(recentMessages)

                Write ONLY the summary — no titles, labels, or extra commentary.
                """
                let response = try await summarySession.respond(to: prompt)
                let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    themeManager.userProfileSummary = summary
                    themeManager.objectWillChange.send()
                }
            } catch { /* silently fail */ }
        }
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
        case "pauseHabitToday":
            return ("pause.circle.fill", "Paused habit for today")
        case "startFocusTimer":
            return ("timer", "Set focus timer")
        case "getCurrentDate":
            return ("calendar", "Got date & time")
        case "getWeather":
            return ("cloud.sun.fill", "Fetched weather")
        case "getLocation":
            return ("location.fill", "Got location")
        case "getUserSummary":
            return ("person.text.rectangle.fill", "Got user profile")
        case "updateUserProfile":
            return ("person.badge.plus.fill", "Updated user profile")
        case "updateAppSetting":
            return ("gearshape.fill", "Updated setting")
        default:
            return ("gearshape.fill", "Processed")
        }
    }

    // MARK: - Profile Seeding

    private func seedProfileFromSwiftData() {
        guard themeManager.userProfileSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let profile = try? modelContext.fetch(FetchDescriptor<UserProfileData>()).first else { return }

        var parts: [String] = []
        if !profile.name.isEmpty { parts.append(profile.name) }

        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: profile.birthday, to: Date()).year ?? 0
        if age > 5 && age < 100 { parts.append("\(age) years old") }

        if !profile.gradeLevel.isEmpty { parts.append(profile.gradeLevel) }
        if !profile.educationSystem.isEmpty { parts.append("studying under \(profile.educationSystem) system") }

        let aboutContent = parts.isEmpty ? "" : parts.joined(separator: ", ") + "."
        let interestStr = profile.interests.isEmpty ? "" : "Interested in: \(profile.interests.joined(separator: ", "))."

        var seedSummary = "## About\n"
        seedSummary += aboutContent + (interestStr.isEmpty ? "" : " " + interestStr)
        seedSummary += "\n\n## Learning Style\n\n## Strengths\n\n## Focus Areas\n\n## Observations\n"

        themeManager.userProfileSummary = seedSummary
    }
}
