//
//  TaskPickerView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/31/25.
//

import SwiftUI
import PhosphorSwift

struct TaskPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let onSelect: (MomentumTask) -> Void

    var allTasks: [MomentumTask] {
        guard let goal = appState.activeProjectGoal else { return [] }
        var tasks: [MomentumTask] = []

        for powerGoal in goal.powerGoals where powerGoal.status == .active {
            for milestone in powerGoal.weeklyMilestones where milestone.status == .inProgress {
                tasks.append(contentsOf: milestone.tasks)
            }
        }

        return tasks.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.momentumDarkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        if allTasks.isEmpty {
                            VStack(spacing: 16) {
                                Ph.tray.regular
                                    .color(.momentumSecondaryText)
                                    .frame(width: 48, height: 48)

                                Text("No active tasks found")
                                    .font(MomentumFont.bodyMedium(16))
                                    .foregroundColor(.momentumSecondaryText)

                                Text("Complete onboarding to create your first goal and tasks")
                                    .font(MomentumFont.body(14))
                                    .foregroundColor(.momentumSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(allTasks) { task in
                                Button {
                                    onSelect(task)
                                } label: {
                                    taskRow(task)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.momentumViolet)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func taskRow(_ task: MomentumTask) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(MomentumFont.bodyMedium(15))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    // Difficulty badge
                    Text(task.difficulty.emoji)
                    Text(task.difficulty.displayName)
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumSecondaryText)

                    Text("•")
                        .foregroundColor(.momentumSecondaryText)

                    // Date
                    Text(dateLabel(for: task.scheduledDate))
                        .font(MomentumFont.body(12))
                        .foregroundColor(.momentumSecondaryText)
                }
            }

            Spacer()

            // Status indicator
            if task.status == .completed {
                Ph.checkCircle.fill
                    .color(.momentumGreenStart)
                    .frame(width: 20, height: 20)
            } else {
                Ph.caretRight.regular
                    .color(.momentumSecondaryText)
                    .frame(width: 16, height: 16)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TaskPickerView { task in
        print("Selected task: \(task.title)")
    }
    .environmentObject({
        let state = AppState()
        state.loadMockData()
        return state
    }())
}
