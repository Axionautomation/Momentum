//
//  OnboardingView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var groqService = GroqService.shared
    @State private var currentStep: OnboardingStep = .welcome
    @State private var visionText: String = ""
    @State private var answers = OnboardingAnswers()
    @State private var isGenerating: Bool = false
    @State private var generatedPlan: AIGeneratedPlan?
    @State private var generatedHabitPlan: AIGeneratedHabitPlan?
    @State private var generatedIdentityPlan: AIGeneratedIdentityPlan?
    @State private var todaysTasks: [MomentumTask] = []
    @State private var errorMessage: String?
    @State private var generatedQuestions: [OnboardingQuestion] = []
    @State private var isLoadingQuestions: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var detailedError: String = ""
    @State private var selectedGoalType: GoalType = .project

    enum OnboardingStep {
        case welcome
        case howItWorks
        case goalTypeSelection
        case visionInput
        case loadingQuestions
        case questionnaire
        case generating
        case firstTasks
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.momentumDarkBackground, Color(hex: "1E293B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            switch currentStep {
            case .welcome:
                WelcomeView(onContinue: { currentStep = .howItWorks })
            case .howItWorks:
                HowItWorksView(
                    onContinue: { currentStep = .goalTypeSelection },
                    onSkip: { currentStep = .goalTypeSelection }
                )
            case .goalTypeSelection:
                GoalTypeSelectionView(
                    selectedGoalType: $selectedGoalType,
                    onContinue: { currentStep = .visionInput },
                    onBack: { currentStep = .howItWorks }
                )
            case .visionInput:
                VisionInputView(
                    visionText: $visionText,
                    onContinue: {
                        answers.visionText = visionText
                        currentStep = .loadingQuestions
                        generateQuestions()
                    },
                    onBack: { currentStep = .howItWorks }
                )
            case .loadingQuestions:
                LoadingQuestionsView()
            case .questionnaire:
                if !generatedQuestions.isEmpty {
                    DynamicQuestionnaireView(
                        questions: generatedQuestions,
                        answers: $answers,
                        onComplete: {
                            currentStep = .generating
                            generatePlan()
                        },
                        onBack: { currentStep = .visionInput }
                    )
                }
            case .generating:
                GeneratingView()
            case .firstTasks:
                if let plan = generatedPlan {
                    FirstTasksView(
                        plan: plan,
                        tasks: todaysTasks,
                        onStartToday: { completeOnboarding() },
                        onViewFullPlan: { completeOnboarding() }
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Generation Failed", isPresented: $showErrorAlert) {
            Button("Retry") {
                if currentStep == .generating {
                    generatePlan()
                } else if currentStep == .loadingQuestions {
                    generateQuestions()
                }
            }
            Button("Go Back") {
                if currentStep == .generating {
                    currentStep = .questionnaire
                } else if currentStep == .loadingQuestions {
                    currentStep = .visionInput
                }
            }
        } message: {
            Text(detailedError)
        }
    }

    private func generateQuestions() {
        Task {
            do {
                // Call Groq AI to generate personalized questions
                print("🚀 Generating questions for vision: \(visionText)")
                let questions = try await groqService.generateOnboardingQuestions(visionText: visionText)

                await MainActor.run {
                    print("✅ Generated \(questions.count) questions")
                    generatedQuestions = questions
                    currentStep = .questionnaire
                }
            } catch {
                await MainActor.run {
                    print("⚠️ Error generating questions, using fallback: \(error)")
                    // Use fallback questions if API fails (less critical than plan generation)
                    generatedQuestions = createFallbackQuestions()
                    currentStep = .questionnaire
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
                question: "What's your target timeline?",
                options: ["3 months", "6 months", "1 year"],
                allowsTextInput: false
            ),
            OnboardingQuestion(
                question: "What's your biggest concern?",
                options: ["Finding clients", "Building skills", "Managing time", "Staying motivated"],
                allowsTextInput: false
            )
        ]
    }

    private func generatePlan() {
        Task {
            do {
                // Call Groq AI to generate the plan with dynamic answers
                print("🚀 Generating plan with vision: \(visionText)")
                print("🎯 Goal Type: \(selectedGoalType)")
                print("📝 Answers: \(answers)")
                let plan = try await groqService.generateGoalPlan(
                    visionText: visionText,
                    goalType: selectedGoalType,
                    answers: answers
                )

                await MainActor.run {
                    print("✅ Plan generated successfully!")
                    switch plan {
                    case .project(let projectPlan):
                        print("Vision Refined: \(projectPlan.visionRefined)")
                        print("Power Goals: \(projectPlan.powerGoals.count)")
                        generatedPlan = projectPlan
                        generatedHabitPlan = nil
                        generatedIdentityPlan = nil
                    case .habit(let habitPlan):
                        print("Vision Refined: \(habitPlan.visionRefined)")
                        print("Frequency: \(habitPlan.frequency)")
                        generatedHabitPlan = habitPlan  // Store full habit plan
                        generatedPlan = AIGeneratedPlan(visionRefined: habitPlan.visionRefined, powerGoals: [], currentPowerGoal: GeneratedCurrentPowerGoal(goal: "", weeklyMilestones: []), anchorTask: "")
                        generatedIdentityPlan = nil
                    case .identity(let identityPlan):
                        print("Vision Refined: \(identityPlan.visionRefined)")
                        print("Identity Statement: \(identityPlan.identityStatement)")
                        generatedIdentityPlan = identityPlan  // Store full identity plan
                        generatedPlan = AIGeneratedPlan(visionRefined: identityPlan.identityStatement, powerGoals: [], currentPowerGoal: GeneratedCurrentPowerGoal(goal: "", weeklyMilestones: []), anchorTask: "")
                        generatedHabitPlan = nil
                    }
                    createTasksFromPlan()
                    currentStep = .firstTasks
                }
            } catch {
                await MainActor.run {
                    print("❌ ERROR generating plan: \(error)")
                    errorMessage = error.localizedDescription
                    detailedError = "Failed to generate personalized plan.\n\nError: \(error.localizedDescription)\n\nPlease check your internet connection and try again."
                    showErrorAlert = true

                    // DO NOT fallback to mock data - let user know it failed
                    // generatedPlan = createMockGeneratedPlan()
                    // createTasksFromPlan()
                    // currentStep = .firstTasks
                }
            }
        }
    }

    private func createMockGeneratedPlan() -> AIGeneratedPlan {
        AIGeneratedPlan(
            visionRefined: "Launch my consulting agency with 3 paying clients by June 2026",
            powerGoals: (1...12).map { month in
                GeneratedPowerGoal(
                    month: month,
                    goal: MockDataService.shared.mockGoal.powerGoals[month - 1].title,
                    description: MockDataService.shared.mockGoal.powerGoals[month - 1].description ?? ""
                )
            },
            currentPowerGoal: GeneratedCurrentPowerGoal(
                goal: "Build Foundation",
                weeklyMilestones: [
                    GeneratedWeeklyMilestone(
                        week: 1,
                        milestone: "Market Research",
                        dailyTasks: [
                            GeneratedDailyTasks(
                                day: 1,
                                tasks: [
                                    GeneratedTask(title: "Research 3 competitors", difficulty: "easy", estimatedMinutes: 15, description: "Analyze their pricing, services, and positioning"),
                                    GeneratedTask(title: "Draft service packages", difficulty: "medium", estimatedMinutes: 30, description: "Create 3-tier pricing structure"),
                                    GeneratedTask(title: "Call 3 potential clients", difficulty: "hard", estimatedMinutes: 45, description: "Validate problem and interest")
                                ]
                            )
                        ]
                    )
                ]
            ),
            anchorTask: "Review business plan notes"
        )
    }

    private func createTasksFromPlan() {
        guard let plan = generatedPlan,
              let firstDay = plan.currentPowerGoal.weeklyMilestones.first?.dailyTasks.first else { return }

        let milestoneId = UUID()
        let goalId = UUID()

        todaysTasks = firstDay.tasks.map { task in
            MomentumTask(
                weeklyMilestoneId: milestoneId,
                goalId: goalId,
                title: task.title,
                taskDescription: task.description,
                difficulty: TaskDifficulty(rawValue: task.difficulty) ?? .medium,
                estimatedMinutes: task.estimatedMinutes,
                scheduledDate: Date()
            )
        }
    }

    private func completeOnboarding() {
        guard let plan = generatedPlan else {
            // Fallback to mock data if no plan
            let goal = MockDataService.shared.mockGoal
            appState.completeOnboarding(with: goal)
            return
        }

        // Convert AI-generated plan to Goal model based on type
        let goal: Goal
        switch selectedGoalType {
        case .project:
            goal = convertPlanToGoal(plan)
        case .habit:
            goal = convertHabitPlanToGoal(plan)
        case .identity:
            goal = convertIdentityPlanToGoal(plan)
        }

        appState.completeOnboarding(with: goal)
    }

    private func convertPlanToGoal(_ plan: AIGeneratedPlan) -> Goal {
        let goalId = UUID()
        let userId = UUID()

        // Create Power Goals from the plan
        var powerGoals: [PowerGoal] = []

        for (index, pgData) in plan.powerGoals.enumerated() {
            let powerGoalId = UUID()
            var milestones: [WeeklyMilestone] = []

            // Only create milestones for the first Power Goal (current one)
            if index == 0 {
                for (weekIndex, milestone) in plan.currentPowerGoal.weeklyMilestones.enumerated() {
                    let milestoneId = UUID()
                    var tasks: [MomentumTask] = []

                    // Create tasks from the milestone
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
            goalType: selectedGoalType,
            isIdentityBased: false,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: powerGoals
        )
    }

    private func convertHabitPlanToGoal(_ plan: AIGeneratedPlan) -> Goal {
        let goalId = UUID()
        let userId = UUID()

        // Parse frequency from the stored habit plan
        let frequency: HabitFrequency
        let weeklyGoal: Int?

        if let habitPlan = generatedHabitPlan {
            // Parse the frequency string from AI response
            switch habitPlan.frequency.lowercased() {
            case "daily":
                frequency = .daily
                weeklyGoal = 7
            case "weekdays":
                frequency = .weekdays
                weeklyGoal = 5
            case "weekends":
                frequency = .weekends
                weeklyGoal = 2
            default:
                frequency = .daily
                weeklyGoal = habitPlan.weeklyGoal ?? 7
            }
        } else {
            // Fallback to daily if no habit plan stored
            frequency = .daily
            weeklyGoal = 7
        }

        // Create HabitConfig with proper initialization
        let habitConfig = HabitConfig(
            frequency: frequency,
            customDays: nil,
            currentStreak: 0,
            longestStreak: 0,
            lastCompletedDate: nil,
            skipHistory: [],
            reminderTime: nil,
            weeklyGoal: weeklyGoal
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
            targetCompletionDate: nil,  // Habits don't have end dates
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: [],  // Habits don't use power goals
            habitConfig: habitConfig,
            identityConfig: nil
        )
    }

    private func convertIdentityPlanToGoal(_ plan: AIGeneratedPlan) -> Goal {
        let goalId = UUID()
        let userId = UUID()

        // Use the stored identity plan if available
        let identityStatement: String
        var milestones: [IdentityMilestone] = []

        if let identityPlan = generatedIdentityPlan {
            identityStatement = identityPlan.identityStatement

            // Convert generated milestones to IdentityMilestone objects
            milestones = identityPlan.milestones.map { genMilestone in
                IdentityMilestone(
                    title: genMilestone.title,
                    isCompleted: false,
                    completedDate: nil,
                    evidenceId: nil
                )
            }
        } else {
            // Fallback
            identityStatement = plan.visionRefined.hasPrefix("I am") ?
                plan.visionRefined : "I am \(plan.visionRefined)"
        }

        // Create IdentityConfig with proper initialization
        let identityConfig = IdentityConfig(
            identityStatement: identityStatement,
            evidenceEntries: [],
            milestones: milestones
        )

        return Goal(
            id: goalId,
            userId: userId,
            visionText: visionText,
            visionRefined: plan.visionRefined,
            goalType: .identity,
            isIdentityBased: true,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: nil,  // Identity goals don't have end dates
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: [],  // Identity goals don't use power goals
            habitConfig: nil,
            identityConfig: identityConfig
        )
    }
}

// MARK: - Goal Type Selection View

struct GoalTypeSelectionView: View {
    @Binding var selectedGoalType: GoalType
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button {
                    onBack()
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
            .padding(.top)

            ScrollView {
                VStack(spacing: 32) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose your goal type")
                            .font(MomentumFont.heading(28))
                            .foregroundColor(.white)

                        Text("Different goals need different approaches")
                            .font(MomentumFont.body(17))
                            .foregroundColor(.momentumSecondaryText)
                    }
                    .padding(.horizontal)

                    // Goal Type Cards
                    VStack(spacing: 16) {
                        goalTypeCard(
                            type: .project,
                            icon: "target",
                            title: "Project Goal",
                            description: "12-month journey with structured milestones",
                            examples: "Launch a business, Build an app, Write a book"
                        )

                        goalTypeCard(
                            type: .habit,
                            icon: "repeat",
                            title: "Daily Habit",
                            description: "Build consistency with daily check-ins and streak tracking",
                            examples: "Exercise daily, Read every morning, Practice meditation"
                        )

                        goalTypeCard(
                            type: .identity,
                            icon: "person.fill.badge.plus",
                            title: "Identity Goal",
                            description: "Become someone through evidence collection",
                            examples: "Become a pianist, Become a runner, Become an artist"
                        )
                    }
                    .padding(.horizontal)
                }
            }

            // Continue Button
            Button(action: onContinue) {
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

    private func goalTypeCard(type: GoalType, icon: String, title: String, description: String, examples: String) -> some View {
        Button {
            selectedGoalType = type
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    if selectedGoalType == type {
                        Circle()
                            .fill(MomentumGradients.primary)
                            .frame(width: 56, height: 56)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 56, height: 56)
                    }

                    iconForType(icon)
                        .color(.white)
                        .frame(width: 24, height: 24)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(MomentumFont.bodyMedium(18))
                        .foregroundColor(.white)

                    Text(description)
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)
                        .lineLimit(2)

                    Text(examples)
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumViolet)
                        .italic()
                }

                Spacer()

                // Selection indicator
                (selectedGoalType == type ? Ph.checkCircle.fill : Ph.circle.regular)
                    .color(selectedGoalType == type ? .momentumViolet : .momentumSecondaryText)
                    .frame(width: 24, height: 24)
            }
            .padding(20)
            .background(
                selectedGoalType == type
                    ? Color.momentumViolet.opacity(0.15)
                    : Color.white.opacity(0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        selectedGoalType == type
                            ? Color.momentumViolet
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func iconForType(_ icon: String) -> Image {
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
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void
    @State private var showAnimation = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.momentumDeepBlue, .momentumViolet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .momentumViolet.opacity(0.5), radius: 30, y: 10)

                    Ph.sparkle.regular
                        .color(.white)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(showAnimation ? 0 : -10))
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: showAnimation)
                }

                VStack(spacing: 12) {
                    Text("Welcome to Momentum")
                        .font(MomentumFont.heading(28))
                        .foregroundColor(.white)

                    Text("Turn your biggest vision into\ntomorrow's first task")
                        .font(MomentumFont.body(18))
                        .foregroundColor(.momentumSecondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .onAppear {
            showAnimation = true
        }
    }
}

// MARK: - How It Works View
struct HowItWorksView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var currentPage = 0

    let benefits: [(Int, String, String)] = [
        (0, "Start with your vision", "Dream big. We'll handle the breakdown."),
        (1, "Get your daily tasks", "Three doable tasks every day. No overwhelm."),
        (2, "Watch progress compound", "Small wins add up. You'll see exactly how far you've come.")
    ]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(MomentumFont.body(16))
                .foregroundColor(.momentumSecondaryText)
                .padding()
            }

            TabView(selection: $currentPage) {
                ForEach(0..<benefits.count, id: \.self) { index in
                    VStack(spacing: 32) {
                        Spacer()

                        benefitIcon(for: benefits[index].0)
                            .frame(width: 80, height: 80)

                        VStack(spacing: 12) {
                            Text(benefits[index].1)
                                .font(MomentumFont.heading(24))
                                .foregroundColor(.white)

                            Text(benefits[index].2)
                                .font(MomentumFont.body(17))
                                .foregroundColor(.momentumSecondaryText)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: onContinue) {
                Text("Got it, let's start")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    @ViewBuilder
    private func benefitIcon(for index: Int) -> some View {
        switch index {
        case 0:
            Ph.mountains.fill
                .foregroundStyle(MomentumGradients.primary)
        case 1:
            Ph.listChecks.regular
                .foregroundStyle(MomentumGradients.primary)
        case 2:
            Ph.chartLineUp.regular
                .foregroundStyle(MomentumGradients.primary)
        default:
            Ph.target.regular
                .foregroundStyle(MomentumGradients.primary)
        }
    }
}

// MARK: - Vision Input View
struct VisionInputView: View {
    @Binding var visionText: String
    let onContinue: () -> Void
    let onBack: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Ph.caretLeft.regular
                            .frame(width: 16, height: 16)
                        Text("Back")
                    }
                    .foregroundColor(.momentumSecondaryText)
                }

                Spacer()

                Button("Skip") {
                    visionText = "Start a consulting agency"
                    onContinue()
                }
                .font(MomentumFont.body(16))
                .foregroundColor(.momentumSecondaryText)
            }
            .padding(.horizontal)
            .padding(.top)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell us about your vision")
                            .font(MomentumFont.heading(28))
                            .foregroundColor(.white)

                        Text("What's the big goal you want to achieve this year?")
                            .font(MomentumFont.body(17))
                            .foregroundColor(.momentumSecondaryText)
                    }
                    .padding(.horizontal)

                    // Text Input
                    VStack(alignment: .trailing, spacing: 8) {
                        TextField("Type your vision here...", text: $visionText, axis: .vertical)
                            .font(MomentumFont.body(17))
                            .foregroundColor(.white)
                            .padding()
                            .frame(minHeight: 120, alignment: .topLeading)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isTextFieldFocused)

                        Text("\(visionText.count)/200")
                            .font(MomentumFont.body(12))
                            .foregroundColor(.momentumSecondaryText)
                    }
                    .padding(.horizontal)

                    // Examples
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples:")
                            .font(MomentumFont.bodyMedium(14))
                            .foregroundColor(.momentumSecondaryText)

                        VStack(alignment: .leading, spacing: 8) {
                            exampleRow("Start a consulting agency")
                            exampleRow("Become an entrepreneur")
                            exampleRow("Launch my first app")
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Continue Button
            Button(action: onContinue) {
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
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func exampleRow(_ text: String) -> some View {
        Button {
            visionText = text
        } label: {
            HStack {
                Text("-")
                Text(text)
            }
            .font(MomentumFont.body(15))
            .foregroundColor(.momentumSecondaryText)
        }
    }
}

// MARK: - Loading Questions View
struct LoadingQuestionsView: View {
    @State private var animationRotation = 0.0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated AI icon
            ZStack {
                Circle()
                    .fill(MomentumGradients.primary)
                    .frame(width: 80, height: 80)
                    .shadow(color: .momentumViolet.opacity(0.5), radius: 20, y: 10)

                Ph.sparkle.regular
                    .color(.white)
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(animationRotation))
            }

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
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationRotation = 360
            }
        }
    }
}

