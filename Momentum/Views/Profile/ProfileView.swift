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
        NavigationStack {
            ZStack {
                Color.momentumBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MomentumSpacing.section) {
                        // Profile Header Card
                        ProfileHeaderCard(user: appState.currentUser)
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .padding(.top, MomentumSpacing.standard)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)

                        // Navigation Sections
                        VStack(spacing: MomentumSpacing.compact) {
                            ProfileNavigationRow(
                                icon: Ph.trophy.fill,
                                iconColor: .momentumGold,
                                title: "Achievements",
                                subtitle: "\(appState.achievements.count) unlocked",
                                index: 0,
                                appeared: appeared
                            ) {
                                AchievementsView()
                            }

                            ProfileNavigationRow(
                                icon: Ph.brain.fill,
                                iconColor: .momentumViolet,
                                title: "AI Memory",
                                subtitle: "What AI knows about you",
                                index: 1,
                                appeared: appeared
                            ) {
                                AIMemoryView()
                            }

                            ProfileNavigationRow(
                                icon: Ph.bell.fill,
                                iconColor: .momentumBlueLight,
                                title: "Notifications",
                                subtitle: "Manage alerts",
                                index: 2,
                                appeared: appeared
                            ) {
                                NotificationPreferencesView()
                            }

                            ProfileNavigationRow(
                                icon: Ph.sparkle.fill,
                                iconColor: .momentumBlue,
                                title: "AI Preferences",
                                subtitle: (appState.currentUser?.aiPersonality ?? .energetic).displayName,
                                index: 3,
                                appeared: appeared
                            ) {
                                AIPreferencesView()
                            }

                            ProfileNavigationRow(
                                icon: Ph.shield.fill,
                                iconColor: .momentumSuccess,
                                title: "Data & Privacy",
                                subtitle: "Export & manage your data",
                                index: 4,
                                appeared: appeared
                            ) {
                                DataPrivacyView()
                            }

                            // Reset Progress (destructive, no navigation)
                            ProfileActionRow(
                                icon: Ph.trash.fill,
                                iconColor: .momentumDanger,
                                title: "Reset Progress",
                                subtitle: "Start fresh",
                                isDestructive: true,
                                index: 5,
                                appeared: appeared
                            ) {
                                showResetConfirmation = true
                            }
                        }
                        .padding(.horizontal, MomentumSpacing.comfortable)

                        // App Info
                        AppInfoCard()
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .offset(y: appeared ? 0 : 50)
                            .opacity(appeared ? 1 : 0)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
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
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let user: MomentumUser?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    private var daysSinceJoined: String {
        guard let user = user else { return "0" }
        let days = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
        return "\(max(1, days))"
    }

    private var memberSince: String {
        guard let user = user else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: user.createdAt)
    }

    var body: some View {
        VStack(spacing: MomentumSpacing.standard) {
            // Top row: Avatar + Info
            HStack(spacing: MomentumSpacing.standard) {
                // Initials circle with gradient
                ZStack {
                    Circle()
                        .fill(MomentumGradients.primary)
                        .frame(width: 64, height: 64)

                    Text(user?.initials ?? "MU")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: .momentumBlue.opacity(0.3), radius: 8, y: 2)

                VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                    Text("\(greeting),")
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumTextSecondary)

                    Text(user?.name ?? "Momentum User")
                        .font(MomentumFont.headingLarge())
                        .foregroundColor(.momentumTextPrimary)
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: 0) {
                // Streak
                HStack(spacing: MomentumSpacing.micro) {
                    Ph.flame.fill
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumWarning)

                    Text("\(user?.streakCount ?? 0)")
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)

                    Text("streak")
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.momentumCardBorder)
                    .frame(width: 1, height: 24)

                // Days active
                HStack(spacing: MomentumSpacing.micro) {
                    Ph.calendarCheck.fill
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumBlue)

                    Text(daysSinceJoined)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)

                    Text("days")
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.momentumCardBorder)
                    .frame(width: 1, height: 24)

                // Member since
                HStack(spacing: MomentumSpacing.micro) {
                    Ph.clock.fill
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumViolet)

                    Text(memberSince)
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, MomentumSpacing.tight)
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.large)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.momentumBlue.opacity(0.3), Color.momentumViolet.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }
}

// MARK: - Profile Navigation Row

struct ProfileNavigationRow<Destination: View>: View {
    let icon: Image
    let iconColor: Color
    let title: String
    let subtitle: String
    let index: Int
    let appeared: Bool
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: MomentumSpacing.standard) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: MomentumRadius.small)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    icon
                        .frame(width: 20, height: 20)
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)

                    Text(subtitle)
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                }

                Spacer()

                Ph.caretRight.regular
                    .frame(width: 16, height: 16)
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(MomentumSpacing.compact)
            .background(Color.momentumBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .strokeBorder(Color.momentumCardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .animation(MomentumAnimation.staggered(index: index + 1), value: appeared)
    }
}

// MARK: - Profile Action Row (non-navigation, e.g. Reset)

struct ProfileActionRow: View {
    let icon: Image
    let iconColor: Color
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let index: Int
    let appeared: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MomentumSpacing.standard) {
                ZStack {
                    RoundedRectangle(cornerRadius: MomentumRadius.small)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    icon
                        .frame(width: 20, height: 20)
                        .foregroundColor(iconColor)
                }

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
            .padding(MomentumSpacing.compact)
            .background(Color.momentumBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .strokeBorder(Color.momentumCardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .animation(MomentumAnimation.staggered(index: index + 1), value: appeared)
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
