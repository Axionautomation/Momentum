//
//  OnboardingView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift
import Combine

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView(onContinue: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.currentStep = .goalTypeSelection
                        }
                    })

                case .goalTypeSelection:
                    GoalTypeSelectionView(
                        selectedType: $viewModel.selectedGoalType,
                        onContinue: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentStep = .visionInput
                            }
                        },
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentStep = .welcome
                            }
                        }
                    )

                case .visionInput:
                    VisionInputView(
                        goalType: viewModel.selectedGoalType,
                        visionText: $viewModel.answers.visionText,
                        onContinue: {
                            Task {
                                await viewModel.generateQuestions()
                            }
                        },
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentStep = .goalTypeSelection
                            }
                        }
                    )

                case .questions:
                    QuestionsView(
                        questions: viewModel.questions,
                        answers: $viewModel.answers,
                        currentQuestionIndex: $viewModel.currentQuestionIndex,
                        onContinue: {
                            Task {
                                await viewModel.generatePlan()
                            }
                        },
                        onBack: {
                            if viewModel.currentQuestionIndex > 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.currentQuestionIndex -= 1
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.currentStep = .visionInput
                                }
                            }
                        }
                    )

                case .generating:
                    GeneratingPlanView(goalType: viewModel.selectedGoalType)

                case .planPreview:
                    if let planResponse = viewModel.generatedPlan {
                        PlanPreviewView(
                            goalType: viewModel.selectedGoalType,
                            planResponse: planResponse,
                            onConfirm: {
                                viewModel.completeOnboarding(appState: appState)
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.currentStep = .questions
                                }
                            }
                        )
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - View Model

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedGoalType: GoalType = .project
    @Published var answers = OnboardingAnswers()
    @Published var questions: [OnboardingQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var generatedPlan: AIGoalPlanResponse?
    @Published var showError = false
    @Published var errorMessage = ""

    private let groqService = GroqService.shared

    enum OnboardingStep {
        case welcome
        case goalTypeSelection
        case visionInput
        case questions
        case generating
        case planPreview
    }

    func generateQuestions() async {
        do {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .generating
            }

            questions = try await groqService.generateOnboardingQuestions(visionText: answers.visionText)

            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .questions
            }
        } catch {
            errorMessage = "Failed to generate questions: \(error.localizedDescription)"
            showError = true
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .visionInput
            }
        }
    }

    func generatePlan() async {
        do {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .generating
            }

            // Add a minimum display time for loading animation
            async let planTask = groqService.generateGoalPlan(
                visionText: answers.visionText,
                goalType: selectedGoalType,
                answers: answers
            )
            async let delayTask = Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds minimum

            let (plan, _) = try await (planTask, delayTask)
            generatedPlan = plan

            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .planPreview
            }
        } catch {
            errorMessage = "Failed to generate plan: \(error.localizedDescription)"
            showError = true
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .questions
            }
        }
    }

    func completeOnboarding(appState: AppState) {
        guard let planResponse = generatedPlan else { return }

        let userId = UUID()

        // Create goal based on type
        let goal: Goal

        switch planResponse {
        case .project(let aiPlan):
            goal = convertToGoal(aiPlan: aiPlan, userId: userId, goalType: .project)

        case .habit(let habitPlan):
            goal = convertToGoal(habitPlan: habitPlan, userId: userId)

        case .identity(let identityPlan):
            goal = convertToGoal(identityPlan: identityPlan, userId: userId)
        }

        appState.completeOnboarding(with: goal)
    }

    // Convert AIGeneratedPlan to Goal
    private func convertToGoal(aiPlan: AIGeneratedPlan, userId: UUID, goalType: GoalType) -> Goal {
        let goalId = UUID()

        let powerGoals = aiPlan.powerGoals.enumerated().map { index, generatedPG in
            PowerGoal(
                id: UUID(),
                goalId: goalId,
                monthNumber: index + 1,
                title: generatedPG.title,
                description: generatedPG.description,
                status: index == 0 ? .active : .notStarted,
                startDate: Calendar.current.date(byAdding: .month, value: index, to: Date()),
                targetDate: Calendar.current.date(byAdding: .month, value: index + 1, to: Date()),
                completionPercentage: 0,
                weeklyMilestones: []
            )
        }

        return Goal(
            id: goalId,
            userId: userId,
            visionText: answers.visionText,
            visionRefined: aiPlan.visionRefined,
            goalType: goalType,
            isIdentityBased: false,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: powerGoals
        )
    }

    // Convert habit plan to Goal
    private func convertToGoal(habitPlan: AIGeneratedHabitPlan, userId: UUID) -> Goal {
        let goalId = UUID()

        // Convert string frequency to enum
        let frequencyEnum: HabitFrequency = {
            switch habitPlan.frequency.lowercased() {
            case "daily": return .daily
            case "weekdays": return .weekdays
            case "weekends": return .weekends
            default: return .daily
            }
        }()

        let habitConfig = HabitConfig(
            frequency: frequencyEnum,
            customDays: nil,
            currentStreak: 0,
            longestStreak: 0,
            lastCompletedDate: nil,
            skipHistory: [],
            reminderTime: nil,
            weeklyGoal: habitPlan.weeklyGoal
        )

        return Goal(
            id: goalId,
            userId: userId,
            visionText: answers.visionText,
            visionRefined: habitPlan.habitDescription,
            goalType: .habit,
            status: .active,
            createdAt: Date(),
            habitConfig: habitConfig
        )
    }

    // Convert identity plan to Goal
    private func convertToGoal(identityPlan: AIGeneratedIdentityPlan, userId: UUID) -> Goal {
        let goalId = UUID()

        let milestones = identityPlan.milestones.map { generatedMilestone in
            IdentityMilestone(
                id: UUID(),
                title: generatedMilestone.title,
                isCompleted: false
            )
        }

        let identityConfig = IdentityConfig(
            identityStatement: identityPlan.identityStatement,
            evidenceEntries: [],
            milestones: milestones
        )

        return Goal(
            id: goalId,
            userId: userId,
            visionText: answers.visionText,
            visionRefined: identityPlan.visionRefined,
            goalType: .identity,
            status: .active,
            createdAt: Date(),
            identityConfig: identityConfig
        )
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MomentumSpacing.section) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.momentumBlue.opacity(0.2), Color.momentumBlue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Ph.sparkle.fill
                        .font(.system(size: 48))
                        .foregroundStyle(MomentumGradients.primary)
                }

                VStack(spacing: MomentumSpacing.compact) {
                    Text("Welcome to Momentum")
                        .font(MomentumFont.display(32))
                        .foregroundColor(.momentumTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Where your biggest dreams\nbecome tomorrow's action")
                        .font(MomentumFont.body(18))
                        .foregroundColor(.momentumTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, MomentumSpacing.large)

            Spacer()

            // Bottom section
            VStack(spacing: MomentumSpacing.standard) {
                Button(action: onContinue) {
                    HStack(spacing: MomentumSpacing.tight) {
                        Text("Begin Your Journey")
                        Ph.arrowRight.regular
                            .font(.system(size: 20))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Takes about 3-5 minutes")
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(.horizontal, MomentumSpacing.large)
            .padding(.bottom, MomentumSpacing.large)
        }
    }
}

// MARK: - Goal Type Selection View

struct GoalTypeSelectionView: View {
    @Binding var selectedType: GoalType
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .font(.system(size: 20))
                        Text("Back")
                            .font(MomentumFont.bodyMedium())
                    }
                    .foregroundColor(.momentumBlue)
                }

                Spacer()
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.top, MomentumSpacing.standard)

            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                    // Title
                    VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                        Text("Choose Your Path")
                            .font(MomentumFont.display(28))
                            .foregroundColor(.momentumTextPrimary)

                        Text("Select the type of goal you want to achieve")
                            .font(MomentumFont.body(17))
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .padding(.horizontal, MomentumSpacing.standard)
                    .padding(.top, MomentumSpacing.comfortable)

                    // Goal Type Cards
                    VStack(spacing: MomentumSpacing.standard) {
                        GoalTypeCard(
                            icon: Ph.target.fill,
                            title: "Project Goal",
                            description: "Achieve a specific outcome with a structured 12-month plan",
                            examples: ["Launch a business", "Learn a new skill", "Complete a certification"],
                            isSelected: selectedType == .project,
                            action: { selectedType = .project }
                        )

                        GoalTypeCard(
                            icon: Ph.repeat.fill,
                            title: "Habit Goal",
                            description: "Build lasting lifestyle habits through consistent daily action",
                            examples: ["Exercise daily", "Read for 30 minutes", "Practice meditation"],
                            isSelected: selectedType == .habit,
                            action: { selectedType = .habit }
                        )

                        GoalTypeCard(
                            icon: Ph.userCircle.fill,
                            title: "Identity Goal",
                            description: "Become the person you aspire to be by collecting evidence",
                            examples: ["Become a leader", "Be more confident", "Develop creativity"],
                            isSelected: selectedType == .identity,
                            action: { selectedType = .identity }
                        )
                    }
                    .padding(.horizontal, MomentumSpacing.standard)
                }
                .padding(.bottom, MomentumSpacing.large)
            }

            // Continue Button
            Button(action: onContinue) {
                HStack(spacing: MomentumSpacing.tight) {
                    Text("Continue")
                    Ph.arrowRight.regular
                        .font(.system(size: 20))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.bottom, MomentumSpacing.large)
        }
    }
}