// MARK: - Dynamic Questionnaire View
struct DynamicQuestionnaireView: View {
    let questions: [OnboardingQuestion]
    @Binding var answers: OnboardingAnswers
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var currentQuestionIndex = 0
    @State private var questionAnswers: [String: String] = [:]
    @State private var textInputAnswer: String = ""
    @State private var showOtherTextField: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var currentQuestion: OnboardingQuestion {
        questions[currentQuestionIndex]
    }

    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(questions.count)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Progress Header
            VStack(spacing: 8) {
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumSecondaryText)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(MomentumGradients.primary)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal)
            .padding(.top)

            Spacer()

            // Question
            VStack(spacing: 32) {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(MomentumGradients.primary)
                        .frame(width: 60, height: 60)

                    Ph.sparkle.regular
                        .color(.white)
                        .frame(width: 28, height: 28)
                }

                Text(currentQuestion.question)
                    .font(MomentumFont.heading(22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Options or Text Input
            VStack(spacing: 12) {
                if let options = currentQuestion.options, !options.isEmpty {
                    // Multiple choice options
                    ForEach(options, id: \.self) { option in
                        Button {
                            handleOptionSelection(option)
                        } label: {
                            HStack {
                                Circle()
                                    .strokeBorder(Color.momentumSecondaryText, lineWidth: 2)
                                    .frame(width: 24, height: 24)

                                Text(option)
                                    .font(MomentumFont.body(16))
                                    .foregroundColor(.white)

                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Show text field when "Other" is selected OR if allowsTextInput is true
                    if showOtherTextField || currentQuestion.allowsTextInput {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(showOtherTextField ? "Please specify:" : "Or type your answer:")
                                .font(MomentumFont.body(14))
                                .foregroundColor(.momentumSecondaryText)

                            TextField("Your answer...", text: $textInputAnswer)
                                .font(MomentumFont.body(16))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .focused($isTextFieldFocused)
                        }
                    }
                } else {
                    // Text-only input
                    TextField("Type your answer...", text: $textInputAnswer, axis: .vertical)
                        .font(MomentumFont.body(16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(minHeight: 100, alignment: .topLeading)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isTextFieldFocused)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Navigation
            HStack {
                if currentQuestionIndex > 0 {
                    Button {
                        withAnimation {
                            currentQuestionIndex -= 1
                            showOtherTextField = false
                            textInputAnswer = ""
                        }
                    } label: {
                        HStack {
                            Ph.caretLeft.regular
                                .frame(width: 16, height: 16)
                            Text("Back")
                        }
                        .foregroundColor(.momentumSecondaryText)
                    }
                } else {
                    Button {
                        onBack()
                    } label: {
                        HStack {
                            Ph.caretLeft.regular
                                .frame(width: 16, height: 16)
                            Text("Back")
                        }
                        .foregroundColor(.momentumSecondaryText)
                    }
                }

                Spacer()

                if !textInputAnswer.isEmpty {
                    Button {
                        selectAnswer(textInputAnswer)
                    } label: {
                        HStack {
                            Text("Next")
                            Ph.arrowRight.regular
                                .frame(width: 16, height: 16)
                        }
                        .foregroundColor(.momentumViolet)
                        .font(MomentumFont.bodyMedium(16))
                    }
                } else {
                    Button("Skip") {
                        skipQuestion()
                    }
                    .foregroundColor(.momentumSecondaryText)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func handleOptionSelection(_ option: String) {
        // Check if this is an "Other" option
        if option.lowercased().contains("other") {
            showOtherTextField = true
            isTextFieldFocused = true
        } else {
            selectAnswer(option)
        }
    }

    private func selectAnswer(_ answer: String) {
        // Store answer with question as key
        questionAnswers[currentQuestion.question] = answer

        // Also store in legacy format for backward compatibility
        storeInLegacyFormat(question: currentQuestion.question, answer: answer)

        // Reset text input and other field state
        textInputAnswer = ""
        showOtherTextField = false

        nextQuestion()
    }

    private func storeInLegacyFormat(question: String, answer: String) {
        // Try to map to OnboardingAnswers fields based on question content
        let questionLower = question.lowercased()

        if questionLower.contains("experience") || questionLower.contains("skill level") {
            answers.experienceLevel = answer
        } else if questionLower.contains("time") || questionLower.contains("hours") {
            answers.weeklyHours = answer
        } else if questionLower.contains("timeline") || questionLower.contains("when") {
            answers.timeline = answer
        } else if questionLower.contains("concern") || questionLower.contains("challenge") || questionLower.contains("worried") {
            answers.biggestConcern = answer
        } else if questionLower.contains("passion") || questionLower.contains("interest") {
            answers.passions = answer
        } else if questionLower.contains("mean") || questionLower.contains("identity") {
            answers.identityMeaning = answer
        }
    }

    private func skipQuestion() {
        nextQuestion()
    }

    private func nextQuestion() {
        withAnimation {
            if currentQuestionIndex < questions.count - 1 {
                currentQuestionIndex += 1
            } else {
                onComplete()
            }
        }
    }
}

// MARK: - Generating View
struct GeneratingView: View {
    @State private var currentStep = 0
    @State private var animationRotation = 0.0

    let steps = [
        "Analyzing your vision",
        "Breaking into Power Goals",
        "Generating your first tasks"
    ]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated shooting star
            ZStack {
                Circle()
                    .fill(MomentumGradients.primary)
                    .frame(width: 100, height: 100)
                    .shadow(color: .momentumViolet.opacity(0.5), radius: 30, y: 10)

                Ph.sparkle.regular
                    .color(.white)
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(animationRotation))
            }

            Text("Creating your momentum plan")
                .font(MomentumFont.heading(22))
                .foregroundColor(.white)

            // Steps
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        if index < currentStep {
                            Ph.checkCircle.fill
                                .color(.momentumGreenStart)
                                .frame(width: 20, height: 20)
                        } else if index == currentStep {
                            ProgressView()
                                .tint(.momentumViolet)
                        } else {
                            Ph.circle.regular
                                .color(.momentumSecondaryText)
                                .frame(width: 20, height: 20)
                        }

                        Text(steps[index])
                            .font(MomentumFont.body(16))
                            .foregroundColor(index <= currentStep ? .white : .momentumSecondaryText)
                    }
                }
            }

            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            animationRotation = 360
        }

        // Simulate step progression
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if currentStep < steps.count - 1 {
                withAnimation {
                    currentStep += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - First Tasks View
struct FirstTasksView: View {
    let plan: AIGeneratedPlan
    let tasks: [MomentumTask]
    let onStartToday: () -> Void
    let onViewFullPlan: () -> Void

    @State private var showTasks = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration
            VStack(spacing: 16) {
                Text("")
                    .font(.system(size: 48))

                Text("Your plan is ready!")
                    .font(MomentumFont.heading(28))
                    .foregroundColor(.white)
            }

            // Vision
            VStack(spacing: 8) {
                Text("Vision:")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumSecondaryText)

                Text(plan.visionRefined)
                    .font(MomentumFont.bodyMedium(18))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 40)

            // First Tasks
            VStack(spacing: 16) {
                Text("Here are your first 3 tasks for today:")
                    .font(MomentumFont.body(16))
                    .foregroundColor(.momentumSecondaryText)

                VStack(spacing: 12) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        taskRow(task)
                            .opacity(showTasks ? 1 : 0)
                            .offset(y: showTasks ? 0 : 20)
                            .animation(.spring().delay(Double(index) * 0.2), value: showTasks)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: onStartToday) {
                    HStack {
                        Text("Start Today")
                        Ph.arrowRight.regular
                            .frame(width: 16, height: 16)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(action: onViewFullPlan) {
                    Text("View Full Plan")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTasks = true
            }
        }
    }

    private func taskRow(_ task: MomentumTask) -> some View {
        HStack {
            Circle()
                .strokeBorder(Color.momentumSecondaryText, lineWidth: 2)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(MomentumFont.bodyMedium(16))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Ph.clock.regular
                            .frame(width: 12, height: 12)
                        Text("\(task.estimatedMinutes) min")
                    }
                    .font(MomentumFont.body(13))
                    .foregroundColor(.momentumSecondaryText)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
