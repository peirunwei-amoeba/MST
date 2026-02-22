//
//  ChatListView.swift
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

struct ChatListView: View {
    /// @Observable class — SwiftUI tracks changes automatically via the observation system.
    let viewModel: AssistantViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.allChatSessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.allChatSessions) { session in
                            ChatSessionRow(
                                session: session,
                                isActive: session.id == viewModel.currentChatId
                            )
                            .listRowBackground(
                                session.id == viewModel.currentChatId
                                    ? themeManager.accentColor.opacity(0.08)
                                    : Color.clear
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.loadChat(session)
                                dismiss()
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteChat(id: viewModel.allChatSessions[index].id)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.newChat()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No saved chats")
                .font(.headline)
            Text("Start a conversation and it will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct ChatSessionRow: View {
    let session: ChatSession
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "bubble.left.fill" : "bubble.left")
                .font(.system(size: 18))
                .foregroundStyle(isActive ? .blue : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.displayTitle)
                    .font(.body.weight(isActive ? .semibold : .regular))
                    .lineLimit(1)

                Text("\(session.messages.count) message\(session.messages.count == 1 ? "" : "s") · \(relativeDate(session.createdDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isActive {
                Spacer()
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
