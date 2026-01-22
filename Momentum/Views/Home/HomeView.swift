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

    // Calculate points for display
    private var weeklyPoints: Int {
        appState.weeklyPointsEarned
    }

    private var pendingTasks: [MomentumTask] {
        appState.todaysTasks.filter { task in
            task.status != .completed && !completedTaskIds.contains(task.id)
        }
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
                        appState.selectedTab = .progress
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                ScrollView {
                    VStack(spacing: MomentumSpacing.section) {
                        // Header
                        HeaderView(
                            weeklyPoints: weeklyPoints,
                            weeklyMax: 42
                        )
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .padding(.top, MomentumSpacing.standard)

                        // Task cards
                        if pendingTasks.isEmpty && appState.todaysTasks.isEmpty {
                            EmptyTasksView()
                                .padding(.top, MomentumSpacing.large)
                        } else if pendingTasks.isEmpty {
                            // All completed - show briefly before celebration
                            VStack(spacing: MomentumSpacing.standard) {
                                Ph.checkCircle.fill
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.momentumSuccess)

                                Text("All done for today!")
                                    .font(MomentumFont.bodyMedium())
                                    .foregroundColor(.momentumTextSecondary)
                            }
                            .padding(.top, MomentumSpacing.large)
                        } else {
                            VStack(spacing: MomentumSpacing.standard) {
                                ForEach(Array(pendingTasks.enumerated()), id: \.element.id) { index, task in
                                    TaskCardView(
                                        task: task,
                                        goalName: goalName(for: task),
                                        onComplete: {
                                            completeTask(task)
                                        },
                                        onExpand: {}
                                    )
                                    .offset(y: appeared ? 0 : 30)
                                    .opacity(appeared ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1),
                                        value: appeared
                                    )
                                }
                            }
                            .padding(.horizontal, MomentumSpacing.comfortable)
                        }

                        // Bottom spacing for tab bar
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .onAppear {
            appeared = true
        }
    }

    // MARK: - Helpers

    private func goalName(for task: MomentumTask) -> String {
        if let goal = appState.activeProjectGoal, goal.id == task.goalId {
            return goal.visionRefined ?? goal.visionText
        }
        for habit in appState.activeHabitGoals where habit.id == task.goalId {
            return habit.visionText
        }
        if let identity = appState.activeIdentityGoal, identity.id == task.goalId {
            return identity.identityConfig?.identityStatement ?? identity.visionText
        }
        return "Goal"
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
