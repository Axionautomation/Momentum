//
//  ProcessView.swift
//  Momentum
//
//  Created by Claude on 1/30/26.
//

import SwiftUI
import PhosphorSwift

struct ProcessView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProject: Goal?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MomentumSpacing.section) {
                // Header
                headerSection

                // Projects Section
                if let project = appState.activeProjectGoal {
                    projectCard(project)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, MomentumSpacing.standard)
            .padding(.top, MomentumSpacing.standard)
            .padding(.bottom, 120)
        }
        .background(Color.momentumBackground)
        .sheet(item: $selectedProject) { project in
            ProjectWorkspaceView(project: project)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                Text("Your Projects")
                    .font(MomentumFont.display(28))
                    .foregroundColor(.momentumTextPrimary)

                Text("AI-powered workspace")
                    .font(MomentumFont.body())
                    .foregroundColor(.momentumTextSecondary)
            }

            Spacer()

            // Future: Add project button
            Button {
                // Add new project
            } label: {
                Ph.plus.bold
                    .frame(width: 20, height: 20)
                    .foregroundColor(.momentumBlue)
                    .padding(12)
                    .background(Color.momentumBlue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Project Card

    private func projectCard(_ project: Goal) -> some View {
        Button {
            selectedProject = project
        } label: {
            VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
                // Project Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.visionRefined ?? project.visionText)
                            .font(MomentumFont.headingMedium())
                            .foregroundColor(.momentumTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let powerGoal = project.powerGoals.first(where: { $0.status == .active }) {
                            Text("Phase \(powerGoal.monthNumber) of 12")
                                .font(MomentumFont.label())
                                .foregroundColor(.momentumTextSecondary)
                        }
                    }

                    Spacer()

                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.momentumCardBorder, lineWidth: 4)
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: project.completionPercentage / 100)
                            .stroke(
                                MomentumGradients.primary,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(project.completionPercentage))%")
                            .font(MomentumFont.label(12))
                            .foregroundColor(.momentumTextPrimary)
                    }
                }

                Divider()
                    .background(Color.momentumCardBorder)

                // Quick Stats Row
                HStack(spacing: MomentumSpacing.comfortable) {
                    quickStat(
                        icon: Ph.question.regular,
                        count: pendingQuestionsCount(for: project),
                        label: "questions"
                    )

                    quickStat(
                        icon: Ph.magnifyingGlass.regular,
                        count: readyResearchCount(for: project),
                        label: "research"
                    )

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Open")
                            .font(MomentumFont.bodyMedium())
                            .foregroundColor(.momentumBlue)
                        Ph.arrowRight.regular
                            .frame(width: 16, height: 16)
                            .foregroundColor(.momentumBlue)
                    }
                }
            }
            .padding(MomentumSpacing.standard)
            .background(Color.momentumCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: MomentumRadius.medium)
                    .strokeBorder(Color.momentumCardBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func quickStat(icon: Image, count: Int, label: String) -> some View {
        HStack(spacing: 6) {
            icon
                .frame(width: 16, height: 16)
                .foregroundColor(count > 0 ? .momentumBlue : .momentumTextTertiary)

            Text("\(count) \(label)")
                .font(MomentumFont.label())
                .foregroundColor(count > 0 ? .momentumTextPrimary : .momentumTextTertiary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MomentumSpacing.standard) {
            Ph.folderOpen.regular
                .frame(width: 48, height: 48)
                .foregroundColor(.momentumTextTertiary)

            Text("No active projects")
                .font(MomentumFont.headingMedium())
                .foregroundColor(.momentumTextPrimary)

            Text("Start by creating a new project in onboarding")
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MomentumSpacing.large)
        .padding(.horizontal, MomentumSpacing.standard)
        .background(Color.momentumBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
    }

    // MARK: - Helpers

    private func pendingQuestionsCount(for project: Goal) -> Int {
        appState.aiProcessor.pendingQuestions(for: project.id).count
    }

    private func readyResearchCount(for project: Goal) -> Int {
        appState.aiProcessor.completedWorkItems(for: project.id).count
    }
}

#Preview {
    ProcessView()
        .environmentObject(AppState())
}
