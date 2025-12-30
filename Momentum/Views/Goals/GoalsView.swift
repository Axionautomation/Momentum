//
//  GoalsView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var expandedPowerGoalId: UUID?

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Your Goals")
                        .font(MomentumFont.heading(20))
                        .foregroundColor(.white)
                        .padding(.top)

                    // Current Focus Card
                    if let currentPowerGoal = getCurrentPowerGoal() {
                        currentFocusCard(currentPowerGoal)
                    }

                    // All Power Goals Section
                    allPowerGoalsSection

                    // Add New Goal Button
                    addGoalButton
                        .padding(.bottom, 40)
                }
            }
        }
    }

    private func getCurrentPowerGoal() -> PowerGoal? {
        guard let goal = appState.activeGoal else { return nil }
        return goal.powerGoals.first(where: { $0.status == .active })
    }

    // MARK: - Current Focus Card
    private func currentFocusCard(_ powerGoal: PowerGoal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Focus")
                    .font(MomentumFont.bodyMedium(14))
                    .foregroundColor(.momentumSecondaryText)
                Spacer()
                Image(systemName: "target")
                    .foregroundColor(.momentumViolet)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Month \(powerGoal.monthNumber): \(powerGoal.title)")
                    .font(MomentumFont.heading(20))
                    .foregroundColor(.white)

                if let description = powerGoal.description {
                    Text(description)
                        .font(MomentumFont.body(15))
                        .foregroundColor(.momentumSecondaryText)
                }
            }

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(powerGoal.completionPercentage * 100))% complete")
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)
                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(MomentumGradients.success)
                            .frame(width: geo.size.width * powerGoal.completionPercentage)
                    }
                }
                .frame(height: 10)
            }

            // View Breakdown Button
            Button {
                withAnimation(.spring()) {
                    if expandedPowerGoalId == powerGoal.id {
                        expandedPowerGoalId = nil
                    } else {
                        expandedPowerGoalId = powerGoal.id
                    }
                }
            } label: {
                HStack {
                    Text(expandedPowerGoalId == powerGoal.id ? "Hide Breakdown" : "View Breakdown")
                    Image(systemName: expandedPowerGoalId == powerGoal.id ? "chevron.up" : "chevron.down")
                }
                .font(MomentumFont.bodyMedium(14))
                .foregroundColor(.momentumViolet)
            }

            // Expanded Breakdown
            if expandedPowerGoalId == powerGoal.id {
                weeklyMilestonesView(powerGoal)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.momentumViolet, lineWidth: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Weekly Milestones View
    private func weeklyMilestonesView(_ powerGoal: PowerGoal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Milestones")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
                .padding(.top, 8)

            ForEach(powerGoal.weeklyMilestones) { milestone in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: milestoneIcon(for: milestone.status))
                            .foregroundColor(milestoneColor(for: milestone.status))

                        Text("Week \(milestone.weekNumber): \(milestone.milestoneText)")
                            .font(MomentumFont.bodyMedium(15))
                            .foregroundColor(milestone.status == .pending ? .momentumSecondaryText : .white)
                    }

                    // Tasks for in-progress milestone
                    if milestone.status == .inProgress {
                        tasksListView(milestone.tasks)
                    }
                }
                .padding()
                .background(Color.white.opacity(milestone.status == .inProgress ? 0.08 : 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func milestoneIcon(for status: MilestoneStatus) -> String {
        switch status {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "circle.dotted"
        case .pending: return "circle"
        }
    }

    private func milestoneColor(for status: MilestoneStatus) -> Color {
        switch status {
        case .completed: return .momentumGreenStart
        case .inProgress: return .momentumViolet
        case .pending: return .momentumSecondaryText
        }
    }

    // MARK: - Tasks List View
    private func tasksListView(_ tasks: [MomentumTask]) -> some View {
        let groupedTasks = Dictionary(grouping: tasks) { task in
            Calendar.current.startOfDay(for: task.scheduledDate)
        }

        let sortedDates = groupedTasks.keys.sorted()

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(sortedDates, id: \.self) { date in
                if let dayTasks = groupedTasks[date] {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dayLabel(for: date))
                            .font(MomentumFont.body(12))
                            .foregroundColor(.momentumSecondaryText)

                        ForEach(dayTasks) { task in
                            HStack(spacing: 8) {
                                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(task.status == .completed ? .momentumGreenStart : .momentumSecondaryText)

                                Text(task.title)
                                    .font(MomentumFont.body(14))
                                    .foregroundColor(task.status == .completed ? .momentumSecondaryText : .white)
                                    .strikethrough(task.status == .completed)
                            }
                        }
                    }
                }
            }
        }
        .padding(.leading, 24)
    }

    private func dayLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    // MARK: - All Power Goals Section
    private var allPowerGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Power Goals (12)")
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(appState.activeGoal?.powerGoals ?? []) { powerGoal in
                    powerGoalRow(powerGoal)
                }
            }
            .padding(.horizontal)
        }
    }

    private func powerGoalRow(_ powerGoal: PowerGoal) -> some View {
        HStack {
            // Status Icon
            ZStack {
                Circle()
                    .fill(powerGoalColor(for: powerGoal.status).opacity(0.2))
                    .frame(width: 36, height: 36)

                if powerGoal.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.momentumGreenStart)
                } else {
                    Text("\(powerGoal.monthNumber)")
                        .font(MomentumFont.stats(14))
                        .foregroundColor(powerGoalColor(for: powerGoal.status))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Month \(powerGoal.monthNumber): \(powerGoal.title)")
                    .font(MomentumFont.bodyMedium(15))
                    .foregroundColor(powerGoal.status == .locked ? .momentumSecondaryText : .white)

                if powerGoal.status == .active {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(MomentumGradients.success)
                                .frame(width: geo.size.width * powerGoal.completionPercentage)
                        }
                    }
                    .frame(height: 4)
                } else if powerGoal.status == .locked {
                    Text("Locked until Month \(powerGoal.monthNumber - 1) done")
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumSecondaryText)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(powerGoal.status == .active ? 0.08 : 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    powerGoal.status == .active ? Color.momentumViolet.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private func powerGoalColor(for status: PowerGoalStatus) -> Color {
        switch status {
        case .completed: return .momentumGreenStart
        case .active: return .momentumViolet
        case .locked: return .momentumSecondaryText
        }
    }

    // MARK: - Add Goal Button
    private var addGoalButton: some View {
        VStack(spacing: 8) {
            Button {
                // Add new goal flow
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Goal")
                }
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.momentumViolet)
            }

            Text("(Premium: Unlimited / Free: 2)")
                .font(MomentumFont.body(12))
                .foregroundColor(.momentumSecondaryText)
        }
        .padding()
    }
}

#Preview {
    GoalsView()
        .environmentObject({
            let state = AppState()
            state.loadMockData()
            return state
        }())
}
