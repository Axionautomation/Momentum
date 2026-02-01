//
//  HomeView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
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
                VStack(spacing: MomentumSpacing.section) {
                    // Header
                    HomeHeaderView(
                        streakCount: appState.streakCount,
                        milestoneProgress: appState.currentMilestoneProgress
                    )
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // AI Feed Section (if there are items)
                    if !appState.aiFeedItems.isEmpty {
                        AIFeedSection(items: appState.aiFeedItems)
                            .padding(.horizontal, MomentumSpacing.comfortable)
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

                    Spacer()

                    // Task cards carousel
                    if pendingTasks.isEmpty && appState.todaysTasks.isEmpty {
                        EmptyTasksView()
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
                    } else {
                        CardStackView(
                            tasks: allTodayTasks,
                            goalNameForTask: { goalName(for: $0) },
                            isTaskCompleted: { isTaskCompleted($0) },
                            onComplete: { completeTask($0) },
                            onExpand: { task in expandedTask = task }
                        )
                        .frame(height: ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height ?? 800) * 0.50)
                    }

                    Spacer()

                    // Bottom spacing for tab bar
                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            appeared = true
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
                Text("AI Assistant")
                    .font(MomentumFont.bodyMedium())
            }
            .foregroundColor(.momentumViolet)

            ForEach(items.prefix(3)) { item in
                AIFeedCard(item: item)
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
            .background(Color.momentumSurfacePrimary)
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

    var body: some View {
        NavigationView {
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
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func skillQuestionView(_ question: SkillQuestion) -> some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            Text(question.question)
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            ForEach(question.options, id: \.self) { option in
                Button {
                    appState.submitSkillAnswer(question, answer: option)
                    dismiss()
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
                    .background(Color.momentumSurfaceSecondary)
                    .cornerRadius(12)
                }
            }
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
                .background(Color.momentumSurfaceSecondary)
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
                                .background(question.answer == option ? Color.momentumSuccess.opacity(0.1) : Color.momentumSurfaceSecondary)
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        TextField("Your answer...", text: .constant(question.answer ?? ""))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(MomentumSpacing.compact)
                .background(Color.momentumSurfacePrimary)
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

#Preview {
    HomeView()
        .environmentObject(AppState())
}
