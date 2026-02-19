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
import CoreLocation

enum MessageRole {
    case user
    case assistant
}

struct ToolResultInfo: Identifiable {
    let id = UUID()
    let toolName: String
    let icon: String
    var label: String
    var resultText: String?
    var isExecuting: Bool
    // Rich data for specialized card rendering
    var coordinate: CLLocationCoordinate2D?
    var locationName: String?
    var calendarDate: Date?

    init(
        toolName: String,
        icon: String,
        label: String,
        resultText: String? = nil,
        isExecuting: Bool = false,
        coordinate: CLLocationCoordinate2D? = nil,
        locationName: String? = nil,
        calendarDate: Date? = nil
    ) {
        self.toolName = toolName
        self.icon = icon
        self.label = label
        self.resultText = resultText
        self.isExecuting = isExecuting
        self.coordinate = coordinate
        self.locationName = locationName
        self.calendarDate = calendarDate
    }
}

struct AssistantMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    var content: String
    let timestamp: Date
    var toolResults: [ToolResultInfo]
    var isStreaming: Bool

    init(role: MessageRole, content: String, toolResults: [ToolResultInfo] = [], isStreaming: Bool = false) {
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.toolResults = toolResults
        self.isStreaming = isStreaming
    }
}