struct GoalTypeCard: View {
    let icon: Image
    let title: String
    let description: String
    let examples: [String]
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                HStack(spacing: MomentumSpacing.compact) {
                    icon
                        .font(.system(size: 28))
                        .foregroundStyle(isSelected ? MomentumGradients.primary : LinearGradient(colors: [.momentumTextSecondary], startPoint: .leading, endPoint: .trailing))

                    Text(title)
                        .font(MomentumFont.headingMedium(20))
                        .foregroundColor(isSelected ? .momentumBlue : .momentumTextPrimary)

                    Spacer()

                    if isSelected {
                        Ph.checkCircle.fill
                            .font(.system(size: 24))
                            .foregroundStyle(MomentumGradients.primary)
                    }
                }

                Text(description)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextSecondary)
                    .multilineTextAlignment(.leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Examples:")
                        .font(MomentumFont.label(13))
                        .foregroundColor(.momentumTextTertiary)

                    ForEach(examples, id: \.self) { example in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.momentumTextTertiary)
                                .frame(width: 3, height: 3)

                            Text(example)
                                .font(MomentumFont.body(14))
                                .foregroundColor(.momentumTextSecondary)
                        }
                    }
                }
            }
            .padding(MomentumSpacing.standard)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .momentumCard(highlighted: isSelected)
    }
}

