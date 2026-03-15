//
//  OnboardingView.swift
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
import AudioToolbox

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var currentStep: Int = 0
    @State private var ambientEngine = AmbientMusicEngine()

    // Step 1: Name & Assistant
    @State private var userName: String = ""
    @State private var assistantName: String = "Spark"

    // Step 2: Birthday
    @State private var birthday: Date = Calendar.current.date(
        byAdding: .year, value: -17, to: Date()
    ) ?? Date()

    // Step 3: Gender
    @State private var gender: String = ""

    // Step 4: Education system
    @State private var educationSystem: String = ""

    // Step 5: Grade level
    @State private var gradeLevel: String = ""

    // Step 6: Interests
    @State private var selectedInterests: Set<String> = []
    @State private var otherInterest: String = ""

    var body: some View {
        ZStack {
            // Buckley green → white background
            LinearGradient(
                colors: [
                    Color(hue: 0.380, saturation: 0.82, brightness: 0.78), // Buckley primary
                    Color(hue: 0.382, saturation: 0.55, brightness: 0.90), // mid green
                    Color(hue: 0.385, saturation: 0.20, brightness: 0.97), // very light green
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle green tint overlay from leading edge
            LinearGradient(
                colors: [
                    Color(hue: 0.378, saturation: 0.70, brightness: 0.72).opacity(0.25),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar — steps 1-7
                if currentStep > 0 && currentStep < 8 {
                    HStack(spacing: 6) {
                        ForEach(1..<8) { i in
                            Capsule()
                                .fill(i <= currentStep
                                      ? Color.black.opacity(0.75)
                                      : Color.black.opacity(0.20))
                                .frame(width: i == currentStep ? 22 : 6, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
                                .onTapGesture {
                                    guard i < currentStep else { return }
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        currentStep = i
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color(white: 0.88), in: Capsule())
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                ZStack {
                    OnboardingStepView(
                        step: currentStep,
                        userName: $userName,
                        assistantName: $assistantName,
                        birthday: $birthday,
                        gender: $gender,
                        educationSystem: $educationSystem,
                        gradeLevel: $gradeLevel,
                        selectedInterests: $selectedInterests,
                        otherInterest: $otherInterest,
                        onAdvance: advanceStep,
                        onComplete: completeOnboarding
                    )
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .onAppear {
            ambientEngine.startMusic()
        }
        .onDisappear {
            ambientEngine.stopMusic()
        }
    }

    private func advanceStep() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1104)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = min(currentStep + 1, 7)
        }
    }

    private func completeOnboarding() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // Delete any existing profile
        if let existing = try? modelContext.fetch(FetchDescriptor<UserProfileData>()) {
            for profile in existing {
                modelContext.delete(profile)
            }
        }

        // Build interests list
        var allInterests = Array(selectedInterests)
        if !otherInterest.trimmingCharacters(in: .whitespaces).isEmpty {
            allInterests.append(otherInterest.trimmingCharacters(in: .whitespaces))
        }

        // Save new profile
        let profile = UserProfileData(
            name: userName,
            birthday: birthday,
            gender: gender,
            educationSystem: educationSystem,
            gradeLevel: gradeLevel,
            interests: allInterests
        )
        modelContext.insert(profile)
        try? modelContext.save()

        // Update ThemeManager
        if !userName.trimmingCharacters(in: .whitespaces).isEmpty {
            themeManager.userName = userName.trimmingCharacters(in: .whitespaces)
        }
        if !assistantName.trimmingCharacters(in: .whitespaces).isEmpty {
            themeManager.assistantName = assistantName.trimmingCharacters(in: .whitespaces)
        }
        themeManager.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserProfileData.self, inMemory: true)
        .environmentObject(ThemeManager())
}
