//
//  TaskExpandedView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/27/26.
//

import SwiftUI
import PhosphorSwift

struct TaskExpandedView: View {
    @State var task: MomentumTask
    let goalName: String
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.momentumDarkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                    // Header bar
                    headerBar

                    // Task info
                    taskHeader

                    // Description
                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Microsteps
                    if !task.microsteps.isEmpty {
                        microstepsSection
                    }

                    // Notes & Research
                    if hasNotes {
                        notesSection
                    }
                }
                .padding(.horizontal, MomentumSpacing.comfortable)
                .padding(.top, MomentumSpacing.standard)
                .padding(.bottom, 100)
            }

            // Fixed bottom button
            completeButton
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Ph.folder.fill
                    .frame(width: 16, height: 16)
                Text(goalName)
                    .font(MomentumFont.label())
                    .lineLimit(1)
            }
            .foregroundColor(.momentumTextSecondary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Ph.x.bold
                    .frame(width: 18, height: 18)
                    .foregroundColor(.momentumTextSecondary)
                    .padding(8)
                    .background(Color.momentumSurfaceSecondary)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Task Header

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            HStack(spacing: MomentumSpacing.tight) {
                Text(task.difficulty.displayName)
                    .font(MomentumFont.label())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(difficultyColor)
                    .cornerRadius(8)

                HStack(spacing: 4) {
                    Ph.clock.regular
                        .frame(width: 14, height: 14)
                    Text("\(task.estimatedMinutes) min")
                        .font(MomentumFont.label())
                }
                .foregroundColor(.momentumTextSecondary)
            }

            Text(task.title)
                .font(MomentumFont.headingLarge())
                .foregroundColor(.momentumTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Microsteps

    private var microstepsSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            Text("Steps")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(task.microsteps.enumerated()), id: \.element.id) { index, step in
                    Button {
                        toggleMicrostep(at: index)
                    } label: {
                        HStack(spacing: MomentumSpacing.compact) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        step.isCompleted ? Color.momentumSuccess : Color.momentumTextTertiary,
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 22, height: 22)

                                if step.isCompleted {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.momentumSuccess)
                                        .frame(width: 22, height: 22)

                                    Ph.check.bold
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(.white)
                                }
                            }

                            Text(step.stepText)
                                .font(MomentumFont.body())
                                .foregroundColor(step.isCompleted ? .momentumTextTertiary : .momentumTextPrimary)
                                .strikethrough(step.isCompleted)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(.vertical, MomentumSpacing.compact)
                    }

                    if index < task.microsteps.count - 1 {
                        Divider()
                            .background(Color.momentumTextTertiary.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.tight)
            .background(Color.momentumSurfacePrimary)
            .cornerRadius(16)
        }
    }

    // MARK: - Notes & Research

    private var hasNotes: Bool {
        !task.notes.researchFindings.isEmpty ||
        !task.notes.userBrainstorms.isEmpty ||
        !task.notes.conversationHistory.isEmpty
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            Text("Notes & Research")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            VStack(spacing: MomentumSpacing.tight) {
                // Research findings
                ForEach(task.notes.researchFindings) { finding in
                    VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                        HStack(spacing: 6) {
                            Ph.magnifyingGlass.regular
                                .frame(width: 14, height: 14)
                            Text(finding.query)
                                .font(MomentumFont.bodyMedium())
                        }
                        .foregroundColor(.momentumTextPrimary)

                        Text(finding.searchResults)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                            .lineLimit(6)
                    }
                    .padding(MomentumSpacing.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.momentumSurfaceSecondary)
                    .cornerRadius(12)
                }

                // Brainstorms
                ForEach(task.notes.userBrainstorms) { brainstorm in
                    HStack(alignment: .top, spacing: MomentumSpacing.tight) {
                        Ph.lightbulb.regular
                            .frame(width: 14, height: 14)
                            .foregroundColor(.momentumGold)
                            .padding(.top, 2)

                        Text(brainstorm.content)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .padding(MomentumSpacing.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.momentumSurfaceSecondary)
                    .cornerRadius(12)
                }

                // Conversation summary
                if !task.notes.conversationHistory.isEmpty {
                    HStack(spacing: 6) {
                        Ph.chatCircle.regular
                            .frame(width: 16, height: 16)
                        Text("\(task.notes.conversationHistory.count) AI messages")
                            .font(MomentumFont.label())
                    }
                    .foregroundColor(.momentumTextTertiary)
                    .padding(.top, MomentumSpacing.tight)
                }
            }
            .padding(MomentumSpacing.standard)
            .background(Color.momentumSurfacePrimary)
            .cornerRadius(16)
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        VStack(spacing: 0) {
            // Fade gradient above button
            LinearGradient(
                colors: [Color.momentumDarkBackground.opacity(0), Color.momentumDarkBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)

            Button {
                onComplete()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Ph.checkCircle.fill
                        .frame(width: 20, height: 20)
                    Text("Mark Complete")
                        .font(MomentumFont.bodyMedium())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MomentumSpacing.standard)
                .background(MomentumGradients.primary)
                .cornerRadius(16)
            }
            .padding(.horizontal, MomentumSpacing.comfortable)
            .padding(.bottom, MomentumSpacing.section)
            .background(Color.momentumDarkBackground)
        }
    }

    // MARK: - Helpers

    private var difficultyColor: Color {
        switch task.difficulty {
        case .easy: return .momentumEasy
        case .medium: return .momentumMedium
        case .hard: return .momentumHard
        }
    }

    private func toggleMicrostep(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            task.microsteps[index].isCompleted.toggle()
        }
        appState.updateTaskInGoal(task)
    }
}
