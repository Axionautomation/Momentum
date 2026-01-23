//
//  TaskDetailView.swift
//  Momentum
//
//  Created by Claude Code on 1/23/26.
//

import SwiftUI
import PhosphorSwift

struct TaskDetailView: View {
    let task: MomentumTask
    let goalName: String
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject var appState: AppState
    @State private var enhancedDetails: EnhancedTaskDetails?
    @State private var isLoadingDetails = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.large) {
                    // Task Overview Section
                    TaskOverviewSection(task: task, goalName: goalName)

                    // Difficulty Explanation Section
                    if let details = enhancedDetails {
                        DifficultyExplanationSection(
                            difficulty: task.difficulty,
                            explanation: details.difficultyExplanation
                        )
                    } else if isLoadingDetails {
                        LoadingSection(title: "Analyzing Difficulty")
                    }

                    // Microsteps Section
                    MicrostepsSection(
                        microsteps: task.microsteps,
                        timeBreakdown: enhancedDetails?.timeBreakdown
                    )

                    // Time Breakdown Section
                    if let details = enhancedDetails {
                        TimeBreakdownSection(breakdown: details.timeBreakdown)
                    }

                    // Tips Section
                    if let details = enhancedDetails, !details.tips.isEmpty {
                        TipsSection(tips: details.tips)
                    }

                    // Notes & AI Chat Section
                    NotesSection(task: task)

                    Spacer(minLength: 100) // Space for bottom button
                }
                .padding(MomentumSpacing.standard)
            }
            .background(Color.momentumDarkBackground)
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Ph.x.regular
                            .frame(width: 24, height: 24)
                            .foregroundColor(.momentumTextPrimary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Complete Button (hold-to-complete)
                HoldToCompleteButton(onComplete: onComplete)
                    .padding(.horizontal, MomentumSpacing.standard)
                    .padding(.vertical, MomentumSpacing.compact)
                    .background(Color.momentumDarkBackground)
            }
        }
        .task {
            await loadEnhancedDetails()
        }
    }

    private func loadEnhancedDetails() async {
        isLoadingDetails = true
        do {
            enhancedDetails = try await GroqService.shared.generateTaskDetails(
                task: task,
                context: goalName
            )
        } catch {
            print("Failed to load enhanced details: \(error)")
        }
        isLoadingDetails = false
    }
}

// MARK: - Task Overview Section

