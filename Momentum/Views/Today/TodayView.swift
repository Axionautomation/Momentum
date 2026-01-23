//
//  TodayView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct TodayView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: MomentumSpacing.section) {
                // Header: Date and Greeting
                HeaderSection()

                // Streak and Progress
                StatsSection()

                // Weekly Milestone Overview
                if let milestone = currentMilestone {
                    MilestoneOverviewCard(milestone: milestone)
                }

                // Today's Tasks
                TasksSection()
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.section)
        }
        .background(Color.momentumBackgroundSecondary)
        .onAppear {
            // Ensure today's content is loaded
            appState.loadTodaysContent()
        }
    }

    // MARK: - Computed Properties

    private var currentMilestone: WeeklyMilestone? {
        guard let projectGoal = appState.activeProjectGoal,
              let currentPowerGoal = projectGoal.powerGoals.first(where: { $0.status == .active }),
              let milestone = currentPowerGoal.weeklyMilestones.first(where: { $0.status == .inProgress }) else {
            return nil
        }
        return milestone
    }

    private var currentGoalName: String {
        appState.activeProjectGoal?.visionRefined ?? appState.activeProjectGoal?.visionText ?? "Your Goal"
    }
}

// MARK: - Header Section

struct HeaderSection: View {
    @EnvironmentObject var appState: AppState

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            Text(greeting)
                .font(MomentumFont.display(32))
                .foregroundColor(.momentumTextPrimary)

            Text(dateString)
                .font(MomentumFont.body(17))
                .foregroundColor(.momentumTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stats Section

struct StatsSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: MomentumSpacing.compact) {
            // Streak Counter
            StreakCard()

            // Weekly Progress
            WeeklyProgressCard()
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
            HStack(spacing: 6) {
                Ph.fire.fill
                    .foregroundColor(.momentumWarning)
                    .frame(width: 18, height: 18)

                Text("Streak")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextSecondary)
            }

            Text("\(appState.currentUser?.streakCount ?? 0)")
                .font(MomentumFont.display(28))
                .foregroundColor(.momentumTextPrimary)

