//
//  ToolResultCardView.swift
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

struct ToolResultCardView: View {
    let toolResult: ToolResultInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: toolResult.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.bounce, value: toolResult.isExecuting)

                Text(toolResult.isExecuting ? toolResult.label : toolResult.label.replacingOccurrences(of: "...", with: ""))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                if toolResult.isExecuting {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let resultText = toolResult.resultText, !toolResult.isExecuting {
                Text(resultText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .padding(.trailing, 40)
        .animation(.easeInOut(duration: 0.3), value: toolResult.isExecuting)
    }
}
