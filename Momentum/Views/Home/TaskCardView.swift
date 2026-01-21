//
//  TaskCardView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift

struct TaskCardView: View {
    let task: MomentumTask
    let goalName: String
    let onComplete: () -> Void
    let onExpand: () -> Void

    @State private var isExpanded = false
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdTimer: Timer?
    @State private var showCompletionGlow = false

    private let holdDuration: Double = 0.8

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: MomentumSpacing.compact) {
                // Difficulty indicator
                DifficultyIndicator(difficulty: task.difficulty)

                // Task info
                VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                    Text(task.title)
                        .font(MomentumFont.bodyMedium())
                        .foregroundColor(.momentumTextPrimary)
                        .lineLimit(isExpanded ? nil : 2)

                    HStack(spacing: MomentumSpacing.compact) {
                        // Estimated time
                        HStack(spacing: 4) {
                            Ph.clock.regular
                                .frame(width: 14, height: 14)
                            Text("\(task.estimatedMinutes) min")
                        }
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)

                        // Goal name
                        HStack(spacing: 4) {
                            Ph.folder.regular
                                .frame(width: 14, height: 14)
                            Text(goalName)
                                .lineLimit(1)
                        }
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextSecondary)
                    }
                }

                Spacer()

                // Hold progress indicator
                if isHolding {
                    ZStack {
                        Circle()
                            .stroke(Color.momentumBlue.opacity(0.2), lineWidth: 3)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: holdProgress)
                            .stroke(Color.momentumBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                    }
                } else {
                    // Chevron for expansion
                    Ph.caretDown.regular
                        .frame(width: 20, height: 20)
                        .foregroundColor(.momentumTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(MomentumSpacing.standard)

            // Expanded content
            if isExpanded {
                ExpandedTaskContent(task: task)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.momentumCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .strokeBorder(
                    difficultyBorderColor,
                    lineWidth: 3
                )
                .opacity(0.3)
        )
        .overlay(
            // Left accent bar
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(difficultyColor)
                    .frame(width: 4)
                    .padding(.vertical, 8)
                Spacer()
            }
            .padding(.leading, 4)
        )
        .overlay(
            // Completion glow
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .stroke(Color.momentumBlue, lineWidth: 4)
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            SoundManager.shared.selectionHaptic()
        }
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

    // MARK: - Difficulty Styling

    private var difficultyColor: Color {
        switch task.difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
        }
    }

    private var difficultyBorderColor: Color {
        switch task.difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
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

    private func completeTask() {
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
            onComplete()
        }
    }
}

// MARK: - Difficulty Indicator

struct DifficultyIndicator: View {
    let difficulty: TaskDifficulty

    private var dotCount: Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    private var color: Color {
        switch difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<dotCount, id: \.self) { _ in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 32, alignment: .leading)
    }
}

// MARK: - Expanded Content

struct ExpandedTaskContent: View {
    let task: MomentumTask
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            Divider()
                .background(Color.momentumCardBorder)

            // Description
            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextSecondary)
                    .padding(.horizontal, MomentumSpacing.standard)
            }

            // Microsteps
            if !task.microsteps.isEmpty {
                VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                    Text("Microsteps")
                        .font(MomentumFont.label())
                        .foregroundColor(.momentumTextSecondary)

                    ForEach(task.microsteps.sorted(by: { $0.orderIndex < $1.orderIndex })) { step in
                        MicrostepRow(step: step)
                    }
                }
                .padding(.horizontal, MomentumSpacing.standard)
            }

            // Action buttons
            HStack(spacing: MomentumSpacing.compact) {
                // Notes button
                Button {
                    appState.openGlobalChat(withTask: task)
                } label: {
                    HStack(spacing: 6) {
                        Ph.notepad.regular
                            .frame(width: 18, height: 18)
                        Text("Notes")
                    }
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumBlue)
                    .padding(.horizontal, MomentumSpacing.compact)
                    .padding(.vertical, MomentumSpacing.tight)
                    .background(Color.momentumBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                }

                // AI Help button
                Button {
                    appState.openGlobalChat(withTask: task)
                } label: {
                    HStack(spacing: 6) {
                        Ph.sparkle.regular
                            .frame(width: 18, height: 18)
                        Text("AI Help")
                    }
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumBlue)
                    .padding(.horizontal, MomentumSpacing.compact)
                    .padding(.vertical, MomentumSpacing.tight)
                    .background(Color.momentumBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                }

                Spacer()
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.bottom, MomentumSpacing.standard)
        }
    }
}

// MARK: - Microstep Row

struct MicrostepRow: View {
    let step: Microstep

    var body: some View {
        HStack(spacing: MomentumSpacing.tight) {
            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(step.isCompleted ? .momentumSuccess : .momentumTextTertiary)
                .frame(width: 20, height: 20)

            Text(step.stepText)
                .font(MomentumFont.body(15))
                .foregroundColor(step.isCompleted ? .momentumTextTertiary : .momentumTextPrimary)
                .strikethrough(step.isCompleted)
        }
    }
}

#Preview {
    let sampleTask = MomentumTask(
        weeklyMilestoneId: UUID(),
        goalId: UUID(),
        title: "Research competitor landing pages for inspiration",
        taskDescription: "Look at 5-10 competitor sites and note what works well",
        difficulty: .medium,
        estimatedMinutes: 30,
        scheduledDate: Date(),
        microsteps: [
            Microstep(taskId: UUID(), stepText: "Find 5 competitor sites", orderIndex: 0),
            Microstep(taskId: UUID(), stepText: "Screenshot best sections", orderIndex: 1),
            Microstep(taskId: UUID(), stepText: "Note common patterns", orderIndex: 2)
        ]
    )

    VStack(spacing: 16) {
        TaskCardView(
            task: sampleTask,
            goalName: "Launch SaaS Product",
            onComplete: {},
            onExpand: {}
        )

        TaskCardView(
            task: MomentumTask(
                weeklyMilestoneId: UUID(),
                goalId: UUID(),
                title: "Quick email check",
                difficulty: .easy,
                estimatedMinutes: 10,
                scheduledDate: Date()
            ),
            goalName: "Daily Habits",
            onComplete: {},
            onExpand: {}
        )

        TaskCardView(
            task: MomentumTask(
                weeklyMilestoneId: UUID(),
                goalId: UUID(),
                title: "Complete full marketing strategy document",
                difficulty: .hard,
                estimatedMinutes: 60,
                scheduledDate: Date()
            ),
            goalName: "Launch SaaS Product",
            onComplete: {},
            onExpand: {}
        )
    }
    .padding()
    .background(Color.momentumBackgroundSecondary)
    .environmentObject(AppState())
}
