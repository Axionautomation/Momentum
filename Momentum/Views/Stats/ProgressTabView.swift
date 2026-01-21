//
//  ProgressTabView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift

struct ProgressTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Header
                    VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                        Text("Your Progress")
                            .font(MomentumFont.headingLarge())
                            .foregroundColor(.momentumTextPrimary)

                        Text("Track your journey to success")
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // Weekly Stats Card
                    WeeklyStatsCard(
                        points: appState.weeklyPointsEarned,
                        maxPoints: appState.weeklyPointsMax,
                        streak: appState.currentUser?.streakCount ?? 0
                    )
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    // Goal Roadmap
                    if let goal = appState.activeProjectGoal {
                        GoalRoadmapCard(goal: goal)
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .offset(y: appeared ? 0 : 30)
                            .opacity(appeared ? 1 : 0)
                    } else {
                        NoGoalCard()
                            .padding(.horizontal, MomentumSpacing.comfortable)
                    }

                    // Bottom spacing for tab bar
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Weekly Stats Card

struct WeeklyStatsCard: View {
    let points: Int
    let maxPoints: Int
    let streak: Int

    var body: some View {
        VStack(spacing: MomentumSpacing.standard) {
            HStack {
                Text("This Week")
                    .font(MomentumFont.headingMedium())
                    .foregroundColor(.momentumTextPrimary)
                Spacer()
            }

            HStack(spacing: MomentumSpacing.section) {
                // Points ring
                LargeProgressRing(currentPoints: points, maxPoints: maxPoints)

                VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                    // Streak
                    HStack(spacing: MomentumSpacing.tight) {
                        Ph.flame.fill
                            .frame(width: 24, height: 24)
                            .foregroundColor(.momentumWarning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(streak) day streak")
                                .font(MomentumFont.bodyMedium())
                                .foregroundColor(.momentumTextPrimary)

                            Text("Keep it going!")
                                .font(MomentumFont.caption())
                                .foregroundColor(.momentumTextSecondary)
                        }
                    }

                    Divider()

                    // Points breakdown
                    HStack(spacing: MomentumSpacing.tight) {
                        Ph.star.fill
                            .frame(width: 24, height: 24)
                            .foregroundColor(.momentumBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(points) points earned")
                                .font(MomentumFont.bodyMedium())
                                .foregroundColor(.momentumTextPrimary)

                            Text("\(maxPoints - points) to go")
                                .font(MomentumFont.caption())
                                .foregroundColor(.momentumTextSecondary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Goal Roadmap Card

struct GoalRoadmapCard: View {
    let goal: Goal

    private var currentMonth: Int {
        goal.powerGoals.firstIndex(where: { $0.status == .active }) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            HStack {
                Text("Goal Roadmap")
                    .font(MomentumFont.headingMedium())
                    .foregroundColor(.momentumTextPrimary)
                Spacer()

                Text("Month \(currentMonth + 1) of 12")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextSecondary)
            }

            // Vision
            Text(goal.visionRefined ?? goal.visionText)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextSecondary)
                .lineLimit(2)

            // Power Goals Timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MomentumSpacing.compact) {
                    ForEach(Array(goal.powerGoals.enumerated()), id: \.element.id) { index, powerGoal in
                        PowerGoalNode(
                            month: index + 1,
                            title: powerGoal.title,
                            status: powerGoal.status,
                            isCurrent: powerGoal.status == .active
                        )
                    }
                }
                .padding(.vertical, MomentumSpacing.tight)
            }
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Power Goal Node

struct PowerGoalNode: View {
    let month: Int
    let title: String
    let status: PowerGoalStatus
    let isCurrent: Bool

    private var nodeColor: Color {
        switch status {
        case .completed: return .momentumSuccess
        case .active: return .momentumBlue
        case .locked: return .momentumTextTertiary
        }
    }

    var body: some View {
        VStack(spacing: MomentumSpacing.tight) {
            // Node circle
            ZStack {
                Circle()
                    .fill(nodeColor.opacity(isCurrent ? 0.2 : 0.1))
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(nodeColor)
                    .frame(width: 32, height: 32)

                if status == .completed {
                    Ph.check.bold
                        .frame(width: 16, height: 16)
                        .foregroundColor(.white)
                } else {
                    Text("\(month)")
                        .font(MomentumFont.label())
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(nodeColor, lineWidth: isCurrent ? 3 : 0)
                    .frame(width: 50, height: 50)
            )

            // Title
            Text(title)
                .font(MomentumFont.caption())
                .foregroundColor(isCurrent ? .momentumTextPrimary : .momentumTextSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// MARK: - No Goal Card

struct NoGoalCard: View {
    var body: some View {
        VStack(spacing: MomentumSpacing.standard) {
            Ph.target.regular
                .frame(width: 48, height: 48)
                .foregroundColor(.momentumTextTertiary)

            Text("No active goal")
                .font(MomentumFont.bodyMedium())
                .foregroundColor(.momentumTextSecondary)

            Text("Start your journey by setting a goal")
                .font(MomentumFont.body(14))
                .foregroundColor(.momentumTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MomentumSpacing.large)
        .momentumCard()
    }
}

#Preview {
    ProgressTabView()
        .environmentObject(AppState())
}
