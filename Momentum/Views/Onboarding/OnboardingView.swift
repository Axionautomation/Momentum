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
                            viewModel.currentStep = .visionInput
                        }
                    })

                case .visionInput:
                    VisionInputView(
                        visionText: $viewModel.answers.visionText,
                        onContinue: {
                            Task {
                                await viewModel.generateQuestions()
                            }
                        },
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentStep = .welcome
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
                    GeneratingPlanView()

                case .planPreview:
                    if let plan = viewModel.generatedPlan {
                        PlanPreviewView(
                            plan: plan,
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
    @Published var answers = OnboardingAnswers()
    @Published var questions: [OnboardingQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var generatedPlan: AIGeneratedPlan?
    @Published var showError = false
    @Published var errorMessage = ""

    private let groqService = GroqService.shared

    enum OnboardingStep {
        case welcome
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
            async let planTask = groqService.generateProjectPlan(
                visionText: answers.visionText,
                answers: answers
            )

            // Run plan generation and minimum delay concurrently
            let plan = try await planTask
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds minimum

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
        guard let aiPlan = generatedPlan else { return }

        let userId = UUID()
        let goal = convertToGoal(aiPlan: aiPlan, userId: userId)
        appState.completeOnboarding(with: goal)
    }

    // Convert AIGeneratedPlan to Goal
    private func convertToGoal(aiPlan: AIGeneratedPlan, userId: UUID) -> Goal {
        let goalId = UUID()
        let today = Date()

        // Get the start of the current week (Monday)
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today

        let powerGoals = aiPlan.powerGoals.enumerated().map { index, generatedPG in
            let powerGoalId = UUID()

            // For the first (active) power goal, populate with weekly milestones and tasks
            let weeklyMilestones: [WeeklyMilestone] = if index == 0 {
                aiPlan.currentPowerGoal.weeklyMilestones.enumerated().map { weekIndex, generatedMilestone in
                    let milestoneId = UUID()

                    // Calculate week start date (current week + weekIndex)
                    let milestoneWeekStart = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: weekStart) ?? weekStart

                    // Convert daily tasks to MomentumTask
                    let tasks = generatedMilestone.dailyTasks.flatMap { dailyTask in
                        dailyTask.tasks.map { generatedTask in
                            // Calculate scheduled date (week start + day offset)
                            let dayOffset = dailyTask.day - 1 // day is 1-indexed
                            let scheduledDate = calendar.date(byAdding: .day, value: dayOffset, to: milestoneWeekStart) ?? milestoneWeekStart

                            // Parse difficulty
                            let difficulty: TaskDifficulty = {
                                switch generatedTask.difficulty.lowercased() {
                                case "easy": return .easy
                                case "medium": return .medium
                                case "hard": return .hard
                                default: return .medium
                                }
                            }()

                            return MomentumTask(
                                id: UUID(),
                                weeklyMilestoneId: milestoneId,
                                goalId: goalId,
                                title: generatedTask.title,
                                taskDescription: generatedTask.description,
                                difficulty: difficulty,
                                estimatedMinutes: generatedTask.estimatedMinutes,
                                isAnchorTask: false,
                                scheduledDate: scheduledDate,
                                status: .pending
                            )
                        }
                    }

                    return WeeklyMilestone(
                        id: milestoneId,
                        powerGoalId: powerGoalId,
                        weekNumber: generatedMilestone.week,
                        milestoneText: generatedMilestone.milestone,
                        status: weekIndex == 0 ? .inProgress : .pending,
                        startDate: milestoneWeekStart,
                        tasks: tasks
                    )
                }
            } else {
                []
            }

            return PowerGoal(
                id: powerGoalId,
                goalId: goalId,
                monthNumber: index + 1,
                title: generatedPG.goal,
                description: generatedPG.description,
                status: index == 0 ? .active : .locked,
                startDate: calendar.date(byAdding: .month, value: index, to: Date()),
                completionPercentage: 0,
                weeklyMilestones: weeklyMilestones
            )
        }

        return Goal(
            id: goalId,
            userId: userId,
            visionText: answers.visionText,
            visionRefined: aiPlan.visionRefined,
            goalType: .project,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: powerGoals
        )
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MomentumSpacing.comfortable) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.momentumBlue.opacity(0.15), Color.momentumBlue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Ph.sparkle.fill
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(MomentumGradients.primary)
                }

                VStack(spacing: MomentumSpacing.compact) {
                    Text("Welcome to Momentum")
                        .font(MomentumFont.display(28))
                        .foregroundColor(.momentumTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Where your biggest dreams\nbecome tomorrow's action")
                        .font(MomentumFont.body(17))
                        .foregroundColor(.momentumTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.horizontal, MomentumSpacing.large)

            Spacer()

            // Bottom section
            VStack(spacing: MomentumSpacing.standard) {
                Button(action: {
                    SoundManager.shared.lightHaptic()
                    onContinue()
                }) {
                    HStack(spacing: MomentumSpacing.tight) {
                        Text("Begin Your Journey")
                        Ph.arrowRight.regular
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
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

// MARK: - Vision Input View

struct VisionInputView: View {
    @Binding var visionText: String
    let onContinue: () -> Void
    let onBack: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    private let exampleVisions = [
        "Launch a 6-figure SaaS product",
        "Get promoted to senior engineer",
        "Build and monetize a content brand",
        "Write and publish my first book"
    ]

    private let promptText = "What do you want to achieve?"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
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
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
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
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
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
            Button(action: {
                SoundManager.shared.lightHaptic()
                onContinue()
            }) {
                HStack(spacing: MomentumSpacing.tight) {
                    Text("Continue")
                    Ph.arrowRight.regular
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
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
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 24, height: 24)
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
                                    .onChange(of: customAnswer) { _, newValue in
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
                    SoundManager.shared.lightHaptic()
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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
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
                    .stroke(Color.momentumCardBorder, lineWidth: 2.5)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(MomentumGradients.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 56, height: 56)
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
            VStack(spacing: MomentumSpacing.compact) {
                Ph.quotes.fill
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(MomentumGradients.primary)

                Text(motivationalQuotes[currentQuoteIndex])
                    .font(MomentumFont.bodyMedium(16))
                    .foregroundColor(.momentumTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
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
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.top, MomentumSpacing.tight)
            }
            .padding(.horizontal, MomentumSpacing.comfortable)
            .padding(.vertical, MomentumSpacing.comfortable)
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
    let plan: AIGeneratedPlan
    let onConfirm: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
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
                                        colors: [Color.momentumSuccess.opacity(0.15), Color.momentumSuccess.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)

                            Ph.checkCircle.fill
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(LinearGradient(
                                    colors: [.momentumSuccess, Color(hex: "34D399")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        }

                        Spacer()
                    }
                    .padding(.top, MomentumSpacing.standard)

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
                    ProjectPlanPreview(plan: plan)
                }
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.bottom, MomentumSpacing.large)
            }

            // Confirm Button
            Button(action: {
                SoundManager.shared.successHaptic()
                onConfirm()
            }) {
                HStack(spacing: MomentumSpacing.tight) {
                    Text("Start My Journey")
                    Ph.rocketLaunch.fill
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
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
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumBlue)

                    Text("Your Refined Vision")
                        .font(MomentumFont.headingMedium(17))
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
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumBlue)

                    Text("12 Power Goals")
                        .font(MomentumFont.headingMedium(17))
                        .foregroundColor(.momentumTextPrimary)
                }

                Text("Monthly milestones to guide your journey")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumTextSecondary)

                ForEach(Array(plan.powerGoals.prefix(3).enumerated()), id: \.element.goal) { index, powerGoal in
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
                            Text(powerGoal.goal)
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

// MARK: - Flow Layout (for tags)

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
