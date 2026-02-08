//
//  AppState.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI
import Combine
import WidgetKit

@MainActor
class AppState: ObservableObject {
    // MARK: - Published State

    @Published var isOnboarded: Bool = false
    @Published var currentUser: MomentumUser?
    @Published var goals: [Goal] = []
    @Published var achievements: [Achievement] = []

    // AI Memory
    @Published var aiMemoryEntries: [AIMemoryEntry] = []

    // Content Drafts
    @Published var drafts: [DraftContent] = []

    // Calendar
    @Published var calendarAccessGranted: Bool = false

    // AI Feed System
    @Published var aiFeedItems: [AIFeedItem] = []
    @Published var pendingSkillQuestions: [SkillQuestion] = []
    @Published var pendingQuestionnaires: [AIQuestionnaire] = []
    @Published var pendingToolPrompts: [ToolPrompt] = []
    @Published var aiReports: [AIReport] = []
    @Published var isEvaluatingTasks: Bool = false

    // User Skills & Preferences
    @Published var userSkills: [String: String] = [:]
    @Published var userPreferences: UserPreferences = UserPreferences()

    // Knowledge Base
    @Published var knowledgeBase: [KnowledgeBaseEntry] = []

    // UI State
    @Published var selectedTab: Tab = .dashboard
    @Published var showTaskCompletionCelebration: Bool = false
    @Published var showAllTasksCompleteCelebration: Bool = false
    @Published var completedTaskMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Briefing Engine
    @Published var briefingEngine = BriefingEngine()

    // Notification Service
    @Published var notificationService = NotificationService()

    // Phase 4 Services
    @Published var researchPipeline = ResearchPipelineService()
    @Published var contentDraftingService = ContentDraftingService()
    @Published var calendarService = CalendarService()
    @Published var aiMemoryService = AIMemoryService()

