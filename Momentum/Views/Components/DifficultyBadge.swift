//
//  DifficultyBadge.swift
//  Momentum
//
//  Created by Claude Code on 1/23/26.
//

import SwiftUI

struct DifficultyCornerBadge: View {
    let difficulty: TaskDifficulty

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 48, height: 48)
            .overlay(
                difficultyIcon
                    .foregroundColor(difficultyColor)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var difficultyIcon: some View {
        switch difficulty {
        case .easy:
            // Single bar
            VStack(spacing: 2) {
                Spacer()
                Rectangle()
                    .fill(difficultyColor)
                    .frame(width: 4, height: 8)
            }
            .frame(width: 24, height: 24)

        case .medium:
            // Two bars
            HStack(spacing: 2) {
                VStack(spacing: 2) {
                    Spacer()
                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: 4, height: 12)
                }
                VStack(spacing: 2) {
                    Spacer()
                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: 4, height: 12)
                }
            }
            .frame(width: 24, height: 24)

        case .hard:
            // Three bars
            HStack(spacing: 2) {
                VStack(spacing: 2) {
                    Spacer()
                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: 4, height: 16)
                }
                VStack(spacing: 2) {
                    Spacer()
                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: 4, height: 16)
                }
                VStack(spacing: 2) {
                    Spacer()
                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: 4, height: 16)
                }
            }
            .frame(width: 24, height: 24)
        }
    }

    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        DifficultyCornerBadge(difficulty: .easy)
        DifficultyCornerBadge(difficulty: .medium)
        DifficultyCornerBadge(difficulty: .hard)
    }
    .padding()
    .background(Color.momentumBackgroundSecondary)
}
