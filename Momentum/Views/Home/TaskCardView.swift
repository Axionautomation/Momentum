//
//  TaskCardView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift

// MARK: - Squircle Shape (Superellipse)

struct Squircle: Shape {
    var n: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let a = rect.width / 2
        let b = rect.height / 2
        let centerX = rect.midX
        let centerY = rect.midY
        let exp = 2.0 / n
        let steps = 360

        var path = Path()

        for i in 0...steps {
            let angle = Double(i) * (2 * .pi / Double(steps))
            let cosA = cos(angle)
            let sinA = sin(angle)

            let x = centerX + a * pow(abs(cosA), exp) * (cosA >= 0 ? 1 : -1)
            let y = centerY + b * pow(abs(sinA), exp) * (sinA >= 0 ? 1 : -1)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }
}

struct TaskCardView: View {
    let task: MomentumTask
    let goalName: String
    var isCompleted: Bool = false
    let onComplete: () -> Void
    let onExpand: () -> Void
    var onDragChanged: ((CGFloat) -> Void)? = nil
    var onDragEnded: ((CGFloat, CGFloat) -> Void)? = nil // (offset, velocity)

    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var completionPopAway = false

    private let holdDuration: Double = 1.5

    private let fillColor = Color.momentumBlue
    private let completedFillColor = Color.momentumBlue

    // Whether to show light (white) text - for completed or during hold
    private var showLightText: Bool {
        isCompleted || holdProgress > 0.5
    }

    var body: some View {
        ZStack {
            // Layer 1: Card background
            Squircle(n: 4)
                .fill(Color.momentumCardBackground)

            // Layer 2: Fill color - blue for completed, dark slate for hold progress
            Squircle(n: 4)
                .fill(isCompleted ? completedFillColor : fillColor)
                .scaleEffect(isCompleted ? 1.0 : holdProgress)

            // Layer 3: Text content (always on top, always readable)
            VStack(alignment: .center, spacing: MomentumSpacing.standard) {
                // Header with Goal and Progress
                HStack {
                    HStack(spacing: 6) {
                        Ph.folder.fill
                            .frame(width: 16, height: 16)
                        Text(goalName)
                            .font(MomentumFont.label())
                            .lineLimit(1)
                    }
                    .foregroundColor(showLightText ? .white.opacity(0.8) : .momentumTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showLightText ? Color.white.opacity(0.15) : Color.momentumBackgroundSecondary)
                    .cornerRadius(12)

                    Spacer()

                    // Show checkmark for completed tasks, checklist progress for pending
                    if isCompleted {
                        HStack(spacing: 6) {
                            Ph.checkCircle.fill
                                .frame(width: 16, height: 16)
                            Text("Done")
                                .font(MomentumFont.label())
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    } else {
                        // Show checklist progress instead of fixed time
                        HStack(spacing: 6) {
                            Ph.listChecks.regular
                                .frame(width: 16, height: 16)
                            if task.checklist.isEmpty {
                                Text("\(task.totalEstimatedMinutes) min")
                                    .font(MomentumFont.label())
                            } else {
                                Text("\(task.completedChecklistCount)/\(task.checklist.count)")
                                    .font(MomentumFont.label())
                            }
                        }
                        .foregroundColor(showLightText ? .white.opacity(0.8) : .momentumTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(showLightText ? Color.white.opacity(0.15) : Color.momentumBackgroundSecondary)
                        .cornerRadius(12)
                    }
                }

                Spacer()

                // Title
                Text(task.title)
                    .font(MomentumFont.headingLarge())
                    .foregroundColor(showLightText ? .white : .momentumTextPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)

                // Outcome goal (instead of description)
                if !task.outcomeGoal.isEmpty {
                    Text(task.outcomeGoal)
                        .font(MomentumFont.body())
                        .foregroundColor(showLightText ? .white.opacity(0.7) : .momentumTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else if let description = task.taskDescription {
                    Text(description)
                        .font(MomentumFont.body())
                        .foregroundColor(showLightText ? .white.opacity(0.7) : .momentumTextSecondary)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Checklist progress bar (if has checklist)
                if !task.checklist.isEmpty {
                    VStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(showLightText ? Color.white.opacity(0.2) : Color.momentumBackgroundSecondary)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(showLightText ? Color.white : Color.momentumSuccess)
                                    .frame(width: geometry.size.width * task.checklistProgress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        // Time remaining
                        HStack(spacing: 4) {
                            Ph.clock.regular
                                .frame(width: 14, height: 14)
                            Text("\(task.remainingMinutes) min left")
                        }
                        .font(MomentumFont.label())
                        .foregroundColor(showLightText ? .white.opacity(0.7) : .momentumTextSecondary)
                    }
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(Squircle(n: 4))
        .overlay(
            // Subtle border
            Squircle(n: 4)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
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
            SoundManager.shared.lightHaptic()
        }
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 25) {
            // Only complete if not already completed
            if !isCompleted {
                completeTask()
            }
        } onPressingChanged: { pressing in
            // Only show hold progress for non-completed tasks
            guard !isCompleted else { return }
            if pressing {
                startHold()
            } else {
                cancelHold()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 25)
                .onChanged { value in
                    if isHolding { cancelHold() }
                    onDragChanged?(value.translation.width)
                }
                .onEnded { value in
                    let velocity = value.predictedEndTranslation.width - value.translation.width
                    onDragEnded?(value.translation.width, velocity)
                }
        )
    }

    // MARK: - Hold Gesture

    private func startHold() {
        isHolding = true
        SoundManager.shared.lightHaptic()

        // Escape the gesture's implicit animation transaction
        // so our explicit animation isn't overridden
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: holdDuration)) {
                holdProgress = 1.0
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        // Escape the gesture's implicit transaction here too
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                holdProgress = 0
            }
        }
    }

    private func completeTask() {
        isHolding = false
        holdProgress = 1.0

        // Completion haptic
        SoundManager.shared.successHaptic()

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
        milestoneId: UUID(),
        goalId: UUID(),
        title: "Research competitor landing pages for inspiration",
        taskDescription: "Look at 5-10 competitor sites and note what works well",
        checklist: [
            ChecklistItem(text: "Find 5 competitor sites", estimatedMinutes: 10, orderIndex: 0),
            ChecklistItem(text: "Screenshot best sections", estimatedMinutes: 10, orderIndex: 1),
            ChecklistItem(text: "Note common patterns", estimatedMinutes: 10, orderIndex: 2)
        ],
        outcomeGoal: "Have a document with 5 competitor examples and key takeaways",
        totalEstimatedMinutes: 30,
        scheduledDate: Date()
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
                milestoneId: UUID(),
                goalId: UUID(),
                title: "Quick email check",
                checklist: [],
                outcomeGoal: "Inbox zero",
                totalEstimatedMinutes: 10,
                scheduledDate: Date()
            ),
            goalName: "Daily Habits",
            onComplete: {},
            onExpand: {}
        )
    }
    .padding()
    .background(Color.momentumBackgroundSecondary)
    .preferredColorScheme(.dark)
    .environmentObject(AppState())
}
