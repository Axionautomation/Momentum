//
//  SwipeableTaskStack.swift
//  Momentum
//
//  Created by Claude Code on 1/23/26.
//

import SwiftUI
import PhosphorSwift

struct SwipeableTaskStack: View {
    let tasks: [MomentumTask]
    let goalName: String
    let onTaskComplete: (MomentumTask) -> Void
    let onTaskTapped: (MomentumTask) -> Void

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0

    var body: some View {
        ZStack {
            // Show top 3 cards in stack
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                if index >= currentIndex && index < currentIndex + 3 {
                    TaskCardView(
                        task: task,
                        goalName: goalName,
                        onComplete: { onTaskComplete(task) },
                        onExpand: { onTaskTapped(task) }
                    )
                    .zIndex(Double(tasks.count - index))
                    .offset(y: CGFloat((index - currentIndex) * 8))
                    .scaleEffect(1.0 - CGFloat((index - currentIndex)) * 0.05)
                    .opacity(index == currentIndex ? 1.0 : 0.7)
                    .offset(index == currentIndex ? dragOffset : .zero)
                    .rotationEffect(index == currentIndex ? .degrees(dragRotation) : .zero)
                    .gesture(
                        index == currentIndex ?
                        DragGesture()
                            .onChanged { gesture in
                                dragOffset = gesture.translation
                                dragRotation = Double(gesture.translation.width / 20)
                            }
                            .onEnded { gesture in
                                handleSwipeEnd(translation: gesture.translation)
                            }
                        : nil
                    )
                }
            }
        }
        .frame(height: 280) // Fixed height for card stack
    }

    private func handleSwipeEnd(translation: CGSize) {
        let swipeThreshold: CGFloat = 100

        if abs(translation.width) > swipeThreshold {
            // Swipe accepted - move to next card
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                dragOffset = CGSize(
                    width: translation.width > 0 ? 500 : -500,
                    height: translation.height
                )
            }

            SoundManager.shared.selectionHaptic()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex = min(currentIndex + 1, tasks.count - 1)
                dragOffset = .zero
                dragRotation = 0
            }
        } else {
            // Swipe cancelled - return to center
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }
}

#Preview {
    let sampleTasks = [
        MomentumTask(
            weeklyMilestoneId: UUID(),
            goalId: UUID(),
            title: "Research competitor landing pages",
            taskDescription: "Look at 5-10 competitor sites",
            difficulty: .medium,
            estimatedMinutes: 30,
            scheduledDate: Date()
        ),
        MomentumTask(
            weeklyMilestoneId: UUID(),
            goalId: UUID(),
            title: "Quick email check",
            difficulty: .easy,
            estimatedMinutes: 10,
            scheduledDate: Date()
        ),
        MomentumTask(
            weeklyMilestoneId: UUID(),
            goalId: UUID(),
            title: "Complete marketing strategy",
            difficulty: .hard,
            estimatedMinutes: 60,
            scheduledDate: Date()
        )
    ]

    SwipeableTaskStack(
        tasks: sampleTasks,
        goalName: "Launch SaaS Product",
        onTaskComplete: { _ in },
        onTaskTapped: { _ in }
    )
    .padding()
    .background(Color.momentumBackgroundSecondary)
}
