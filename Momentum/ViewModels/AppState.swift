//
//  AppState.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isOnboarded: Bool = false
    @Published var currentUser: MomentumUser?
    @Published var activeGoal: Goal?
    @Published var todaysTasks: [MomentumTask] = []
    @Published var selectedTab: Tab = .today
    @Published var showTaskCompletionCelebration: Bool = false
    @Published var showAllTasksCompleteCelebration: Bool = false
    @Published var completedTaskMessage: String = ""

    // AI Service
    private let groqService = GroqService.shared

    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case today = "Today"
        case road = "Road"
        case goals = "Goals"
        case stats = "Stats"
        case me = "Me"

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .road: return "road.lanes"
            case .goals: return "target"
            case .stats: return "chart.bar.fill"
            case .me: return "person.fill"
            }
        }
    }

    // MARK: - Initialization
    init() {
        loadUserData()
    }

    // MARK: - User Data
    func loadUserData() {
        // Check if user has completed onboarding
        isOnboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if isOnboarded {
            // Load mock user data for now
            loadMockData()
        }
    }

    func completeOnboarding(with goal: Goal) {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Create user
        currentUser = MomentumUser(email: "user@example.com")
        activeGoal = goal

        // Persist the goal
        saveGoal(goal)
        saveUser(currentUser!)

        // Load today's tasks from the goal
        loadTodaysTasks()
    }

    func loadMockData() {
        // Try to load persisted data first
        if let savedGoal = loadGoal(), let savedUser = loadUser() {
            currentUser = savedUser
            activeGoal = savedGoal
            loadTodaysTasks()
        } else {
            // Fallback to mock data
            currentUser = MockDataService.shared.mockUser
            activeGoal = MockDataService.shared.mockGoal
            todaysTasks = MockDataService.shared.todaysTasks
        }
    }

    // MARK: - Persistence
    private func saveGoal(_ goal: Goal) {
        if let encoded = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(encoded, forKey: "savedGoal")
        }
    }

    private func loadGoal() -> Goal? {
        if let data = UserDefaults.standard.data(forKey: "savedGoal"),
           let goal = try? JSONDecoder().decode(Goal.self, from: data) {
            return goal
        }
        return nil
    }

    private func saveUser(_ user: MomentumUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "savedUser")
        }
    }

    private func loadUser() -> MomentumUser? {
        if let data = UserDefaults.standard.data(forKey: "savedUser"),
           let user = try? JSONDecoder().decode(MomentumUser.self, from: data) {
            return user
        }
        return nil
    }

    // MARK: - Task Management
    func loadTodaysTasks() {
        guard let goal = activeGoal,
              let currentPowerGoal = goal.powerGoals.first(where: { $0.status == .active }),
              let currentMilestone = currentPowerGoal.weeklyMilestones.first(where: { $0.status == .inProgress }) else {
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        todaysTasks = currentMilestone.tasks.filter {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: today)
        }
    }

    func completeTask(_ task: MomentumTask) {
        guard let index = todaysTasks.firstIndex(where: { $0.id == task.id }) else { return }

        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.completedAt = Date()
        todaysTasks[index] = updatedTask

        // Update the task in the goal structure
        updateTaskInGoal(updatedTask)

        // Update streak
        updateStreak()

        // Get personalized AI message
        getPersonalizedCompletionMessage(forTask: task)

        // Check if all tasks are complete
        let allComplete = todaysTasks.allSatisfy { $0.status == .completed }
        if allComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showAllTasksCompleteCelebration = true
            }
        }

        // Hide celebration after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showTaskCompletionCelebration = false
        }
    }

    private func updateTaskInGoal(_ task: MomentumTask) {
        guard var goal = activeGoal else { return }

        // Find and update the task in the goal structure
        for (pgIndex, powerGoal) in goal.powerGoals.enumerated() {
            for (wmIndex, milestone) in powerGoal.weeklyMilestones.enumerated() {
                if let taskIndex = milestone.tasks.firstIndex(where: { $0.id == task.id }) {
                    goal.powerGoals[pgIndex].weeklyMilestones[wmIndex].tasks[taskIndex] = task
                    activeGoal = goal
                    saveGoal(goal)
                    return
                }
            }
        }
    }

    private func getPersonalizedCompletionMessage(forTask task: MomentumTask) {
        let personality = currentUser?.aiPersonality ?? .energetic

        // Use default message first
        showTaskCompletionCelebration = true
        completedTaskMessage = personality.completionMessage

        // Then get AI-powered message in background
        Task {
            do {
                let message = try await groqService.getPersonalizedMessage(
                    event: .taskCompleted,
                    personality: personality,
                    context: "Task: \(task.title)"
                )

                await MainActor.run {
                    // Only update if still showing the celebration
                    if showTaskCompletionCelebration {
                        completedTaskMessage = message
                    }
                }
            } catch {
                // Keep default message on error
                print("Error getting AI message: \(error)")
            }
        }
    }

    func updateStreak() {
        guard var user = currentUser else { return }

        let now = Date()
        let calendar = Calendar.current

        if let lastCompleted = user.lastTaskCompletedAt {
            let daysSinceLast = calendar.dateComponents([.day], from: lastCompleted, to: now).day ?? 0

            if daysSinceLast <= 1 {
                // Continue or start streak
                if daysSinceLast == 1 || (daysSinceLast == 0 && !calendar.isDate(lastCompleted, inSameDayAs: now)) {
                    user.streakCount += 1
                }
            } else {
                // Streak broken
                user.streakCount = 1
            }
        } else {
            user.streakCount = 1
        }

        user.lastTaskCompletedAt = now
        if user.streakCount > user.longestStreak {
            user.longestStreak = user.streakCount
        }

        currentUser = user
        saveUser(user)
    }

    // MARK: - Progress Calculations
    var weeklyTasksCompleted: Int {
        // In a real app, this would query all tasks for the current week
        todaysTasks.filter { $0.status == .completed }.count
    }

    var weeklyTotalTasks: Int {
        // In a real app, this would be 21 (3 tasks * 7 days)
        21
    }

    var currentPowerGoalProgress: Double {
        activeGoal?.powerGoals.first(where: { $0.status == .active })?.completionPercentage ?? 0
    }

    // MARK: - Reset for Testing
    func resetOnboarding() {
        isOnboarded = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "savedGoal")
        UserDefaults.standard.removeObject(forKey: "savedUser")
        currentUser = nil
        activeGoal = nil
        todaysTasks = []
    }
}
