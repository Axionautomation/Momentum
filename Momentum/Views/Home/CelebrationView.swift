//
//  CelebrationView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift

struct CelebrationView: View {
    let pointsEarned: Int
    let weeklyPoints: Int
    let weeklyMax: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showConfetti = false
    @State private var particlePositions: [CGPoint] = []
    @State private var particleOpacities: [Double] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.momentumBackground
                    .ignoresSafeArea()

                // Confetti particles
                ForEach(0..<20, id: \.self) { index in
                    ConfettiParticle(
                        color: confettiColors[index % confettiColors.count],
                        delay: Double(index) * 0.05,
                        containerSize: geometry.size
                    )
                    .opacity(showConfetti ? 1 : 0)
                }

                // Main content
                VStack(spacing: MomentumSpacing.section) {
                Spacer()

                // Trophy/celebration icon
                ZStack {
                    Circle()
                        .fill(Color.momentumBlue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Ph.trophy.fill
                        .frame(width: 60, height: 60)
                        .foregroundColor(.momentumBlue)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                // Message
                VStack(spacing: MomentumSpacing.tight) {
                    Text("You crushed it today!")
                        .font(MomentumFont.headingLarge())
                        .foregroundColor(.momentumTextPrimary)

                    Text("All tasks completed")
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumTextSecondary)
                }
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)

                // Points earned
                VStack(spacing: MomentumSpacing.tight) {
                    Text("+\(pointsEarned) points")
                        .font(MomentumFont.headingMedium())
                        .foregroundColor(.momentumBlue)

                    // Weekly progress ring
                    LargeProgressRing(
                        currentPoints: weeklyPoints,
                        maxPoints: weeklyMax
                    )
                    .padding(.top, MomentumSpacing.standard)

                    Text("this week")
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextTertiary)
                }
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)

                Spacer()

                // CTA Button
                Button {
                    onDismiss()
                } label: {
                    Text("See Your Progress")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, MomentumSpacing.section)
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)

                // Secondary dismiss
                Button {
                    onDismiss()
                } label: {
                    Text("Back to Home")
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumTextSecondary)
                }
                .padding(.bottom, MomentumSpacing.large)
                .opacity(appeared ? 1 : 0)
            }
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }

            // Confetti after slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                SoundManager.shared.playCelebration()
                SoundManager.shared.successHaptic()
            }
        }
    }

    private let confettiColors: [Color] = [
        .momentumBlue,
        .momentumBlueLight,
        .momentumSuccess,
        .momentumWarning,
        .momentumViolet,       // Purple
        .momentumGrowth        // Pink/Violet
    ]
}

// MARK: - Confetti Particle

struct ConfettiParticle: View {
    let color: Color
    let delay: Double
    let containerSize: CGSize

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: CGFloat.random(in: 8...14), height: CGFloat.random(in: 8...14))
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .onAppear {
                // Random starting position at top
                position = CGPoint(
                    x: CGFloat.random(in: 0...containerSize.width),
                    y: -20
                )

                // Animate falling
                withAnimation(
                    .easeIn(duration: Double.random(in: 2...3))
                    .delay(delay)
                ) {
                    position = CGPoint(
                        x: position.x + CGFloat.random(in: -100...100),
                        y: containerSize.height + 50
                    )
                    rotation = Double.random(in: 360...720)
                }

                // Fade in then out
                withAnimation(.easeIn(duration: 0.3).delay(delay)) {
                    opacity = 1
                }

                withAnimation(.easeOut(duration: 0.5).delay(delay + 2)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Empty State View

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: MomentumSpacing.standard) {
            Ph.checkCircle.regular
                .frame(width: 48, height: 48)
                .foregroundColor(.momentumTextTertiary)

            Text("No tasks for today")
                .font(MomentumFont.bodyMedium())
                .foregroundColor(.momentumTextSecondary)

            Text("Check back tomorrow or explore your goals")
                .font(MomentumFont.body(14))
                .foregroundColor(.momentumTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(MomentumSpacing.large)
    }
}

#Preview("Celebration") {
    CelebrationView(
        pointsEarned: 6,
        weeklyPoints: 24,
        weeklyMax: 42,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    EmptyTasksView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.momentumBackgroundSecondary)
        .preferredColorScheme(.dark)
}
