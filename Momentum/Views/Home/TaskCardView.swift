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

    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var holdTimer: Timer?
    @State private var showCompletionGlow = false

    private let holdDuration: Double = 0.8

    var body: some View {
        // Main card content
        HStack(spacing: MomentumSpacing.compact) {
            // Task info
            VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                Text(task.title)
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)
                    .lineLimit(2)

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
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FFD699"), Color(hex: "#FFB84D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 36))
        .overlay(
            // Hold fill animation - rounded square expands from center
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(holdProgress)
                    .opacity(holdProgress * 0.8)
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.9)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 36))
            .allowsHitTesting(false)
        )
        .overlay(
            // Completion glow
            RoundedRectangle(cornerRadius: 36)
                .stroke(Color.white, lineWidth: 4)
                .opacity(showCompletionGlow ? 0.8 : 0)
                .blur(radius: showCompletionGlow ? 4 : 0)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 12,
            x: 0,
            y: 4
        )
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHolding)
        .onTapGesture {
            onExpand()
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
