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
    @State private var completionPopAway = false

    private let holdDuration: Double = 1.0
    private let squircleRadius: CGFloat = 60

    var body: some View {
        VStack(alignment: .center, spacing: MomentumSpacing.standard) {
            // Header with Goal and Time
            HStack {
                HStack(spacing: 6) {
                    Ph.folder.fill
                        .frame(width: 16, height: 16)
                    Text(goalName)
                        .font(MomentumFont.label())
                        .lineLimit(1)
                }
                .foregroundColor(holdProgress > 0.6 ? .white.opacity(0.8) : .momentumTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(holdProgress > 0.6 ? Color.white.opacity(0.15) : Color.momentumBackgroundSecondary)
                .cornerRadius(12)

                Spacer()

                HStack(spacing: 6) {
                    Ph.clock.fill
                        .frame(width: 16, height: 16)
                    Text("\(task.estimatedMinutes) min")
                        .font(MomentumFont.label())
                }
                .foregroundColor(holdProgress > 0.6 ? .white.opacity(0.8) : .momentumTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(holdProgress > 0.6 ? Color.white.opacity(0.15) : Color.momentumBackgroundSecondary)
                .cornerRadius(12)
            }

            Spacer()

            // Title
            Text(task.title)
                .font(MomentumFont.headingLarge())
                .foregroundColor(holdProgress > 0.6 ? .white : .momentumTextPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.center)

            // Description
            if let description = task.taskDescription {
                Text(description)
                    .font(MomentumFont.body())
                    .foregroundColor(holdProgress > 0.6 ? .white.opacity(0.7) : .momentumTextSecondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Microsteps hint
            if !task.microsteps.isEmpty {
                HStack(spacing: 4) {
                    Ph.listChecks.regular
                        .frame(width: 18, height: 18)
                    Text("\(task.microsteps.count) steps")
                }
                .font(MomentumFont.bodyMedium())
                .foregroundColor(holdProgress > 0.6 ? .white.opacity(0.7) : .momentumTextSecondary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: squircleRadius, style: .continuous))
        .overlay(
            // Hold fill animation - purple blob materializes from center-high and expands
            GeometryReader { geometry in
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height * 0.4 // Slightly above center
                let maxDimension = max(geometry.size.width, geometry.size.height) * 1.5

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.momentumViolet,
                                Color.momentumViolet.opacity(0.9),
                                Color(red: 0.38, green: 0.15, blue: 0.85)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: maxDimension / 2
                        )
                    )
                    .frame(width: maxDimension * holdProgress, height: maxDimension * holdProgress)
                    .position(x: centerX, y: centerY)
                    .opacity(holdProgress == 0 ? 0 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: squircleRadius, style: .continuous))
            .allowsHitTesting(false)
        )
        .overlay(
            // Subtle border
            RoundedRectangle(cornerRadius: squircleRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 20,
            x: 0,
            y: 8
        )
        .scaleEffect(completionPopAway ? 0.01 : (isHolding ? 0.96 : 1.0))
        .opacity(completionPopAway ? 0 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHolding)
        .animation(.easeIn(duration: 0.35), value: completionPopAway)
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

        // Animate the purple fill expanding
        withAnimation(.easeInOut(duration: holdDuration)) {
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

        // Completion haptic
        SoundManager.shared.successHaptic()
        SoundManager.shared.playPop()

        // Pop away animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation {
                completionPopAway = true
            }
        }

        // Trigger completion callback after pop away
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
