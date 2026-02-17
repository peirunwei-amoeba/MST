//
//  AssistantMessage.swift
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

import Foundation

enum MessageRole {
    case user
    case assistant
}

struct ToolResultInfo: Identifiable {
    let id = UUID()
    let toolName: String
    let icon: String
    let label: String
    var resultText: String?
    var isExecuting: Bool
}

struct AssistantMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    var content: String
    let timestamp: Date
    var toolResults: [ToolResultInfo]

    init(role: MessageRole, content: String, toolResults: [ToolResultInfo] = []) {
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.toolResults = toolResults
    }
}
