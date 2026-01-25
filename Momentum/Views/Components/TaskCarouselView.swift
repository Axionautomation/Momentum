//
//  TaskCarouselView.swift
//  Momentum
//
//  Created by Claude Code on 1/25/26.
//

import SwiftUI
import PhosphorSwift

struct TaskCarouselView: View {
    let tasks: [MomentumTask]
    let goalName: String
    let onTaskComplete: (MomentumTask) -> Void
    let onTaskTapped: (MomentumTask) -> Void

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    // Layout constants
    private let peekAmount: CGFloat = 24
    private let cardSpacing: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - (peekAmount * 2) - cardSpacing
            let cardHeight = geometry.size.height

            VStack(spacing: MomentumSpacing.compact) {
                // Carousel
                HStack(spacing: cardSpacing) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        CarouselTaskCard(
                            task: task,
                            goalName: goalName,
                            onComplete: { onTaskComplete(task) },
                            onTapped: { onTaskTapped(task) }
                        )
                        .frame(width: cardWidth, height: cardHeight * 0.85)
                    }
                }
                .padding(.horizontal, peekAmount)
                .offset(x: -CGFloat(currentIndex) * (cardWidth + cardSpacing) + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragOffset = gesture.translation.width
                        }
                        .onEnded { gesture in
                            handleSwipeEnd(
                                translation: gesture.translation.width,
                                velocity: gesture.predictedEndTranslation.width - gesture.translation.width,
                                cardWidth: cardWidth
                            )
                        }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.9), value: dragOffset)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<tasks.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.momentumViolet : Color.momentumTextTertiary.opacity(0.4))
                            .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.top, MomentumSpacing.tight)
            }
        }
    }

    private func handleSwipeEnd(translation: CGFloat, velocity: CGFloat, cardWidth: CGFloat) {
        let threshold = cardWidth * 0.3
        let velocityThreshold: CGFloat = 200

        var newIndex = currentIndex

        if translation < -threshold || velocity < -velocityThreshold {
            // Swipe left - go to next
            newIndex = min(currentIndex + 1, tasks.count - 1)
        } else if translation > threshold || velocity > velocityThreshold {
            // Swipe right - go to previous
            newIndex = max(currentIndex - 1, 0)
        }

        if newIndex != currentIndex {
            SoundManager.shared.selectionHaptic()
        }

        currentIndex = newIndex
        dragOffset = 0
    }
}

// MARK: - Carousel Task Card

struct CarouselTaskCard: View {
    let task: MomentumTask
    let goalName: String
    let onComplete: () -> Void
    let onTapped: () -> Void

    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var showCompletionGlow = false

    private let holdDuration: Double = 0.8
    private let cornerRadius: CGFloat = 56

    private var difficultyColor: Color {
        switch task.difficulty {
        case .easy: return .momentumSuccess
        case .medium: return .momentumWarning
        case .hard: return .momentumDanger
        }
    }

    private var difficultyText: String {
        switch task.difficulty {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    private var difficultyIcon: some View {
        switch task.difficulty {
        case .easy:
            return AnyView(Ph.leaf.fill)
        case .medium:
            return AnyView(Ph.flame.fill)
        case .hard:
            return AnyView(Ph.lightning.fill)
        }
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)

            // Hold progress overlay
            RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.momentumViolet.opacity(0.6), Color.momentumBlue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(holdProgress)
                .padding(4)

            // Content
            VStack(spacing: 0) {
                // Top: Difficulty badge
                HStack {
                    Spacer()

                    HStack(spacing: 6) {
                        difficultyIcon
                            .frame(width: 16, height: 16)
                        Text(difficultyText)
                            .font(MomentumFont.label())
                    }
                    .foregroundColor(difficultyColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(difficultyColor.opacity(0.15))
                    )

                    Spacer()
                }
                .padding(.top, MomentumSpacing.large)

                Spacer()

                // Center: Task title
                VStack(spacing: MomentumSpacing.compact) {
                    Text(task.title)
                        .font(MomentumFont.headingMedium(22))
                        .foregroundColor(.momentumDarkBackground)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, MomentumSpacing.large)

                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
                            .font(MomentumFont.body(15))
                            .foregroundColor(.momentumTextTertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, MomentumSpacing.large)
                    }
                }

                Spacer()

                // Bottom: Time and goal info
                VStack(spacing: MomentumSpacing.tight) {
                    HStack(spacing: 6) {
                        Ph.clock.regular
                            .frame(width: 16, height: 16)
                        Text("\(task.estimatedMinutes) min")
                    }
                    .font(MomentumFont.body(15))
                    .foregroundColor(.momentumTextSecondary)

                    HStack(spacing: 6) {
                        Ph.target.regular
                            .frame(width: 14, height: 14)
                        Text(goalName)
                            .lineLimit(1)
                    }
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextTertiary)
                }
                .padding(.bottom, MomentumSpacing.large)
            }

            // Completion indicator
            if isHolding {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.momentumViolet.opacity(0.3), lineWidth: 4)
                                .frame(width: 44, height: 44)

                            Circle()
                                .trim(from: 0, to: holdProgress)
                                .stroke(Color.momentumViolet, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))

                            Ph.check.bold
                                .foregroundColor(.momentumViolet)
                                .frame(width: 20, height: 20)
                                .opacity(holdProgress)
                        }
                        Spacer()
                    }
                    .padding(.bottom, MomentumSpacing.section)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .overlay(
            // Completion glow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.momentumViolet, lineWidth: 6)
                .opacity(showCompletionGlow ? 0.8 : 0)
                .blur(radius: showCompletionGlow ? 8 : 0)
        )
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 20,
            x: 0,
            y: 8
        )
        .scaleEffect(isHolding ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHolding)
        .onTapGesture {
            onTapped()
            SoundManager.shared.selectionHaptic()
        }
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 50) {
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

        withAnimation(.easeInOut(duration: 0.3)) {
            showCompletionGlow = true
        }

        SoundManager.shared.playPop()
        SoundManager.shared.mediumHaptic()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

#Preview {
    let sampleTasks = [
        MomentumTask(
            weeklyMilestoneId: UUID(),
            goalId: UUID(),
            title: "Research competitor landing pages for inspiration",
            taskDescription: "Look at 5-10 competitor sites",
            difficulty: .easy,
            estimatedMinutes: 15,
            scheduledDate: Date()
        ),
        MomentumTask(
            weeklyMilestoneId: UUID(),
            goalId: UUID(),
            title: "Draft initial wireframes for the homepage",
            taskDescription: "Create 3 layout variations",
            difficulty: .medium,
            estimatedMinutes: 45,
            scheduledDate: Date()
        ),
        MomentumTask(
            weeklyMilestoneId: UUID(),
            goalId: UUID(),
            title: "Build complete marketing strategy document",
            taskDescription: "Include competitor analysis, positioning, and channel strategy",
            difficulty: .hard,
            estimatedMinutes: 90,
            scheduledDate: Date()
        )
    ]

    VStack {
        TaskCarouselView(
            tasks: sampleTasks,
            goalName: "Launch SaaS Product",
            onTaskComplete: { _ in },
            onTaskTapped: { _ in }
        )
        .frame(height: UIScreen.main.bounds.height * 0.5)
    }
    .padding()
    .background(Color.momentumBackgroundSecondary)
}
