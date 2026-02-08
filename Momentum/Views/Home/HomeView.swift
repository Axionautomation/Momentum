//
//  HomeView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift
import UIKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var briefingAppeared = false
    @State private var feedAppeared = false
    @State private var completedTaskIds: Set<UUID> = []
    @State private var showCelebration = false
    @State private var expandedTask: MomentumTask? = nil

    // All tasks for today - pending first, then completed
    private var allTodayTasks: [MomentumTask] {
        appState.todaysTasks.sorted { task1, task2 in
            let task1Completed = task1.status == .completed || completedTaskIds.contains(task1.id)
            let task2Completed = task2.status == .completed || completedTaskIds.contains(task2.id)
            // Pending tasks come first
            if task1Completed != task2Completed {
                return !task1Completed
            }
            return false
        }
    }

    private var pendingTasks: [MomentumTask] {
        appState.todaysTasks.filter { task in
            task.status != .completed && !completedTaskIds.contains(task.id)
        }
    }

    private func isTaskCompleted(_ task: MomentumTask) -> Bool {
        task.status == .completed || completedTaskIds.contains(task.id)
    }

    var body: some View {
        ZStack {
            // Background
            Color.momentumBackground
                .ignoresSafeArea()

            if showCelebration {
                AllTasksCompleteCelebrationView(
                    onDismiss: {
                        withAnimation {
                            showCelebration = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                ScrollView {
                    VStack(spacing: MomentumSpacing.section) {
                        // Briefing Hero or fallback header (fade + slide up entrance)
                        if let briefing = appState.currentBriefing {
                            BriefingHeroCard(
                                briefing: briefing,
                                isGenerating: appState.briefingEngine.isGenerating,
                                onRefresh: {
                                    Task { await appState.refreshBriefing() }
                                }
                            )
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .padding(.top, MomentumSpacing.standard)
                            .offset(y: briefingAppeared ? 0 : 16)
                            .opacity(briefingAppeared ? 1 : 0)
                        } else if appState.briefingEngine.isGenerating {
                            BriefingShimmerCard()
                                .padding(.horizontal, MomentumSpacing.comfortable)
                                .padding(.top, MomentumSpacing.standard)
                                .opacity(briefingAppeared ? 1 : 0)
                        } else {
                            HomeHeaderView(
                                streakCount: appState.streakCount,
                                milestoneProgress: appState.currentMilestoneProgress
                            )
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .padding(.top, MomentumSpacing.standard)
                            .offset(y: briefingAppeared ? 0 : 12)
                            .opacity(briefingAppeared ? 1 : 0)
                        }

                        // Quick Actions
                        QuickActionsRow(
                            onAskAI: { appState.openGlobalChat() },
                            onRefreshBriefing: {
                                Task { await appState.refreshBriefing() }
                            }
                        )
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .offset(y: briefingAppeared ? 0 : 10)
                        .opacity(briefingAppeared ? 1 : 0)

                        // AI Feed Section (staggered fade in)
                        if !appState.aiFeedItems.isEmpty {
                            AIFeedSection(items: appState.aiFeedItems)
                                .padding(.horizontal, MomentumSpacing.comfortable)
                                .offset(y: feedAppeared ? 0 : 12)
                                .opacity(feedAppeared ? 1 : 0)
                        }

                        // Loading indicator during AI evaluation
                        if appState.isEvaluatingTasks {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .momentumViolet))
                                Text("AI is preparing your day...")
                                    .font(MomentumFont.label())
                                    .foregroundColor(.momentumTextSecondary)
                            }
                            .padding(.vertical, MomentumSpacing.compact)
                        }

                        // Task cards carousel
                        if pendingTasks.isEmpty && appState.todaysTasks.isEmpty {
                            EmptyTasksView()
                                .padding(.top, MomentumSpacing.large)
                        } else if pendingTasks.isEmpty {
                            // All tasks completed
                            VStack(spacing: MomentumSpacing.section) {
                                VStack(spacing: MomentumSpacing.standard) {
                                    Ph.checkCircle.fill
                                        .frame(width: 56, height: 56)
                                        .foregroundColor(.momentumSuccess)

                                    Text("All done for today!")
                                        .font(MomentumFont.headingMedium())
                                        .foregroundColor(.momentumTextPrimary)

                                    Text("You've completed all your tasks")
                                        .font(MomentumFont.body())
                                        .foregroundColor(.momentumTextSecondary)
                                }

                                // Work ahead button
                                if appState.hasMorePendingTasks {
                                    Button {
                                        completedTaskIds.removeAll()
                                        // Load next batch of tasks
                                        Task {
                                            await appState.generateWeeklyTasks()
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Ph.arrowRight.bold
                                                .frame(width: 18, height: 18)
                                            Text("See Tomorrow's Tasks")
                                                .font(MomentumFont.bodyMedium())
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, MomentumSpacing.section)
                                        .padding(.vertical, MomentumSpacing.standard)
                                        .background(MomentumGradients.primary)
                                        .cornerRadius(16)
                                    }
                                    .padding(.top, MomentumSpacing.compact)
                                }
                            }
                            .padding(.top, MomentumSpacing.large)
                        } else {
                            CardStackView(
                                tasks: allTodayTasks,
                                goalNameForTask: { goalName(for: $0) },
                                isTaskCompleted: { isTaskCompleted($0) },
                                onComplete: { completeTask($0) },
                                onExpand: { task in expandedTask = task }
                            )
                            .frame(height: screenHeight * 0.50)
                        }

                        // Bottom spacing for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
        }
        .onAppear {
            appeared = true

            // Staggered entrance animations
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
                briefingAppeared = true
            }
            withAnimation(MomentumAnimation.smoothSpring.delay(0.25)) {
                feedAppeared = true
            }

            // Trigger task evaluation on appear
            Task {
                await appState.evaluateTodaysTasks()
            }
        }
        .sheet(item: $expandedTask) { task in
            let isTaskCompleted = task.status == .completed || completedTaskIds.contains(task.id)
            TaskExpandedView(
                task: task,
                goalName: goalName(for: task),
                isCompleted: isTaskCompleted,
                onComplete: {
                    completeTask(task)
                },
                onUndoComplete: {
                    uncompleteTask(task)
                }
            )
        }
    }

    // MARK: - Helpers

    private var screenHeight: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height ?? 850
    }

    private func goalName(for task: MomentumTask) -> String {
        if let goal = appState.activeGoal, goal.id == task.goalId {
            return goal.visionRefined ?? goal.visionText
        }
        return appState.activeGoal?.visionRefined ?? appState.activeGoal?.visionText ?? "Goal"
    }

    private func completeTask(_ task: MomentumTask) {
        // Add to completed set for immediate UI update
        _ = withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            completedTaskIds.insert(task.id)
        }

        // Update app state
        appState.completeTask(task)

        // Check if all tasks are now complete
        let allComplete = appState.todaysTasks.allSatisfy { t in
            t.status == .completed || completedTaskIds.contains(t.id)
        }

        if allComplete && !appState.hasMorePendingTasks {
            // Show celebration after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showCelebration = true
                }
            }
        }
    }

    private func uncompleteTask(_ task: MomentumTask) {
        _ = withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            completedTaskIds.remove(task.id)
        }
        appState.uncompleteTask(task)
    }
}

