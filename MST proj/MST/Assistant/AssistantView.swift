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
import UIKit

struct AssistantView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var pointsManager: PointsManager
    @Environment(FocusTimerBridge.self) private var focusTimerBridge
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AssistantViewModel?
    @State private var showOnboarding = false
    @State private var showIconPicker = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Full-screen glass background
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                // Subtle accent gradient behind the glass
                LinearGradient(
                    colors: [
                        themeManager.accentColor.opacity(0.06),
                        themeManager.accentColor.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if let viewModel {
                                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                        AssistantMessageView(message: message)
                                            .padding(.vertical, 10)
                                            .id(message.id)
                                            .transition(.move(edge: .bottom).combined(with: .opacity))

                                        if index < viewModel.messages.count - 1 {
                                            Divider()
                                                .opacity(0.1)
                                                .padding(.horizontal, 24)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 16)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel?.messages.count) {
                            if let last = viewModel?.messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel?.messages.last?.toolResults.count) {
                            if let last = viewModel?.messages.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel?.isGenerating) {
                            if let last = viewModel?.messages.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: icon button (opens icon picker)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showIconPicker = true
                    } label: {
                        Image(systemName: themeManager.assistantIconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(themeManager.accentColor)
                    }
                }

                // Center: name + thinking status
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(themeManager.assistantName.isEmpty ? "Spark" : themeManager.assistantName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let viewModel, viewModel.isGenerating {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(themeManager.accentColor)
                                    .symbolEffect(.pulse, isActive: true)
                                Text("Thinking...")
                                    .font(.caption2)
                                    .foregroundStyle(themeManager.accentColor)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            Text("Apple Intelligence")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel?.isGenerating)
                }

                // Trailing: clear + dismiss
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if let viewModel, !viewModel.messages.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.4)) {
                                    viewModel.clearConversation()
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .animation(.spring(response: 0.35), value: viewModel?.messages.isEmpty)
                }
            }
        }
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
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIcon: $themeManager.assistantIconName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            let placeholder = "Ask \(themeManager.assistantName.isEmpty ? "Spark" : themeManager.assistantName)..."

            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.accentColor.opacity(0.7))

                TextField(placeholder, text: Binding(
                    get: { viewModel?.inputText ?? "" },
                    set: { viewModel?.inputText = $0 }
                ), axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...4)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { sendCurrentMessage() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            // Send button
            Button {
                sendCurrentMessage()
            } label: {
                ZStack {
                    if let viewModel, viewModel.isGenerating {
                        // Stop indicator
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(canSend ? themeManager.accentColor : Color.secondary.opacity(0.4))
                    }
                }
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: Circle())
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(!canSend && !(viewModel?.isGenerating == true))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, max(16, safeAreaBottom))
    }

    private var canSend: Bool {
        guard let viewModel else { return false }
        return !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isGenerating
    }

    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.bottom ?? 0
    }

    private func sendCurrentMessage() {
        guard let viewModel, canSend else { return }
        let text = viewModel.inputText
        inputFocused = false
        Task { await viewModel.sendMessage(text) }
    }
}
