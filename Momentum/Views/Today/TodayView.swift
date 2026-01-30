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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // DEBUG: Remove this banner after confirming build works
                    Text("CAROUSEL BUILD - JAN 25")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)

                    // Header: Date and Greeting
                    HeaderSection()

                    // Streak and Progress
                    StatsSection()

                    // Weekly Milestone Overview
                    if let milestone = currentMilestone {
                        MilestoneOverviewCard(milestone: milestone)
                    }

                    // Today's Tasks
                    TasksSection(availableHeight: geometry.size.height)
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
    let availableHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Project Tasks
            if !appState.todaysTasks.isEmpty {
                VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                    Text("Today's Tasks")
                        .font(MomentumFont.headingMedium(20))
                        .foregroundColor(.momentumTextPrimary)

                    TabView {
                        ForEach(appState.todaysTasks) { task in
                            TaskCardView(
                                task: task,
                                goalName: appState.activeProjectGoal?.visionRefined ?? "Project Goal",
                                onComplete: {
                                    appState.completeTask(task)
                                },
                                onExpand: {
                                    selectedTask = task
                                }
                            )
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .padding(.bottom, MomentumSpacing.large)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: availableHeight * 0.55)
                }
            }

            // Empty State
            if appState.todaysTasks.isEmpty {
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
