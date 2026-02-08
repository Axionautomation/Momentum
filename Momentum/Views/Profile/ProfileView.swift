//
//  ProfileView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Header
                    VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                        Text("Profile")
                            .font(MomentumFont.headingLarge())
                            .foregroundColor(.momentumTextPrimary)

                        Text("Your settings and stats")
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // Stats Card
                    StatsCard(user: appState.currentUser)
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    // AI Personality
                    AIPersonalityCard(
                        personality: appState.currentUser?.aiPersonality ?? .energetic,
                        onChange: { newPersonality in
                            updatePersonality(newPersonality)
                        }
                    )
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    // Settings Section
                    SettingsCard(
                        onResetTapped: {
                            showResetConfirmation = true
                        }
                    )
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)

                    // App Info
                    AppInfoCard()
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .offset(y: appeared ? 0 : 50)
                        .opacity(appeared ? 1 : 0)

                    // Bottom spacing for tab bar
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                appState.resetOnboarding()
            }
        } message: {
            Text("This will delete all your goals, tasks, and progress. This cannot be undone.")
        }
    }

    private func updatePersonality(_ personality: AIPersonality) {
        guard var user = appState.currentUser else { return }
        user.aiPersonality = personality
        appState.currentUser = user
        // User is auto-saved through Combine publisher when currentUser changes
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    let user: MomentumUser?

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            Text("Your Stats")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            HStack(spacing: MomentumSpacing.standard) {
                StatItem(
                    icon: Ph.flame.fill,
                    iconColor: .momentumWarning,
                    value: "\(user?.streakCount ?? 0)",
                    label: "Current Streak"
                )

                Divider()
                    .frame(height: 50)

                StatItem(
                    icon: Ph.trophy.fill,
                    iconColor: .momentumSuccess,
                    value: "\(user?.longestStreak ?? 0)",
                    label: "Longest Streak"
                )

                Divider()
                    .frame(height: 50)

                StatItem(
                    icon: Ph.calendarCheck.fill,
                    iconColor: .momentumBlue,
                    value: daysSinceJoined,
                    label: "Days Active"
                )
            }
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }

    private var daysSinceJoined: String {
        guard let user = user else { return "0" }
        let days = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
        return "\(max(1, days))"
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: Image
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: MomentumSpacing.tight) {
            icon
                .frame(width: 24, height: 24)
                .foregroundColor(iconColor)

            Text(value)
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            Text(label)
                .font(MomentumFont.caption())
                .foregroundColor(.momentumTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AI Personality Card

struct AIPersonalityCard: View {
    let personality: AIPersonality
    let onChange: (AIPersonality) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            HStack {
                Ph.robot.fill
                    .frame(width: 24, height: 24)
                    .foregroundColor(.momentumBlue)

                Text("AI Personality")
                    .font(MomentumFont.headingMedium())
                    .foregroundColor(.momentumTextPrimary)
            }

            Text("Choose how your AI assistant communicates")
                .font(MomentumFont.body(14))
                .foregroundColor(.momentumTextSecondary)

            VStack(spacing: MomentumSpacing.tight) {
                ForEach(AIPersonality.allCases, id: \.self) { option in
                    PersonalityOption(
                        personality: option,
                        isSelected: option == personality,
                        onSelect: { onChange(option) }
                    )
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Personality Option

struct PersonalityOption: View {
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
                    .fill(isSelected ? Color.momentumBlue.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Card

struct SettingsCard: View {
    let onResetTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            Text("Settings")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            VStack(spacing: 0) {
                SettingsRow(
                    icon: Ph.bell.regular,
                    title: "Notifications",
                    subtitle: "Manage reminders"
                ) {
                    // TODO: Open notifications settings
                }

                Divider()

                SettingsRow(
                    icon: Ph.trash.regular,
                    title: "Reset Progress",
                    subtitle: "Start fresh",
                    isDestructive: true
                ) {
                    onResetTapped()
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: Image
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                icon
                    .frame(width: 22, height: 22)
                    .foregroundColor(isDestructive ? .momentumDanger : .momentumTextSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(isDestructive ? .momentumDanger : .momentumTextPrimary)

                    Text(subtitle)
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                }

                Spacer()

                Ph.caretRight.regular
                    .frame(width: 16, height: 16)
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(.vertical, MomentumSpacing.compact)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Info Card

struct AppInfoCard: View {
    var body: some View {
        VStack(spacing: MomentumSpacing.tight) {
            Text("Momentum")
                .font(MomentumFont.bodyMedium())
                .foregroundColor(.momentumTextSecondary)

            Text("Version 1.0.0")
                .font(MomentumFont.caption())
                .foregroundColor(.momentumTextTertiary)

            Text("The operating system for achieving anything.")
                .font(MomentumFont.caption())
                .foregroundColor(.momentumTextTertiary)
                .italic()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MomentumSpacing.standard)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
