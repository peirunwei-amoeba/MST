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
                        // Markdown rendered after stream completes
                        let attributed = (try? AttributedString(
                            markdown: message.content,
                            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                        )) ?? AttributedString(message.content)
                        Text(attributed)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.trailing, 40)
            }
        }
    }
}

