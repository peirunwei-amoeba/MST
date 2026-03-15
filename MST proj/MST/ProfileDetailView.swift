//
//  ProfileDetailView.swift
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

struct ProfileDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private struct ProfileSection: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let content: String
    }

    private var sections: [ProfileSection] {
        let raw = themeManager.userProfileSummary
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let sectionDefs: [(header: String, title: String, icon: String)] = [
            ("## About", "About", "person.fill"),
            ("## Learning Style", "Learning Style", "brain.fill"),
            ("## Strengths", "Strengths", "star.fill"),
            ("## Focus Areas", "Focus Areas", "target"),
            ("## Observations", "Observations", "eye.fill")
        ]

        var result: [ProfileSection] = []
        let lines = raw.components(separatedBy: "\n")
        var currentHeader: String? = nil
        var currentLines: [String] = []

        func flush() {
            guard let header = currentHeader else { return }
            let content = currentLines
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            if let def = sectionDefs.first(where: { $0.header == header }) {
                result.append(ProfileSection(title: def.title, icon: def.icon, content: content))
            }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("## ") {
                flush()
                currentHeader = trimmed
                currentLines = []
            } else {
                currentLines.append(line)
            }
        }
        flush()

        return result
    }

    var body: some View {
        List {
            if sections.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 6) {
                            Text("No profile yet")
                                .font(.headline)
                            Text("Chat with the AI assistant to build your profile. Share your goals, study habits, or interests and the AI will learn about you.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                ForEach(sections) { section in
                    Section {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.accentColor.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: section.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(themeManager.accentColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                if section.content.isEmpty {
                                    Text("Not yet filled in — chat with the AI to add insights here.")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                } else {
                                    Text(section.content)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("AI Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
    .environmentObject(ThemeManager())
}
