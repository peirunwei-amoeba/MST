//
//  OnboardingStepViews.swift
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

// MARK: - Dispatch View

struct OnboardingStepView: View {
    let step: Int
    @Binding var userName: String
    @Binding var assistantName: String
    @Binding var birthday: Date
    @Binding var gender: String
    @Binding var educationSystem: String
    @Binding var gradeLevel: String
    @Binding var selectedInterests: Set<String>
    @Binding var otherInterest: String
    let onAdvance: () -> Void
    let onComplete: () -> Void

    var body: some View {
        switch step {
        case 0: WelcomeStep(onAdvance: onAdvance)
        case 1: NameStep(userName: $userName, assistantName: $assistantName, onAdvance: onAdvance)
        case 2: BirthdayStep(birthday: $birthday, onAdvance: onAdvance)
        case 3: GenderStep(gender: $gender, onAdvance: onAdvance)
        case 4: EducationStep(educationSystem: $educationSystem, gradeLevel: $gradeLevel, onAdvance: onAdvance)
        case 5: GradeStep(educationSystem: educationSystem, gradeLevel: $gradeLevel, onAdvance: onAdvance)
        case 6: InterestsStep(selectedInterests: $selectedInterests, otherInterest: $otherInterest, onAdvance: onAdvance)
        case 7: CompletionStep(userName: userName, onComplete: onComplete)
        default: EmptyView()
        }
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStep: View {
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(36)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.4)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.65), value: appeared)

                VStack(spacing: 10) {
                    Text("Welcome to MST")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Your personal productivity companion.\nLet's set things up for you.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
            }

            Spacer()
            Spacer()

            Button(action: onAdvance) {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.body.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .contentShape(Capsule())
            }
            .glassEffect(.regular.tint(themeManager.accentColor.opacity(0.35)).interactive(), in: .capsule)
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Step 1: Name

struct NameStep: View {
    @Binding var userName: String
    @Binding var assistantName: String
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    var isValid: Bool { !userName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "person.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(28)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 6) {
                    Text("What's your name?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("We'll personalise your experience.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                VStack(spacing: 14) {
                    TextField("Your name", text: $userName)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding()
                        .glassEffect(.regular, in: .capsule)
                        .textContentType(.name)
                        .autocorrectionDisabled()

                    if !themeManager.stabilityMode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI Assistant Name")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 16)
                        TextField("e.g. Spark", text: $assistantName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding()
                            .glassEffect(.regular, in: .capsule)
                            .autocorrectionDisabled()
                    }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
            }

            Spacer()
            Spacer()

            GlassContinueButton(disabled: !isValid, action: onAdvance)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }
        .padding(.horizontal, 28)
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Step 2: Birthday

struct BirthdayStep: View {
    @Binding var birthday: Date
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(28)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 6) {
                    Text("When's your birthday?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Helps us tailor your experience.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                DatePicker(
                    "Birthday",
                    selection: $birthday,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(themeManager.accentColor)
                .padding(4)
                .glassEffect(.regular, in: .rect(cornerRadius: 20, style: .continuous))
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
            }

            Spacer()

            GlassContinueButton(disabled: false, action: onAdvance)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }
        .padding(.horizontal, 28)
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Step 3: Gender

struct GenderStep: View {
    @Binding var gender: String
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    private let options = ["Man", "Woman", "Non-binary", "Prefer not to say"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(28)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 6) {
                    Text("How do you identify?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Optional — helps personalise messages.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                VStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                gender = option
                            }
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if gender == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeManager.accentColor)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 15)
                            .contentShape(Capsule())
                        }
                        .glassEffect(
                            gender == option
                                ? .regular.tint(themeManager.accentColor.opacity(0.28)).interactive()
                                : .regular.interactive(),
                            in: .capsule
                        )
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
            }

            Spacer()

            GlassContinueButton(disabled: gender.isEmpty, action: onAdvance)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }
        .padding(.horizontal, 28)
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Step 4: Education System

struct EducationStep: View {
    @Binding var educationSystem: String
    @Binding var gradeLevel: String
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    struct EducationOption {
        let name: String
        let flag: String
    }

    private let options: [EducationOption] = [
        .init(name: "Singapore", flag: "🇸🇬"),
        .init(name: "United States", flag: "🇺🇸"),
        .init(name: "United Kingdom", flag: "🇬🇧"),
        .init(name: "Australia", flag: "🇦🇺"),
        .init(name: "International / Other", flag: "🌍")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(28)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 6) {
                    Text("Your education system?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("We'll show the right grade levels for you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                VStack(spacing: 10) {
                    ForEach(options, id: \.name) { option in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                educationSystem = option.name
                                gradeLevel = ""
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(option.flag)
                                    .font(.title3)
                                Text(option.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if educationSystem == option.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeManager.accentColor)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 14)
                            .contentShape(Capsule())
                        }
                        .glassEffect(
                            educationSystem == option.name
                                ? .regular.tint(themeManager.accentColor.opacity(0.28)).interactive()
                                : .regular.interactive(),
                            in: .capsule
                        )
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
            }

            Spacer()

            GlassContinueButton(disabled: educationSystem.isEmpty, action: onAdvance)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }
        .padding(.horizontal, 28)
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Step 5: Grade Level