struct TaskOverviewSection: View {
    let task: MomentumTask
    let goalName: String

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            // Task description
            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
            }

            // Meta information
            HStack(spacing: MomentumSpacing.standard) {
                // Estimated time
                HStack(spacing: 6) {
                    Ph.clock.regular
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time")
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextTertiary)
                        Text("\(task.estimatedMinutes) min")
                            .font(MomentumFont.bodyMedium(15))
                            .foregroundColor(.momentumTextPrimary)
                    }
                }
                .padding(MomentumSpacing.compact)
                .background(Color.momentumSurfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))

                // Goal context
                HStack(spacing: 6) {
                    Ph.target.regular
                        .frame(width: 18, height: 18)
                        .foregroundColor(.momentumBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goal")
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextTertiary)
                        Text(goalName)
                            .font(MomentumFont.bodyMedium(15))
                            .foregroundColor(.momentumTextPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(MomentumSpacing.compact)
                .background(Color.momentumSurfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))

                Spacer()
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

// MARK: - Difficulty Explanation Section

struct DifficultyExplanationSection: View {
    let difficulty: TaskDifficulty
    let explanation: String

    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
        }
    }

    private var difficultyIcon: some View {
        switch difficulty {
        case .easy:
            return Ph.checkCircle.regular
        case .medium:
            return Ph.warning.regular
        case .hard:
            return Ph.lightning.regular
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack(spacing: MomentumSpacing.tight) {
                difficultyIcon
                    .frame(width: 20, height: 20)
                    .foregroundColor(difficultyColor)

                Text("Why \(difficulty.displayName)?")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)
            }

            Text(explanation)
                .font(MomentumFont.body(15))
                .foregroundColor(.momentumTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

// MARK: - Microsteps Section

struct MicrostepsSection: View {
    let microsteps: [Microstep]
    let timeBreakdown: [MicrostepTimeEstimate]?

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack {
                Ph.listChecks.regular
                    .frame(width: 20, height: 20)
                    .foregroundColor(.momentumBlue)

                Text("Microsteps")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)

                Spacer()

                if !microsteps.isEmpty {
                    Text("\(microsteps.filter { $0.isCompleted }.count)/\(microsteps.count)")
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextTertiary)
                }
            }

            if microsteps.isEmpty {
                Text("No microsteps yet")
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextTertiary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                    ForEach(microsteps.sorted(by: { $0.orderIndex < $1.orderIndex })) { step in
                        MicrostepRowView(
                            step: step,
                            timeEstimate: timeBreakdown?.first { $0.microstep == step.stepText }?.estimatedMinutes
                        )
                    }
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

struct MicrostepRowView: View {
    let step: Microstep
    let timeEstimate: Int?

    var body: some View {
        HStack(spacing: MomentumSpacing.compact) {
            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(step.isCompleted ? .momentumSuccess : .momentumTextTertiary)
                .frame(width: 20, height: 20)

            Text(step.stepText)
                .font(MomentumFont.body(15))
                .foregroundColor(step.isCompleted ? .momentumTextTertiary : .momentumTextPrimary)
                .strikethrough(step.isCompleted)

            Spacer()

            if let time = timeEstimate {
                Text("\(time)m")
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextTertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Time Breakdown Section

struct TimeBreakdownSection: View {
    let breakdown: [MicrostepTimeEstimate]

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack {
                Ph.timer.regular
                    .frame(width: 20, height: 20)
                    .foregroundColor(.momentumBlue)

                Text("Time Breakdown")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)
            }

            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                ForEach(Array(breakdown.enumerated()), id: \.offset) { index, estimate in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(estimate.microstep)
                                .font(MomentumFont.body(15))
                                .foregroundColor(.momentumTextPrimary)

                            Spacer()

                            Text("\(estimate.estimatedMinutes) min")
                                .font(MomentumFont.bodyMedium(15))
                                .foregroundColor(.momentumBlue)
                        }

                        Text(estimate.rationale)
                            .font(MomentumFont.caption())
                            .foregroundColor(.momentumTextTertiary)
                    }
                    .padding(.vertical, 6)

                    if index < breakdown.count - 1 {
                        Divider()
                            .background(Color.momentumCardBorder)
                    }
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

// MARK: - Tips Section

struct TipsSection: View {
    let tips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack {
                Ph.lightbulb.regular
                    .frame(width: 20, height: 20)
                    .foregroundColor(.momentumGold)

                Text("Tips")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)
            }

            VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: MomentumSpacing.tight) {
                        Text("\(index + 1).")
                            .font(MomentumFont.body(15))
                            .foregroundColor(.momentumGold)

                        Text(tip)
                            .font(MomentumFont.body(15))
                            .foregroundColor(.momentumTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    let task: MomentumTask
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack {
                Ph.notepad.regular
                    .frame(width: 20, height: 20)
                    .foregroundColor(.momentumBlue)

                Text("Notes & AI Chat")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)

                Spacer()

                Button {
                    appState.openGlobalChat(withTask: task)
                } label: {
                    HStack(spacing: 4) {
                        Ph.sparkle.regular
                            .frame(width: 16, height: 16)
                        Text("Open AI")
                    }
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumBlue)
                    .padding(.horizontal, MomentumSpacing.tight)
                    .padding(.vertical, 6)
                    .background(Color.momentumBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if !task.notes.conversationHistory.isEmpty {
                Text("\(task.notes.conversationHistory.count) conversation(s)")
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextSecondary)
            } else {
                Text("No notes yet. Tap 'Open AI' to start a conversation.")
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextTertiary)
                    .italic()
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

// MARK: - Loading Section

struct LoadingSection: View {
    let title: String

    var body: some View {
        VStack(spacing: MomentumSpacing.compact) {
            ProgressView()
                .tint(.momentumBlue)

            Text(title)
                .font(MomentumFont.body(15))
                .foregroundColor(.momentumTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(MomentumSpacing.large)
        .background(Color.momentumSurfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }
}

// MARK: - Hold to Complete Button

struct HoldToCompleteButton: View {
    let onComplete: () -> Void

    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0

    private let holdDuration: Double = 0.8

    var body: some View {
        ZStack {
            // Background with gradient fill
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .fill(
                    LinearGradient(
                        colors: [Color.momentumBlue, Color.momentumViolet],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 56)

            // Progress fill
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: geometry.size.width * holdProgress)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))

            // Label
            HStack(spacing: MomentumSpacing.tight) {
                if isHolding {
                    ProgressView()
                        .tint(.white)
                } else {
                    Ph.checkCircle.regular
                        .frame(width: 20, height: 20)
                }

                Text(isHolding ? "Hold to Complete..." : "Complete Task")
                    .font(MomentumFont.bodyMedium())
            }
            .foregroundColor(.white)
        }
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHolding)
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 50) {
            // Completed
            completeTask()
        } onPressingChanged: { pressing in
            if pressing {
                startHold()
            } else {
                cancelHold()
            }
        }
    }

    private func startHold() {
        isHolding = true
        holdProgress = 0
        SoundManager.shared.lightHaptic()

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

    private func completeTask() {
        isHolding = false
        SoundManager.shared.playPop()
        SoundManager.shared.mediumHaptic()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onComplete()
        }
    }
}

#Preview {
    let sampleTask = MomentumTask(
        weeklyMilestoneId: UUID(),
        goalId: UUID(),
        title: "Research competitor landing pages",
        taskDescription: "Look at 5-10 competitor sites and note what works well for inspiration",
        difficulty: .medium,
        estimatedMinutes: 30,
        scheduledDate: Date(),
        microsteps: [
            Microstep(taskId: UUID(), stepText: "Find 5 competitor sites", orderIndex: 0),
            Microstep(taskId: UUID(), stepText: "Screenshot best sections", orderIndex: 1),
            Microstep(taskId: UUID(), stepText: "Note common patterns", orderIndex: 2)
        ]
    )

    TaskDetailView(
        task: sampleTask,
        goalName: "Launch SaaS Product",
        onComplete: {},
        onDismiss: {}
    )
    .environmentObject(AppState())
}
