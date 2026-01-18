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
    @Environment(\.dismiss) private var dismiss
    @State private var showPremiumUpgrade = false
    @State private var showAIPersonality = false
    @State private var showGenerateNewPlan = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.momentumDarkBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Ph.caretLeft.regular
                                .frame(width: 16, height: 16)
                            Text("Back")
                        }
                        .foregroundColor(.momentumViolet)
                    }
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
            Ph.userCircle.fill
                .color(.momentumSecondaryText)
                .frame(width: 72, height: 72)

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
                Ph.star.fill
                    .color(.momentumGold)
                    .frame(width: 20, height: 20)
                Text("Premium Features")
                    .font(MomentumFont.bodyMedium(16))
                    .foregroundColor(.white)
                Spacer()
            }

            if appState.currentUser?.subscriptionTier == .free {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Ph.lock.fill
                            .color(.momentumSecondaryText)
                            .frame(width: 16, height: 16)
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
                        Ph.arrowRight.regular
                            .frame(width: 16, height: 16)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                HStack {
                    Ph.sealCheck.fill
                        .color(.momentumGreenStart)
                        .frame(width: 20, height: 20)
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
            Ph.check.regular
                .color(.momentumViolet)
                .frame(width: 12, height: 12)
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
                iconForSettings(icon)
                    .color(.momentumSecondaryText)
                    .frame(width: 24, height: 24)

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

                Ph.caretRight.regular
                    .color(.momentumSecondaryText)
                    .frame(width: 14, height: 14)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func iconForSettings(_ icon: String) -> Image {
        switch icon {
        case "brain.head.profile":
            return Ph.brain.regular
        case "bell.fill":
            return Ph.bell.fill
        case "moon.fill":
            return Ph.moon.fill
        case "calendar":
            return Ph.calendar.regular
        default:
            return Ph.gear.regular
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
                manageGoalRow(title: "Generate New Plan", icon: "sparkles") {
                    showGenerateNewPlan = true
                }
                Divider().background(Color.white.opacity(0.1))
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

    private func manageGoalRow(title: String, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Ph.sparkle.regular
                        .color(.momentumViolet)
                        .frame(width: 24, height: 24)
                }
                Text(title)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.white)
                Spacer()
                Ph.caretRight.regular
                    .color(.momentumSecondaryText)
                    .frame(width: 14, height: 14)
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
                Ph.caretRight.regular
                    .color(.momentumSecondaryText)
                    .frame(width: 14, height: 14)
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
                        Ph.xCircle.fill
                            .color(.momentumSecondaryText)
                            .frame(width: 28, height: 28)
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
                            Ph.arrowRight.regular
                                .frame(width: 16, height: 16)
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
            Ph.checkCircle.fill
                .color(.momentumGreenStart)
                .frame(width: 20, height: 20)
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
                (selectedPlan == plan ? Ph.radioButton.fill : Ph.circle.regular)
                    .color(selectedPlan == plan ? .momentumViolet : .momentumSecondaryText)
                    .frame(width: 20, height: 20)

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
                            Ph.caretLeft.regular
                                .frame(width: 16, height: 16)
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
                (selectedPersonality == personality ? Ph.radioButton.fill : Ph.circle.regular)
                    .color(selectedPersonality == personality ? .momentumViolet : .momentumSecondaryText)
                    .frame(width: 20, height: 20)

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

// MARK: - Quick Plan Generator Sheet
struct QuickPlanGeneratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var groqService = GroqService.shared

    @State private var selectedGoalType: GoalType = .project
    @State private var visionText: String = ""
    @State private var generatedQuestions: [OnboardingQuestion] = []
    @State private var answers = OnboardingAnswers()
    @State private var isLoadingQuestions = false
    @State private var isGeneratingPlan = false
    @State private var currentStep: Step = .goalTypeSelection

    enum Step {
        case goalTypeSelection
        case vision
        case loadingQuestions
        case questions
        case generating
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.momentumDarkBackground
                    .ignoresSafeArea()

                switch currentStep {
                case .goalTypeSelection:
                    goalTypeSelectionView
                case .vision:
                    visionInputView
                case .loadingQuestions:
                    loadingQuestionsView
                case .questions:
                    if !generatedQuestions.isEmpty {
                        questionsView
                    }
                case .generating:
                    generatingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.momentumSecondaryText)
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Ph.sparkle.regular
                            .color(.momentumViolet)
                            .frame(width: 16, height: 16)
                        Text("Generate Plan")
                            .font(MomentumFont.heading(17))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Goal Type Selection
    private var goalTypeSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("What type of goal?")
                    .font(MomentumFont.heading(24))
                    .foregroundColor(.white)

                Text("Choose the approach that fits your vision")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                goalTypeButton(
                    type: .project,
                    icon: "target",
                    title: "Project Goal",
                    description: "12-month structured plan with milestones"
                )

                goalTypeButton(
                    type: .habit,
                    icon: "repeat",
                    title: "Daily Habit",
                    description: "Build consistency with streak tracking"
                )

                goalTypeButton(
                    type: .identity,
                    icon: "person.fill.badge.plus",
                    title: "Identity Goal",
                    description: "Become someone through evidence"
                )
            }
            .padding(.horizontal)

            Spacer()

            Button {
                currentStep = .vision
            } label: {
                HStack {
                    Text("Continue")
                    Ph.arrowRight.regular
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func goalTypeButton(type: GoalType, icon: String, title: String, description: String) -> some View {
        Button {
            selectedGoalType = type
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    if selectedGoalType == type {
                        Circle()
                            .fill(MomentumGradients.primary)
                            .frame(width: 48, height: 48)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 48, height: 48)
                    }

                    iconForGoalType(icon)
                        .color(.white)
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(.white)

                    Text(description)
                        .font(MomentumFont.body(13))
                        .foregroundColor(.momentumSecondaryText)
                }

                Spacer()

                (selectedGoalType == type ? Ph.checkCircle.fill : Ph.circle.regular)
                    .color(selectedGoalType == type ? .momentumViolet : .momentumSecondaryText)
                    .frame(width: 20, height: 20)
            }
            .padding()
            .background(selectedGoalType == type ? Color.momentumViolet.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selectedGoalType == type ? Color.momentumViolet : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func iconForGoalType(_ icon: String) -> Image {
        switch icon {
        case "target":
            return Ph.target.regular
        case "repeat":
            return Ph.repeat.regular
        case "person.fill.badge.plus":
            return Ph.userPlus.fill
        default:
            return Ph.target.regular
        }
    }

    // MARK: - Vision Input
    private var visionInputView: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    currentStep = .goalTypeSelection
                } label: {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .frame(width: 16, height: 16)
                        Text("Back")
                    }
                    .foregroundColor(.momentumSecondaryText)
                }
                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                Text("What's your vision?")
                    .font(MomentumFont.heading(24))
                    .foregroundColor(.white)

                Text("Tell us what you want to achieve")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)
            }

            TextField("Type your vision...", text: $visionText, axis: .vertical)
                .font(MomentumFont.body(17))
                .foregroundColor(.white)
                .padding()
                .frame(minHeight: 120, alignment: .topLeading)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            Spacer()

            Button {
                generateQuestions()
            } label: {
                HStack {
                    Text("Continue")
                    Ph.arrowRight.regular
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(visionText.count < 10)
            .opacity(visionText.count < 10 ? 0.5 : 1)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Loading Questions
    private var loadingQuestionsView: some View {
        VStack(spacing: 40) {
            Spacer()

            ProgressView()
                .tint(.momentumViolet)
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Analyzing your vision")
                    .font(MomentumFont.heading(20))
                    .foregroundColor(.white)

                Text("Creating personalized questions...")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Questions View
    private var questionsView: some View {
        DynamicQuestionnaireView(
            questions: generatedQuestions,
            answers: $answers,
            onComplete: {
                generatePlan()
            },
            onBack: {
                currentStep = .vision
            }
        )
    }

    // MARK: - Generating View
    private var generatingView: some View {
        VStack(spacing: 40) {
            Spacer()

            ProgressView()
                .tint(.momentumViolet)
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Generating your plan")
                    .font(MomentumFont.heading(20))
                    .foregroundColor(.white)

                Text("This will just take a moment...")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)
            }

            Spacer()
        }
    }

    // MARK: - AI Functions
    private func generateQuestions() {
        currentStep = .loadingQuestions
        answers.visionText = visionText

        Task {
            do {
                let questions = try await groqService.generateOnboardingQuestions(visionText: visionText)

                await MainActor.run {
                    generatedQuestions = questions
                    currentStep = .questions
                }
            } catch {
                await MainActor.run {
                    // Fallback to default questions
                    generatedQuestions = createFallbackQuestions()
                    currentStep = .questions
                }
                print("Error generating questions: \(error)")
            }
        }
    }

    private func generatePlan() {
        currentStep = .generating

        Task {
            do {
                let plan = try await groqService.generateGoalPlan(
                    visionText: visionText,
                    goalType: selectedGoalType,
                    answers: answers
                )

                await MainActor.run {
                    // Convert plan to Goal and save
                    let goal = convertPlanToGoal(plan)
                    appState.addGoal(goal)
                    appState.loadTodaysContent()

                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("Error generating plan: \(error)")
                    dismiss()
                }
            }
        }
    }

    private func createFallbackQuestions() -> [OnboardingQuestion] {
        [
            OnboardingQuestion(
                question: "What's your current experience level?",
                options: ["Complete beginner", "Some experience", "Intermediate", "Advanced"],
                allowsTextInput: false
            ),
            OnboardingQuestion(
                question: "How much time can you dedicate weekly?",
                options: ["5-10 hours", "10-20 hours", "20+ hours"],
                allowsTextInput: false
            ),
            OnboardingQuestion(
                question: "What's your biggest concern?",
                options: ["Getting started", "Staying consistent", "Making progress", "Managing time"],
                allowsTextInput: false
            )
        ]
    }

    private func convertPlanToGoal(_ response: AIGoalPlanResponse) -> Goal {
        let goalId = UUID()
        let userId = appState.currentUser?.id ?? UUID()

        switch response {
        case .project(let plan):
            return convertProjectPlan(plan, goalId: goalId, userId: userId)
        case .habit(let plan):
            return convertHabitPlan(plan, goalId: goalId, userId: userId)
        case .identity(let plan):
            return convertIdentityPlan(plan, goalId: goalId, userId: userId)
        }
    }

    // MARK: - Project Conversion
    private func convertProjectPlan(_ plan: AIGeneratedPlan, goalId: UUID, userId: UUID) -> Goal {
        var powerGoals: [PowerGoal] = []

        for (index, pgData) in plan.powerGoals.enumerated() {
            let powerGoalId = UUID()
            var milestones: [WeeklyMilestone] = []

            if index == 0 {
                for (weekIndex, milestone) in plan.currentPowerGoal.weeklyMilestones.enumerated() {
                    let milestoneId = UUID()
                    var tasks: [MomentumTask] = []

                    for dailyTask in milestone.dailyTasks {
                        let taskDate = Calendar.current.date(
                            byAdding: .day,
                            value: (weekIndex * 7) + (dailyTask.day - 1),
                            to: Date()
                        ) ?? Date()

                        for taskData in dailyTask.tasks {
                            let task = MomentumTask(
                                weeklyMilestoneId: milestoneId,
                                goalId: goalId,
                                title: taskData.title,
                                taskDescription: taskData.description,
                                difficulty: TaskDifficulty(rawValue: taskData.difficulty) ?? .medium,
                                estimatedMinutes: taskData.estimatedMinutes,
                                isAnchorTask: taskData.title.lowercased().contains(plan.anchorTask.lowercased().prefix(10)),
                                scheduledDate: taskDate
                            )
                            tasks.append(task)
                        }
                    }

                    milestones.append(WeeklyMilestone(
                        powerGoalId: powerGoalId,
                        weekNumber: weekIndex + 1,
                        milestoneText: milestone.milestone,
                        status: weekIndex == 0 ? .inProgress : .pending,
                        startDate: weekIndex == 0 ? Date() : nil,
                        tasks: tasks
                    ))
                }
            }

            powerGoals.append(PowerGoal(
                id: powerGoalId,
                goalId: goalId,
                monthNumber: pgData.month,
                title: pgData.goal,
                description: pgData.description,
                status: index == 0 ? .active : .locked,
                startDate: index == 0 ? Date() : nil,
                completionPercentage: 0,
                weeklyMilestones: milestones
            ))
        }

        return Goal(
            id: goalId,
            userId: userId,
            visionText: visionText,
            visionRefined: plan.visionRefined,
            goalType: .project,
            isIdentityBased: false,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: powerGoals
        )
    }

    // MARK: - Habit Conversion
    private func convertHabitPlan(_ plan: AIGeneratedHabitPlan, goalId: UUID, userId: UUID) -> Goal {
        let frequency: HabitFrequency = {
            switch plan.frequency.lowercased() {
            case "daily": return .daily
            case "weekdays": return .weekdays
            case "weekends": return .weekends
            default: return .daily
            }
        }()

        let habitConfig = HabitConfig(
            frequency: frequency,
            customDays: nil,
            currentStreak: 0,
            longestStreak: 0,
            lastCompletedDate: nil,
            skipHistory: [],
            reminderTime: nil,
            weeklyGoal: plan.weeklyGoal
        )

        return Goal(
            id: goalId,
            userId: userId,
            visionText: visionText,
            visionRefined: plan.visionRefined,
            goalType: .habit,
            isIdentityBased: false,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: nil,
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: [],
            habitConfig: habitConfig,
            identityConfig: nil
        )
    }

    // MARK: - Identity Conversion
    private func convertIdentityPlan(_ plan: AIGeneratedIdentityPlan, goalId: UUID, userId: UUID) -> Goal {
        let identityMilestones = plan.milestones.map { milestone in
            IdentityMilestone(
                title: milestone.title,
                isCompleted: false,
                completedDate: nil,
                evidenceId: nil
            )
        }

        let identityConfig = IdentityConfig(
            identityStatement: plan.identityStatement,
            evidenceEntries: [],
            milestones: identityMilestones
        )

        // If it's a complex identity, return as identity goal
        // If it's simple, we could treat it like a habit, but still categorize as identity
        return Goal(
            id: goalId,
            userId: userId,
            visionText: visionText,
            visionRefined: plan.visionRefined,
            goalType: .identity,
            isIdentityBased: true,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: nil,
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: [],
            habitConfig: nil,
            identityConfig: identityConfig
        )
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
