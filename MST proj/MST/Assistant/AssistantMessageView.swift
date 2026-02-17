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

struct AssistantMessageView: View {
    let message: AssistantMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tool result cards (if any)
            ForEach(message.toolResults) { toolResult in
                ToolResultCardView(toolResult: toolResult)
            }

            // Message content
            if !message.content.isEmpty {
                Group {
                    if message.role == .user {
                        Text(message.content)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.leading, 40)
                    } else {
                        let attributed = (try? AttributedString(markdown: message.content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(message.content)
                        Text(attributed)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 40)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
