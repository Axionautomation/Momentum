//
//  ProfileView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPremiumUpgrade = false
    @State private var showAIPersonality = false
    @State private var showGenerateNewPlan = false

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Profile")
                        .font(MomentumFont.heading(20))
                        .foregroundColor(.white)
                        .padding(.top)

                    // Profile Card
                    profileCard

                    // Premium Features Card
                    premiumFeaturesCard

                    // Settings Section
                    settingsSection

                    // Manage Goals Section
                    manageGoalsSection

                    // Support Section
                    supportSection

                    // Log Out Button
                    Button {
                        appState.resetOnboarding()
                    } label: {
                        Text("Log Out")
                            .font(MomentumFont.bodyMedium(16))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeSheet()
        }
        .sheet(isPresented: $showAIPersonality) {
            AIPersonalitySheet()
        }
        .sheet(isPresented: $showGenerateNewPlan) {
            QuickPlanGeneratorSheet()
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.momentumSecondaryText)

            VStack(spacing: 4) {
                Text("Henry Smith")
                    .font(MomentumFont.heading(20))
                    .foregroundColor(.white)

                Text(appState.currentUser?.email ?? "user@example.com")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumSecondaryText)

                if let createdAt = appState.currentUser?.createdAt {
                    Text("Member since \(createdAt.formatted(.dateTime.month().year()))")
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumSecondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Premium Features Card
    private var premiumFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.momentumGold)
                Text("Premium Features")
                    .font(MomentumFont.bodyMedium(16))
                    .foregroundColor(.white)
                Spacer()
            }

            if appState.currentUser?.subscriptionTier == .free {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.momentumSecondaryText)
                        Text("You're on the Free plan")
                            .font(MomentumFont.body(15))
                            .foregroundColor(.momentumSecondaryText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upgrade to unlock:")
                            .font(MomentumFont.body(14))
                            .foregroundColor(.momentumSecondaryText)

                        premiumFeatureRow(text: "Unlimited goals")
                        premiumFeatureRow(text: "Calendar sync")
                        premiumFeatureRow(text: "AI personality customization")
                        premiumFeatureRow(text: "Advanced analytics")
                        premiumFeatureRow(text: "Unlimited AI re-planning")
                    }

                    Text("$4.99/mo or $39.99/year")
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    showPremiumUpgrade = true
                } label: {
                    HStack {
                        Text("Upgrade to Premium")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.momentumGreenStart)
                    Text("Premium Active")
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(.momentumGreenStart)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.momentumGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func premiumFeatureRow(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.momentumViolet)
            Text(text)
                .font(MomentumFont.body(14))
                .foregroundColor(.white)
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
                .padding(.horizontal)

            VStack(spacing: 0) {
                settingsRow(icon: "brain.head.profile", title: "AI Personality", isPremium: true) {
                    showAIPersonality = true
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                settingsRow(icon: "bell.fill", title: "Notifications", isPremium: false) {
                    // Notifications settings
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                settingsRow(icon: "moon.fill", title: "Theme (Light/Dark/Auto)", isPremium: false) {
                    // Theme settings
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                settingsRow(icon: "calendar", title: "Calendar Settings", isPremium: true) {
                    // Calendar settings
                }
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func settingsRow(icon: String, title: String, isPremium: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.momentumSecondaryText)
                    .frame(width: 24)

                Text(title)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.white)

                Spacer()

                if isPremium && appState.currentUser?.subscriptionTier == .free {
                    Text("Premium")
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.momentumGold.opacity(0.2))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.momentumSecondaryText)
            }
            .padding()
        }
    }

    // MARK: - Manage Goals Section
    private var manageGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manage Goals")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
                .padding(.horizontal)

            VStack(spacing: 0) {
                manageGoalRow(title: "Active Goals (1/2)") {}
                Divider().background(Color.white.opacity(0.1))
                manageGoalRow(title: "Completed Goals") {}
                Divider().background(Color.white.opacity(0.1))
                manageGoalRow(title: "Archived Goals") {}
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func manageGoalRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.momentumSecondaryText)
            }
            .padding()
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
                .padding(.horizontal)

            VStack(spacing: 0) {
                supportRow(title: "Help & Tutorials") {}
                Divider().background(Color.white.opacity(0.1))
                supportRow(title: "Contact Support") {}
                Divider().background(Color.white.opacity(0.1))
                supportRow(title: "Privacy Policy") {}
                Divider().background(Color.white.opacity(0.1))
                supportRow(title: "Terms of Service") {}
            }
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    private func supportRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.momentumSecondaryText)
            }
            .padding()
        }
    }
}