// MARK: - AI Feed Section

struct AIFeedSection: View {
    let items: [AIFeedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack(spacing: 6) {
                Ph.sparkle.fill
                    .frame(width: 16, height: 16)
                Text("AI Activity")
                    .font(MomentumFont.bodyMedium())
            }
            .foregroundColor(.momentumViolet)

            ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                AIFeedCard(item: item)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(MomentumAnimation.staggered(index: index, baseDelay: 0.08), value: items.count)
            }
        }
    }
}

// MARK: - AI Feed Card

struct AIFeedCard: View {
    let item: AIFeedItem
    @State private var showSheet = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)
                        .lineLimit(1)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(MomentumFont.label())
                            .foregroundColor(.momentumTextSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Ph.arrowRight.regular
                    .frame(width: 16, height: 16)
                    .foregroundColor(.momentumTextTertiary)
            }
            .padding(MomentumSpacing.compact)
            .background(Color.momentumBackgroundSecondary)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showSheet) {
            AIFeedItemSheet(item: item)
        }
    }
}

// MARK: - AI Feed Item Sheet

struct AIFeedItemSheet: View {
    let item: AIFeedItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    // Quiz enhancement states
    @State private var showQuizHelpBubble = false
    @State private var selectedOptionForExplanation: String?
    @State private var showOptionExplanation = false
    @State private var currentSkillQuestion: SkillQuestion?

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                        switch item {
                        case .skillQuestion(let question):
                            skillQuestionView(question)
                        case .toolPrompt(let prompt):
                            toolPromptView(prompt)
                        case .questionnaire(let questionnaire):
                            questionnaireView(questionnaire)
                        case .report(let report):
                            reportView(report)
                        }
                    }
                    .padding(MomentumSpacing.comfortable)
                }
                .background(Color.momentumBackground)

                // Quiz help bubble overlay
                if showQuizHelpBubble, let question = currentSkillQuestion {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showQuizHelpBubble = false
                            }
                        }

                    VStack {
                        Spacer()
                        QuizHelpBubble(
                            question: question,
                            goalContext: appState.activeGoal?.visionRefined ?? appState.activeGoal?.visionText ?? "",
                            onSelectOption: { option in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showQuizHelpBubble = false
                                }
                                selectedOptionForExplanation = option
                                showOptionExplanation = true
                            },
                            onDismiss: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showQuizHelpBubble = false
                                }
                            }
                        )
                        .padding(.horizontal, MomentumSpacing.standard)
                        .padding(.bottom, MomentumSpacing.section)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showOptionExplanation) {
                if let option = selectedOptionForExplanation, let question = currentSkillQuestion {
                    OptionExplanationSheet(
                        question: question,
                        selectedOption: option,
                        goalContext: appState.activeGoal?.visionRefined ?? appState.activeGoal?.visionText ?? "",
                        onConfirm: {
                            SoundManager.shared.successHaptic()
                            appState.submitSkillAnswer(question, answer: option)
                            showOptionExplanation = false
                            dismiss()
                        },
                        onChooseDifferent: {
                            showOptionExplanation = false
                            selectedOptionForExplanation = nil
                        }
                    )
                    .presentationDetents([.height(480)])
                    .presentationBackground(Color.momentumBackground)
                }
            }
        }
    }

    private func skillQuestionView(_ question: SkillQuestion) -> some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            Text(question.question)
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            // Help me choose button
            Button {
                currentSkillQuestion = question
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showQuizHelpBubble = true
                }
            } label: {
                HStack(spacing: 6) {
                    Ph.sparkle.regular
                        .frame(width: 16, height: 16)
                    Text("Help me choose")
                        .font(MomentumFont.label())
                }
                .foregroundColor(.momentumViolet)
                .padding(.horizontal, MomentumSpacing.compact)
                .padding(.vertical, MomentumSpacing.tight)
                .background(Color.momentumViolet.opacity(0.1))
                .cornerRadius(MomentumRadius.small)
            }

            ForEach(question.options, id: \.self) { option in
                Button {
                    currentSkillQuestion = question
                    selectedOptionForExplanation = option
                    showOptionExplanation = true
                } label: {
                    HStack {
                        Text(option)
                            .font(MomentumFont.body())
                        Spacer()
                        Ph.arrowRight.regular
                            .frame(width: 16, height: 16)
                    }
                    .foregroundColor(.momentumTextPrimary)
                    .padding(MomentumSpacing.standard)
                    .background(Color.momentumCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.momentumCardBorder, lineWidth: 1)
                    )
                }
            }
        }
        .onAppear {
            currentSkillQuestion = question
        }
    }

    private func toolPromptView(_ prompt: ToolPrompt) -> some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            HStack {
                Text("For: \(prompt.toolName)")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumViolet)

                Spacer()

                Button {
                    UIPasteboard.general.string = prompt.prompt
                    SoundManager.shared.successHaptic()
                } label: {
                    HStack(spacing: 4) {
                        Ph.copy.regular
                            .frame(width: 16, height: 16)
                        Text("Copy")
                    }
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.white)
                    .padding(.horizontal, MomentumSpacing.standard)
                    .padding(.vertical, MomentumSpacing.compact)
                    .background(MomentumGradients.primary)
                    .cornerRadius(8)
                }
            }

            Text(prompt.context)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextSecondary)

            Text(prompt.prompt)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextPrimary)
                .padding(MomentumSpacing.standard)
                .background(Color.momentumBackgroundSecondary)
                .cornerRadius(12)
        }
    }

    private func questionnaireView(_ questionnaire: AIQuestionnaire) -> some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            ForEach(questionnaire.questions) { question in
                VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                    Text(question.question)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)

                    if let options = question.options {
                        ForEach(options, id: \.self) { option in
                            Button {
                                SoundManager.shared.successHaptic()
                                appState.submitQuestionnaireAnswer(questionnaire, questionId: question.id, answer: option)
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(MomentumFont.body())
                                    Spacer()
                                    if question.answer == option {
                                        Ph.checkCircle.fill
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.momentumSuccess)
                                    }
                                }
                                .foregroundColor(.momentumTextPrimary)
                                .padding(MomentumSpacing.compact)
                                .background(question.answer == option ? Color.momentumSuccess.opacity(0.1) : Color.momentumCardBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(question.answer == option ? Color.momentumSuccess : Color.momentumCardBorder, lineWidth: 1)
                                )
                            }
                        }
                    } else {
                        TextField("Your answer...", text: .constant(question.answer ?? ""))
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextPrimary)
                            .padding(MomentumSpacing.compact)
                            .background(Color.momentumCardBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.momentumCardBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(MomentumSpacing.compact)
                .background(Color.momentumBackgroundSecondary)
                .cornerRadius(12)
            }
        }
    }

    private func reportView(_ report: AIReport) -> some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            Text(report.summary)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextPrimary)

            if let details = report.details {
                Text(details)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
            }

            if let sources = report.sources, !sources.isEmpty {
                VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                    Text("Sources")
                        .font(MomentumFont.label())
                        .foregroundColor(.momentumTextTertiary)

                    ForEach(sources, id: \.self) { source in
                        Text(source)
                            .font(MomentumFont.label())
                            .foregroundColor(.momentumBlue)
                    }
                }
            }
        }
    }
}