struct GradeStep: View {
    let educationSystem: String
    @Binding var gradeLevel: String
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    private var gradeLevels: [String] {
        switch educationSystem {
        case "Singapore":
            return ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6",
                    "Secondary 1", "Secondary 2", "Secondary 3", "Secondary 4", "Secondary 5",
                    "JC Year 1", "JC Year 2",
                    "Polytechnic Year 1", "Polytechnic Year 2", "Polytechnic Year 3",
                    "University Year 1", "University Year 2", "University Year 3", "University Year 4"]
        case "United States":
            return ["Kindergarten", "Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5",
                    "Grade 6", "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11", "Grade 12",
                    "Freshman (College)", "Sophomore (College)", "Junior (College)", "Senior (College)",
                    "Graduate School"]
        case "United Kingdom":
            return ["Year 1", "Year 2", "Year 3", "Year 4", "Year 5", "Year 6",
                    "Year 7", "Year 8", "Year 9", "Year 10", "Year 11",
                    "Year 12 (Sixth Form)", "Year 13 (Sixth Form)",
                    "University Year 1", "University Year 2", "University Year 3", "University Year 4"]
        case "Australia":
            return ["Year 1", "Year 2", "Year 3", "Year 4", "Year 5", "Year 6",
                    "Year 7", "Year 8", "Year 9", "Year 10", "Year 11", "Year 12",
                    "University Year 1", "University Year 2", "University Year 3", "University Year 4"]
        default:
            return ["Primary School", "Middle School", "High School / Secondary",
                    "Pre-University / Sixth Form", "University / College", "Graduate / Postgraduate",
                    "Professional / Working"]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(22)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 6) {
                    Text("What's your grade level?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Pick the option that fits best.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
            }
            .padding(.top, 20)
            .padding(.horizontal, 28)

            Picker("Grade Level", selection: $gradeLevel) {
                Text("Select…").tag("")
                ForEach(gradeLevels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(.wheel)
            .tint(themeManager.accentColor)
            .frame(height: 200)
            .glassEffect(.regular, in: .rect(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

            Spacer()

            GlassContinueButton(disabled: gradeLevel.isEmpty, action: onAdvance)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Step 6: Interests

struct InterestsStep: View {
    @Binding var selectedInterests: Set<String>
    @Binding var otherInterest: String
    let onAdvance: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false
    @State private var showOtherField = false

    private let presetInterests = [
        "Mathematics", "Sciences", "English / Literature", "History",
        "Art & Design", "Music", "Sports / PE", "Computer Science",
        "Languages", "Reading", "Creative Writing", "Engineering",
        "Business", "Economics", "Philosophy", "Psychology",
        "Biology", "Chemistry"
    ]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(themeManager.accentColor)
                    .padding(22)
                    .glassEffect(.regular, in: .circle)
                    .symbolEffect(.bounce, value: appeared)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 6) {
                    Text("What are your interests?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Select all that apply — optional.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
            }
            .padding(.top, 20)
            .padding(.horizontal, 28)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(presetInterests, id: \.self) { interest in
                            interestChip(interest)
                        }

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showOtherField.toggle()
                                if !showOtherField { otherInterest = "" }
                            }
                        } label: {
                            Text("Other")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(showOtherField ? themeManager.accentColor : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .contentShape(Capsule())
                        }
                        .glassEffect(
                            showOtherField
                                ? .regular.tint(themeManager.accentColor.opacity(0.28)).interactive()
                                : .regular.interactive(),
                            in: .capsule
                        )
                        .buttonStyle(.plain)
                    }

                    if showOtherField {
                        TextField("Your interest...", text: $otherInterest)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding()
                            .glassEffect(.regular, in: .capsule)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

            GlassContinueButton(disabled: false, action: onAdvance, label: "Continue")
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }
        .onAppear { withAnimation { appeared = true } }
    }

    private func interestChip(_ interest: String) -> some View {
        let isSelected = selectedInterests.contains(interest)
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if isSelected { selectedInterests.remove(interest) }
                else { selectedInterests.insert(interest) }
            }
        } label: {
            Text(interest)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? themeManager.accentColor : .primary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Capsule())
        }
        .glassEffect(
            isSelected
                ? .regular.tint(themeManager.accentColor.opacity(0.28)).interactive()
                : .regular.interactive(),
            in: .capsule
        )
        .buttonStyle(.plain)
    }
}

// MARK: - Step 7: Completion

struct CompletionStep: View {
    let userName: String
    let onComplete: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var appeared = false

    private var displayName: String {
        userName.trimmingCharacters(in: .whitespaces).isEmpty ? "there" : userName
    }

    var body: some View {
        ZStack {
            if appeared {
                ConfettiView(particleCount: 80)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.green)
                        .padding(36)
                        .glassEffect(.regular.tint(.green.opacity(0.25)), in: .circle)
                        .symbolEffect(.bounce, value: appeared)
                        .scaleEffect(appeared ? 1.0 : 0.3)
                        .opacity(appeared ? 1.0 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

                    VStack(spacing: 10) {
                        Text("You're all set, \(displayName)!")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text("MST is ready to help you achieve your goals.\nLet's make every day count.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
                }

                Spacer()
                Spacer()

                Button(action: onComplete) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.body.weight(.semibold))
                        Text("Start Using MST")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .contentShape(Capsule())
                }
                .glassEffect(.regular.tint(themeManager.accentColor.opacity(0.35)).interactive(), in: .capsule)
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Shared Glass Continue Button

struct GlassContinueButton: View {
    let disabled: Bool
    let action: () -> Void
    var label: String = "Continue"
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.body.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(disabled ? Color.primary.opacity(0.3) : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .contentShape(Capsule())
        }
        .glassEffect(
            disabled
                ? .regular
                : .regular.tint(themeManager.accentColor.opacity(0.35)).interactive(),
            in: .capsule
        )
        .buttonStyle(.plain)
        .disabled(disabled)
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
    }
}

// MARK: - Legacy alias

typealias ContinueButton = GlassContinueButton