// MARK: - Premium Upgrade Sheet
struct PremiumUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .annual

    enum PremiumPlan {
        case monthly, annual
    }

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.momentumSecondaryText)
                    }
                }
                .padding(.horizontal)

                Text("Unlock Your Full Potential")
                    .font(MomentumFont.heading(24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    featureRow(text: "Unlimited goals")
                    featureRow(text: "Calendar sync")
                    featureRow(text: "Custom AI personality")
                    featureRow(text: "Advanced insights")
                    featureRow(text: "Unlimited AI re-planning")
                    featureRow(text: "Priority support")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Text("Choose Your Plan")
                    .font(MomentumFont.bodyMedium(18))
                    .foregroundColor(.white)

                // Plan options
                VStack(spacing: 12) {
                    planOption(plan: .monthly, price: "$4.99/month", subtitle: nil)
                    planOption(plan: .annual, price: "$39.99/year", subtitle: "Save 33% - 2 months free!")
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    Text("7-day free trial included")
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)
                    Text("Cancel anytime")
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        // Start trial
                    } label: {
                        HStack {
                            Text("Start Free Trial")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        // Restore purchases
                    } label: {
                        Text("Restore Purchases")
                            .font(MomentumFont.body(14))
                            .foregroundColor(.momentumSecondaryText)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    private func featureRow(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.momentumGreenStart)
            Text(text)
                .font(MomentumFont.body(16))
                .foregroundColor(.white)
        }
    }

    private func planOption(plan: PremiumPlan, price: String, subtitle: String?) -> some View {
        Button {
            selectedPlan = plan
        } label: {
            HStack {
                Image(systemName: selectedPlan == plan ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedPlan == plan ? .momentumViolet : .momentumSecondaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(price)
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MomentumFont.body(13))
                            .foregroundColor(.momentumGreenStart)
                    }
                }

                Spacer()

                if plan == .annual {
                    Text("BEST VALUE")
                        .font(MomentumFont.body(10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.momentumViolet)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color.white.opacity(selectedPlan == plan ? 0.1 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        selectedPlan == plan ? Color.momentumViolet : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - AI Personality Sheet
struct AIPersonalitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedPersonality: AIPersonality = .energetic

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.momentumSecondaryText)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Text("AI Personality")
                    .font(MomentumFont.heading(24))
                    .foregroundColor(.white)

                Text("Choose your coach's style:")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)

                VStack(spacing: 12) {
                    ForEach(AIPersonality.allCases, id: \.self) { personality in
                        personalityOption(personality)
                    }
                }
                .padding(.horizontal)

                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview Message:")
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)

                    Text("\"\(selectedPersonality.completionMessage)\"")
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    // Save changes
                    dismiss()
                } label: {
                    Text("Save Changes")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            selectedPersonality = appState.currentUser?.aiPersonality ?? .energetic
        }
    }

    private func personalityOption(_ personality: AIPersonality) -> some View {
        Button {
            selectedPersonality = personality
        } label: {
            HStack {
                Image(systemName: selectedPersonality == personality ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedPersonality == personality ? .momentumViolet : .momentumSecondaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(personality.displayName)
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(.white)

                    Text("\"\(personality.sampleMessage)\"")
                        .font(MomentumFont.body(13))
                        .foregroundColor(.momentumSecondaryText)
                }

                Spacer()
            }
            .padding()
            .background(Color.white.opacity(selectedPersonality == personality ? 0.1 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        selectedPersonality == personality ? Color.momentumViolet : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject({
            let state = AppState()
            state.loadMockData()
            return state
        }())
}
