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

    // Goal State
    @Published var activeProjectGoal: Goal?
    @Published var archivedGoals: [Goal] = []

    // Today's Content
    @Published var todaysTasks: [MomentumTask] = []      // Project tasks (3)

    // UI State
    @Published var selectedTab: Tab = .home
    @Published var showTaskCompletionCelebration: Bool = false
    @Published var showAllTasksCompleteCelebration: Bool = false
    @Published var completedTaskMessage: String = ""

    // AI Service
    private let groqService = GroqService.shared

    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case home = "Home"
        case process = "Process"
        case mindset = "Mindset"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house"
            case .process: return "squares"
            case .mindset: return "brain"
            case .profile: return "user"
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
            // Load AI data
            loadAIData()
        }
    }

    func completeOnboarding(with goal: Goal) {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Create user
        currentUser = MomentumUser(email: "user@example.com")

        // Set the project goal
        activeProjectGoal = goal

        // Persist
        saveAllGoals()
        saveUser(currentUser!)

        // Load today's content
        loadTodaysContent()

        // Trigger AI processing for initial tasks
        Task {
            await triggerInitialAIProcessing()
        }
    }

    /// Trigger AI processing for all initial tasks after onboarding
    private func triggerInitialAIProcessing() async {
        guard let goal = activeProjectGoal else { return }

        // Process each of today's tasks for AI analysis
        for task in todaysTasks {
            await aiProcessor.processNewTask(task, goal: goal)
        }

        // Save AI data after processing
        saveAIData()
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

        // Load archived goals
        if let data = UserDefaults.standard.data(forKey: "savedArchivedGoals"),
           let archived = try? JSONDecoder().decode([Goal].self, from: data) {
            archivedGoals = archived
        }
    }

    /// Save a goal
    func saveGoal(_ goal: Goal) {
        activeProjectGoal = goal
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
    /// Tasks are loaded with rollover: pending tasks from today or earlier appear first,
    /// capped at 3 tasks maximum. Oldest tasks by scheduledDate take priority.
    func loadTodaysContent() {
        let today = Calendar.current.startOfDay(for: Date())

        // Load project tasks: pending tasks scheduled for today or earlier, max 3
        if let projectGoal = activeProjectGoal,
           let currentPowerGoal = projectGoal.powerGoals.first(where: { $0.status == .active }),
           let currentMilestone = currentPowerGoal.weeklyMilestones.first(where: { $0.status == .inProgress }) {

            // Get all pending tasks scheduled for today or before (rollover logic)
            let pendingTasks = currentMilestone.tasks.filter {
                $0.status == .pending &&
                Calendar.current.startOfDay(for: $0.scheduledDate) <= today
            }

            // Sort by scheduledDate (oldest first) and take max 3
            todaysTasks = Array(
                pendingTasks.sorted { $0.scheduledDate < $1.scheduledDate }.prefix(3)
            )
        } else {
            todaysTasks = []
        }

    }

    /// Legacy method for backward compatibility
    func loadTodaysTasks() {
        loadTodaysContent()
    }

    /// Load the next batch of tasks (for working ahead after completing today's tasks)
    /// Gets the next 3 pending tasks from the active milestone, regardless of scheduledDate
    func loadNextTasks() {
        if let projectGoal = activeProjectGoal,
           let currentPowerGoal = projectGoal.powerGoals.first(where: { $0.status == .active }),
           let currentMilestone = currentPowerGoal.weeklyMilestones.first(where: { $0.status == .inProgress }) {

            // Get all pending tasks, sorted by scheduledDate
            let pendingTasks = currentMilestone.tasks
                .filter { $0.status == .pending }
                .sorted { $0.scheduledDate < $1.scheduledDate }

            // Take the next 3
            todaysTasks = Array(pendingTasks.prefix(3))
        }
    }

    /// Check if there are more pending tasks available after completing current ones
    var hasMorePendingTasks: Bool {
        guard let projectGoal = activeProjectGoal,
              let currentPowerGoal = projectGoal.powerGoals.first(where: { $0.status == .active }),
              let currentMilestone = currentPowerGoal.weeklyMilestones.first(where: { $0.status == .inProgress }) else {
            return false
        }

        let pendingCount = currentMilestone.tasks.filter { $0.status == .pending }.count
        return pendingCount > 0
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

    func uncompleteTask(_ task: MomentumTask) {
        guard let index = todaysTasks.firstIndex(where: { $0.id == task.id }) else { return }

        var updatedTask = task
        updatedTask.status = .pending
        updatedTask.completedAt = nil
        todaysTasks[index] = updatedTask

        // Update the task in the goal structure
        updateTaskInGoal(updatedTask)
    }

    func updateTaskInGoal(_ task: MomentumTask) {
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

    // MARK: - Goal Management

    /// Add a new goal
    func addGoal(_ goal: Goal) {
        activeProjectGoal = goal
        saveAllGoals()
        loadTodaysContent()
    }

    /// Archive a goal
    func archiveGoal(_ goalId: UUID) {
        guard activeProjectGoal?.id == goalId else { return }

        var goalToArchive = activeProjectGoal
        activeProjectGoal = nil

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

    // MARK: - Weekly Points System
    // Easy = 1pt, Medium = 2pt, Hard = 3pt
    // Max per day = 6pts (1+2+3), Max per week = 42pts

    /// Points earned this week from completed tasks
    var weeklyPointsEarned: Int {
        // Get start of current week (Monday)
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return 0
        }

        var totalPoints = 0

        // Check project goal tasks
        if let goal = activeProjectGoal {
            for powerGoal in goal.powerGoals {
                for milestone in powerGoal.weeklyMilestones {
                    for task in milestone.tasks {
                        if task.status == .completed,
                           let completedAt = task.completedAt,
                           completedAt >= weekStart {
                            totalPoints += pointsForDifficulty(task.difficulty)
                        }
                    }
                }
            }
        }

        return totalPoints
    }

    /// Points for a given difficulty
    func pointsForDifficulty(_ difficulty: TaskDifficulty) -> Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    /// Maximum weekly points
    var weeklyPointsMax: Int { 42 }

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

        // Check today's tasks
        if let task = todaysTasks.first(where: { $0.id == id }) {
            return task
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
            migratedGoal.goalType = .project

            activeProjectGoal = migratedGoal

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
        UserDefaults.standard.removeObject(forKey: "savedArchivedGoals")
        UserDefaults.standard.removeObject(forKey: "savedUser")
        UserDefaults.standard.removeObject(forKey: "savedAIQuestions")
        UserDefaults.standard.removeObject(forKey: "savedAIWorkItems")

        currentUser = nil
        activeProjectGoal = nil
        archivedGoals = []
        todaysTasks = []
    }

    // MARK: - AI Task Processor

    /// AI processor for background work
    let aiProcessor = AITaskProcessor()

    /// Get pending AI questions for the active project
    var pendingAIQuestions: [AIQuestion] {
        guard let projectId = activeProjectGoal?.id else { return [] }
        return aiProcessor.pendingQuestions(for: projectId)
    }

    /// Get completed AI work items for the active project
    var completedAIWorkItems: [AIWorkItem] {
        guard let projectId = activeProjectGoal?.id else { return [] }
        return aiProcessor.completedWorkItems(for: projectId)
    }

    /// Submit an answer to an AI question
    func submitAIAnswer(questionId: UUID, answer: String) {
        aiProcessor.submitAnswer(for: questionId, answer: answer)
        saveAIData()
    }

    /// Queue research for a topic
    func queueAIResearch(title: String, taskId: UUID? = nil) {
        guard let projectId = activeProjectGoal?.id else { return }
        aiProcessor.queueResearch(title: title, goalId: projectId, taskId: taskId)
    }

    /// Queue a tool prompt generation
    func queueAIToolPrompt(title: String, taskId: UUID? = nil) {
        guard let projectId = activeProjectGoal?.id else { return }
        aiProcessor.queueToolPrompt(title: title, goalId: projectId, taskId: taskId)
    }

    /// Process pending AI work for active project
    func processAIWork() async {
        guard let project = activeProjectGoal else { return }
        await aiProcessor.processAllPendingWork(for: project)
        saveAIData()
    }

    /// Trigger AI processing for a new task
    func triggerAIProcessing(for task: MomentumTask) async {
        guard let project = activeProjectGoal else { return }
        await aiProcessor.processNewTask(task, goal: project)
        saveAIData()
    }

    // MARK: - AI Data Persistence

    private func saveAIData() {
        // Save pending questions
        if let encoded = try? JSONEncoder().encode(aiProcessor.pendingQuestions) {
            UserDefaults.standard.set(encoded, forKey: "savedAIQuestions")
        }

        // Save work items
        if let encoded = try? JSONEncoder().encode(aiProcessor.completedWorkItems) {
            UserDefaults.standard.set(encoded, forKey: "savedAIWorkItems")
        }
    }

    func loadAIData() {
        // Load pending questions
        if let data = UserDefaults.standard.data(forKey: "savedAIQuestions"),
           let questions = try? JSONDecoder().decode([AIQuestion].self, from: data) {
            aiProcessor.pendingQuestions = questions
        }

        // Load work items
        if let data = UserDefaults.standard.data(forKey: "savedAIWorkItems"),
           let items = try? JSONDecoder().decode([AIWorkItem].self, from: data) {
            aiProcessor.completedWorkItems = items
        }
    }
}