// MARK: - Option Explanation Sheet

struct OptionExplanationSheet: View {
    let question: SkillQuestion
    let selectedOption: String
    let goalContext: String
    let onConfirm: () -> Void
    let onChooseDifferent: () -> Void

    @State private var explanation: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let groqService = GroqService.shared

    var body: some View {
        VStack(spacing: MomentumSpacing.section) {
            // Header
            VStack(spacing: MomentumSpacing.compact) {
                Text("You selected")
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)

                Text(selectedOption)
                    .font(MomentumFont.headingMedium())
                    .foregroundColor(.momentumTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MomentumSpacing.standard)
                    .padding(.vertical, MomentumSpacing.compact)
                    .background(Color.momentumBlue.opacity(0.1))
                    .cornerRadius(MomentumRadius.small)
            }
            .padding(.top, MomentumSpacing.standard)

            // Explanation content
            VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                HStack(spacing: 6) {
                    Ph.sparkle.fill
                        .frame(width: 16, height: 16)
                        .foregroundColor(.momentumViolet)
                    Text("What this means")
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)
                }

                if isLoading {
                    HStack(spacing: MomentumSpacing.tight) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .momentumViolet))
                        Text("Understanding your choice...")
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MomentumSpacing.standard)
                } else if let explanation = explanation {
                    Text(explanation)
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumTextSecondary)
                        .padding(MomentumSpacing.standard)
                } else if let error = errorMessage {
                    Text(error)
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumWarning)
                        .padding(MomentumSpacing.standard)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.momentumBackgroundSecondary)
            .cornerRadius(MomentumRadius.medium)
            .padding(.horizontal, MomentumSpacing.comfortable)

            Spacer()

            // Action buttons
            VStack(spacing: MomentumSpacing.compact) {
                Button {
                    onConfirm()
                } label: {
                    Text("Confirm this answer")
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MomentumSpacing.standard)
                        .background(MomentumGradients.primary)
                        .cornerRadius(MomentumRadius.medium)
                }

                Button {
                    onChooseDifferent()
                } label: {
                    Text("Choose different option")
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MomentumSpacing.standard)
                        .background(Color.momentumBlue.opacity(0.1))
                        .cornerRadius(MomentumRadius.medium)
                }
            }
            .padding(.horizontal, MomentumSpacing.comfortable)
            .padding(.bottom, MomentumSpacing.section)
        }
        .background(Color.momentumBackground)
        .task {
            await fetchExplanation()
        }
    }

    private func fetchExplanation() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await groqService.getOptionExplanation(
                question: question.question,
                selectedOption: selectedOption,
                allOptions: question.options,
                skill: question.skill,
                goalContext: goalContext
            )
            explanation = result
        } catch {
            errorMessage = "Couldn't load explanation, but you can still confirm your choice."
            print("Option explanation error: \(error)")
        }

        isLoading = false
    }
}

