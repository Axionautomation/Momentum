//
//  AIPreferencesView.swift
//  Momentum
//
//  Created by Henry Bowman on 2/8/26.
//

import SwiftUI
import PhosphorSwift

struct AIPreferencesView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    private var currentPersonality: AIPersonality {
        appState.currentUser?.aiPersonality ?? .energetic
    }

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // AI Personality Section
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        SectionHeader(icon: Ph.robot.fill, title: "AI Personality", color: .momentumBlue)

                        Text("Choose how your AI assistant communicates")
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextSecondary)
                            .padding(.horizontal, MomentumSpacing.standard)

                        VStack(spacing: MomentumSpacing.tight) {
                            ForEach(Array(AIPersonality.allCases.enumerated()), id: \.element) { index, personality in
                                PersonalityOptionRow(
                                    personality: personality,
                                    isSelected: personality == currentPersonality,
                                    onSelect: {
                                        updatePersonality(personality)
                                    }
                                )
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(MomentumAnimation.staggered(index: index), value: appeared)
                            }
                        }
                        .padding(.horizontal, MomentumSpacing.standard)
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // Proactivity Level
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        SectionHeader(icon: Ph.lightning.fill, title: "AI Proactivity", color: .momentumWarning)

                        VStack(spacing: MomentumSpacing.compact) {
                            HStack {
                                Text("Minimal")
                                    .font(MomentumFont.caption())
                                    .foregroundColor(.momentumTextTertiary)
                                Spacer()
                                Text("Proactive")
                                    .font(MomentumFont.caption())
                                    .foregroundColor(.momentumTextTertiary)
                            }

                            Slider(
                                value: Binding(
                                    get: { appState.userPreferences.aiProactivityLevel },
                                    set: { appState.userPreferences.aiProactivityLevel = $0 }
                                ),
                                in: 0...1,
                                step: 0.1
                            )
                            .tint(.momentumBlue)

                            Text(proactivityDescription)
                                .font(MomentumFont.caption())
                                .foregroundColor(.momentumTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, MomentumSpacing.standard)
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    // Model Preference
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        SectionHeader(icon: Ph.cpu.fill, title: "AI Model", color: .momentumViolet)

                        VStack(spacing: MomentumSpacing.tight) {
                            ForEach(Array(ModelPreference.allCases.enumerated()), id: \.element) { index, model in
                                ModelOptionRow(
                                    model: model,
                                    isSelected: model == appState.userPreferences.modelPreference,
                                    onSelect: {
                                        appState.userPreferences.modelPreference = model
                                    }
                                )
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(MomentumAnimation.staggered(index: index + 4), value: appeared)
                            }
                        }
                        .padding(.horizontal, MomentumSpacing.standard)
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("AI Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var proactivityDescription: String {
        let level = appState.userPreferences.aiProactivityLevel
        if level < 0.3 { return "AI only responds when asked" }
        else if level < 0.6 { return "AI suggests improvements occasionally" }
        else if level < 0.8 { return "AI proactively researches and suggests" }
        else { return "AI actively prepares content and recommendations" }
    }

    private func updatePersonality(_ personality: AIPersonality) {
        guard var user = appState.currentUser else { return }
        user.aiPersonality = personality
        appState.currentUser = user
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: Image
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: MomentumSpacing.tight) {
            icon
                .frame(width: 20, height: 20)
                .foregroundColor(color)

            Text(title)
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)
        }
        .padding(.horizontal, MomentumSpacing.standard)
    }
}

// MARK: - Personality Option Row

struct PersonalityOptionRow: View {
    let personality: AIPersonality
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(personality.displayName)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)

                    Text("\"\(personality.sampleMessage)\"")
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                        .italic()
                }

                Spacer()

                if isSelected {
                    Ph.checkCircle.fill
                        .frame(width: 22, height: 22)
                        .foregroundColor(.momentumBlue)
                } else {
                    Circle()
                        .stroke(Color.momentumTextTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(MomentumSpacing.compact)
            .background(
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .fill(isSelected ? Color.momentumBlue.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .strokeBorder(isSelected ? Color.momentumBlue.opacity(0.2) : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Model Option Row

struct ModelOptionRow: View {
    let model: ModelPreference
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)

                    Text(model.description)
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                }

                Spacer()

                if isSelected {
                    Ph.checkCircle.fill
                        .frame(width: 22, height: 22)
                        .foregroundColor(.momentumViolet)
                } else {
                    Circle()
                        .stroke(Color.momentumTextTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(MomentumSpacing.compact)
            .background(
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .fill(isSelected ? Color.momentumViolet.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .strokeBorder(isSelected ? Color.momentumViolet.opacity(0.2) : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AIPreferencesView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
