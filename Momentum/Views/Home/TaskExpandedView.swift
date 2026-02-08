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
    let isCompleted: Bool
    let onComplete: () -> Void
    var onUndoComplete: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                    // Header bar
                    headerBar

                    // Task info
                    taskHeader

                    // Outcome goal
                    if !task.outcomeGoal.isEmpty {
                        outcomeSection
                    }

                    // Description
                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Checklist
                    if !task.checklist.isEmpty {
                        checklistSection
                    }

                    // Tool prompts if any
                    if let evaluation = task.aiEvaluation, let toolPrompts = evaluation.toolPrompts, !toolPrompts.isEmpty {
                        toolPromptsSection(toolPrompts)
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
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Task Header

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            // Time and checklist info
            HStack(spacing: MomentumSpacing.tight) {
                HStack(spacing: 4) {
                    Ph.clock.regular
                        .frame(width: 14, height: 14)
                    Text("\(task.totalEstimatedMinutes) min")
                        .font(MomentumFont.label())
                }
                .foregroundColor(.momentumTextSecondary)

                if !task.checklist.isEmpty {
                    Text("•")
                        .foregroundColor(.momentumTextTertiary)

                    HStack(spacing: 4) {
                        Ph.listChecks.regular
                            .frame(width: 14, height: 14)
                        Text("\(task.completedChecklistCount)/\(task.checklist.count) steps")
                            .font(MomentumFont.label())
                    }
                    .foregroundColor(.momentumTextSecondary)
                }
            }

            Text(task.title)
                .font(MomentumFont.headingLarge())
                .foregroundColor(.momentumTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Outcome Section

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
            HStack(spacing: 6) {
                Ph.target.regular
                    .frame(width: 16, height: 16)
                Text("Done when:")
                    .font(MomentumFont.bodyMedium())
            }
            .foregroundColor(.momentumSuccess)

            Text(task.outcomeGoal)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextPrimary)
                .padding(MomentumSpacing.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.momentumSuccess.opacity(0.1))
                .cornerRadius(12)
        }
    }

    // MARK: - Checklist

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            Text("Steps")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(task.checklist.sorted { $0.orderIndex < $1.orderIndex }.enumerated()), id: \.element.id) { index, item in
                    Button {
                        toggleChecklistItem(at: index)
                    } label: {
                        HStack(spacing: MomentumSpacing.compact) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        item.isCompleted ? Color.momentumSuccess : Color.momentumCardBorder,
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 22, height: 22)

                                if item.isCompleted {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.momentumSuccess)
                                        .frame(width: 22, height: 22)

                                    Ph.check.bold
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.text)
                                    .font(MomentumFont.body())
                                    .foregroundColor(item.isCompleted ? .momentumTextTertiary : .momentumTextPrimary)
                                    .strikethrough(item.isCompleted)
                                    .multilineTextAlignment(.leading)

                                Text("\(item.estimatedMinutes) min")
                                    .font(MomentumFont.label())
                                    .foregroundColor(.momentumTextTertiary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, MomentumSpacing.compact)
                    }

                    if index < task.checklist.count - 1 {
                        Divider()
                            .background(Color.momentumCardBorder)
                    }
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.vertical, MomentumSpacing.tight)
            .background(Color.momentumBackgroundSecondary)
            .cornerRadius(16)
        }
    }

    // MARK: - Tool Prompts Section

    private func toolPromptsSection(_ prompts: [ToolPrompt]) -> some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            Text("AI Prompts")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            ForEach(prompts) { prompt in
                VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                    HStack {
                        HStack(spacing: 6) {
                            Ph.sparkle.fill
                                .frame(width: 14, height: 14)
                            Text(prompt.toolName)
                                .font(MomentumFont.bodyMedium())
                        }
                        .foregroundColor(.momentumViolet)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = prompt.prompt
                            SoundManager.shared.successHaptic()
                        } label: {
                            HStack(spacing: 4) {
                                Ph.copy.regular
                                    .frame(width: 14, height: 14)
                                Text("Copy")
                                    .font(MomentumFont.label())
                            }
                            .foregroundColor(.momentumViolet)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.momentumViolet.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    Text(prompt.context)
                        .font(MomentumFont.label())
                        .foregroundColor(.momentumTextSecondary)

                    Text(prompt.prompt)
                        .font(MomentumFont.body())
                        .foregroundColor(.momentumTextPrimary)
                        .lineLimit(6)
                        .padding(MomentumSpacing.compact)
                        .background(Color.momentumBackgroundSecondary)
                        .cornerRadius(8)
                }
                .padding(MomentumSpacing.compact)
                .background(Color.momentumViolet.opacity(0.05))
                .cornerRadius(12)
            }
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
                    .background(Color.momentumBackgroundSecondary)
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
                    .background(Color.momentumBackgroundSecondary)
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
            .background(Color.momentumBackgroundSecondary)
            .cornerRadius(16)
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        VStack(spacing: 0) {
            // Fade gradient above button
            LinearGradient(
                colors: [Color.momentumBackground.opacity(0), Color.momentumBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)

            if isCompleted {
                // Undo completion button for completed tasks
                Button {
                    onUndoComplete?()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Ph.arrowCounterClockwise.bold
                            .frame(width: 20, height: 20)
                        Text("Undo Completion")
                            .font(MomentumFont.bodyMedium())
                    }
                    .foregroundColor(.momentumBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MomentumSpacing.standard)
                    .background(Color.momentumBlue.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.momentumBlue.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, MomentumSpacing.comfortable)
                .padding(.bottom, MomentumSpacing.section)
                .background(Color.momentumBackground)
            } else {
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
                .background(Color.momentumBackground)
            }
        }
    }

    // MARK: - Helpers

    private func toggleChecklistItem(at index: Int) {
        let sortedChecklist = task.checklist.sorted { $0.orderIndex < $1.orderIndex }
        guard index < sortedChecklist.count else { return }
        let itemId = sortedChecklist[index].id

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let checklistIndex = task.checklist.firstIndex(where: { $0.id == itemId }) {
                task.checklist[checklistIndex].isCompleted.toggle()
            }
        }

        appState.toggleChecklistItem(taskId: task.id, checklistItemId: itemId)
    }
}
