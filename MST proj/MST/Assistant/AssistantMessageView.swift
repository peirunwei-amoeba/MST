//
//  AssistantMessageView.swift
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
import Combine

// MARK: - Full Markdown Renderer

struct MarkdownContentView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
    }

    private enum MarkdownBlock {
        case heading(String, level: Int)
        case paragraph(String)
        case bulletItem(String)
        case numberedItem(String, number: Int)
        case codeBlock(String, language: String?)
        case divider
    }

    private var parsedBlocks: [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var lines = content.components(separatedBy: "\n")
        var i = 0
        var numberedIndex = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block
            if trimmed.hasPrefix("```") {
                let lang = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                i += 1
                var codeLines: [String] = []
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(codeLines.joined(separator: "\n"), language: lang.isEmpty ? nil : lang))
                i += 1
                continue
            }

            // Heading
            if trimmed.hasPrefix("### ") {
                blocks.append(.heading(String(trimmed.dropFirst(4)), level: 3))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(.heading(String(trimmed.dropFirst(3)), level: 2))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(.heading(String(trimmed.dropFirst(2)), level: 1))
            }
            // Horizontal rule
            else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                blocks.append(.divider)
            }
            // Bullet
            else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                numberedIndex = 0
                let text = String(trimmed.dropFirst(2))
                blocks.append(.bulletItem(text))
            }
            // Numbered list
            else if let match = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                numberedIndex += 1
                let text = String(trimmed[match.upperBound...])
                blocks.append(.numberedItem(text, number: numberedIndex))
            }
            // Empty line — do NOT reset numberedIndex so blank lines inside a list keep counting
            else if trimmed.isEmpty {
                // intentionally left blank
            }
            // Normal paragraph — resets numbered list context
            else if !trimmed.isEmpty {
                numberedIndex = 0
                blocks.append(.paragraph(trimmed))
            }

            i += 1
        }
        return blocks
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let text, let level):
            inlineMarkdown(text)
                .font(level == 1 ? .title2.bold() : level == 2 ? .title3.bold() : .headline)
                .foregroundStyle(.primary)
                .padding(.top, level <= 2 ? 4 : 2)

        case .paragraph(let text):
            inlineMarkdown(text)
                .font(.body)
                .foregroundStyle(.primary)

        case .bulletItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                    .foregroundStyle(.secondary)
                inlineMarkdown(text)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

        case .numberedItem(let text, let number):
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 20, alignment: .trailing)
                inlineMarkdown(text)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

        case .codeBlock(let code, _):
            Text(code)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

        case .divider:
            Divider().opacity(0.3)
        }
    }

    private func inlineMarkdown(_ text: String) -> Text {
        // Parse inline markdown: **bold**, *italic*, `code`, ~~strikethrough~~
        let attributed = (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
        return Text(attributed)
    }
}

// MARK: - Typing indicator

struct TypingIndicatorView: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.28, on: .main, in: .common).autoconnect()

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
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Message view

struct AssistantMessageView: View {
    let message: AssistantMessage
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        if message.role == .user {
            userBubble
        } else {
            assistantContent
        }
    }

    // MARK: User bubble — glass pill, trailing

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 56)
            Text(message.content)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        }
        .padding(.horizontal, 16)
    }

    // MARK: Assistant content — tool cards + text, leading

    private var assistantContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tool result cards
            if !message.toolResults.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(message.toolResults) { toolResult in
                        ToolResultCardView(toolResult: toolResult)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Text content
            if message.isStreaming && message.content.isEmpty {
                // Show typing dots while waiting for first token
                TypingIndicatorView()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else if !message.content.isEmpty {
                Group {
                    if message.isStreaming {
                        // Plain text with cursor during streaming
                        (Text(message.content) + Text("▋").foregroundColor(.secondary))
                            .font(.body)
                            .foregroundStyle(.primary)
                    } else {
                        // Full markdown rendered after stream completes
                        MarkdownContentView(content: message.content)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.trailing, 40)
            }
        }
    }
}

