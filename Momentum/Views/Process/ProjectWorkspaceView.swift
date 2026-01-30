//
//  ProjectWorkspaceView.swift
//  Momentum
//
//  Created by Claude on 1/30/26.
//

import SwiftUI
import PhosphorSwift

struct ProjectWorkspaceView: View {
    let project: Goal
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showChat = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                    // Header with progress
                    headerSection

                    // Needs Your Input Section
                    if !pendingQuestions.isEmpty {
                        needsInputSection
                    }

                    // AI Work Ready Section
                    if !completedWorkItems.isEmpty {
                        aiWorkReadySection
                    }

                    // Current Phase Section
                    currentPhaseSection

                    // All Phases Timeline
                    phasesTimelineSection
                }
                .padding(.horizontal, MomentumSpacing.standard)
                .padding(.top, MomentumSpacing.standard)
                .padding(.bottom, 120)
            }
            .background(Color.momentumBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Ph.caretLeft.regular
                                .frame(width: 20, height: 20)
                            Text("Back")
                                .font(MomentumFont.bodyMedium())
                        }
                        .foregroundColor(.momentumBlue)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showChat = true
                    } label: {
                        Ph.chatCircle.fill
                            .frame(width: 24, height: 24)
                            .foregroundColor(.momentumBlue)
                    }
                }
            }
            .sheet(isPresented: $showChat) {
                // AI Chat sheet - can reuse GlobalAIChatView
                Text("AI Chat Coming Soon")
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            Text(project.visionRefined ?? project.visionText)
                .font(MomentumFont.headingLarge())
                .foregroundColor(.momentumTextPrimary)
                .lineLimit(3)

            if let powerGoal = currentPowerGoal {
                HStack(spacing: MomentumSpacing.compact) {
                    progressRing

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Phase \(powerGoal.monthNumber): \(powerGoal.title)")
                            .font(MomentumFont.bodyMedium())
                            .foregroundColor(.momentumTextPrimary)

                        Text("\(Int(project.completionPercentage))% complete")
                            .font(MomentumFont.label())
                            .foregroundColor(.momentumTextSecondary)
                    }
                }
                .padding(MomentumSpacing.compact)
                .background(Color.momentumBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.momentumCardBorder, lineWidth: 3)
                .frame(width: 40, height: 40)

            Circle()
                .trim(from: 0, to: project.completionPercentage / 100)
                .stroke(
                    MomentumGradients.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
        }
    }

    // MARK: - Needs Input Section

    private var needsInputSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            sectionHeader(icon: Ph.question.fill, title: "Needs Your Input", count: pendingQuestions.count)

            VStack(spacing: MomentumSpacing.compact) {
                ForEach(pendingQuestions) { question in
                    AIQuestionCard(question: question) { answer in
                        appState.submitAIAnswer(questionId: question.id, answer: answer)
                    }
                }
            }
        }
    }

    // MARK: - AI Work Ready Section

    private var aiWorkReadySection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            sectionHeader(icon: Ph.sparkle.fill, title: "AI Work Ready", count: completedWorkItems.count)

            VStack(spacing: MomentumSpacing.compact) {
                ForEach(completedWorkItems) { item in
                    AIReportCard(workItem: item)
                }
            }
        }
    }

    // MARK: - Current Phase Section

    private var currentPhaseSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            sectionHeader(icon: Ph.target.fill, title: "Current Focus", count: nil)

            if let powerGoal = currentPowerGoal {
                VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                    Text(powerGoal.title)
                        .font(MomentumFont.headingMedium())
                        .foregroundColor(.momentumTextPrimary)

                    if let description = powerGoal.description {
                        Text(description)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }

                    // Current milestone
                    if let milestone = currentMilestone {
                        HStack(spacing: MomentumSpacing.tight) {
                            Ph.flag.regular
                                .frame(width: 16, height: 16)
                                .foregroundColor(.momentumBlue)

                            Text("Week \(milestone.weekNumber): \(milestone.milestoneText)")
                                .font(MomentumFont.label())
                                .foregroundColor(.momentumTextSecondary)
                        }
                        .padding(.top, MomentumSpacing.tight)
                    }
                }
                .padding(MomentumSpacing.standard)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.momentumBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            }
        }
    }

    // MARK: - Phases Timeline Section

    private var phasesTimelineSection: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            sectionHeader(icon: Ph.listNumbers.fill, title: "All Phases", count: nil)

            VStack(spacing: 0) {
                ForEach(Array(project.powerGoals.enumerated()), id: \.element.id) { index, powerGoal in
                    phaseRow(powerGoal: powerGoal, index: index)

                    if index < project.powerGoals.count - 1 {
                        // Connector line
                        HStack {
                            Rectangle()
                                .fill(powerGoal.status == .completed ? Color.momentumSuccess : Color.momentumCardBorder)
                                .frame(width: 2, height: 20)
                                .padding(.leading, 15)

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func phaseRow(powerGoal: PowerGoal, index: Int) -> some View {
        HStack(spacing: MomentumSpacing.compact) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(phaseStatusColor(powerGoal.status))
                    .frame(width: 32, height: 32)

                if powerGoal.status == .completed {
                    Ph.check.bold
                        .frame(width: 14, height: 14)
                        .foregroundColor(.white)
                } else {
                    Text("\(index + 1)")
                        .font(MomentumFont.label(14))
                        .foregroundColor(powerGoal.status == .active ? .white : .momentumTextTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(powerGoal.title)
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(powerGoal.status == .locked ? .momentumTextTertiary : .momentumTextPrimary)

                Text("Month \(powerGoal.monthNumber)")
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextTertiary)
            }

            Spacer()

            if powerGoal.status == .active {
                Text("Current")
                    .font(MomentumFont.label(12))
                    .foregroundColor(.momentumBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.momentumBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, MomentumSpacing.tight)
    }

    private func phaseStatusColor(_ status: PowerGoalStatus) -> Color {
        switch status {
        case .completed: return .momentumSuccess
        case .active: return .momentumBlue
        case .locked: return .momentumCardBorder
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(icon: Image, title: String, count: Int?) -> some View {
        HStack(spacing: MomentumSpacing.tight) {
            icon
                .frame(width: 18, height: 18)
                .foregroundColor(.momentumBlue)

            Text(title)
                .font(MomentumFont.headingMedium(17))
                .foregroundColor(.momentumTextPrimary)

            if let count = count, count > 0 {
                Text("\(count)")
                    .font(MomentumFont.label(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.momentumBlue)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Computed Properties

    private var currentPowerGoal: PowerGoal? {
        project.powerGoals.first(where: { $0.status == .active })
    }

    private var currentMilestone: WeeklyMilestone? {
        currentPowerGoal?.weeklyMilestones.first(where: { $0.status == .inProgress })
    }

    private var pendingQuestions: [AIQuestion] {
        appState.aiProcessor.pendingQuestions(for: project.id)
    }

    private var completedWorkItems: [AIWorkItem] {
        appState.aiProcessor.completedWorkItems(for: project.id)
    }
}

// MARK: - AI Question Card

struct AIQuestionCard: View {
    let question: AIQuestion
    let onAnswer: (String) -> Void

    @State private var selectedOption: String?
    @State private var customInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            // Priority badge
            HStack {
                priorityBadge

                Spacer()

                if let taskId = question.taskId {
                    Text("Related to task")
                        .font(MomentumFont.caption())
                        .foregroundColor(.momentumTextTertiary)
                }
            }

            // Question
            Text(question.question)
                .font(MomentumFont.bodyMedium())
                .foregroundColor(.momentumTextPrimary)

            // Options
            VStack(spacing: MomentumSpacing.tight) {
                ForEach(question.options) { option in
                    Button {
                        selectedOption = option.label
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(MomentumFont.body())
                                .foregroundColor(.momentumTextPrimary)

                            Spacer()

                            if selectedOption == option.label {
                                Ph.checkCircle.fill
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.momentumBlue)
                            } else {
                                Circle()
                                    .strokeBorder(Color.momentumCardBorder, lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(MomentumSpacing.compact)
                        .background(
                            selectedOption == option.label
                            ? Color.momentumBlue.opacity(0.1)
                            : Color.momentumBackgroundSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom input if allowed
            if question.allowsCustomInput {
                TextField("Or type your own answer...", text: $customInput)
                    .font(MomentumFont.body())
                    .padding(MomentumSpacing.compact)
                    .background(Color.momentumBackgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                    .onChange(of: customInput) { _, newValue in
                        if !newValue.isEmpty {
                            selectedOption = nil
                        }
                    }
            }

            // Submit button
            Button {
                let answer = customInput.isEmpty ? (selectedOption ?? "") : customInput
                onAnswer(answer)
            } label: {
                Text("Submit Answer")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MomentumSpacing.compact)
                    .background(
                        (selectedOption != nil || !customInput.isEmpty)
                        ? Color.momentumBlue
                        : Color.momentumTextTertiary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
            }
            .disabled(selectedOption == nil && customInput.isEmpty)
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .strokeBorder(Color.momentumCardBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 6, height: 6)

            Text(question.priority.rawValue.capitalized)
                .font(MomentumFont.caption())
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch question.priority {
        case .blocking: return .momentumDanger
        case .important: return .momentumWarning
        case .optional: return .momentumTextTertiary
        }
    }
}

// MARK: - AI Report Card

struct AIReportCard: View {
    let workItem: AIWorkItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
            // Header
            HStack {
                workTypeIcon

                Text(workItem.title)
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.momentumTextSecondary)
                }
            }

            // Summary (always visible)
            if let result = workItem.result {
                Text(result.summary)
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
                    .lineLimit(isExpanded ? nil : 2)

                // Expanded content
                if isExpanded {
                    if let details = result.details {
                        Divider()
                            .background(Color.momentumCardBorder)

                        Text(details)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }

                    if let sources = result.sources, !sources.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sources")
                                .font(MomentumFont.label())
                                .foregroundColor(.momentumTextTertiary)

                            ForEach(sources, id: \.self) { source in
                                Text("• \(source)")
                                    .font(MomentumFont.caption())
                                    .foregroundColor(.momentumBlue)
                            }
                        }
                    }

                    if let prompt = result.prompt {
                        Button {
                            UIPasteboard.general.string = prompt
                        } label: {
                            HStack(spacing: 6) {
                                Ph.copy.regular
                                    .frame(width: 16, height: 16)
                                Text("Copy Prompt")
                                    .font(MomentumFont.label())
                            }
                            .foregroundColor(.momentumBlue)
                            .padding(.horizontal, MomentumSpacing.compact)
                            .padding(.vertical, MomentumSpacing.tight)
                            .background(Color.momentumBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
                        }
                    }
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .strokeBorder(Color.momentumCardBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var workTypeIcon: some View {
        Group {
            switch workItem.type {
            case .research:
                Ph.magnifyingGlass.fill
            case .report:
                Ph.fileText.fill
            case .toolPrompt:
                Ph.code.fill
            case .ideaGeneration:
                Ph.lightbulb.fill
            }
        }
        .frame(width: 20, height: 20)
        .foregroundColor(.momentumBlue)
    }
}

#Preview {
    let sampleGoal = Goal(
        userId: UUID(),
        visionText: "Launch a successful SaaS product",
        visionRefined: "Build and launch a 6-figure SaaS product in 12 months",
        powerGoals: [
            PowerGoal(
                goalId: UUID(),
                monthNumber: 1,
                title: "Market Research & Validation",
                description: "Validate the market need and define target customers",
                status: .completed
            ),
            PowerGoal(
                goalId: UUID(),
                monthNumber: 2,
                title: "MVP Development",
                description: "Build the minimum viable product",
                status: .active
            ),
            PowerGoal(
                goalId: UUID(),
                monthNumber: 3,
                title: "Beta Launch",
                description: "Launch to beta users and gather feedback",
                status: .locked
            )
        ]
    )

    return NavigationStack {
        ProjectWorkspaceView(project: sampleGoal)
            .environmentObject(AppState())
    }
}