    // AI Service
    private let groqService = GroqService.shared
    private var cancellables = Set<AnyCancellable>()
    private var lastEvaluationDate: Date?

    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case goals = "Goals"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .goals: return "target"
            case .profile: return "user"
            }
        }
    }

    // MARK: - Persistence Keys
    private enum StorageKeys {
        static let isOnboarded = "hasCompletedOnboarding"
        static let currentUser = "savedUser"
        static let goals = "savedGoals"
        static let achievements = "savedAchievements"
        static let userSkills = "userSkills"
        static let userPreferences = "userPreferences"
        static let knowledgeBase = "knowledgeBase"
        static let pendingSkillQuestions = "pendingSkillQuestions"
        static let pendingQuestionnaires = "pendingQuestionnaires"
        static let pendingToolPrompts = "pendingToolPrompts"
        static let aiReports = "aiReports"
        static let aiMemoryEntries = "aiMemoryEntries"
        static let drafts = "drafts"
        static let calendarAccessGranted = "calendarAccessGranted"
        static let migrationVersion = "migrationVersion"
    }

    // MARK: - Initialization
    init() {
        loadState()
        setupAutoSave()
    }

    // MARK: - Computed Properties

    var activeGoal: Goal? {
        goals.first { $0.status == .active }
    }

    var currentMilestone: Milestone? {
        guard let goal = activeGoal else { return nil }
        let index = goal.currentMilestoneIndex
        guard index < goal.milestones.count else { return nil }
        return goal.milestones[index]
    }

    var todaysTasks: [MomentumTask] {
        guard let milestone = currentMilestone else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return milestone.tasks.filter { task in
            task.status == .pending &&
            calendar.startOfDay(for: task.scheduledDate) <= today
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    var completedTodaysTasks: [MomentumTask] {
        guard let milestone = currentMilestone else { return [] }
        let calendar = Calendar.current
        return milestone.tasks.filter { task in
            task.status == .completed &&
            calendar.isDateInToday(task.completedAt ?? Date.distantPast)
        }
    }

    var hasMorePendingTasks: Bool {
        guard let milestone = currentMilestone else { return false }
        return milestone.tasks.contains { $0.status == .pending }
    }

    var streakCount: Int {
        currentUser?.streakCount ?? 0
    }

    var currentMilestoneProgress: Double {
        currentMilestone?.completionPercentage ?? 0
    }

    var currentBriefing: BriefingReport? {
        briefingEngine.currentBriefing
    }

    /// Weekly points earned (calculated from completed tasks)
    var weeklyPointsEarned: Int {
        guard let milestone = currentMilestone else { return 0 }
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        return milestone.tasks
            .filter { task in
                guard task.status == .completed,
                      let completedAt = task.completedAt else { return false }
                return completedAt >= weekStart
            }
            .reduce(0) { $0 + $1.difficulty.points }
    }

    /// Maximum weekly points possible
    var weeklyPointsMax: Int {
        guard let milestone = currentMilestone else { return 30 }
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()

        return milestone.tasks
            .filter { task in
                task.scheduledDate >= weekStart && task.scheduledDate < weekEnd
            }
            .reduce(0) { $0 + $1.difficulty.points }
    }

    /// AI Task Processor for background AI work
    lazy var aiProcessor: AITaskProcessor = AITaskProcessor()

    // MARK: - State Management

    private func loadState() {
        let defaults = UserDefaults.standard

        runMigrations()

        isOnboarded = defaults.bool(forKey: StorageKeys.isOnboarded)

        if let userData = defaults.data(forKey: StorageKeys.currentUser),
           let user = try? JSONDecoder().decode(MomentumUser.self, from: userData) {
            currentUser = user
        }

        if let goalsData = defaults.data(forKey: StorageKeys.goals),
           let loadedGoals = try? JSONDecoder().decode([Goal].self, from: goalsData) {
            goals = loadedGoals
        }

        if let achievementsData = defaults.data(forKey: StorageKeys.achievements),
           let loadedAchievements = try? JSONDecoder().decode([Achievement].self, from: achievementsData) {
            achievements = loadedAchievements
        }

        if let skillsData = defaults.data(forKey: StorageKeys.userSkills),
           let loadedSkills = try? JSONDecoder().decode([String: String].self, from: skillsData) {
            userSkills = loadedSkills
        }

        if let prefsData = defaults.data(forKey: StorageKeys.userPreferences),
           let loadedPrefs = try? JSONDecoder().decode(UserPreferences.self, from: prefsData) {
            userPreferences = loadedPrefs
        }

        if let kbData = defaults.data(forKey: StorageKeys.knowledgeBase),
           let loadedKB = try? JSONDecoder().decode([KnowledgeBaseEntry].self, from: kbData) {
            knowledgeBase = loadedKB
        }

        if let sqData = defaults.data(forKey: StorageKeys.pendingSkillQuestions),
           let loadedSQ = try? JSONDecoder().decode([SkillQuestion].self, from: sqData) {
            pendingSkillQuestions = loadedSQ
        }

        if let qaData = defaults.data(forKey: StorageKeys.pendingQuestionnaires),
           let loadedQA = try? JSONDecoder().decode([AIQuestionnaire].self, from: qaData) {
            pendingQuestionnaires = loadedQA
        }

        if let tpData = defaults.data(forKey: StorageKeys.pendingToolPrompts),
           let loadedTP = try? JSONDecoder().decode([ToolPrompt].self, from: tpData) {
            pendingToolPrompts = loadedTP
        }

        if let reportsData = defaults.data(forKey: StorageKeys.aiReports),
           let loadedReports = try? JSONDecoder().decode([AIReport].self, from: reportsData) {
            aiReports = loadedReports
        }

        if let memoryData = defaults.data(forKey: StorageKeys.aiMemoryEntries),
           let loadedMemory = try? JSONDecoder().decode([AIMemoryEntry].self, from: memoryData) {
            aiMemoryEntries = loadedMemory
        }

        if let draftsData = defaults.data(forKey: StorageKeys.drafts),
           let loadedDrafts = try? JSONDecoder().decode([DraftContent].self, from: draftsData) {
            drafts = loadedDrafts
        }

        calendarAccessGranted = defaults.bool(forKey: StorageKeys.calendarAccessGranted)

        refreshAIFeed()
    }

    private func saveState() {
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()

        defaults.set(isOnboarded, forKey: StorageKeys.isOnboarded)

        if let user = currentUser, let data = try? encoder.encode(user) {
            defaults.set(data, forKey: StorageKeys.currentUser)
        }

        if let data = try? encoder.encode(goals) {
            defaults.set(data, forKey: StorageKeys.goals)
        }

        if let data = try? encoder.encode(achievements) {
            defaults.set(data, forKey: StorageKeys.achievements)
        }

        if let data = try? encoder.encode(userSkills) {
            defaults.set(data, forKey: StorageKeys.userSkills)
        }

        if let data = try? encoder.encode(userPreferences) {
            defaults.set(data, forKey: StorageKeys.userPreferences)
        }

        if let data = try? encoder.encode(knowledgeBase) {
            defaults.set(data, forKey: StorageKeys.knowledgeBase)
        }

        if let data = try? encoder.encode(pendingSkillQuestions) {
            defaults.set(data, forKey: StorageKeys.pendingSkillQuestions)
        }

        if let data = try? encoder.encode(pendingQuestionnaires) {
            defaults.set(data, forKey: StorageKeys.pendingQuestionnaires)
        }

        if let data = try? encoder.encode(pendingToolPrompts) {
            defaults.set(data, forKey: StorageKeys.pendingToolPrompts)
        }

        if let data = try? encoder.encode(aiReports) {
            defaults.set(data, forKey: StorageKeys.aiReports)
        }

        if let data = try? encoder.encode(aiMemoryEntries) {
            defaults.set(data, forKey: StorageKeys.aiMemoryEntries)
        }

        if let data = try? encoder.encode(drafts) {
            defaults.set(data, forKey: StorageKeys.drafts)
        }

        defaults.set(calendarAccessGranted, forKey: StorageKeys.calendarAccessGranted)

        // Update widget data in shared App Group container
        updateWidgetData()
    }

    /// Write current state to the shared App Group container for the widget.
    private func updateWidgetData() {
        let topTasks = todaysTasks.prefix(3).map { $0.title }
        let insight = currentBriefing?.insight

        let widgetData = WidgetData(
            streakCount: streakCount,
            tasksRemaining: todaysTasks.filter { $0.status == .pending }.count,
            tasksCompleted: completedTodaysTasks.count,
            totalTasks: todaysTasks.count + completedTodaysTasks.count,
            topTaskTitles: Array(topTasks),
            aiInsight: insight,
            goalDomain: activeGoal?.domain.rawValue,
            milestoneName: currentMilestone?.title,
            milestoneProgress: (currentMilestone?.completionPercentage ?? 0) / 100.0,
            lastUpdated: Date()
        )
        widgetData.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func setupAutoSave() {
        $goals
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)

        $currentUser
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)

        $userSkills
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
    }

    // MARK: - Migration

    private func runMigrations() {
        let defaults = UserDefaults.standard
        let currentVersion = defaults.integer(forKey: StorageKeys.migrationVersion)

        if currentVersion < 4 {
            migrateToMilestoneSystem()
            defaults.set(4, forKey: StorageKeys.migrationVersion)
        }

        if currentVersion < 5 {
            migrateToDomainSystem()
            defaults.set(5, forKey: StorageKeys.migrationVersion)
        }
    }

    private func migrateToMilestoneSystem() {
        print("Running migration to Milestone system (v4)")
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "savedProjectGoal")
        defaults.removeObject(forKey: "savedGoal")
        defaults.removeObject(forKey: "savedArchivedGoals")
    }

    private func migrateToDomainSystem() {
        print("Running migration to Domain system (v5)")
        // Existing goals default to .career domain via the Codable default
        // No data deletion needed — the domain field has a default value
    }

    // MARK: - Onboarding

    func completeOnboarding(with goal: Goal) {
        let userId = goal.userId
        currentUser = MomentumUser(
            id: userId,
            email: "user@momentum.app",
            preferences: userPreferences
        )

        goals = [goal]
        isOnboarded = true
        saveState()

        // Request notification permission and schedule default notifications
        Task {
            let granted = await notificationService.requestPermission()
            if granted {
                notificationService.scheduleMorningBriefing(at: 8, minute: 0)
                notificationService.scheduleStreakReminder()
            }
            await evaluateTodaysTasks()
        }
    }

    // MARK: - AI Feed Management

    func refreshAIFeed() {
        var items: [AIFeedItem] = []

        for question in pendingSkillQuestions where question.answer == nil {
            items.append(.skillQuestion(question))
        }

        for questionnaire in pendingQuestionnaires where !questionnaire.isCompleted {
            items.append(.questionnaire(questionnaire))
        }

        for report in aiReports.prefix(3) {
            items.append(.report(report))
        }

        for prompt in pendingToolPrompts {
            items.append(.toolPrompt(prompt))
        }

        aiFeedItems = items.sorted { $0.priority < $1.priority }
    }

    // MARK: - Daily Task Evaluation

    func evaluateTodaysTasks() async {
        guard !todaysTasks.isEmpty else { return }

        let calendar = Calendar.current
        if let lastEval = lastEvaluationDate, calendar.isDateInToday(lastEval) {
            return
        }

        isEvaluatingTasks = true

        do {
            let goalContext = activeGoal?.visionRefined ?? activeGoal?.visionText ?? ""
            let evaluations = try await groqService.evaluateTodaysTasks(
                tasks: todaysTasks,
                userSkills: userSkills,
                goalContext: goalContext
            )

            for (index, evaluation) in evaluations.enumerated() {
                guard index < todaysTasks.count else { break }
                let task = todaysTasks[index]

                let approach = TaskApproach(rawValue: evaluation.approach) ?? .userDirect
                let aiEvaluation = TaskAIEvaluation(
                    canAIDo: evaluation.canAIDo,
                    canUserDo: evaluation.canUserDo,
                    skillsRequired: evaluation.skillsRequired,
                    approach: approach,
                    guidanceNeeded: evaluation.guidanceNeeded
                )

                updateTaskEvaluation(taskId: task.id, evaluation: aiEvaluation)

                if let skillQuestions = evaluation.skillQuestions {
                    for sq in skillQuestions where userSkills[sq.skill] == nil {
                        let question = SkillQuestion(
                            taskId: task.id,
                            skill: sq.skill,
                            question: sq.question,
                            options: sq.options
                        )
                        pendingSkillQuestions.append(question)
                    }
                }

                if let toolSuggestion = evaluation.toolSuggestion {
                    Task {
                        do {
                            let prompt = try await groqService.generateToolPromptForTask(
                                task: task,
                                tool: toolSuggestion.toolName,
                                userSkillLevel: userSkills[toolSuggestion.toolName.lowercased()],
                                goalContext: goalContext
                            )
                            pendingToolPrompts.append(prompt)
                            refreshAIFeed()
                        } catch {
                            print("Failed to generate tool prompt: \(error)")
                        }
                    }
                }

                if evaluation.guidanceNeeded {
                    Task {
                        do {
                            let questionnaire = try await groqService.generateGuidanceQuestionnaire(
                                task: task,
                                goalContext: goalContext
                            )
                            pendingQuestionnaires.append(questionnaire)
                            refreshAIFeed()
                        } catch {
                            print("Failed to generate questionnaire: \(error)")
                        }
                    }
                }
            }

            lastEvaluationDate = Date()
            refreshAIFeed()

        } catch {
            print("Failed to evaluate tasks: \(error)")
        }

        isEvaluatingTasks = false

        // Trigger briefing generation after evaluation
        await briefingEngine.generateBriefingIfNeeded(
            goal: activeGoal,
            tasks: currentMilestone?.tasks ?? [],
            streak: streakCount,
            milestone: currentMilestone,
            personality: currentUser?.aiPersonality ?? .energetic
        )
    }

    func refreshBriefing() async {
        await briefingEngine.forceRefreshBriefing(
            goal: activeGoal,
            tasks: currentMilestone?.tasks ?? [],
            streak: streakCount,
            milestone: currentMilestone,
            personality: currentUser?.aiPersonality ?? .energetic
        )
    }

    private func updateTaskEvaluation(taskId: UUID, evaluation: TaskAIEvaluation) {
        guard let goalIndex = goals.firstIndex(where: { goal in
            goal.milestones.contains { $0.tasks.contains { $0.id == taskId } }
        }),
        let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.tasks.contains { $0.id == taskId } }),
        let taskIndex = goals[goalIndex].milestones[milestoneIndex].tasks.firstIndex(where: { $0.id == taskId })
        else { return }

        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].aiEvaluation = evaluation
    }

    // MARK: - Skill Question Handling

    func submitSkillAnswer(_ question: SkillQuestion, answer: String) {
        userSkills[question.skill] = answer

        if let index = pendingSkillQuestions.firstIndex(where: { $0.id == question.id }) {
            pendingSkillQuestions[index].answer = answer
            pendingSkillQuestions[index].answeredAt = Date()
        }

        userPreferences.userSkills[question.skill] = answer
        refreshAIFeed()
        saveState()

        Task {
            await evaluateTodaysTasks()
        }
    }

    // MARK: - Questionnaire Handling

    func submitQuestionnaireAnswer(_ questionnaire: AIQuestionnaire, questionId: UUID, answer: String) {
        guard let qIndex = pendingQuestionnaires.firstIndex(where: { $0.id == questionnaire.id }) else { return }

        if let bqIndex = pendingQuestionnaires[qIndex].questions.firstIndex(where: { $0.id == questionId }) {
            pendingQuestionnaires[qIndex].questions[bqIndex].answer = answer
        }

        let allAnswered = pendingQuestionnaires[qIndex].questions.allSatisfy { $0.answer != nil }
        if allAnswered {
            pendingQuestionnaires[qIndex].isCompleted = true

            let entry = KnowledgeBaseEntry(
                goalId: activeGoal?.id ?? UUID(),
                type: .brainstorm,
                title: questionnaire.title,
                content: pendingQuestionnaires[qIndex].questions.map { "Q: \($0.question)\nA: \($0.answer ?? "")" }.joined(separator: "\n\n"),
                tags: ["questionnaire", "brainstorm"]
            )
            addToKnowledgeBase(entry)
        }

        refreshAIFeed()
    }

    // MARK: - Knowledge Base

    func addToKnowledgeBase(_ entry: KnowledgeBaseEntry) {
        knowledgeBase.append(entry)
        saveState()
    }

    func searchKnowledgeBase(query: String) -> [KnowledgeBaseEntry] {
        let lowercaseQuery = query.lowercased()
        return knowledgeBase.filter { entry in
            entry.title.lowercased().contains(lowercaseQuery) ||
            entry.content.lowercased().contains(lowercaseQuery) ||
            entry.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }

    // MARK: - Task Management

    func completeTask(_ task: MomentumTask) {
        guard let goalIndex = goals.firstIndex(where: { $0.milestones.contains { $0.tasks.contains { $0.id == task.id } } }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.tasks.contains { $0.id == task.id } }),
              let taskIndex = goals[goalIndex].milestones[milestoneIndex].tasks.firstIndex(where: { $0.id == task.id })
        else { return }

        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].status = .completed
        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].completedAt = Date()

        updateMilestoneProgress(goalIndex: goalIndex, milestoneIndex: milestoneIndex)
        updateStreak()
        checkAchievements()
        getPersonalizedCompletionMessage(forTask: task)

        // Cancel task reminder and streak reminder for today
        notificationService.cancelTaskReminder(taskId: task.id)
        notificationService.cancelStreakReminderForToday()

        let allComplete = todaysTasks.allSatisfy { $0.status == .completed }
        if allComplete && !hasMorePendingTasks {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showAllTasksCompleteCelebration = true
            }
        }

        SoundManager.shared.successHaptic()
    }

    func uncompleteTask(_ task: MomentumTask) {
        guard let goalIndex = goals.firstIndex(where: { $0.milestones.contains { $0.tasks.contains { $0.id == task.id } } }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.tasks.contains { $0.id == task.id } }),
              let taskIndex = goals[goalIndex].milestones[milestoneIndex].tasks.firstIndex(where: { $0.id == task.id })
        else { return }

        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].status = .pending
        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].completedAt = nil

        updateMilestoneProgress(goalIndex: goalIndex, milestoneIndex: milestoneIndex)
    }

    func updateTaskInGoal(_ task: MomentumTask) {
        guard let goalIndex = goals.firstIndex(where: { $0.milestones.contains { $0.tasks.contains { $0.id == task.id } } }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.tasks.contains { $0.id == task.id } }),
              let taskIndex = goals[goalIndex].milestones[milestoneIndex].tasks.firstIndex(where: { $0.id == task.id })
        else { return }

        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex] = task
    }

    func toggleChecklistItem(taskId: UUID, checklistItemId: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.milestones.contains { $0.tasks.contains { $0.id == taskId } } }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.tasks.contains { $0.id == taskId } }),
              let taskIndex = goals[goalIndex].milestones[milestoneIndex].tasks.firstIndex(where: { $0.id == taskId }),
              let checklistIndex = goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].checklist.firstIndex(where: { $0.id == checklistItemId })
        else { return }

        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].checklist[checklistIndex].isCompleted.toggle()
    }

    private func updateMilestoneProgress(goalIndex: Int, milestoneIndex: Int) {
        let milestone = goals[goalIndex].milestones[milestoneIndex]
        let totalTasks = milestone.tasks.count
        guard totalTasks > 0 else { return }

        let completedTasks = milestone.tasks.filter { $0.status == .completed }.count
        let percentage = Double(completedTasks) / Double(totalTasks) * 100

        goals[goalIndex].milestones[milestoneIndex].completionPercentage = percentage

        if completedTasks == totalTasks {
            goals[goalIndex].milestones[milestoneIndex].status = .completed
            goals[goalIndex].milestones[milestoneIndex].completedAt = Date()
            advanceToNextMilestone(goalIndex: goalIndex)
        }

        updateGoalProgress(goalIndex: goalIndex)
    }

    private func advanceToNextMilestone(goalIndex: Int) {
        // Send milestone completion notification for the just-completed milestone
        let completedIndex = goals[goalIndex].currentMilestoneIndex
        if completedIndex < goals[goalIndex].milestones.count {
            let completedMilestone = goals[goalIndex].milestones[completedIndex]
            notificationService.scheduleMilestoneAlert(milestone: completedMilestone)
        }

        let nextIndex = completedIndex + 1

        if nextIndex < goals[goalIndex].milestones.count {
            goals[goalIndex].currentMilestoneIndex = nextIndex
            goals[goalIndex].milestones[nextIndex].status = .active
            goals[goalIndex].milestones[nextIndex].startedAt = Date()

            Task { await generateWeeklyTasks() }
        } else {
            goals[goalIndex].status = .completed
        }
    }

    private func updateGoalProgress(goalIndex: Int) {
        let milestones = goals[goalIndex].milestones
        let completed = milestones.filter { $0.status == .completed }.count
        guard !milestones.isEmpty else { return }
        goals[goalIndex].completionPercentage = Double(completed) / Double(milestones.count) * 100
    }

    // MARK: - Weekly Task Generation

    func generateWeeklyTasks() async {
        guard let goal = activeGoal, let milestone = currentMilestone else { return }

        isLoading = true

        do {
            let completedTasks = milestone.tasks.filter { $0.status == .completed }
            let goalContext = goal.visionRefined ?? goal.visionText

            let generatedTasks = try await groqService.generateWeeklyTasks(
                milestone: milestone,
                weeklyTimeBudget: userPreferences.weeklyTimeMinutes,
                availableDays: userPreferences.availableDays,
                userSkills: userSkills,
                previousTasks: completedTasks,
                goalContext: goalContext
            )

            let calendar = Calendar.current
            let today = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today

            var newTasks: [MomentumTask] = []
            for generatedTask in generatedTasks {
                let dayOffset = generatedTask.scheduledDay - 1
                let scheduledDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? today

                let checklist = generatedTask.checklist.enumerated().map { index, item in
                    ChecklistItem(text: item.text, estimatedMinutes: item.estimatedMinutes, orderIndex: index)
                }

                let totalMinutes = checklist.reduce(0) { $0 + $1.estimatedMinutes }

                let task = MomentumTask(
                    milestoneId: milestone.id,
                    goalId: goal.id,
                    title: generatedTask.title,
                    taskDescription: generatedTask.description,
                    checklist: checklist,
                    outcomeGoal: generatedTask.outcomeGoal,
                    totalEstimatedMinutes: totalMinutes,
                    scheduledDate: scheduledDate
                )
                newTasks.append(task)
            }

            if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }),
               let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.id == milestone.id }) {
                goals[goalIndex].milestones[milestoneIndex].tasks.append(contentsOf: newTasks)
            }

            // Schedule reminders for new tasks
            for task in newTasks {
                notificationService.scheduleTaskReminder(for: task)
            }

            await evaluateTodaysTasks()

        } catch {
            errorMessage = "Failed to generate weekly tasks: \(error.localizedDescription)"
            print("Weekly task generation failed: \(error)")
        }

        isLoading = false
    }

    // MARK: - Streak Management

    private func updateStreak() {
        guard var user = currentUser else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastCompleted = user.lastTaskCompletedAt {
            let lastDay = calendar.startOfDay(for: lastCompleted)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                user.streakCount += 1
            } else if daysDiff > 1 {
                user.streakCount = 1
            }
        } else {
            user.streakCount = 1
        }

        if user.streakCount > user.longestStreak {
            user.longestStreak = user.streakCount
        }

        user.lastTaskCompletedAt = Date()
        currentUser = user
    }

    private func getPersonalizedCompletionMessage(forTask task: MomentumTask) {
        let personality = currentUser?.aiPersonality ?? .energetic
        showTaskCompletionCelebration = true
        completedTaskMessage = personality.completionMessage

        Task {
            do {
                let message = try await groqService.getPersonalizedMessage(
                    event: .taskCompleted,
                    personality: personality,
                    context: "Task: \(task.title)"
                )
                if showTaskCompletionCelebration {
                    completedTaskMessage = message
                }
            } catch {
                print("Error getting AI message: \(error)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showTaskCompletionCelebration = false
        }
    }

    // MARK: - Achievements

    private func checkAchievements() {
        guard let user = currentUser else { return }

        if user.streakCount >= 7 && !hasAchievement(.sevenDayStreak) {
            unlockAchievement(.sevenDayStreak)
        }

        if user.streakCount >= 30 && !hasAchievement(.thirtyDayStreak) {
            unlockAchievement(.thirtyDayStreak)
        }

        if let goal = activeGoal {
            let completedMilestones = goal.milestones.filter { $0.status == .completed }.count
            if completedMilestones >= 1 && !hasAchievement(.firstGoalComplete) {
                unlockAchievement(.firstGoalComplete)
            }
        }
    }

    private func hasAchievement(_ badgeType: BadgeType) -> Bool {
        achievements.contains { $0.badgeType == badgeType }
    }

    private func unlockAchievement(_ badgeType: BadgeType) {
        guard let user = currentUser else { return }
        achievements.append(Achievement(userId: user.id, badgeType: badgeType))
        SoundManager.shared.successHaptic()
    }

    // MARK: - Task Notes Management

    func updateTaskNotes(_ taskId: UUID, notes: TaskNotes) {
        guard let goalIndex = goals.firstIndex(where: { $0.milestones.contains { $0.tasks.contains { $0.id == taskId } } }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.tasks.contains { $0.id == taskId } }),
              let taskIndex = goals[goalIndex].milestones[milestoneIndex].tasks.firstIndex(where: { $0.id == taskId })
        else { return }

        var updatedNotes = notes
        updatedNotes.lastUpdated = Date()
        goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].notes = updatedNotes
    }

    func addConversationMessage(taskId: UUID, message: ConversationMessage) {
        guard let task = findTask(by: taskId) else { return }
        var notes = task.notes
        notes.conversationHistory.append(message)
        updateTaskNotes(taskId, notes: notes)
    }

    func addResearchFinding(taskId: UUID, finding: ResearchFinding) {
        guard let task = findTask(by: taskId) else { return }
        var notes = task.notes
        notes.researchFindings.append(finding)
        updateTaskNotes(taskId, notes: notes)
    }

    func findTask(by id: UUID) -> MomentumTask? {
        for goal in goals {
            for milestone in goal.milestones {
                if let task = milestone.tasks.first(where: { $0.id == id }) {
                    return task
                }
            }
        }
        return nil
    }

    // MARK: - Global AI Chat State

    @Published var showGlobalChat: Bool = false
    @Published var globalChatTaskContext: MomentumTask?

    func openGlobalChat(withTask task: MomentumTask? = nil) {
        globalChatTaskContext = task
        showGlobalChat = true
    }

    func closeGlobalChat() {
        showGlobalChat = false
    }

    func switchChatTask(_ task: MomentumTask) {
        globalChatTaskContext = task
    }

    // MARK: - Compatibility Methods (Legacy support)

    /// Load today's content (placeholder for legacy code)
    func loadTodaysContent() {
        // Content is loaded reactively through computed properties
        // This method exists for backward compatibility
    }

    /// Load mock data for previews
    func loadMockData() {
        let userId = UUID()
        currentUser = MomentumUser(id: userId, email: "demo@momentum.app")

        let goalId = UUID()
        let milestoneId = UUID()

        let milestone = Milestone(
            id: milestoneId,
            goalId: goalId,
            sequenceNumber: 1,
            title: "Getting Started",
            description: "Foundation tasks to kick off your goal",
            status: .active,
            tasks: [
                MomentumTask(
                    milestoneId: milestoneId,
                    goalId: goalId,
                    title: "Sample Task",
                    taskDescription: "A sample task for preview",
                    checklist: [
                        ChecklistItem(text: "Step 1", estimatedMinutes: 10, orderIndex: 0),
                        ChecklistItem(text: "Step 2", estimatedMinutes: 15, orderIndex: 1)
                    ],
                    outcomeGoal: "Complete the sample task",
                    totalEstimatedMinutes: 25,
                    scheduledDate: Date()
                )
            ],
            startedAt: Date()
        )

        goals = [
            Goal(
                id: goalId,
                userId: userId,
                visionText: "Sample Goal",
                visionRefined: "A refined sample goal for preview",
                milestones: [milestone]
            )
        ]

        isOnboarded = true
    }

    /// Submit an answer to an AI question
    func submitAIAnswer(questionId: UUID, answer: String) {
        aiProcessor.submitAnswer(for: questionId, answer: answer)
    }

    // MARK: - AI Memory Management

    func deleteMemoryEntry(_ entry: AIMemoryEntry) {
        aiMemoryEntries.removeAll { $0.id == entry.id }
        saveState()
    }

    func clearAllMemoryEntries() {
        aiMemoryEntries.removeAll()
        saveState()
    }

    func clearChatHistory() {
        for goalIndex in goals.indices {
            for milestoneIndex in goals[goalIndex].milestones.indices {
                for taskIndex in goals[goalIndex].milestones[milestoneIndex].tasks.indices {
                    goals[goalIndex].milestones[milestoneIndex].tasks[taskIndex].notes.conversationHistory.removeAll()
                }
            }
        }
        saveState()
    }

    // MARK: - Research Pipeline

    /// Trigger research for a query and save results
    func triggerResearch(query: String, taskId: UUID? = nil) async {
        guard let goal = activeGoal else { return }
        let goalContext = goal.visionRefined ?? goal.visionText

        let result = await researchPipeline.executeResearch(
            query: query,
            taskContext: goalContext,
            taskTitle: query,
            goalId: goal.id,
            taskId: taskId
        )

        if let result = result {
            if let entry = result.knowledgeEntry {
                addToKnowledgeBase(entry)
            }
            if let report = result.report {
                aiReports.insert(report, at: 0)
                refreshAIFeed()
            }
        }
    }

    // MARK: - Content Drafting

    /// Generate a content draft and save it
    func generateDraft(type: DraftType, title: String, taskId: UUID? = nil, additionalInstructions: String? = nil) async {
        guard let goal = activeGoal else { return }
        let goalContext = goal.visionRefined ?? goal.visionText

        let draft = await contentDraftingService.generateDraft(
            type: type,
            title: title,
            context: goalContext,
            goalId: goal.id,
            taskId: taskId,
            additionalInstructions: additionalInstructions
        )

        if let draft = draft {
            drafts.insert(draft, at: 0)
            saveState()
        }
    }

    /// Update a draft's status
    func updateDraftStatus(_ draft: DraftContent, status: DraftStatus) {
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index].status = status
            drafts[index].updatedAt = Date()
            saveState()
        }
    }

    /// Delete a draft
    func deleteDraft(_ draft: DraftContent) {
        drafts.removeAll { $0.id == draft.id }
        saveState()
    }

    // MARK: - Calendar Integration

    /// Request calendar access and update state
    func requestCalendarAccess() async {
        let granted = await calendarService.requestAccess()
        calendarAccessGranted = granted
        saveState()
    }

    /// Schedule a focus session for a task
    func scheduleFocusSession(for task: MomentumTask, duration: Int) async {
        guard calendarAccessGranted else { return }
        do {
            try await calendarService.scheduleFocusSession(for: task, duration: duration)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helper Methods

    func getGoalName(for task: MomentumTask) -> String {
        goals.first { $0.id == task.goalId }?.visionRefined ?? goals.first { $0.id == task.goalId }?.visionText ?? "Goal"
    }

    func getMilestoneName(for task: MomentumTask) -> String {
        for goal in goals {
            if let milestone = goal.milestones.first(where: { $0.id == task.milestoneId }) {
                return milestone.title
            }
        }
        return "Milestone"
    }

    // MARK: - Reset

    func resetOnboarding() {
        isOnboarded = false
        currentUser = nil
        goals = []
        achievements = []
        aiFeedItems = []
        pendingSkillQuestions = []
        pendingQuestionnaires = []
        pendingToolPrompts = []
        aiReports = []
        aiMemoryEntries = []
        drafts = []
        calendarAccessGranted = false
        userSkills = [:]
        userPreferences = UserPreferences()
        knowledgeBase = []

        let defaults = UserDefaults.standard
        for key in [StorageKeys.isOnboarded, StorageKeys.currentUser, StorageKeys.goals,
                    StorageKeys.achievements, StorageKeys.userSkills, StorageKeys.userPreferences,
                    StorageKeys.knowledgeBase, StorageKeys.pendingSkillQuestions,
                    StorageKeys.pendingQuestionnaires, StorageKeys.pendingToolPrompts,
                    StorageKeys.aiReports, StorageKeys.aiMemoryEntries,
                    StorageKeys.drafts, StorageKeys.calendarAccessGranted] {
            defaults.removeObject(forKey: key)
        }
    }
}