// MARK: - Vision Input View

struct VisionInputView: View {
    let goalType: GoalType
    @Binding var visionText: String
    let onContinue: () -> Void
    let onBack: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    private var exampleVisions: [String] {
        switch goalType {
        case .project:
            return [
                "Launch a 6-figure SaaS product",
                "Get promoted to senior engineer",
                "Build and monetize a content brand",
                "Write and publish my first book"
            ]
        case .habit:
            return [
                "Exercise 5 days a week",
                "Read for 30 minutes daily",
                "Practice meditation every morning",
                "Learn a new language consistently"
            ]
        case .identity:
            return [
                "Become a confident public speaker",
                "Develop as a creative thinker",
                "Embody a leadership mindset",
                "Be someone who inspires others"
            ]
        }
    }

    private var promptText: String {
        switch goalType {
        case .project:
            return "What specific outcome do you want to achieve?"
        case .habit:
            return "What habit do you want to build into your lifestyle?"
        case .identity:
            return "Who do you want to become?"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .font(.system(size: 20))
                        Text("Back")
                            .font(MomentumFont.bodyMedium())
                    }
                    .foregroundColor(.momentumBlue)
                }

                Spacer()

                Text("Step 1 of 2")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.top, MomentumSpacing.standard)

            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                    // Title
                    VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                        Text("Share Your Vision")
                            .font(MomentumFont.display(28))
                            .foregroundColor(.momentumTextPrimary)

                        Text(promptText)
                            .font(MomentumFont.body(17))
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .padding(.horizontal, MomentumSpacing.standard)
                    .padding(.top, MomentumSpacing.comfortable)

                    // Text Input
                    VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                        TextField("Type your vision here...", text: $visionText, axis: .vertical)
                            .font(MomentumFont.body(17))
                            .foregroundColor(.momentumTextPrimary)
                            .padding(MomentumSpacing.standard)
                            .lineLimit(5...10)
                            .focused($isTextFieldFocused)
                            .background(
                                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                                    .fill(Color.momentumBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MomentumRadius.medium)
                                            .strokeBorder(
                                                isTextFieldFocused ? Color.momentumBlue : Color.momentumCardBorder,
                                                lineWidth: isTextFieldFocused ? 2 : 1
                                            )
                                    )
                            )

                        Text("\(visionText.count) characters")
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextTertiary)
                    }
                    .padding(.horizontal, MomentumSpacing.standard)

                    // Examples
                    VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                        HStack(spacing: 6) {
                            Ph.lightbulb.regular
                                .font(.system(size: 16))
                                .foregroundColor(.momentumTextTertiary)

                            Text("Get inspired:")
                                .font(MomentumFont.label(14))
                                .foregroundColor(.momentumTextTertiary)
                        }

                        ForEach(exampleVisions, id: \.self) { example in
                            Button {
                                visionText = example
                            } label: {
                                HStack {
                                    Text(example)
                                        .font(MomentumFont.body(15))
                                        .foregroundColor(.momentumTextSecondary)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    Ph.arrowRight.regular
                                        .font(.system(size: 14))
                                        .foregroundColor(.momentumTextTertiary)
                                }
                                .padding(.vertical, MomentumSpacing.compact)
                                .padding(.horizontal, MomentumSpacing.standard)
                                .background(Color.momentumBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                            }
                        }
                    }
                    .padding(.horizontal, MomentumSpacing.standard)
                }
                .padding(.bottom, MomentumSpacing.large)
            }

            // Continue Button
            Button(action: onContinue) {
                HStack(spacing: MomentumSpacing.tight) {
                    Text("Continue")
                    Ph.arrowRight.regular
                        .font(.system(size: 20))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(visionText.count < 10)
            .opacity(visionText.count < 10 ? 0.5 : 1.0)
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.bottom, MomentumSpacing.large)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Questions View

struct QuestionsView: View {
    let questions: [OnboardingQuestion]
    @Binding var answers: OnboardingAnswers
    @Binding var currentQuestionIndex: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var selectedAnswer: String = ""
    @State private var customAnswer: String = ""

    private var currentQuestion: OnboardingQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .font(.system(size: 20))
                        Text("Back")
                            .font(MomentumFont.bodyMedium())
                    }
                    .foregroundColor(.momentumBlue)
                }

                Spacer()

                Text("Step 2 of 2")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.top, MomentumSpacing.standard)

            if let question = currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                        // Progress
                        VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                                .font(MomentumFont.label(13))
                                .foregroundColor(.momentumTextTertiary)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.momentumCardBorder.opacity(0.3))
                                        .frame(height: 6)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(MomentumGradients.primary)
                                        .frame(
                                            width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(questions.count),
                                            height: 6
                                        )
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.horizontal, MomentumSpacing.standard)
                        .padding(.top, MomentumSpacing.comfortable)

                        // Question
                        Text(question.question)
                            .font(MomentumFont.headingMedium(24))
                            .foregroundColor(.momentumTextPrimary)
                            .padding(.horizontal, MomentumSpacing.standard)

                        // Answer Options
                        if let options = question.options {
                            VStack(spacing: MomentumSpacing.compact) {
                                ForEach(options, id: \.self) { option in
                                    Button {
                                        selectedAnswer = option
                                        customAnswer = ""
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(MomentumFont.body(16))
                                                .foregroundColor(.momentumTextPrimary)
                                                .multilineTextAlignment(.leading)

                                            Spacer()

                                            if selectedAnswer == option {
                                                Ph.checkCircle.fill
                                                    .font(.system(size: 24))
                                                    .foregroundStyle(MomentumGradients.primary)
                                            } else {
                                                Circle()
                                                    .strokeBorder(Color.momentumCardBorder, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                            }
                                        }
                                        .padding(MomentumSpacing.standard)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .momentumCard(highlighted: selectedAnswer == option)
                                }
                            }
                            .padding(.horizontal, MomentumSpacing.standard)
                        }

                        // Custom text input if allowed
                        if question.allowsTextInput {
                            VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                                Text("Or write your own answer:")
                                    .font(MomentumFont.label(14))
                                    .foregroundColor(.momentumTextSecondary)

                                TextField("Type here...", text: $customAnswer)
                                    .font(MomentumFont.body(16))
                                    .foregroundColor(.momentumTextPrimary)
                                    .padding(MomentumSpacing.standard)
                                    .background(
                                        RoundedRectangle(cornerRadius: MomentumRadius.medium)
                                            .fill(Color.momentumBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                                                    .strokeBorder(Color.momentumCardBorder, lineWidth: 1)
                                            )
                                    )
                                    .onChange(of: customAnswer) { newValue in
                                        if !newValue.isEmpty {
                                            selectedAnswer = ""
                                        }
                                    }
                            }
                            .padding(.horizontal, MomentumSpacing.standard)
                        }
                    }
                    .padding(.bottom, MomentumSpacing.large)
                }

                // Continue Button
                Button(action: {
                    saveCurrentAnswer()
                    if isLastQuestion {
                        onContinue()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentQuestionIndex += 1
                            selectedAnswer = ""
                            customAnswer = ""
                        }
                    }
                }) {
                    HStack(spacing: MomentumSpacing.tight) {
                        Text(isLastQuestion ? "Generate My Plan" : "Next Question")
                        Ph.arrowRight.regular
                            .font(.system(size: 20))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedAnswer.isEmpty && customAnswer.isEmpty)
                .opacity((selectedAnswer.isEmpty && customAnswer.isEmpty) ? 0.5 : 1.0)
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.bottom, MomentumSpacing.large)
            }
        }
        .onAppear {
            loadCurrentAnswer()
        }
    }

    private func saveCurrentAnswer() {
        guard let question = currentQuestion else { return }
        let answer = customAnswer.isEmpty ? selectedAnswer : customAnswer

        // Map answers to OnboardingAnswers fields
        // This is a simple mapping - you may need to adjust based on question content
        if question.question.lowercased().contains("experience") {
            answers.experienceLevel = answer
        } else if question.question.lowercased().contains("hours") || question.question.lowercased().contains("time") {
            answers.weeklyHours = answer
        } else if question.question.lowercased().contains("timeline") || question.question.lowercased().contains("when") {
            answers.timeline = answer
        } else if question.question.lowercased().contains("concern") || question.question.lowercased().contains("challenge") {
            answers.biggestConcern = answer
        } else if question.question.lowercased().contains("passion") || question.question.lowercased().contains("enjoy") {
            answers.passions = answer
        } else if question.question.lowercased().contains("identity") || question.question.lowercased().contains("mean") {
            answers.identityMeaning = answer
        }
    }

    private func loadCurrentAnswer() {
        guard let question = currentQuestion else { return }

        // Load previously saved answer if navigating back
        if question.question.lowercased().contains("experience") && !answers.experienceLevel.isEmpty {
            selectedAnswer = answers.experienceLevel
        } else if question.question.lowercased().contains("hours") && !answers.weeklyHours.isEmpty {
            selectedAnswer = answers.weeklyHours
        } else if question.question.lowercased().contains("timeline") && !answers.timeline.isEmpty {
            selectedAnswer = answers.timeline
        } else if question.question.lowercased().contains("concern") && !answers.biggestConcern.isEmpty {
            selectedAnswer = answers.biggestConcern
        } else if question.question.lowercased().contains("passion") && !answers.passions.isEmpty {
            selectedAnswer = answers.passions
        } else if question.question.lowercased().contains("identity") && !answers.identityMeaning.isEmpty {
            selectedAnswer = answers.identityMeaning
        }
    }
}