            Text("days")
                .font(MomentumFont.caption())
                .foregroundColor(.momentumTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Weekly Progress Card

struct WeeklyProgressCard: View {
    @EnvironmentObject var appState: AppState

    private var progressPercentage: Double {
        let earned = Double(appState.weeklyPointsEarned)
        let max = Double(appState.weeklyPointsMax)
        return max > 0 ? earned / max : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
            HStack(spacing: 6) {
                Ph.chartBar.fill
                    .foregroundColor(.momentumBlue)
                    .frame(width: 18, height: 18)

                Text("Weekly")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(appState.weeklyPointsEarned)")
                    .font(MomentumFont.display(28))
                    .foregroundColor(.momentumTextPrimary)

                Text("/ \(appState.weeklyPointsMax) pts")
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextTertiary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.momentumCardBorder.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(MomentumGradients.primary)
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Milestone Overview Card

struct MilestoneOverviewCard: View {
    let milestone: WeeklyMilestone
    @EnvironmentObject var appState: AppState

    private var currentPowerGoalTitle: String {
        guard let projectGoal = appState.activeProjectGoal,
              let currentPowerGoal = projectGoal.powerGoals.first(where: { $0.status == .active }) else {
            return ""
        }
        return currentPowerGoal.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack(spacing: 8) {
                Ph.target.fill
                    .foregroundColor(.momentumBlue)
                    .frame(width: 20, height: 20)

                Text("This Week")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextSecondary)

                Spacer()

                Text("Week \(milestone.weekNumber)")
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextTertiary)
                    .padding(.horizontal, MomentumSpacing.tight)
                    .padding(.vertical, 4)
                    .background(Color.momentumBlue.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(currentPowerGoalTitle)
                .font(MomentumFont.headingMedium(18))
                .foregroundColor(.momentumTextPrimary)
                .lineLimit(2)

            Text(milestone.milestoneText)
                .font(MomentumFont.body(15))
                .foregroundColor(.momentumTextSecondary)
                .lineLimit(3)
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Tasks Section

struct TasksSection: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTask: MomentumTask?

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Project Tasks
            if !appState.todaysTasks.isEmpty {
                VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                    Text("Today's Tasks")
                        .font(MomentumFont.headingMedium(20))
                        .foregroundColor(.momentumTextPrimary)

                    ZStack {
                        SwipeableTaskStack(
                            tasks: appState.todaysTasks,
                            goalName: appState.activeProjectGoal?.visionRefined ?? "Project Goal",
                            onTaskComplete: { task in
                                appState.completeTask(task)
                            },
                            onTaskTapped: { task in
                                selectedTask = task
                            }
                        )

                        // Difficulty badge overlay
                        if let currentTask = appState.todaysTasks.first {
                            VStack {
                                HStack {
                                    Spacer()
                                    DifficultyCornerBadge(difficulty: currentTask.difficulty)
                                        .padding(.trailing, MomentumSpacing.standard)
                                        .padding(.top, MomentumSpacing.compact)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Habit Check-ins
            if !appState.todaysHabits.isEmpty {
                VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                    Text("Daily Habits")
                        .font(MomentumFont.headingMedium(20))
                        .foregroundColor(.momentumTextPrimary)

                    ForEach(appState.todaysHabits) { checkIn in
                        HabitCheckInCard(checkIn: checkIn)
                    }
                }
            }

            // Identity Task
            if let identityTask = appState.todaysIdentityTask {
                VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                    Text("Identity Building")
                        .font(MomentumFont.headingMedium(20))
                        .foregroundColor(.momentumTextPrimary)

                    TaskCardView(
                        task: identityTask,
                        goalName: appState.activeIdentityGoal?.identityConfig?.identityStatement ?? "Identity Goal",
                        onComplete: {
                            // Handle identity task completion
                            appState.completeTask(identityTask)
                        },
                        onExpand: {}
                    )
                }
            }

            // Empty State
            if appState.todaysTasks.isEmpty && appState.todaysHabits.isEmpty && appState.todaysIdentityTask == nil {
                EmptyStateView()
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(
                task: task,
                goalName: appState.activeProjectGoal?.visionRefined ?? "Project Goal",
                onComplete: {
                    appState.completeTask(task)
                    selectedTask = nil
                },
                onDismiss: {
                    selectedTask = nil
                }
            )
        }
    }
}

// MARK: - Habit Check-In Card

struct HabitCheckInCard: View {
    let checkIn: HabitCheckIn
    @EnvironmentObject var appState: AppState

    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var showCompletionGlow = false

    private let holdDuration: Double = 0.8

    private var habitGoal: Goal? {
        appState.activeHabitGoals.first { $0.id == checkIn.habitGoalId }
    }

    private var habitName: String {
        habitGoal?.visionRefined ?? habitGoal?.visionText ?? "Habit"
    }

    var body: some View {
        HStack(spacing: MomentumSpacing.compact) {
            // Check indicator
            ZStack {
                Circle()
                    .stroke(Color.momentumSuccess.opacity(0.3), lineWidth: 2)
                    .frame(width: 32, height: 32)

                if checkIn.isCompleted {
                    Circle()
                        .fill(Color.momentumSuccess)
                        .frame(width: 32, height: 32)

                    Ph.check.bold
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                } else if isHolding {
                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(Color.momentumSuccess, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
            }

            // Habit info
            VStack(alignment: .leading, spacing: 4) {
                Text(habitName)
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(checkIn.isCompleted ? .momentumTextTertiary : .momentumTextPrimary)
                    .strikethrough(checkIn.isCompleted)

                if let config = habitGoal?.habitConfig {
                    HStack(spacing: 6) {
                        Ph.fire.fill
                            .frame(width: 14, height: 14)
                        Text("\(config.currentStreak) day streak")
                    }
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextSecondary)
                }
            }

            Spacer()
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        .overlay(
            // Hold fill animation - green fills from edges to center
            GeometryReader { geometry in
                ZStack {
                    // Top edge
                    Rectangle()
                        .fill(Color.momentumSuccess.opacity(0.15))
                        .frame(height: geometry.size.height * holdProgress * 0.5)
                        .frame(maxHeight: .infinity, alignment: .top)

                    // Bottom edge
                    Rectangle()
                        .fill(Color.momentumSuccess.opacity(0.15))
                        .frame(height: geometry.size.height * holdProgress * 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    // Left edge
                    Rectangle()
                        .fill(Color.momentumSuccess.opacity(0.15))
                        .frame(width: geometry.size.width * holdProgress * 0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Right edge
                    Rectangle()
                        .fill(Color.momentumSuccess.opacity(0.15))
                        .frame(width: geometry.size.width * holdProgress * 0.5)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .strokeBorder(
                    Color.momentumSuccess.opacity(0.3),
                    lineWidth: 2
                )
        )
        .overlay(
            // Left accent bar
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.momentumSuccess)
                    .frame(width: 4)
                    .padding(.vertical, 8)
                Spacer()
            }
            .padding(.leading, 4)
        )
        .overlay(
            // Completion glow
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .stroke(Color.momentumSuccess, lineWidth: 4)
                .opacity(showCompletionGlow ? 0.8 : 0)
                .blur(radius: showCompletionGlow ? 4 : 0)
        )
        .shadow(
            color: Color.black.opacity(0.06),
            radius: 12,
            x: 0,
            y: 4
        )
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHolding)
        .opacity(checkIn.isCompleted ? 0.6 : 1.0)
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 50) {
            // Completed
            completeHabit()
        } onPressingChanged: { pressing in
            if !checkIn.isCompleted {
                if pressing {
                    startHold()
                } else {
                    cancelHold()
                }
            }
        }
    }

    // MARK: - Hold Gesture

    private func startHold() {
        isHolding = true
        holdProgress = 0
        SoundManager.shared.lightHaptic()

        // Animate progress
        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }
    }

    private func cancelHold() {
        isHolding = false
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }

    private func completeHabit() {
        isHolding = false
        holdProgress = 1.0

        // Show completion glow
        withAnimation(.easeInOut(duration: 0.3)) {
            showCompletionGlow = true
        }

        // Play sound and haptic
        SoundManager.shared.playPop()
        SoundManager.shared.mediumHaptic()

        // Brief delay then trigger completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.completeHabitCheckIn(checkIn)

            // Hide glow
            withAnimation(.easeOut(duration: 0.2)) {
                showCompletionGlow = false
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: MomentumSpacing.standard) {
            ZStack {
                Circle()
                    .fill(Color.momentumBlue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Ph.checkCircle.fill
                    .font(.system(size: 40))
                    .foregroundColor(.momentumBlue)
            }

            Text("All caught up!")
                .font(MomentumFont.headingMedium(20))
                .foregroundColor(.momentumTextPrimary)

            Text("No tasks scheduled for today. Check back tomorrow or add new goals to stay on track.")
                .font(MomentumFont.body(15))
                .foregroundColor(.momentumTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MomentumSpacing.section)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MomentumSpacing.large)
    }
}

#Preview {
    TodayView()
        .environmentObject(AppState())
}