// MARK: - All Tasks Complete Celebration

struct AllTasksCompleteCelebrationView: View {
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: MomentumSpacing.section) {
            Spacer()

            VStack(spacing: MomentumSpacing.standard) {
                Ph.confetti.fill
                    .frame(width: 80, height: 80)
                    .foregroundColor(.momentumGold)

                Text("Amazing work!")
                    .font(MomentumFont.headingLarge())
                    .foregroundColor(.momentumTextPrimary)

                Text("You've completed all your tasks for today")
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
                    .multilineTextAlignment(.center)

                // Streak display
                HStack(spacing: 8) {
                    Ph.flame.fill
                        .frame(width: 20, height: 20)
                    Text("\(appState.streakCount) day streak")
                        .font(MomentumFont.bodyMedium())
                }
                .foregroundColor(.momentumCoral)
                .padding(.top, MomentumSpacing.compact)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Continue")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MomentumSpacing.standard)
                    .background(MomentumGradients.primary)
                    .cornerRadius(16)
            }
            .padding(.horizontal, MomentumSpacing.comfortable)
            .padding(.bottom, MomentumSpacing.section)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.momentumBackground)
    }
}

// MARK: - Card Stack View

struct CardStackView: View {
    let tasks: [MomentumTask]
    let goalNameForTask: (MomentumTask) -> String
    let isTaskCompleted: (MomentumTask) -> Bool
    let onComplete: (MomentumTask) -> Void
    let onExpand: (MomentumTask) -> Void

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isTossing = false
    @State private var hiddenCardIndex: Int? = nil

