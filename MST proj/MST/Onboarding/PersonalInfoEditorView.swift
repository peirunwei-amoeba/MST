//
//  PersonalInfoEditorView.swift
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

struct PersonalInfoEditorView: View {
    @Bindable var profile: UserProfileData
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @State private var interestInput: String = ""

    private let genderOptions = ["Man", "Woman", "Non-binary", "Prefer not to say"]
    private let educationOptions = ["Singapore", "United States", "United Kingdom", "Australia", "International / Other"]

    var body: some View {
        Form {
            Section("Personal") {
                HStack {
                    Label("Name", systemImage: "person.fill")
                    Spacer()
                    TextField("Your name", text: $profile.name)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }

                DatePicker(
                    "Birthday",
                    selection: $profile.birthday,
                    in: ...Date(),
                    displayedComponents: .date
                )

                Picker("Gender", selection: $profile.gender) {
                    Text("Prefer not to say").tag("")
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }

            Section("Education") {
                Picker("System", selection: $profile.educationSystem) {
                    Text("Not specified").tag("")
                    ForEach(educationOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                if !profile.educationSystem.isEmpty {
                    Picker("Grade Level", selection: $profile.gradeLevel) {
                        Text("Not specified").tag("")
                        ForEach(gradeLevels(for: profile.educationSystem), id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }
            }

            Section("Interests") {
                if profile.interests.isEmpty {
                    Text("No interests added yet")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(profile.interests, id: \.self) { interest in
                        Text(interest)
                    }
                    .onDelete { indices in
                        profile.interests.remove(atOffsets: indices)
                    }
                }

                HStack {
                    TextField("Add interest...", text: $interestInput)
                        .autocorrectionDisabled()
                    Button("Add") {
                        let trimmed = interestInput.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        profile.interests.append(trimmed)
                        interestInput = ""
                    }
                    .foregroundStyle(themeManager.accentColor)
                    .disabled(interestInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: profile.name) { _, newName in
            if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                themeManager.userName = newName.trimmingCharacters(in: .whitespaces)
            }
        }
    }

    private func gradeLevels(for system: String) -> [String] {
        switch system {
        case "Singapore":
            return ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6",
                    "Secondary 1", "Secondary 2", "Secondary 3", "Secondary 4", "Secondary 5",
                    "JC Year 1", "JC Year 2",
                    "Polytechnic Year 1", "Polytechnic Year 2", "Polytechnic Year 3",
                    "University Year 1", "University Year 2", "University Year 3", "University Year 4"]
        case "United States":
            return ["Kindergarten", "Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5",
                    "Grade 6", "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11", "Grade 12",
                    "Freshman (College)", "Sophomore (College)", "Junior (College)", "Senior (College)"]
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
}

// MARK: - Wrapper that creates a profile lazily if none exists

struct PersonalInfoEditorViewWrapper: View {
    @Query private var profiles: [UserProfileData]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var profile: UserProfileData?

    var body: some View {
        Group {
            if let p = profile {
                PersonalInfoEditorView(profile: p)
            } else {
                ProgressView()
                    .navigationTitle("Personal Info")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            if let existing = profiles.first {
                profile = existing
            } else {
                let defaultBirthday = Calendar.current.date(byAdding: .year, value: -17, to: Date()) ?? Date()
                let new = UserProfileData(
                    name: themeManager.userName,
                    birthday: defaultBirthday
                )
                modelContext.insert(new)
                try? modelContext.save()
                profile = new
            }
        }
    }
}
