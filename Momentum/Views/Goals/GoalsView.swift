//
//  GoalsView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import PhosphorSwift

struct GoalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var expandedPowerGoalId: UUID?
    @State private var expandedTaskId: UUID?
    @State private var editingBrainstormForTask: UUID?
    @State private var brainstormText: String = ""
    @State private var selectedFilter: GoalFilter = .all
    @State private var showProfile = false
    @State private var showAddGoal = false

    enum GoalFilter: String, CaseIterable {
        case all = "All"
        case projects = "Projects"
        case habits = "Habits"
        case identities = "Identities"
    }

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with profile icon
                    HStack {
                        Text("Your Goals")
                            .font(MomentumFont.heading(20))
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            showProfile = true
                        } label: {
                            Ph.userCircle.fill
                                .frame(width: 28, height: 28)
                                .color(.momentumSecondaryText)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(GoalFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Active Project Section
                    if selectedFilter == .all || selectedFilter == .projects {
                        projectSection
                    }

                    // Active Habits Section
                    if selectedFilter == .all || selectedFilter == .habits {
                        habitsSection
                    }

                    // Active Identity Section
                    if selectedFilter == .all || selectedFilter == .identities {
                        identitySection
                    }

                    // Add New Goal Button
                    addGoalButton
                        .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showAddGoal) {
            QuickPlanGeneratorSheet()
        }
    }

    private func getCurrentPowerGoal() -> PowerGoal? {
        guard let goal = appState.activeProjectGoal else { return nil }
        return goal.powerGoals.first(where: { $0.status == .active })
    }

    // MARK: - Goal Type Sections

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Active Project", icon: "target")

            if appState.activeProjectGoal != nil {
                // Current Focus Card
                if let currentPowerGoal = getCurrentPowerGoal() {
                    currentFocusCard(currentPowerGoal)
                }

                // All Power Goals Section
                allPowerGoalsSection
            } else {
                emptyStateCard(
                    icon: "target",
                    title: "No Active Project",
                    subtitle: "Start a new 12-month project goal to track structured progress"
                )
            }
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Active Habits", icon: "repeat")

            if !appState.activeHabitGoals.isEmpty {
                VStack(spacing: 12) {
                    ForEach(appState.activeHabitGoals) { habit in
                        HabitGoalCard(habit: habit)
                    }
                }
                .padding(.horizontal)
            } else {
                emptyStateCard(
                    icon: "repeat",
                    title: "No Active Habits",
                    subtitle: "Create daily habits to build consistency and track streaks"
                )
            }
        }
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Active Identity", icon: "person.fill.badge.plus")

            if let identity = appState.activeIdentityGoal {
                IdentityGoalCard(identity: identity)
            } else {
                emptyStateCard(
                    icon: "person.fill.badge.plus",
                    title: "No Active Identity",
                    subtitle: "Build a new identity through consistent evidence collection"
                )
            }
        }
    }

    // MARK: - Helper Components

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            iconForName(icon)
                .color(.momentumViolet)
                .frame(width: 18, height: 18)
            Text(title)
                .font(MomentumFont.bodyMedium(18))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
    }

    private func iconForName(_ name: String) -> Image {
        switch name {
        case "target":
            return Ph.target.regular
        case "repeat":
            return Ph.repeat.regular
        case "person.fill.badge.plus":
            return Ph.userPlus.fill
        default:
            return Ph.circle.regular
        }
    }

    private func iconForEmptyState(_ name: String) -> Image {
        switch name {
        case "target":
            return Ph.target.regular
        case "repeat":
            return Ph.repeat.regular
        case "person.fill.badge.plus":
            return Ph.userPlus.fill
        default:
            return Ph.circle.regular
        }
    }

    private func emptyStateCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            iconForEmptyState(icon)
                .color(.momentumSecondaryText)
                .frame(width: 40, height: 40)

            Text(title)
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)

            Text(subtitle)
                .font(MomentumFont.body(14))
                .foregroundColor(.momentumSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Current Focus Card
    private func currentFocusCard(_ powerGoal: PowerGoal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Focus")
                    .font(MomentumFont.bodyMedium(14))
                    .foregroundColor(.momentumSecondaryText)
                Spacer()
                Ph.target.regular
                    .frame(width: 16, height: 16)
                    .color(.momentumViolet)
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
                    (expandedPowerGoalId == powerGoal.id ? Ph.caretUp.regular : Ph.caretDown.regular)
                        .frame(width: 14, height: 14)
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
                        milestoneIcon(for: milestone.status)
                            .color(milestoneColor(for: milestone.status))
                            .frame(width: 16, height: 16)

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

    private func milestoneIcon(for status: MilestoneStatus) -> Image {
        switch status {
        case .completed:
            return Ph.checkCircle.fill
        case .inProgress:
            return Ph.circle.regular
        case .pending:
            return Ph.circle.regular
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
        let tasksWithNotes = appState.tasksWithNotes()

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(sortedDates, id: \.self) { date in
                if let dayTasks = groupedTasks[date] {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dayLabel(for: date))
                            .font(MomentumFont.body(12))
                            .foregroundColor(.momentumSecondaryText)

                        ForEach(dayTasks) { task in
                            VStack(spacing: 0) {
                                // Task Row (tappable)
                                Button {
                                    withAnimation(.spring()) {
                                        if expandedTaskId == task.id {
                                            expandedTaskId = nil
                                        } else {
                                            expandedTaskId = task.id
                                        }
                                    }
                                } label: {
                                    taskRow(task, hasNotes: tasksWithNotes.contains(task.id))
                                }
                                .buttonStyle(.plain)

                                // Expanded Notes Section
                                if expandedTaskId == task.id {
                                    taskNotesSection(task)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.leading, 24)
    }

    private func taskRow(_ task: MomentumTask, hasNotes: Bool) -> some View {
        HStack(spacing: 8) {
            (task.status == .completed ? Ph.checkCircle.fill : Ph.circle.regular)
                .frame(width: 14, height: 14)
                .color(task.status == .completed ? .momentumGreenStart : .momentumSecondaryText)

            Text(task.title)
                .font(MomentumFont.body(14))
                .foregroundColor(task.status == .completed ? .momentumSecondaryText : .white)
                .strikethrough(task.status == .completed)

            Spacer()

            // Notes indicator badge
            if hasNotes {
                Ph.note.regular
                    .frame(width: 12, height: 12)
                    .color(.momentumViolet)
            }

            (expandedTaskId == task.id ? Ph.caretUp.regular : Ph.caretDown.regular)
                .frame(width: 10, height: 10)
                .color(.momentumSecondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(expandedTaskId == task.id ? Color.white.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Task Notes Section

    private func taskNotesSection(_ task: MomentumTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Brainstorm Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Brainstorm & Ideas")
                    .font(MomentumFont.bodyMedium(14))
                    .foregroundColor(.white)

                if task.notes.userBrainstorms.isEmpty {
                    TextField("Put brainstormed ideas here and I will help you do them", text: $brainstormText, axis: .vertical)
                        .font(MomentumFont.body(14))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .lineLimit(3...6)
                        .onSubmit {
                            if !brainstormText.isEmpty {
                                appState.updateBrainstorm(taskId: task.id, brainstormId: nil, content: brainstormText)
                                brainstormText = ""
                            }
                        }
                } else {
                    ForEach(task.notes.userBrainstorms) { brainstorm in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(brainstorm.content)
                                .font(MomentumFont.body(14))
                                .foregroundColor(.white)

                            Text(brainstorm.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(MomentumFont.body(11))
                                .foregroundColor(.momentumSecondaryText)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Add another brainstorm
                    Button {
                        editingBrainstormForTask = task.id
                    } label: {
                        HStack {
                            Ph.plusCircle.regular
                                .frame(width: 13, height: 13)
                            Text("Add another idea")
                        }
                        .font(MomentumFont.body(13))
                        .foregroundColor(.momentumViolet)
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Research Findings Section
            if !task.notes.researchFindings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Research Findings")
                        .font(MomentumFont.bodyMedium(14))
                        .foregroundColor(.white)

                    ForEach(task.notes.researchFindings) { finding in
                        researchFindingCard(finding)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))
            }

            // Conversation History Section
            if !task.notes.conversationHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI Conversation History")
                            .font(MomentumFont.bodyMedium(14))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(task.notes.conversationHistory.count) messages")
                            .font(MomentumFont.body(12))
                            .foregroundColor(.momentumSecondaryText)
                    }

                    // Show last 3 messages
                    ForEach(task.notes.conversationHistory.suffix(3)) { message in
                        conversationMessageRow(message)
                    }

                    if task.notes.conversationHistory.count > 3 {
                        Button {
                            // Open AI assistant with this task
                            appState.openGlobalChat(withTask: task)
                        } label: {
                            Text("View full conversation (\(task.notes.conversationHistory.count) messages)")
                                .font(MomentumFont.body(12))
                                .foregroundColor(.momentumViolet)
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))
            }

            // Open AI Assistant Button
            Button {
                appState.openGlobalChat(withTask: task)
            } label: {
                HStack {
                    Ph.sparkle.regular
                        .frame(width: 13, height: 13)
                    Text("Ask AI for help with this task")
                }
                .font(MomentumFont.bodyMedium(13))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(MomentumGradients.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
    }

    private func researchFindingCard(_ finding: ResearchFinding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(finding.query)
                    .font(MomentumFont.bodyMedium(13))
                    .foregroundColor(.white)

                Spacer()

                Text(finding.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(MomentumFont.body(11))
                    .foregroundColor(.momentumSecondaryText)
            }

            // Show clarifications if any
            if !finding.clarifyingQA.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(finding.clarifyingQA.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 4) {
                            Text("Q:")
                                .font(MomentumFont.bodyMedium(12))
                                .foregroundColor(.momentumViolet)
                            Text(finding.clarifyingQA[index].question)
                                .font(MomentumFont.body(12))
                                .foregroundColor(.momentumSecondaryText)
                        }
                        HStack(alignment: .top, spacing: 4) {
                            Text("A:")
                                .font(MomentumFont.bodyMedium(12))
                                .foregroundColor(.momentumGreenStart)
                            Text(finding.clarifyingQA[index].answer)
                                .font(MomentumFont.body(12))
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            Text(finding.searchResults)
                .font(MomentumFont.body(13))
                .foregroundColor(.momentumSecondaryText)
                .lineLimit(4)

            Button {
                // Expand to show full research - for now just open AI chat
                appState.openGlobalChat(withTask: appState.findTask(by: finding.id) ?? appState.globalChatTaskContext)
            } label: {
                Text("Read more")
                    .font(MomentumFont.body(12))
                    .foregroundColor(.momentumViolet)
            }
        }
        .padding(10)
        .background(Color.momentumViolet.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func conversationMessageRow(_ message: ConversationMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                Ph.sparkle.regular
                    .frame(width: 10, height: 10)
                    .color(.momentumViolet)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(message.content)
                    .font(MomentumFont.body(12))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(MomentumFont.body(10))
                    .foregroundColor(.momentumSecondaryText)
            }
        }
        .padding(8)
        .background(message.role == .user ? Color.momentumViolet.opacity(0.1) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                ForEach(appState.activeProjectGoal?.powerGoals ?? []) { powerGoal in
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
                    Ph.check.regular
                        .frame(width: 14, height: 14)
                        .color(.momentumGreenStart)
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
                showAddGoal = true
            } label: {
                HStack {
                    Ph.plusCircle.fill
                        .frame(width: 16, height: 16)
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

// MARK: - Habit Goal Card Component

struct HabitGoalCard: View {
    let habit: Goal
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(habit.visionText)
                    .font(MomentumFont.heading(18))
                    .foregroundColor(.white)

                Spacer()

                Ph.repeat.regular
                    .frame(width: 18, height: 18)
                    .color(.momentumViolet)
            }

            if let config = habit.habitConfig {
                // Streak Stats
                HStack(spacing: 16) {
                    statBox(title: "Current", value: "\(config.currentStreak)", emoji: "🔥")
                    statBox(title: "Longest", value: "\(config.longestStreak)", emoji: "⭐")
                    statBox(title: "Frequency", value: config.frequency.rawValue.capitalized, emoji: "📅")
                }

                // Progress indicator
                if let weeklyGoal = config.weeklyGoal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("This week")
                                .font(MomentumFont.body(13))
                                .foregroundColor(.momentumSecondaryText)
                            Spacer()
                            Text("Goal: \(weeklyGoal)")
                                .font(MomentumFont.body(13))
                                .foregroundColor(.momentumSecondaryText)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(MomentumGradients.success)
                                    .frame(width: geo.size.width * min(Double(config.currentStreak % 7) / Double(weeklyGoal), 1.0))
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.momentumViolet.opacity(0.5), lineWidth: 1)
        )
    }

    private func statBox(title: String, value: String, emoji: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 20))
            Text(value)
                .font(MomentumFont.stats(18))
                .foregroundColor(.white)
            Text(title)
                .font(MomentumFont.body(12))
                .foregroundColor(.momentumSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Identity Goal Card Component

struct IdentityGoalCard: View {
    let identity: Goal
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(identity.visionText)
                        .font(MomentumFont.heading(18))
                        .foregroundColor(.white)

                    if let identityStatement = identity.identityConfig?.identityStatement {
                        Text(identityStatement)
                            .font(MomentumFont.body(15))
                            .foregroundColor(.momentumGold)
                            .italic()
                    }
                }

                Spacer()

                Ph.userPlus.fill
                    .frame(width: 18, height: 18)
                    .color(.momentumGold)
            }

            if let config = identity.identityConfig {
                // Evidence Stats
                HStack(spacing: 16) {
                    statBox(
                        title: "Evidence",
                        value: "\(config.evidenceEntries.count)",
                        icon: "doc.text.fill"
                    )
                    statBox(
                        title: "Milestones",
                        value: "\(config.milestones.filter(\.isCompleted).count)/\(config.milestones.count)",
                        icon: "flag.fill"
                    )
                }

                // Recent Evidence
                if !config.evidenceEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Evidence")
                            .font(MomentumFont.bodyMedium(14))
                            .foregroundColor(.white)

                        ForEach(config.evidenceEntries.prefix(2)) { entry in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(moodColor(for: entry.mood))
                                    .frame(width: 8, height: 8)

                                Text(entry.description)
                                    .font(MomentumFont.body(13))
                                    .foregroundColor(.momentumSecondaryText)
                                    .lineLimit(1)

                                Spacer()

                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(MomentumFont.body(11))
                                    .foregroundColor(.momentumSecondaryText)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.momentumGold.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func statBox(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.momentumViolet)
            Text(value)
                .font(MomentumFont.stats(18))
                .foregroundColor(.white)
            Text(title)
                .font(MomentumFont.body(12))
                .foregroundColor(.momentumSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func moodColor(for mood: EvidenceMood) -> Color {
        switch mood {
        case .struggled: return .momentumCoral
        case .okay: return .momentumGold
        case .good: return .momentumGreenStart
        case .great: return .momentumViolet
        }
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