    private let swipeThreshold: CGFloat = 60
    private let peekOffsetX: CGFloat = 25
    private let backScale: CGFloat = 0.92

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    let position = relativePosition(of: index)
                    let isFront = position == 0
                    let taskIsCompleted = isTaskCompleted(task)

                    TaskCardView(
                        task: task,
                        goalName: goalNameForTask(task),
                        isCompleted: taskIsCompleted,
                        onComplete: { onComplete(task) },
                        onExpand: { onExpand(task) },
                        onDragChanged: isFront ? { offset in
                            guard !isTossing else { return }
                            dragOffset = offset
                        } : nil,
                        onDragEnded: isFront ? { offset, velocity in
                            guard !isTossing else { return }
                            handleDragEnd(offset: offset, velocity: velocity, screenWidth: geometry.size.width)
                        } : nil
                    )
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.bottom, MomentumSpacing.large)
                    .zIndex(isFront ? 10 : Double(5 - abs(position)))
                    .scaleEffect(isFront ? 1.0 : backScale)
                    .offset(
                        x: isFront ? dragOffset : CGFloat(position) * peekOffsetX,
                        y: isFront ? -abs(dragOffset) * 0.1 : 0
                    )
                    .rotationEffect(
                        isFront ? .degrees(Double(dragOffset) / 18.0) : .zero
                    )
                    .opacity(cardOpacity(index: index, position: position))
                    .allowsHitTesting(isFront && !isTossing)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: tasks.count) { _, newCount in
            if newCount > 0 && currentIndex >= newCount {
                currentIndex = 0
            }
        }
    }

    // MARK: - Positioning

    private func relativePosition(of index: Int) -> Int {
        let count = tasks.count
        guard count > 0 else { return 0 }
        var diff = index - currentIndex
        if count > 1 {
            while diff > count / 2 { diff -= count }
            while diff <= -(count + 1) / 2 { diff += count }
        }
        return diff
    }

    private func cardOpacity(index: Int, position: Int) -> Double {
        if index == hiddenCardIndex { return 0 }
        if abs(position) > 1 { return 0.5 }
        if abs(position) == 1 { return 0.85 }
        return 1.0
    }

    // MARK: - Drag & Toss

    private func handleDragEnd(offset: CGFloat, velocity: CGFloat, screenWidth: CGFloat) {
        let shouldSwipe = abs(offset) > swipeThreshold || abs(velocity) > 500
        guard shouldSwipe, tasks.count > 1 else {
            // Spring back to center
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                dragOffset = 0
            }
            return
        }

        let direction: CGFloat = offset > 0 ? 1 : -1
        isTossing = true

        // 1. Toss the front card off-screen diagonally
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = direction * (screenWidth + 150)
        }

        // 2. After toss animation, swap cards
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let oldIndex = currentIndex
            hiddenCardIndex = oldIndex

            // Reset drag offset without animation
            dragOffset = 0

            // Advance index
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                if direction > 0 {
                    currentIndex = (currentIndex + 1) % tasks.count
                } else {
                    currentIndex = (currentIndex - 1 + tasks.count) % tasks.count
                }
            }

            // 3. Fade the tossed card back in at its new peek position
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeIn(duration: 0.25)) {
                    hiddenCardIndex = nil
                }
                isTossing = false
            }
        }
    }
}

