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

    // Calculate points for display
    private var weeklyPoints: Int {
        appState.weeklyPointsEarned
    }

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

    private var todayPointsEarned: Int {
        appState.todaysTasks
            .filter { $0.status == .completed || completedTaskIds.contains($0.id) }
            .reduce(0) { $0 + pointsForDifficulty($1.difficulty) }
    }

    var body: some View {
        ZStack {
            // Background
            Color.momentumBackground
                .ignoresSafeArea()

            if showCelebration {
                CelebrationView(
                    pointsEarned: todayPointsEarned,
                    weeklyPoints: weeklyPoints + todayPointsEarned,
                    weeklyMax: 42,
                    onDismiss: {
                        withAnimation {
                            showCelebration = false
                        }
                        // Stay on home tab to show "work ahead" option
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                VStack(spacing: MomentumSpacing.section) {
                    // Header
                    HeaderView(
                        weeklyPoints: weeklyPoints,
                        weeklyMax: 42
                    )
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)
                    
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
                                    appState.loadNextTasks()
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
                        .frame(height: ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height ?? 800) * 0.55)
                    }

                    Spacer()
                    
                    // Bottom spacing for tab bar
                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            appeared = true
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
        if let goal = appState.activeProjectGoal, goal.id == task.goalId {
            return goal.visionRefined ?? goal.visionText
        }
        return appState.activeProjectGoal?.visionRefined ?? appState.activeProjectGoal?.visionText ?? "Goal"
    }

    private func pointsForDifficulty(_ difficulty: TaskDifficulty) -> Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
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

        if allComplete {
            // Show celebration after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showCelebration = true
                }
            }
        }
    }

    private func uncompleteTask(_ task: MomentumTask) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            completedTaskIds.remove(task.id)
        }
        appState.uncompleteTask(task)
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

            // Advance index — back cards animate to new positions
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

// MARK: - Header View

struct HeaderView: View {
    let weeklyPoints: Int
    let weeklyMax: Int

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

            // Weekly progress ring
            WeeklyProgressRing(
                currentPoints: weeklyPoints,
                maxPoints: weeklyMax
            )
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
