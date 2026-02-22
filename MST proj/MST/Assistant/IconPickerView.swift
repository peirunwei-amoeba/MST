//
//  IconPickerView.swift
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

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchText = ""

    // Common SF symbols for an AI assistant
    private let allSymbols: [(category: String, symbols: [String])] = [
        ("AI & Tech", [
            "sparkles", "wand.and.stars", "bubbles.and.sparkles", "brain",
            "brain.head.profile", "cpu", "cpu.fill", "network", "infinity",
            "bolt.fill", "bolt.circle.fill", "antenna.radiowaves.left.and.right",
            "microchip", "terminal.fill", "chevron.left.forwardslash.chevron.right"
        ]),
        ("Stars & Space", [
            "star.fill", "star.circle.fill", "moon.stars.fill", "sun.max.fill",
            "moon.fill", "cloud.bolt.fill", "wind", "tornado", "hurricane",
            "flame.fill", "globe.americas.fill", "globe.europe.africa.fill"
        ]),
        ("People & Mind", [
            "person.fill", "person.circle.fill", "figure.mind.and.body",
            "figure.wave", "figure.run", "hand.raised.fill", "hands.clap.fill",
            "heart.fill", "heart.circle.fill", "face.smiling.fill", "mustache.fill"
        ]),
        ("Nature", [
            "leaf.fill", "tree.fill", "pawprint.fill", "hare.fill",
            "bird.fill", "fish.fill", "ant.fill", "ladybug.fill",
            "flower.fill", "drop.fill", "snowflake"
        ]),
        ("Learning", [
            "graduationcap.fill", "books.vertical.fill", "book.fill",
            "pencil", "paintpalette.fill", "lightbulb.fill", "lightbulb.circle.fill",
            "magnifyingglass.circle.fill", "puzzlepiece.fill", "trophy.fill"
        ]),
        ("Music & Fun", [
            "music.note", "music.mic", "headphones", "gamecontroller.fill",
            "dice.fill", "theatermasks.fill", "popcorn.fill", "camera.fill",
            "photo.artframe", "paintbrush.fill"
        ]),
        ("Productivity", [
            "checkmark.circle.fill", "list.bullet.clipboard.fill", "calendar",
            "timer", "clock.fill", "bell.fill", "bell.badge.fill",
            "gear", "wrench.and.screwdriver.fill", "hammer.fill"
        ])
    ]

    private var filteredSymbols: [(category: String, symbols: [String])] {
        if searchText.isEmpty { return allSymbols }
        let query = searchText.lowercased()
        let matched = allSymbols.flatMap { $0.symbols }.filter { $0.contains(query) }
        return matched.isEmpty ? [] : [("Results", matched)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(filteredSymbols, id: \.category) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 64), spacing: 12)],
                                spacing: 12
                            ) {
                                ForEach(section.symbols, id: \.self) { symbol in
                                    symbolCell(symbol)
                                }
                            }
                        }
                    }

                    if filteredSymbols.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 40)
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search symbols")
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func symbolCell(_ symbol: String) -> some View {
        let isSelected = selectedIcon == symbol

        Button {
            selectedIcon = symbol
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(isSelected ? .white : themeManager.accentColor)
                    .frame(width: 56, height: 56)
                    .background(
                        isSelected
                            ? themeManager.accentColor
                            : themeManager.accentColor.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isSelected ? themeManager.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            }
        }
        .buttonStyle(GlassButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