// MARK: - Generating Plan View

struct GeneratingPlanView: View {
    let goalType: GoalType
    @State private var currentQuoteIndex = 0
    @State private var timer: Timer?

    private let motivationalQuotes = [
        "Your potential is limitless. Let's unlock it together.",
        "Every master was once a beginner. Your journey starts now.",
        "The secret to getting ahead is getting started.",
        "Dream big. Start small. Act now.",
        "Success is the sum of small efforts repeated daily.",
        "Believe in yourself. You're capable of amazing things.",
        "Your future self will thank you for starting today.",
        "Progress, not perfection. That's the goal.",
        "The best time to start was yesterday. The second best is now.",
        "You don't have to be great to start, but you have to start to be great."
    ]

    var body: some View {
        VStack(spacing: MomentumSpacing.section) {
            Spacer()

            // Loading Animation
            ZStack {
                Circle()
                    .stroke(Color.momentumCardBorder, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(MomentumGradients.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) { }
            }

            VStack(spacing: MomentumSpacing.tight) {
                Text("Crafting Your Plan")
                    .font(MomentumFont.headingMedium(24))
                    .foregroundColor(.momentumTextPrimary)

                Text("Our AI is designing your personalized path to success")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Motivational Quote Carousel
            VStack(spacing: MomentumSpacing.standard) {
                Ph.quotes.fill
                    .font(.system(size: 32))
                    .foregroundStyle(MomentumGradients.primary)

                Text(motivationalQuotes[currentQuoteIndex])
                    .font(MomentumFont.bodyMedium(18))
                    .foregroundColor(.momentumTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .id(currentQuoteIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))

                // Quote indicators
                HStack(spacing: 6) {
                    ForEach(0..<motivationalQuotes.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentQuoteIndex ? Color.momentumBlue : Color.momentumCardBorder)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, MomentumSpacing.tight)
            }
            .padding(.horizontal, MomentumSpacing.large)
            .padding(.vertical, MomentumSpacing.section)
            .background(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .fill(Color.momentumBackgroundSecondary)
            )
            .padding(.horizontal, MomentumSpacing.standard)

            Spacer()
        }
        .onAppear {
            startQuoteCarousel()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startQuoteCarousel() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuoteIndex = (currentQuoteIndex + 1) % motivationalQuotes.count
            }
        }
    }
}

// MARK: - Plan Preview View

struct PlanPreviewView: View {
    let goalType: GoalType
    let planResponse: AIGoalPlanResponse
    let onConfirm: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .font(.system(size: 20))
                        Text("Back")
                            .font(MomentumFont.bodyMedium())
                    }
                    .foregroundColor(.momentumBlue)
                }

                Spacer()
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.top, MomentumSpacing.standard)

            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                    // Success Icon
                    HStack {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.momentumSuccess.opacity(0.2), Color.momentumSuccess.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Ph.checkCircle.fill
                                .font(.system(size: 48))
                                .foregroundStyle(LinearGradient(
                                    colors: [.momentumSuccess, Color(hex: "34D399")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        }

                        Spacer()
                    }
                    .padding(.top, MomentumSpacing.comfortable)

                    // Title
                    VStack(spacing: MomentumSpacing.tight) {
                        Text("Your Plan is Ready!")
                            .font(MomentumFont.display(28))
                            .foregroundColor(.momentumTextPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Here's your personalized path to success")
                            .font(MomentumFont.body(17))
                            .foregroundColor(.momentumTextSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    // Plan Content
                    switch planResponse {
                    case .project(let plan):
                        ProjectPlanPreview(plan: plan)

                    case .habit(let plan):
                        HabitPlanPreview(plan: plan)

                    case .identity(let plan):
                        IdentityPlanPreview(plan: plan)
                    }
                }
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.bottom, MomentumSpacing.large)
            }

            // Confirm Button
            Button(action: onConfirm) {
                HStack(spacing: MomentumSpacing.tight) {
                    Text("Start My Journey")
                    Ph.rocketLaunch.fill
                        .font(.system(size: 20))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.bottom, MomentumSpacing.large)
        }
    }
}

