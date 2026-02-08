//
//  NotificationPreferencesView.swift
//  Momentum
//
//  Created by Henry Bowman on 2/8/26.
//

import SwiftUI
import PhosphorSwift

struct NotificationPreferencesView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Morning Briefing Section
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.sun.fill
                                .frame(width: 20, height: 20)
                                .foregroundColor(.momentumWarning)

                            Text("Morning Briefing")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumTextPrimary)
                        }

                        NotificationToggleRow(
                            icon: Ph.bell.fill,
                            iconColor: .momentumBlue,
                            title: "Briefing Notifications",
                            subtitle: "Get your daily morning briefing",
                            isOn: Binding(
                                get: { appState.userPreferences.morningBriefingEnabled },
                                set: { appState.userPreferences.morningBriefingEnabled = $0 }
                            )
                        )
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(MomentumAnimation.staggered(index: 0), value: appeared)

                        if appState.userPreferences.morningBriefingEnabled {
                            HStack {
                                Ph.clock.regular
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.momentumTextSecondary)

                                Text("Delivery time")
                                    .font(MomentumFont.body())
                                    .foregroundColor(.momentumTextPrimary)

                                Spacer()

                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { appState.userPreferences.briefingTime },
                                        set: { appState.userPreferences.briefingTime = $0 }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .tint(.momentumBlue)
                                .colorScheme(.dark)
                            }
                            .padding(MomentumSpacing.compact)
                            .background(Color.momentumSurface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // Task Alerts Section
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.checkSquare.fill
                                .frame(width: 20, height: 20)
                                .foregroundColor(.momentumBlue)

                            Text("Task Alerts")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumTextPrimary)
                        }

                        NotificationToggleRow(
                            icon: Ph.timer.fill,
                            iconColor: .momentumBlueLight,
                            title: "Task Reminders",
                            subtitle: "Reminders for upcoming tasks",
                            isOn: Binding(
                                get: { appState.userPreferences.taskRemindersEnabled },
                                set: { appState.userPreferences.taskRemindersEnabled = $0 }
                            )
                        )
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(MomentumAnimation.staggered(index: 1), value: appeared)
                    }
                    .padding(MomentumSpacing.standard)
                    .momentumCard()
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    // Progress Alerts Section
                    VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.chartLineUp.fill
                                .frame(width: 20, height: 20)
                                .foregroundColor(.momentumSuccess)

                            Text("Progress Alerts")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumTextPrimary)
                        }

                        NotificationToggleRow(
                            icon: Ph.flame.fill,
                            iconColor: .momentumWarning,
                            title: "Streak Alerts",
                            subtitle: "Don't break your streak",
                            isOn: Binding(
                                get: { appState.userPreferences.streakAlertsEnabled },
                                set: { appState.userPreferences.streakAlertsEnabled = $0 }
                            )
                        )
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(MomentumAnimation.staggered(index: 2), value: appeared)

                        NotificationToggleRow(
                            icon: Ph.trophy.fill,
                            iconColor: .momentumGold,
                            title: "Achievement Alerts",
                            subtitle: "Celebrate new achievements",
                            isOn: Binding(
                                get: { appState.userPreferences.achievementAlertsEnabled },
                                set: { appState.userPreferences.achievementAlertsEnabled = $0 }
                            )
                        )
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(MomentumAnimation.staggered(index: 3), value: appeared)
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
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let icon: Image
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: MomentumSpacing.compact) {
            ZStack {
                RoundedRectangle(cornerRadius: MomentumRadius.small)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                icon
                    .frame(width: 18, height: 18)
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

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.momentumBlue)
        }
        .padding(MomentumSpacing.compact)
        .background(Color.momentumSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
