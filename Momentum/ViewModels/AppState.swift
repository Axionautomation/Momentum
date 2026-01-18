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

    // Multi-Goal Architecture
    @Published var activeProjectGoal: Goal?
    @Published var activeHabitGoals: [Goal] = []
    @Published var activeIdentityGoal: Goal?
    @Published var archivedGoals: [Goal] = []

    // Today's Content
    @Published var todaysTasks: [MomentumTask] = []      // Project tasks (3)
    @Published var todaysHabits: [HabitCheckIn] = []     // Habit check-ins
    @Published var todaysIdentityTask: MomentumTask?     // 1 identity task

    // UI State
    @Published var selectedTab: Tab = .today
    @Published var showTaskCompletionCelebration: Bool = false
    @Published var showAllTasksCompleteCelebration: Bool = false
    @Published var completedTaskMessage: String = ""

    // AI Service
    private let groqService = GroqService.shared

    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case today = "Today"
        case journey = "Journey"      // Renamed from "road"
        case goals = "Goals"
        case progress = "Progress"    // Renamed from "stats"
        // REMOVED: me (now accessed via profile icon)

        var icon: String {
            switch self {
            case .today: return "sun"
            case .journey: return "road"
            case .goals: return "target"
            case .progress: return "chart"
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
            // Migrate tasks if needed
            migrateTasksIfNeeded()
        }
    }

    func completeOnboarding(with goal: Goal) {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Create user
        currentUser = MomentumUser(email: "user@example.com")

        // Set goal based on type
        switch goal.goalType {
        case .project:
            activeProjectGoal = goal
        case .habit:
            activeHabitGoals = [goal]
        case .identity:
            activeIdentityGoal = goal
        }

        // Persist
        saveAllGoals()
        saveUser(currentUser!)

        // Load today's content
        loadTodaysContent()
    }

    func loadMockData() {
        // Try to load persisted data first
        loadAllGoals()

        if let savedUser = loadUser() {
            currentUser = savedUser
            loadTodaysContent()
        } else {
            // Fallback to mock data
            currentUser = MockDataService.shared.mockUser
            activeProjectGoal = MockDataService.shared.mockGoal
            todaysTasks = MockDataService.shared.todaysTasks
        }
    }

    // MARK: - Persistence

    /// Save all goals to UserDefaults
    func saveAllGoals() {
        // Save project goal
        if let project = activeProjectGoal,
           let encoded = try? JSONEncoder().encode(project) {
            UserDefaults.standard.set(encoded, forKey: "savedProjectGoal")
        }

        // Save habit goals
        if let encoded = try? JSONEncoder().encode(activeHabitGoals) {
            UserDefaults.standard.set(encoded, forKey: "savedHabitGoals")
        }

        // Save identity goal
        if let identity = activeIdentityGoal,
           let encoded = try? JSONEncoder().encode(identity) {
            UserDefaults.standard.set(encoded, forKey: "savedIdentityGoal")
        }

        // Save archived goals
        if let encoded = try? JSONEncoder().encode(archivedGoals) {
            UserDefaults.standard.set(encoded, forKey: "savedArchivedGoals")
        }
    }

    /// Load all goals from UserDefaults
    private func loadAllGoals() {
        // Load project goal
        if let data = UserDefaults.standard.data(forKey: "savedProjectGoal"),
           let project = try? JSONDecoder().decode(Goal.self, from: data) {
            activeProjectGoal = project
        }

        // Load habit goals
        if let data = UserDefaults.standard.data(forKey: "savedHabitGoals"),
           let habits = try? JSONDecoder().decode([Goal].self, from: data) {
            activeHabitGoals = habits
        }

        // Load identity goal
        if let data = UserDefaults.standard.data(forKey: "savedIdentityGoal"),
           let identity = try? JSONDecoder().decode(Goal.self, from: data) {
            activeIdentityGoal = identity
        }

        // Load archived goals
        if let data = UserDefaults.standard.data(forKey: "savedArchivedGoals"),
           let archived = try? JSONDecoder().decode([Goal].self, from: data) {
            archivedGoals = archived
        }
    }

    /// Legacy: Save a single goal (kept for backward compatibility)
    func saveGoal(_ goal: Goal) {
        switch goal.goalType {
        case .project:
            activeProjectGoal = goal
        case .habit:
            if !activeHabitGoals.contains(where: { $0.id == goal.id }) {
                activeHabitGoals.append(goal)
            } else if let index = activeHabitGoals.firstIndex(where: { $0.id == goal.id }) {
                activeHabitGoals[index] = goal
            }
        case .identity:
            activeIdentityGoal = goal
        }
        saveAllGoals()
    }

    /// Legacy: Load goal from old format (for migration)
    private func loadLegacyGoal() -> Goal? {
        if let data = UserDefaults.standard.data(forKey: "savedGoal"),
           let goal = try? JSONDecoder().decode(Goal.self, from: data) {
            return goal
        }
        return nil
    }

    func saveUser(_ user: MomentumUser) {
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

    /// Load all content for today (project tasks, habit check-ins, identity task)
    func loadTodaysContent() {
        let today = Calendar.current.startOfDay(for: Date())

        // Load project tasks (3 tasks from active milestone)
        if let projectGoal = activeProjectGoal,
           let currentPowerGoal = projectGoal.powerGoals.first(where: { $0.status == .active }),
           let currentMilestone = currentPowerGoal.weeklyMilestones.first(where: { $0.status == .inProgress }) {
            todaysTasks = currentMilestone.tasks.filter {
                Calendar.current.isDate($0.scheduledDate, inSameDayAs: today)
            }
        } else {
            todaysTasks = []
        }

        // Load habit check-ins
        todaysHabits = activeHabitGoals.flatMap { habit in
            generateHabitCheckIns(for: habit, date: today)
        }

        // Load identity task
        if let identityGoal = activeIdentityGoal {
            todaysIdentityTask = generateDailyIdentityTask(for: identityGoal, date: today)
        } else {
            todaysIdentityTask = nil
        }
    }

    /// Legacy method for backward compatibility
    func loadTodaysTasks() {
        loadTodaysContent()
    }

    /// Generate habit check-ins for a specific date
    private func generateHabitCheckIns(for habit: Goal, date: Date) -> [HabitCheckIn] {
        guard habit.goalType == .habit else { return [] }

        // Check if habit should be done today based on frequency
        let shouldDoToday = shouldPerformHabit(habit, on: date)
        guard shouldDoToday else { return [] }

        // Create or return existing check-in
        return [HabitCheckIn(
            habitGoalId: habit.id,
            scheduledDate: date,
            isCompleted: false,
            completedAt: nil,
            notes: nil,
            skipped: false
        )]
    }

    /// Check if a habit should be performed on a given date
    private func shouldPerformHabit(_ habit: Goal, on date: Date) -> Bool {
        guard let config = habit.habitConfig else { return false }

        let weekday = Calendar.current.component(.weekday, from: date) - 1 // 0 = Sunday

        switch config.frequency {
        case .daily:
            return true
        case .weekdays:
            return weekday >= 1 && weekday <= 5 // Monday-Friday
        case .weekends:
            return weekday == 0 || weekday == 6 // Saturday-Sunday
        case .custom:
            return config.customDays?.contains(weekday) ?? false
        }
    }

    /// Generate daily identity task
    private func generateDailyIdentityTask(for identity: Goal, date: Date) -> MomentumTask? {
        guard identity.goalType == .identity else { return nil }

        // Create a simple evidence collection task
        let taskId = UUID()
        let prompt = identity.identityConfig?.identityStatement ?? "Build your identity"

        return MomentumTask(
            id: taskId,
            weeklyMilestoneId: UUID(), // Not used for identity tasks
            goalId: identity.id,
            title: "Evidence: \(prompt)",
            taskDescription: "Log evidence of living this identity today",
            difficulty: .easy,
            estimatedMinutes: 10,
            isAnchorTask: false,
            scheduledDate: date,
            status: .pending
        )
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
        // Try project goal
        if var goal = activeProjectGoal {
            for (pgIndex, powerGoal) in goal.powerGoals.enumerated() {
                for (wmIndex, milestone) in powerGoal.weeklyMilestones.enumerated() {
                    if let taskIndex = milestone.tasks.firstIndex(where: { $0.id == task.id }) {
                        goal.powerGoals[pgIndex].weeklyMilestones[wmIndex].tasks[taskIndex] = task
                        activeProjectGoal = goal
                        saveAllGoals()
                        return
                    }
                }
            }
        }

        // Identity tasks don't need to be saved in goal structure (they're generated daily)
        // Habit check-ins are handled separately
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

    // MARK: - Habit Management

    /// Complete a habit check-in and update streak
    func completeHabitCheckIn(_ checkIn: HabitCheckIn) {
        guard let habitIndex = activeHabitGoals.firstIndex(where: { $0.id == checkIn.habitGoalId }) else { return }

        // Update check-in
        if let checkInIndex = todaysHabits.firstIndex(where: { $0.id == checkIn.id }) {
            todaysHabits[checkInIndex].isCompleted = true
            todaysHabits[checkInIndex].completedAt = Date()
        }

        // Update habit streak
        updateHabitStreak(&activeHabitGoals[habitIndex])
        saveAllGoals()
    }

    /// Update streak for a habit goal
    func updateHabitStreak(_ habit: inout Goal) {
        guard habit.goalType == .habit, var config = habit.habitConfig else { return }

        let now = Date()
        let calendar = Calendar.current

        if let lastCompleted = config.lastCompletedDate {
            let daysSinceLast = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastCompleted), to: calendar.startOfDay(for: now)).day ?? 0

            if daysSinceLast <= 1 {
                // Continue streak (same day or next day)
                if daysSinceLast == 1 {
                    config.currentStreak += 1
                }
                // If same day (daysSinceLast == 0), don't increment
            } else {
                // Streak broken
                config.currentStreak = 1
            }
        } else {
            config.currentStreak = 1
        }

        config.lastCompletedDate = now
        if config.currentStreak > config.longestStreak {
            config.longestStreak = config.currentStreak
        }

        habit.habitConfig = config
    }

    // MARK: - Identity Management

    /// Add an evidence entry to an identity goal
    func addEvidenceEntry(_ entry: EvidenceEntry, to goalId: UUID) {
        if var identity = activeIdentityGoal, identity.id == goalId {
            identity.identityConfig?.evidenceEntries.append(entry)
            activeIdentityGoal = identity
            saveAllGoals()
        }
    }

    /// Complete an identity milestone
    func completeIdentityMilestone(_ milestoneId: UUID, in goalId: UUID, with evidenceId: UUID?) {
        if var identity = activeIdentityGoal, identity.id == goalId,
           let milestoneIndex = identity.identityConfig?.milestones.firstIndex(where: { $0.id == milestoneId }) {
            identity.identityConfig?.milestones[milestoneIndex].isCompleted = true
            identity.identityConfig?.milestones[milestoneIndex].completedDate = Date()
            identity.identityConfig?.milestones[milestoneIndex].evidenceId = evidenceId
            activeIdentityGoal = identity
            saveAllGoals()
        }
    }

    // MARK: - Goal Management

    /// Add a new goal
    func addGoal(_ goal: Goal) {
        switch goal.goalType {
        case .project:
            activeProjectGoal = goal
        case .habit:
            activeHabitGoals.append(goal)
        case .identity:
            activeIdentityGoal = goal
        }
        saveAllGoals()
        loadTodaysContent()
    }

    /// Archive a goal
    func archiveGoal(_ goalId: UUID) {
        var goalToArchive: Goal?

        // Find and remove from active goals
        if activeProjectGoal?.id == goalId {
            goalToArchive = activeProjectGoal
            activeProjectGoal = nil
        } else if let habitIndex = activeHabitGoals.firstIndex(where: { $0.id == goalId }) {
            goalToArchive = activeHabitGoals.remove(at: habitIndex)
        } else if activeIdentityGoal?.id == goalId {
            goalToArchive = activeIdentityGoal
            activeIdentityGoal = nil
        }

        // Add to archived
        if var goal = goalToArchive {
            goal.status = .archived
            archivedGoals.append(goal)
            saveAllGoals()
            loadTodaysContent()
        }
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
        activeProjectGoal?.powerGoals.first(where: { $0.status == .active })?.completionPercentage ?? 0
    }

    // MARK: - Task Notes Management

    /// Update notes for a specific task
    func updateTaskNotes(_ taskId: UUID, notes: TaskNotes) {
        // Try project goal
        if var goal = activeProjectGoal {
            for (pgIndex, powerGoal) in goal.powerGoals.enumerated() {
                for (wmIndex, milestone) in powerGoal.weeklyMilestones.enumerated() {
                    if let taskIndex = milestone.tasks.firstIndex(where: { $0.id == taskId }) {
                        var updatedNotes = notes
                        updatedNotes.lastUpdated = Date()
                        goal.powerGoals[pgIndex].weeklyMilestones[wmIndex].tasks[taskIndex].notes = updatedNotes
                        activeProjectGoal = goal
                        saveAllGoals()

                        // Update todaysTasks if this is one of them
                        if let todayIndex = todaysTasks.firstIndex(where: { $0.id == taskId }) {
                            todaysTasks[todayIndex].notes = updatedNotes
                        }
                        return
                    }
                }
            }
        }
    }

    /// Add a conversation message to a task's notes
    func addConversationMessage(taskId: UUID, message: ConversationMessage) {
        guard let task = findTask(by: taskId) else { return }
        var notes = task.notes
        notes.conversationHistory.append(message)
        updateTaskNotes(taskId, notes: notes)
    }

    /// Add a research finding to a task's notes
    func addResearchFinding(taskId: UUID, finding: ResearchFinding) {
        guard let task = findTask(by: taskId) else { return }
        var notes = task.notes
        notes.researchFindings.append(finding)
        updateTaskNotes(taskId, notes: notes)
    }

    /// Update or create a brainstorm note for a task
    func updateBrainstorm(taskId: UUID, brainstormId: UUID? = nil, content: String) {
        guard let task = findTask(by: taskId) else { return }
        var notes = task.notes

        if let id = brainstormId,
           let index = notes.userBrainstorms.firstIndex(where: { $0.id == id }) {
            // Update existing brainstorm
            notes.userBrainstorms[index].content = content
            notes.userBrainstorms[index].lastModified = Date()
        } else {
            // Create new brainstorm
            let brainstorm = BrainstormNote(content: content)
            notes.userBrainstorms.append(brainstorm)
        }

        updateTaskNotes(taskId, notes: notes)
    }

    /// Delete a brainstorm note
    func deleteBrainstorm(taskId: UUID, brainstormId: UUID) {
        guard let task = findTask(by: taskId) else { return }
        var notes = task.notes
        notes.userBrainstorms.removeAll { $0.id == brainstormId }
        updateTaskNotes(taskId, notes: notes)
    }

    /// Find a task by ID across all goals
    func findTask(by id: UUID) -> MomentumTask? {
        // Check project goal
        if let goal = activeProjectGoal {
            for powerGoal in goal.powerGoals {
                for milestone in powerGoal.weeklyMilestones {
                    if let task = milestone.tasks.first(where: { $0.id == id }) {
                        return task
                    }
                }
            }
        }

        // Check identity task
        if let identityTask = todaysIdentityTask, identityTask.id == id {
            return identityTask
        }

        return nil
    }

    /// Get set of task IDs that have notes (for UI indicators)
    func tasksWithNotes() -> Set<UUID> {
        var taskIds = Set<UUID>()

        // Check project goal tasks
        if let goal = activeProjectGoal {
            for powerGoal in goal.powerGoals {
                for milestone in powerGoal.weeklyMilestones {
                    for task in milestone.tasks {
                        if !task.notes.conversationHistory.isEmpty ||
                           !task.notes.researchFindings.isEmpty ||
                           !task.notes.userBrainstorms.isEmpty {
                            taskIds.insert(task.id)
                        }
                    }
                }
            }
        }

        return taskIds
    }

    // MARK: - Global AI Chat State

    @Published var showGlobalChat: Bool = false
    @Published var globalChatTaskContext: MomentumTask?

    /// Open global chat with optional task context
    func openGlobalChat(withTask task: MomentumTask? = nil) {
        globalChatTaskContext = task
        showGlobalChat = true
    }

    /// Close global chat
    func closeGlobalChat() {
        showGlobalChat = false
        // Don't clear task context - preserve for next open
    }

    /// Switch the task context in global chat
    func switchChatTask(_ task: MomentumTask) {
        globalChatTaskContext = task
    }

    // MARK: - Data Migration

    /// Migrate existing tasks to include notes structure and multi-goal architecture
    private func migrateTasksIfNeeded() {
        let migrationVersion = UserDefaults.standard.integer(forKey: "taskNotesMigrationVersion")

        if migrationVersion < 1 {
            print("🔄 Migrating tasks to v1 (adding notes structure)...")
            migrateV1Tasks()
            UserDefaults.standard.set(1, forKey: "taskNotesMigrationVersion")
            print("✅ Migration complete")
        }

        if migrationVersion < 2 {
            print("🔄 Migrating to v2 (multi-goal architecture)...")
            migrateToMultiGoalArchitecture()
            UserDefaults.standard.set(2, forKey: "taskNotesMigrationVersion")
            print("✅ Migration to v2 complete")
        }
    }

    private func migrateV1Tasks() {
        guard let goal = activeProjectGoal else { return }
        var needsSave = false

        for (_, powerGoal) in goal.powerGoals.enumerated() {
            for (_, milestone) in powerGoal.weeklyMilestones.enumerated() {
                for (_, _) in milestone.tasks.enumerated() {
                    // Tasks created with new init will have default TaskNotes()
                    // This ensures any tasks loaded from old data get initialized properly
                    // The TaskNotes init already provides empty arrays, so no action needed
                    // Just mark that we've checked it
                    needsSave = true
                }
            }
        }

        if needsSave {
            activeProjectGoal = goal
            saveAllGoals()
        }
    }

    /// Migrate from single activeGoal to multi-goal architecture
    private func migrateToMultiGoalArchitecture() {
        // Check if there's a legacy goal saved
        if let legacyGoal = loadLegacyGoal() {
            print("Found legacy goal, migrating to multi-goal format...")

            // Set goalType to project if not already set
            var migratedGoal = legacyGoal
            if migratedGoal.goalType != .project && migratedGoal.goalType != .habit && migratedGoal.goalType != .identity {
                // Default to project type for legacy goals
                migratedGoal.goalType = .project
            }

            // Place in appropriate category based on type
            switch migratedGoal.goalType {
            case .project:
                activeProjectGoal = migratedGoal
            case .habit:
                activeHabitGoals = [migratedGoal]
            case .identity:
                activeIdentityGoal = migratedGoal
            }

            // Save in new format
            saveAllGoals()
            print("✅ Legacy goal migrated successfully")
        }
    }

    // MARK: - Reset for Testing
    func resetOnboarding() {
        isOnboarded = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Clear all goal storage
        UserDefaults.standard.removeObject(forKey: "savedGoal")
        UserDefaults.standard.removeObject(forKey: "savedProjectGoal")
        UserDefaults.standard.removeObject(forKey: "savedHabitGoals")
        UserDefaults.standard.removeObject(forKey: "savedIdentityGoal")
        UserDefaults.standard.removeObject(forKey: "savedArchivedGoals")
        UserDefaults.standard.removeObject(forKey: "savedUser")

        currentUser = nil
        activeProjectGoal = nil
        activeHabitGoals = []
        activeIdentityGoal = nil
        archivedGoals = []
        todaysTasks = []
        todaysHabits = []
        todaysIdentityTask = nil
    }
}
