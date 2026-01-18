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
    @State private var selectedTask: MomentumTask?
    @State private var showProfile = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    var body: some View {
        ZStack {
            // Background
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView

                    // Vision Card
                    visionCard

                    // Today's Date Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Momentum")
                            .font(MomentumFont.heading(24))
                            .foregroundColor(.white)

                        Text(dateFormatter.string(from: Date()))
                            .font(MomentumFont.body(16))
                            .foregroundColor(.momentumSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // PROJECT TASKS SECTION
                    if !appState.todaysTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(
                                title: "Project Tasks",
                                subtitle: appState.activeProjectGoal?.visionRefined,
                                icon: "target"
                            )

                            VStack(spacing: 12) {
                                ForEach(appState.todaysTasks) { task in
                                    TaskCardView(task: task) {
                                        selectedTask = task
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // HABIT CHECK-INS SECTION
                    if !appState.todaysHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(
                                title: "Daily Habits",
                                subtitle: "\(appState.todaysHabits.filter(\.isCompleted).count)/\(appState.todaysHabits.count) complete",
                                icon: "repeat"
                            )

                            VStack(spacing: 8) {
                                ForEach(appState.todaysHabits) { habit in
                                    HabitCheckInRow(checkIn: habit)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // IDENTITY TASK SECTION
                    if let identityTask = appState.todaysIdentityTask {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(
                                title: "Identity Building",
                                subtitle: appState.activeIdentityGoal?.identityConfig?.identityStatement,
                                icon: "person.fill.badge.plus"
                            )

                            TaskCardView(task: identityTask) {
                                selectedTask = identityTask
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.momentumGold, lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Weekly Progress
                    weeklyProgressView

                    // View Journey Button
                    Button {
                        appState.selectedTab = .journey
                    } label: {
                        HStack {
                            Text("View Your Journey")
                            Ph.arrowRight.regular
                                .frame(width: 16, height: 16)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .padding(.top)
            }

            // Task Completion Toast
            if appState.showTaskCompletionCelebration {
                VStack {
                    CompletionToast(message: appState.completedTaskMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .animation(.spring(), value: appState.showTaskCompletionCelebration)
            }

            // All Tasks Complete Celebration
            if appState.showAllTasksCompleteCelebration {
                AllTasksCompleteCelebrationView {
                    appState.showAllTasksCompleteCelebration = false
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task) {
                appState.completeTask(task)
                selectedTask = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 20))
                Text("\(appState.currentUser?.streakCount ?? 0)")
                    .font(MomentumFont.stats(18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())

            Spacer()

            Button {
                showProfile = true
            } label: {
                Ph.userCircle.fill
                    .frame(width: 32, height: 32)
                    .color(.momentumSecondaryText)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Vision Card
    private var visionCard: some View {
        VStack {
            Text(appState.activeProjectGoal?.visionRefined ?? appState.activeProjectGoal?.visionText ?? "Set your vision")
                .font(MomentumFont.bodyMedium(18))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.momentumSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.momentumDeepBlue.opacity(0.5), .momentumViolet.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Section Header
    private func sectionHeader(title: String, subtitle: String?, icon: String) -> some View {
        HStack(spacing: 8) {
            iconForName(icon)
                .color(.momentumViolet)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MomentumFont.heading(20))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MomentumFont.body(14))
                        .foregroundColor(.momentumSecondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
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

    // MARK: - Weekly Progress
    private var weeklyProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Week: \(appState.weeklyTasksCompleted)/\(appState.weeklyTotalTasks) tasks")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumSecondaryText)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(MomentumGradients.success)
                        .frame(width: geo.size.width * CGFloat(appState.weeklyTasksCompleted) / CGFloat(max(appState.weeklyTotalTasks, 1)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Task Card View
struct TaskCardView: View {
    let task: MomentumTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .strokeBorder(task.status == .completed ? Color.momentumGreenStart : Color.momentumSecondaryText, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if task.status == .completed {
                        Circle()
                            .fill(MomentumGradients.success)
                            .frame(width: 28, height: 28)

                        Ph.check.regular
                            .frame(width: 14, height: 14)
                            .color(.white)
                    }
                }

                // Task Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(MomentumFont.bodyMedium(17))
                        .foregroundColor(task.status == .completed ? .momentumSecondaryText : .white)
                        .strikethrough(task.status == .completed)
                        .lineLimit(2)

                    if task.status == .completed, let completedAt = task.completedAt {
                        Text("Done at \(completedAt.formatted(date: .omitted, time: .shortened))")
                            .font(MomentumFont.body(13))
                            .foregroundColor(.momentumGreenStart)
                    } else {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Ph.clock.regular
                                    .frame(width: 12, height: 12)
                                    .color(.momentumSecondaryText)
                                Text("\(task.estimatedMinutes) min")
                                    .font(MomentumFont.body(13))
                                    .foregroundColor(.momentumSecondaryText)
                            }

                            HStack(spacing: 4) {
                                Text(task.difficulty.emoji)
                                    .font(.system(size: 12))
                                Text(task.difficulty.displayName)
                                    .font(MomentumFont.body(13))
                            }
                            .foregroundColor(Color(hex: task.difficulty.color))
                        }
                    }
                }

                Spacer()

                if task.status != .completed {
                    Ph.caretRight.regular
                        .frame(width: 14, height: 14)
                        .color(.momentumSecondaryText)
                }
            }
            .padding()
            .background(Color.white.opacity(task.status == .completed ? 0.03 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        task.isAnchorTask ? Color.momentumViolet.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Detail Sheet
struct TaskDetailSheet: View {
    let task: MomentumTask
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showAIAssistant = false
    @State private var isGeneratingMicrosteps = false
    @State private var generatedMicrosteps: [String] = []
    @StateObject private var groqService = GroqService.shared

    var body: some View {
        ZStack {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Task Title
                VStack(spacing: 8) {
                    Text(task.title)
                        .font(MomentumFont.heading(22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    if let description = task.taskDescription {
                        Text(description)
                            .font(MomentumFont.body(16))
                            .foregroundColor(.momentumSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 24)

                // Metadata
                HStack(spacing: 24) {
                    HStack(spacing: 6) {
                        Ph.clock.regular
                            .frame(width: 15, height: 15)
                            .color(.momentumSecondaryText)
                        Text("\(task.estimatedMinutes) min")
                            .foregroundColor(.momentumSecondaryText)
                    }

                    HStack(spacing: 6) {
                        Text(task.difficulty.emoji)
                        Text(task.difficulty.displayName)
                    }
                    .foregroundColor(Color(hex: task.difficulty.color))
                }
                .font(MomentumFont.body(15))

                // Microsteps
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Microsteps:")
                            .font(MomentumFont.bodyMedium(16))
                            .foregroundColor(.white)

                        Spacer()

                        if task.microsteps.isEmpty && !isGeneratingMicrosteps && generatedMicrosteps.isEmpty {
                            Button {
                                generateMicrosteps()
                            } label: {
                                HStack(spacing: 4) {
                                    Ph.sparkle.regular
                                        .frame(width: 12, height: 12)
                                    Text("Generate")
                                        .font(MomentumFont.body(13))
                                }
                                .foregroundColor(.momentumViolet)
                            }
                        }
                    }

                    if isGeneratingMicrosteps {
                        HStack {
                            ProgressView()
                                .tint(.momentumViolet)
                            Text("AI is creating microsteps...")
                                .font(MomentumFont.body(14))
                                .foregroundColor(.momentumSecondaryText)
                        }
                        .padding()
                    } else if !task.microsteps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(task.microsteps.sorted(by: { $0.orderIndex < $1.orderIndex })) { step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.momentumViolet)
                                    Text(step.stepText)
                                        .foregroundColor(.momentumSecondaryText)
                                }
                                .font(MomentumFont.body(15))
                            }
                        }
                    } else if !generatedMicrosteps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(generatedMicrosteps.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.momentumViolet)
                                    Text(generatedMicrosteps[index])
                                        .foregroundColor(.momentumSecondaryText)
                                }
                                .font(MomentumFont.body(15))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                // AI Assistant Button
                Button {
                    showAIAssistant = true
                } label: {
                    HStack {
                        Ph.sparkle.regular
                            .frame(width: 15, height: 15)
                        Text("Ask AI Assistant for Help")
                    }
                    .font(MomentumFont.bodyMedium(15))
                    .foregroundColor(.momentumViolet)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.momentumViolet.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        onComplete()
                    } label: {
                        HStack {
                            Ph.check.regular
                                .frame(width: 16, height: 16)
                            Text("Mark Complete")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAIAssistant) {
            AIAssistantView(task: task)
        }
    }

    private func generateMicrosteps() {
        isGeneratingMicrosteps = true

        Task {
            do {
                let steps = try await groqService.generateMicrosteps(
                    taskTitle: task.title,
                    taskDescription: task.taskDescription,
                    difficulty: task.difficulty
                )

                await MainActor.run {
                    generatedMicrosteps = steps
                    isGeneratingMicrosteps = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingMicrosteps = false
                    // Could show error message here
                }
                print("Error generating microsteps: \(error)")
            }
        }
    }
}

// MARK: - Completion Toast
struct CompletionToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Text(message)
                .font(MomentumFont.bodyMedium(16))
                .foregroundColor(.white)
            Text("")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.momentumSurfaceSecondary)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.top, 60)
    }
}

// MARK: - All Tasks Complete Celebration
struct AllTasksCompleteCelebrationView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 20) {
                Text(" All 3 Done! ")
                    .font(MomentumFont.heading(28))
                    .foregroundColor(.white)

                Text("You're building unstoppable momentum")
                    .font(MomentumFont.body(18))
                    .foregroundColor(.momentumSecondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("View Progress")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        onDismiss()
                    } label: {
                        HStack {
                            Text("Keep Going")
                            Ph.arrowRight.regular
                                .frame(width: 16, height: 16)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(32)
            .background(Color.momentumDarkBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Habit Check-In Row
struct HabitCheckInRow: View {
    let checkIn: HabitCheckIn
    @EnvironmentObject var appState: AppState

    var habitGoal: Goal? {
        appState.activeHabitGoals.first(where: { $0.id == checkIn.habitGoalId })
    }

    var body: some View {
        Button {
            appState.completeHabitCheckIn(checkIn)
        } label: {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            checkIn.isCompleted ? Color.momentumGreenStart : Color.momentumSecondaryText,
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if checkIn.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(MomentumGradients.success)
                            .frame(width: 28, height: 28)

                        Ph.check.regular
                            .frame(width: 14, height: 14)
                            .color(.white)
                    }
                }

                // Habit info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habitGoal?.visionText ?? "Habit")
                        .font(MomentumFont.bodyMedium(16))
                        .foregroundColor(checkIn.isCompleted ? .momentumSecondaryText : .white)
                        .strikethrough(checkIn.isCompleted)

                    if let config = habitGoal?.habitConfig {
                        HStack(spacing: 4) {
                            Text("🔥")
                            Text("\(config.currentStreak) day streak")
                                .font(MomentumFont.body(13))
                                .foregroundColor(.momentumGreenStart)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.white.opacity(checkIn.isCompleted ? 0.03 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .environmentObject({
            let state = AppState()
            state.loadMockData()
            return state
        }())
}