// MARK: - Home Header View

struct HomeHeaderView: View {
    let streakCount: Int
    let milestoneProgress: Double

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                Text(greeting)
                    .font(MomentumFont.headingLarge())
                    .foregroundColor(.momentumTextPrimary)

                Text(dateString)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
            }

            Spacer()

            // Streak display
            if streakCount > 0 {
                HStack(spacing: 4) {
                    Ph.flame.fill
                        .frame(width: 18, height: 18)
                    Text("\(streakCount)")
                        .font(MomentumFont.bodyMedium())
                }
                .foregroundColor(.momentumCoral)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.momentumCoral.opacity(0.15))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Briefing Hero Card

struct BriefingHeroCard: View {
    let briefing: BriefingReport
    let isGenerating: Bool
    let onRefresh: () -> Void

    private var accentColor: Color {
        briefing.goalDomain?.color ?? .momentumBlue
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Gradient accent edge
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .padding(.horizontal, MomentumSpacing.standard)

            // Greeting + refresh
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                    Text(briefing.greeting)
                        .font(MomentumFont.headingLarge())
                        .foregroundColor(.momentumTextPrimary)

                    Text(dateString)
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumTextSecondary)
                }

                Spacer()

                Button {
                    onRefresh()
                } label: {
                    Ph.arrowClockwise.regular
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumTextTertiary)
                        .rotationEffect(.degrees(isGenerating ? 360 : 0))
                        .animation(
                            isGenerating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: isGenerating
                        )
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)

            // AI Insight
            HStack(alignment: .top, spacing: MomentumSpacing.compact) {
                Ph.sparkle.fill
                    .frame(width: 16, height: 16)
                    .foregroundColor(accentColor)
                    .padding(.top, 2)

                Text(briefing.insight)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, MomentumSpacing.standard)

            // Focus area pill
            HStack(spacing: 6) {
                Ph.crosshair.regular
                    .frame(width: 14, height: 14)
                Text(briefing.focusArea)
                    .font(MomentumFont.label())
            }
            .foregroundColor(accentColor)
            .padding(.horizontal, MomentumSpacing.compact)
            .padding(.vertical, MomentumSpacing.tight)
            .background(accentColor.opacity(0.1))
            .cornerRadius(MomentumRadius.small)
            .padding(.horizontal, MomentumSpacing.standard)

            // Stats row
            HStack(spacing: MomentumSpacing.comfortable) {
                // Streak
                if briefing.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Ph.flame.fill
                            .frame(width: 16, height: 16)
                        Text("\(briefing.currentStreak)")
                            .font(MomentumFont.bodyMedium())
                    }
                    .foregroundColor(.momentumCoral)
                }

                // Tasks today
                HStack(spacing: 4) {
                    Ph.listChecks.regular
                        .frame(width: 16, height: 16)
                    Text("\(briefing.tasksToday) today")
                        .font(MomentumFont.label())
                }
                .foregroundColor(.momentumTextSecondary)

                // Milestone progress mini ring
                if let name = briefing.milestoneName {
                    HStack(spacing: 6) {
                        MiniProgressRing(
                            progress: briefing.milestoneProgress / 100,
                            color: accentColor,
                            size: 18
                        )
                        Text(name)
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.bottom, MomentumSpacing.compact)
        }
        .padding(.vertical, MomentumSpacing.compact)
        .background(Color.momentumCardBackground)
        .cornerRadius(MomentumRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .stroke(Color.momentumCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Mini Progress Ring

struct MiniProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Briefing Shimmer Card

struct BriefingShimmerCard: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Accent bar shimmer
            ShimmerRect(width: .infinity, height: 3)
                .padding(.horizontal, MomentumSpacing.standard)

            // Greeting shimmer
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                ShimmerRect(width: 180, height: 28)
                ShimmerRect(width: 140, height: 17)
            }
            .padding(.horizontal, MomentumSpacing.standard)

            // Insight shimmer
            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                ShimmerRect(width: .infinity, height: 17)
                ShimmerRect(width: 220, height: 17)
            }
            .padding(.horizontal, MomentumSpacing.standard)

            // Focus pill shimmer
            ShimmerRect(width: 160, height: 28)
                .padding(.horizontal, MomentumSpacing.standard)

            // Stats shimmer
            HStack(spacing: MomentumSpacing.comfortable) {
                ShimmerRect(width: 50, height: 20)
                ShimmerRect(width: 70, height: 20)
                ShimmerRect(width: 100, height: 20)
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.bottom, MomentumSpacing.compact)
        }
        .padding(.vertical, MomentumSpacing.compact)
        .background(Color.momentumCardBackground)
        .cornerRadius(MomentumRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .stroke(Color.momentumCardBorder, lineWidth: 1)
        )
    }
}

