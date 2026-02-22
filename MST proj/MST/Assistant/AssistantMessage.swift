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

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct ToolResultInfo: Identifiable, Codable {
    let id: UUID
    let toolName: String
    let icon: String
    var label: String
    var resultText: String?
    var isExecuting: Bool
    // Rich data for specialized card rendering
    var coordinate: CLLocationCoordinate2D?
    var locationName: String?
    var calendarDate: Date?

    // Custom Codable to handle CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, toolName, icon, label, resultText, isExecuting
        case latitude, longitude, locationName, calendarDate
    }

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
        self.id = UUID()
        self.toolName = toolName
        self.icon = icon
        self.label = label
        self.resultText = resultText
        self.isExecuting = isExecuting
        self.coordinate = coordinate
        self.locationName = locationName
        self.calendarDate = calendarDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.toolName = try container.decode(String.self, forKey: .toolName)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.label = try container.decode(String.self, forKey: .label)
        self.resultText = try container.decodeIfPresent(String.self, forKey: .resultText)
        self.isExecuting = false // Always mark as not-executing when loading from persistence
        if let lat = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let lon = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            self.coordinate = nil
        }
        self.locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        self.calendarDate = try container.decodeIfPresent(Date.self, forKey: .calendarDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(toolName, forKey: .toolName)
        try container.encode(icon, forKey: .icon)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(resultText, forKey: .resultText)
        try container.encode(false, forKey: .isExecuting) // Never save as executing
        if let coord = coordinate {
            try container.encode(coord.latitude, forKey: .latitude)
            try container.encode(coord.longitude, forKey: .longitude)
        }
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encodeIfPresent(calendarDate, forKey: .calendarDate)
    }
}

struct AssistantMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var toolResults: [ToolResultInfo]
    var isStreaming: Bool

    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, toolResults
    }

    init(role: MessageRole, content: String, toolResults: [ToolResultInfo] = [], isStreaming: Bool = false) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.toolResults = toolResults
        self.isStreaming = isStreaming
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.role = try container.decode(MessageRole.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
        self.timestamp = (try? container.decode(Date.self, forKey: .timestamp)) ?? Date()
        self.toolResults = (try? container.decode([ToolResultInfo].self, forKey: .toolResults)) ?? []
        self.isStreaming = false // Never restore as streaming
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(toolResults, forKey: .toolResults)
    }
}
