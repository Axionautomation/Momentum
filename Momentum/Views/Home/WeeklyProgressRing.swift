//
//  WeeklyProgressRing.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI

struct WeeklyProgressRing: View {
    let currentPoints: Int
    let maxPoints: Int
    var size: CGFloat = 56
    var lineWidth: CGFloat = 6

    private var progress: Double {
        guard maxPoints > 0 else { return 0 }
        return min(Double(currentPoints) / Double(maxPoints), 1.0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.momentumBlue.opacity(0.15),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.momentumBlue,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Center text
            VStack(spacing: 0) {
                Text("\(currentPoints)")
                    .font(MomentumFont.label(size * 0.28))
                    .fontWeight(.bold)
                    .foregroundColor(.momentumTextPrimary)

                Text("/\(maxPoints)")
                    .font(MomentumFont.caption(size * 0.18))
                    .foregroundColor(.momentumTextTertiary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Larger variant for celebration screen

struct LargeProgressRing: View {
    let currentPoints: Int
    let maxPoints: Int

    private var progress: Double {
        guard maxPoints > 0 else { return 0 }
        return min(Double(currentPoints) / Double(maxPoints), 1.0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.momentumBlue.opacity(0.15),
                    lineWidth: 12
                )

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.momentumBlue, .momentumBlueLight, .momentumBlue],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text("\(currentPoints)")
                    .font(MomentumFont.display(36))
                    .foregroundColor(.momentumTextPrimary)

                Text("of \(maxPoints) pts")
                    .font(MomentumFont.body(14))
                    .foregroundColor(.momentumTextSecondary)
            }
        }
        .frame(width: 140, height: 140)
    }
}

#Preview {
    VStack(spacing: 32) {
        WeeklyProgressRing(currentPoints: 18, maxPoints: 42)

        WeeklyProgressRing(currentPoints: 6, maxPoints: 42, size: 44, lineWidth: 5)

        LargeProgressRing(currentPoints: 24, maxPoints: 42)
    }
    .padding()
    .background(Color.momentumBackground)
    .preferredColorScheme(.dark)
}