struct ShimmerRect: View {
    let width: CGFloat
    let height: CGFloat

    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.momentumTextTertiary.opacity(0.15))
            .frame(maxWidth: width == .infinity ? .infinity : width, maxHeight: height)
            .frame(height: height)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.momentumTextTertiary.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Quick Actions Row

struct QuickActionsRow: View {
    let onAskAI: () -> Void
    let onRefreshBriefing: () -> Void

    var body: some View {
        HStack(spacing: MomentumSpacing.compact) {
            Button {
                onAskAI()
            } label: {
                HStack(spacing: 6) {
                    Ph.chatCircleDots.regular
                        .frame(width: 16, height: 16)
                    Text("Ask AI")
                        .font(MomentumFont.label())
                }
                .foregroundColor(.momentumBlue)
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.vertical, MomentumSpacing.compact)
                .background(Color.momentumBlue.opacity(0.1))
                .cornerRadius(MomentumRadius.small)
            }

            Button {
                onRefreshBriefing()
            } label: {
                HStack(spacing: 6) {
                    Ph.arrowClockwise.regular
                        .frame(width: 16, height: 16)
                    Text("Refresh Briefing")
                        .font(MomentumFont.label())
                }
                .foregroundColor(.momentumViolet)
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.vertical, MomentumSpacing.compact)
                .background(Color.momentumViolet.opacity(0.1))
                .cornerRadius(MomentumRadius.small)
            }

            Spacer()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
