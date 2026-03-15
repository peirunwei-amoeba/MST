//
//  UpdateUserProfileTool.swift
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
import FoundationModels
import Combine

struct UpdateUserProfileTool: Tool {
    let name = "updateUserProfile"
    let description = """
    Update a specific section of the user's profile with a new insight. \
    Use this immediately when the user shares personal information, preferences, learning patterns, or goals. \
    Update only ONE section per call. Do not announce that you are updating the profile.
    """

    @Generable
    struct Arguments {
        @Guide(description: "The profile section to update. Must be one of: 'about', 'learning_style', 'strengths', 'focus_areas', 'observations'")
        var field: String

        @Guide(description: "The new content for this section. Be concise, insightful, and write in third person (e.g. 'Studies at JC in Singapore...'). Max 2-3 sentences.")
        var content: String
    }

    var themeManager: ThemeManager
    var tracker: ToolCallTracker

    func call(arguments: Arguments) async throws -> String {
        tracker.startCall(name: name)

        let field = arguments.field.lowercased().trimmingCharacters(in: .whitespaces)
        let content = arguments.content.trimmingCharacters(in: .whitespacesAndNewlines)

        let headerMap: [String: String] = [
            "about": "## About",
            "learning_style": "## Learning Style",
            "strengths": "## Strengths",
            "focus_areas": "## Focus Areas",
            "observations": "## Observations"
        ]

        guard let header = headerMap[field] else {
            let result = "Unknown field '\(field)'. Use one of: about, learning_style, strengths, focus_areas, observations."
            tracker.record(name: name, result: result)
            return result
        }

        await MainActor.run {
            updateSection(header: header, content: content)
        }

        let result = "Updated \(field) profile section"
        tracker.record(name: name, result: result)
        return result
    }

    @MainActor
    private func updateSection(header: String, content: String) {
        var profile = themeManager.userProfileSummary

        if profile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile = "## About\n\n## Learning Style\n\n## Strengths\n\n## Focus Areas\n\n## Observations\n"
        }

        var lines = profile.components(separatedBy: "\n")
        var newLines: [String] = []
        var inTarget = false
        var inserted = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == header {
                inTarget = true
                newLines.append(line)
                newLines.append(content)
                inserted = true
            } else if trimmed.hasPrefix("## ") && inTarget {
                inTarget = false
                newLines.append(line)
            } else if !inTarget {
                newLines.append(line)
            }
            // Lines belonging to the replaced section are dropped
        }

        if !inserted {
            newLines.append("")
            newLines.append(header)
            newLines.append(content)
        }

        themeManager.userProfileSummary = newLines.joined(separator: "\n")
        themeManager.objectWillChange.send()
    }
}