// MARK: - Project Plan Preview

struct ProjectPlanPreview: View {
    let plan: AIGeneratedPlan

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Refined Vision
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                HStack(spacing: 6) {
                    Ph.target.fill
                        .font(.system(size: 20))
                        .foregroundColor(.momentumBlue)

                    Text("Your Refined Vision")
                        .font(MomentumFont.headingMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                Text(plan.visionRefined)
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumTextSecondary)
                    .padding(MomentumSpacing.standard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            }

            // Power Goals Summary
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                HStack(spacing: 6) {
                    Ph.listChecks.fill
                        .font(.system(size: 20))
                        .foregroundColor(.momentumBlue)

                    Text("12 Power Goals")
                        .font(MomentumFont.headingMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                Text("Monthly milestones to guide your journey")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumTextSecondary)

                ForEach(Array(plan.powerGoals.prefix(3).enumerated()), id: \.element.title) { index, powerGoal in
                    HStack(alignment: .top, spacing: MomentumSpacing.compact) {
                        Text("\(index + 1)")
                            .font(MomentumFont.bodyMedium(14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(MomentumGradients.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(powerGoal.title)
                                .font(MomentumFont.bodyMedium(16))
                                .foregroundColor(.momentumTextPrimary)

                            Text(powerGoal.description)
                                .font(MomentumFont.body(14))
                                .foregroundColor(.momentumTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(MomentumSpacing.compact)
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                }

                if plan.powerGoals.count > 3 {
                    Text("+ \(plan.powerGoals.count - 3) more power goals")
                        .font(MomentumFont.label(14))
                        .foregroundColor(.momentumTextTertiary)
                        .padding(.leading, MomentumSpacing.large)
                }
            }
        }
    }
}

// MARK: - Habit Plan Preview

struct HabitPlanPreview: View {
    let plan: AIGeneratedHabitPlan

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Habit Description
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                HStack(spacing: 6) {
                    Ph.repeat.fill
                        .font(.system(size: 20))
                        .foregroundColor(.momentumBlue)

                    Text("Your Habit")
                        .font(MomentumFont.headingMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                Text(plan.habitDescription)
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumTextSecondary)
                    .padding(MomentumSpacing.standard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            }

            // Frequency
            HStack(spacing: MomentumSpacing.standard) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(MomentumFont.label(13))
                        .foregroundColor(.momentumTextTertiary)

                    Text(plan.frequency.capitalized)
                        .font(MomentumFont.bodyMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                Spacer()

                if let weeklyGoal = plan.weeklyGoal {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Weekly Goal")
                            .font(MomentumFont.label(13))
                            .foregroundColor(.momentumTextTertiary)

                        Text("\(weeklyGoal)x per week")
                            .font(MomentumFont.bodyMedium(18))
                            .foregroundColor(.momentumTextPrimary)
                    }
                }
            }
            .padding(MomentumSpacing.standard)
            .background(Color.momentumBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        }
    }
}

// MARK: - Identity Plan Preview

struct IdentityPlanPreview: View {
    let plan: AIGeneratedIdentityPlan

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Identity Statement
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                HStack(spacing: 6) {
                    Ph.userCircle.fill
                        .font(.system(size: 20))
                        .foregroundColor(.momentumBlue)

                    Text("Your Identity")
                        .font(MomentumFont.headingMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                Text(plan.identityStatement)
                    .font(MomentumFont.bodyMedium(18))
                    .foregroundColor(.momentumTextPrimary)
                    .padding(MomentumSpacing.standard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.momentumBlue.opacity(0.1), Color.momentumBlue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            }

            // Evidence Categories
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                HStack(spacing: 6) {
                    Ph.heart.fill
                        .font(.system(size: 20))
                        .foregroundColor(.momentumBlue)

                    Text("Evidence Categories")
                        .font(MomentumFont.headingMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                FlowLayout(spacing: MomentumSpacing.tight) {
                    ForEach(plan.evidenceCategories, id: \.self) { category in
                        Text(category)
                            .font(MomentumFont.body(14))
                            .foregroundColor(.momentumBlue)
                            .padding(.horizontal, MomentumSpacing.compact)
                            .padding(.vertical, MomentumSpacing.tight)
                            .background(Color.momentumBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                    }
                }
            }

            // Milestones
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                HStack(spacing: 6) {
                    Ph.flagCheckered.fill
                        .font(.system(size: 20))
                        .foregroundColor(.momentumBlue)

                    Text("Identity Milestones")
                        .font(MomentumFont.headingMedium(18))
                        .foregroundColor(.momentumTextPrimary)
                }

                ForEach(Array(plan.milestones.prefix(3).enumerated()), id: \.element.title) { index, milestone in
                    HStack(alignment: .top, spacing: MomentumSpacing.compact) {
                        Ph.checkCircle.regular
                            .font(.system(size: 20))
                            .foregroundColor(.momentumTextTertiary)

                        Text(milestone.title)
                            .font(MomentumFont.bodyMedium(16))
                            .foregroundColor(.momentumTextPrimary)

                        Spacer()
                    }
                    .padding(MomentumSpacing.compact)
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                }

                if plan.milestones.count > 3 {
                    Text("+ \(plan.milestones.count - 3) more milestones")
                        .font(MomentumFont.label(14))
                        .foregroundColor(.momentumTextTertiary)
                        .padding(.leading, MomentumSpacing.large)
                }
            }
        }
    }
}

// MARK: - Flow Layout (for Core Values tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
