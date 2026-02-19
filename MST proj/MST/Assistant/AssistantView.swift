//
//  AssistantView.swift
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
import SwiftData

struct AssistantView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var pointsManager: PointsManager
    @Environment(FocusTimerBridge.self) private var focusTimerBridge
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AssistantViewModel?
    @State private var showOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider().opacity(0.15)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if let viewModel {
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                AssistantMessageView(message: message)
                                    .padding(.vertical, 10)
                                    .id(message.id)

                                if index < viewModel.messages.count - 1 {
                                    Divider().opacity(0.15).padding(.horizontal, 16)
                                }
                            }

                            // Loading indicator
                            if viewModel.isGenerating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .id("loading")
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .onChange(of: viewModel?.messages.count) {
                    if let lastMessage = viewModel?.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel?.isGenerating) {
                    if viewModel?.isGenerating == true {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            Divider().opacity(0.3)

            // Input bar
            inputBar
        }
        .background(themeManager.backgroundColor)
        .onAppear {
            if viewModel == nil {
                viewModel = AssistantViewModel(
                    modelContext: modelContext,
                    pointsManager: pointsManager,
                    focusTimerBridge: focusTimerBridge,
                    themeManager: themeManager
                )
            }
            if !themeManager.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            AssistantOnboardingView()
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(themeManager.accentColor)

            Text(themeManager.assistantName.isEmpty ? "Spark" : themeManager.assistantName)
                .font(.headline)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            let placeholder = "Ask \(themeManager.assistantName.isEmpty ? "Spark" : themeManager.assistantName)..."
            TextField(placeholder, text: Binding(
                get: { viewModel?.inputText ?? "" },
                set: { viewModel?.inputText = $0 }
            ))
            .textFieldStyle(.plain)
            .font(.body)
            .submitLabel(.send)
            .onSubmit {
                sendCurrentMessage()
            }

            Button {
                sendCurrentMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(canSend ? themeManager.accentColor : Color.secondary.opacity(0.3))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var canSend: Bool {
        guard let viewModel else { return false }
        return !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isGenerating
    }

    private func sendCurrentMessage() {
        guard let viewModel, canSend else { return }
        let text = viewModel.inputText
        Task {
            await viewModel.sendMessage(text)
        }
    }
}
