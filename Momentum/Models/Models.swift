//
//  Models.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import Foundation
import SwiftUI

// MARK: - User Preferences

struct UserPreferences: Codable {
    var weeklyTimeMinutes: Int              // User's weekly time budget
    var preferredSessionMinutes: Int        // Typical session length
    var availableDays: [Int]                // Days of week available (1=Sun, 2=Mon, etc.)
    var userSkills: [String: String]        // Skill -> answer cache (e.g., "coding" -> "intermediate")

    // Notification preferences
    var morningBriefingEnabled: Bool
    var briefingTime: Date                  // Time of day for briefing
    var taskRemindersEnabled: Bool
    var streakAlertsEnabled: Bool
    var achievementAlertsEnabled: Bool

    // AI preferences
    var aiProactivityLevel: Double          // 0.0 (minimal) to 1.0 (proactive)
    var modelPreference: ModelPreference

    init(
        weeklyTimeMinutes: Int = 300,
        preferredSessionMinutes: Int = 30,
        availableDays: [Int] = [2, 3, 4, 5, 6], // Mon-Fri default
        userSkills: [String: String] = [:],
        morningBriefingEnabled: Bool = true,
        briefingTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
        taskRemindersEnabled: Bool = true,
        streakAlertsEnabled: Bool = true,
        achievementAlertsEnabled: Bool = true,
        aiProactivityLevel: Double = 0.7,
        modelPreference: ModelPreference = .auto
    ) {
        self.weeklyTimeMinutes = weeklyTimeMinutes
        self.preferredSessionMinutes = preferredSessionMinutes
        self.availableDays = availableDays
        self.userSkills = userSkills
        self.morningBriefingEnabled = morningBriefingEnabled
        self.briefingTime = briefingTime
        self.taskRemindersEnabled = taskRemindersEnabled
        self.streakAlertsEnabled = streakAlertsEnabled
        self.achievementAlertsEnabled = achievementAlertsEnabled
        self.aiProactivityLevel = aiProactivityLevel
        self.modelPreference = modelPreference
    }
}

enum ModelPreference: String, Codable, CaseIterable {
    case auto
    case fast
    case balanced

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .fast: return "Fast (Groq)"
        case .balanced: return "Balanced (OpenAI)"
        }
    }

    var description: String {
        switch self {
        case .auto: return "Let Momentum choose the best model"
        case .fast: return "Fastest responses, great for most tasks"
        case .balanced: return "GPT-4o for complex reasoning tasks"
        }
    }
}

// MARK: - User Model
struct MomentumUser: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var createdAt: Date
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?
    var aiPersonality: AIPersonality
    var streakCount: Int
    var longestStreak: Int
    var lastTaskCompletedAt: Date?
    var preferences: UserPreferences?

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first, !first.isEmpty {
            return String(first.prefix(2)).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }

    init(
        id: UUID = UUID(),
        name: String = "Momentum User",
        email: String,
        createdAt: Date = Date(),
        subscriptionTier: SubscriptionTier = .free,
        subscriptionExpiresAt: Date? = nil,
        aiPersonality: AIPersonality = .energetic,
        streakCount: Int = 0,
        longestStreak: Int = 0,
        lastTaskCompletedAt: Date? = nil,
        preferences: UserPreferences? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.aiPersonality = aiPersonality
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.lastTaskCompletedAt = lastTaskCompletedAt
        self.preferences = preferences
    }
}

enum SubscriptionTier: String, Codable {
    case free
    case premium
}

enum AIPersonality: String, Codable, CaseIterable {
    case energetic
    case calm
    case direct
    case motivational

    var displayName: String {
        switch self {
        case .energetic: return "Energetic & Friendly"
        case .calm: return "Calm & Focused"
        case .direct: return "Direct & No-Nonsense"
        case .motivational: return "Motivational Coach"
        }
    }

    var sampleMessage: String {
        switch self {
        case .energetic: return "Let's crush these tasks!"
        case .calm: return "Take it one step at a time"
        case .direct: return "Here's what needs doing"
        case .motivational: return "You've got this, champion!"
        }
    }

    var completionMessage: String {
        switch self {
        case .energetic: return "Nice work! 1 step closer"
        case .calm: return "Well done. Progress made."
        case .direct: return "Task done. Next."
        case .motivational: return "Yes! You're unstoppable!"
        }
    }
}

// MARK: - Goal Model
struct Goal: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var visionText: String
    var visionRefined: String?
    var goalType: GoalType
    var domain: GoalDomain
    var status: GoalStatus
    var createdAt: Date
    var targetCompletionDate: Date?
    var currentMilestoneIndex: Int
    var completionPercentage: Double
    var milestones: [Milestone]
    var knowledgeBase: [KnowledgeBaseEntry]

    init(
        id: UUID = UUID(),
        userId: UUID,
        visionText: String,
        visionRefined: String? = nil,
        goalType: GoalType = .project,
        domain: GoalDomain = .career,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        targetCompletionDate: Date? = nil,
        currentMilestoneIndex: Int = 0,
        completionPercentage: Double = 0,
        milestones: [Milestone] = [],
        knowledgeBase: [KnowledgeBaseEntry] = []
    ) {
        self.id = id
        self.userId = userId
        self.visionText = visionText
        self.visionRefined = visionRefined
        self.goalType = goalType
        self.domain = domain
        self.status = status
        self.createdAt = createdAt
        self.targetCompletionDate = targetCompletionDate
        self.currentMilestoneIndex = currentMilestoneIndex
        self.completionPercentage = completionPercentage
        self.milestones = milestones
        self.knowledgeBase = knowledgeBase
    }
}

enum GoalStatus: String, Codable {
    case active
    case completed
    case archived
}

enum GoalType: String, Codable {
    case project      // 12-milestone structured goal
}

// MARK: - Goal Domain

enum GoalDomain: String, Codable, CaseIterable {
    case career
    case finance
    case growth

    var displayName: String {
        switch self {
        case .career: return "Career"
        case .finance: return "Finance"
        case .growth: return "Growth"
        }
    }

    var color: Color {
        switch self {
        case .career: return .momentumCareer
        case .finance: return .momentumFinance
        case .growth: return .momentumGrowth
        }
    }
}


// MARK: - Milestone Model (12 per Goal, sequential)

struct Milestone: Identifiable, Codable {
    let id: UUID
    var goalId: UUID
    var sequenceNumber: Int         // 1-12, sequential (NOT month-based)
    var title: String
    var description: String?
    var status: MilestoneStatus
    var completionPercentage: Double
    var tasks: [MomentumTask]       // Tasks directly on milestone
    var startedAt: Date?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        goalId: UUID,
        sequenceNumber: Int,
        title: String,
        description: String? = nil,
        status: MilestoneStatus = .locked,
        completionPercentage: Double = 0,
        tasks: [MomentumTask] = [],
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.sequenceNumber = sequenceNumber
        self.title = title
        self.description = description
        self.status = status
        self.completionPercentage = completionPercentage
        self.tasks = tasks
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

enum MilestoneStatus: String, Codable {
    case locked
    case active
    case completed
}

// MARK: - Task Model (No difficulty levels)
struct MomentumTask: Identifiable, Codable {
    let id: UUID
    var milestoneId: UUID
    var goalId: UUID
    var title: String
    var taskDescription: String?
    var checklist: [ChecklistItem]      // Detailed steps with time estimates
    var outcomeGoal: String             // Clear "done" definition
    var totalEstimatedMinutes: Int      // Sum of checklist times
    var scheduledDate: Date
    var status: TaskStatus
    var completedAt: Date?
    var aiEvaluation: TaskAIEvaluation? // Daily evaluation result
    var notes: TaskNotes

    init(
        id: UUID = UUID(),
        milestoneId: UUID,
        goalId: UUID,
        title: String,
        taskDescription: String? = nil,
        checklist: [ChecklistItem] = [],
        outcomeGoal: String = "",
        totalEstimatedMinutes: Int = 30,
        scheduledDate: Date,
        status: TaskStatus = .pending,
        completedAt: Date? = nil,
        aiEvaluation: TaskAIEvaluation? = nil,
        notes: TaskNotes = TaskNotes()
    ) {
        self.id = id
        self.milestoneId = milestoneId
        self.goalId = goalId
        self.title = title
        self.taskDescription = taskDescription
        self.checklist = checklist
        self.outcomeGoal = outcomeGoal
        self.totalEstimatedMinutes = totalEstimatedMinutes
        self.scheduledDate = scheduledDate
        self.status = status
        self.completedAt = completedAt
        self.aiEvaluation = aiEvaluation
        self.notes = notes
    }

    // Computed properties for checklist progress
    var completedChecklistCount: Int {
        checklist.filter { $0.isCompleted }.count
    }

    var checklistProgress: Double {
        guard !checklist.isEmpty else { return 0 }
        return Double(completedChecklistCount) / Double(checklist.count)
    }

    var remainingMinutes: Int {
        checklist.filter { !$0.isCompleted }.reduce(0) { $0 + $1.estimatedMinutes }
    }

    // MARK: - Derived Properties

    /// Difficulty derived from estimated time (for display purposes)
    var difficulty: TaskDifficulty {
        if totalEstimatedMinutes <= 15 {
            return .easy
        } else if totalEstimatedMinutes <= 45 {
            return .medium
        } else {
            return .hard
        }
    }

    /// Alias for totalEstimatedMinutes
    var estimatedMinutes: Int {
        totalEstimatedMinutes
    }

    /// Checklist items as microsteps (for legacy views)
    var microsteps: [Microstep] {
        checklist.enumerated().map { index, item in
            Microstep(
                id: item.id,
                taskId: self.id,
                stepText: item.text,
                isCompleted: item.isCompleted,
                orderIndex: index
            )
        }
    }
}

// MARK: - Checklist Item (Granular task steps with time estimates)

struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var estimatedMinutes: Int
    var isCompleted: Bool
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        text: String,
        estimatedMinutes: Int = 10,
        isCompleted: Bool = false,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.text = text
        self.estimatedMinutes = estimatedMinutes
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
    }
}

enum TaskStatus: String, Codable {
    case pending
    case completed
    case skipped
}

// MARK: - Task AI Evaluation (Daily evaluation result)

struct TaskAIEvaluation: Codable, Equatable {
    let evaluatedAt: Date
    let canAIDo: Bool
    let canUserDo: Bool
    let skillsRequired: [String]
    let approach: TaskApproach
    let skillQuestions: [SkillQuestion]?
    let toolPrompts: [ToolPrompt]?
    let guidanceNeeded: Bool

    init(
        evaluatedAt: Date = Date(),
        canAIDo: Bool = false,
        canUserDo: Bool = true,
        skillsRequired: [String] = [],
        approach: TaskApproach = .userDirect,
        skillQuestions: [SkillQuestion]? = nil,
        toolPrompts: [ToolPrompt]? = nil,
        guidanceNeeded: Bool = false
    ) {
        self.evaluatedAt = evaluatedAt
        self.canAIDo = canAIDo
        self.canUserDo = canUserDo
        self.skillsRequired = skillsRequired
        self.approach = approach
        self.skillQuestions = skillQuestions
        self.toolPrompts = toolPrompts
        self.guidanceNeeded = guidanceNeeded
    }
}

enum TaskApproach: String, Codable {
    case userDirect       // User does it themselves
    case aiAssisted       // AI helps
    case toolHandoff      // External tool needed
    case needsGuidance    // Generate questionnaire
}

// MARK: - Skill Question (Just-in-time skill questions)

struct SkillQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let taskId: UUID
    let skill: String           // "coding", "design", etc.
    let question: String        // "Can you code in Swift?"
    let options: [String]       // ["Yes", "No", "Learning"]
    var answer: String?
    var answeredAt: Date?

    init(
        id: UUID = UUID(),
        taskId: UUID,
        skill: String,
        question: String,
        options: [String] = ["Yes", "No", "Learning"],
        answer: String? = nil,
        answeredAt: Date? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.skill = skill
        self.question = question
        self.options = options
        self.answer = answer
        self.answeredAt = answeredAt
    }
}

// MARK: - Tool Prompt (Copy-paste prompts for external tools)

struct ToolPrompt: Identifiable, Codable, Equatable {
    let id: UUID
    let taskId: UUID
    let toolName: String        // "Cursor", "Claude", "v0"
    let prompt: String          // The actual prompt
    let context: String         // Why this prompt
    let createdAt: Date

    init(
        id: UUID = UUID(),
        taskId: UUID,
        toolName: String,
        prompt: String,
        context: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.toolName = toolName
        self.prompt = prompt
        self.context = context
        self.createdAt = createdAt
    }
}

// MARK: - AI Feed Item (Unified feed for homepage)

enum AIFeedItem: Identifiable, Codable {
    case skillQuestion(SkillQuestion)
    case toolPrompt(ToolPrompt)
    case questionnaire(AIQuestionnaire)
    case report(AIReport)

    var id: UUID {
        switch self {
        case .skillQuestion(let q): return q.id
        case .toolPrompt(let p): return p.id
        case .questionnaire(let q): return q.id
        case .report(let r): return r.id
        }
    }

    var priority: Int {
        switch self {
        case .skillQuestion: return 1  // Highest priority
        case .questionnaire: return 2
        case .report: return 3
        case .toolPrompt: return 4
        }
    }

    var title: String {
        switch self {
        case .skillQuestion(let q): return q.question
        case .toolPrompt(let p): return "Prompt for \(p.toolName)"
        case .questionnaire(let q): return q.title
        case .report(let r): return r.title
        }
    }

    var subtitle: String? {
        switch self {
        case .skillQuestion(let q): return "Skill: \(q.skill)"
        case .toolPrompt(let p): return p.context
        case .questionnaire(let q): return "\(q.questions.count) questions"
        case .report(let r): return r.summary
        }
    }
}

// MARK: - AI Questionnaire (For brainstorming and decisions)

struct AIQuestionnaire: Identifiable, Codable, Equatable {
    let id: UUID
    let taskId: UUID
    let title: String           // "Decide your value prop"
    var questions: [BrainstormQuestion]
    var isCompleted: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        taskId: UUID,
        title: String,
        questions: [BrainstormQuestion],
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.title = title
        self.questions = questions
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

struct BrainstormQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let question: String
    let options: [String]?      // nil = free text
    var answer: String?

    init(
        id: UUID = UUID(),
        question: String,
        options: [String]? = nil,
        answer: String? = nil
    ) {
        self.id = id
        self.question = question
        self.options = options
        self.answer = answer
    }
}

// MARK: - AI Report (Research and reports storage)

struct AIReport: Identifiable, Codable, Equatable {
    let id: UUID
    let taskId: UUID?
    let goalId: UUID
    let title: String
    let summary: String         // Always shown
    let details: String?        // Expandable
    let sources: [String]?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        goalId: UUID,
        title: String,
        summary: String,
        details: String? = nil,
        sources: [String]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.goalId = goalId
        self.title = title
        self.summary = summary
        self.details = details
        self.sources = sources
        self.createdAt = createdAt
    }
}

// MARK: - Knowledge Base Entry (Project knowledge storage)

struct KnowledgeBaseEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let goalId: UUID
    let type: KnowledgeType
    let title: String
    let content: String
    let tags: [String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        goalId: UUID,
        type: KnowledgeType,
        title: String,
        content: String,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.type = type
        self.title = title
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
    }
}

enum KnowledgeType: String, Codable {
    case research
    case report
    case decision
    case brainstorm
    case toolPrompt
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var badgeType: BadgeType
    var unlockedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        badgeType: BadgeType,
        unlockedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.badgeType = badgeType
        self.unlockedAt = unlockedAt
    }
}

enum BadgeType: String, Codable, CaseIterable {
    case sevenDayStreak = "7_day_streak"
    case first100Tasks = "first_100"
    case fastStart = "fast_start"
    case thirtyDayStreak = "30_day_streak"
    case weekPerfect = "week_perfect"
    case firstGoalComplete = "first_goal_complete"
    case hundredTasks = "hundred_tasks"
    case fiveHundredTasks = "five_hundred_tasks"
    case domainMaster = "domain_master"
    case speedDemon = "speed_demon"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case researchPro = "research_pro"

    var title: String {
        switch self {
        case .sevenDayStreak: return "7 Day Streak"
        case .first100Tasks: return "First 100"
        case .fastStart: return "Fast Start"
        case .thirtyDayStreak: return "30 Day Streak"
        case .weekPerfect: return "Perfect Week"
        case .firstGoalComplete: return "Goal Crusher"
        case .hundredTasks: return "Centurion"
        case .fiveHundredTasks: return "Task Machine"
        case .domainMaster: return "Domain Master"
        case .speedDemon: return "Speed Demon"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .researchPro: return "Research Pro"
        }
    }

    var description: String {
        switch self {
        case .sevenDayStreak: return "Complete tasks 7 days in a row"
        case .first100Tasks: return "Complete 100 total tasks"
        case .fastStart: return "Complete 3 tasks in your first 3 days"
        case .thirtyDayStreak: return "Complete tasks 30 days in a row"
        case .weekPerfect: return "Complete all daily tasks for a week"
        case .firstGoalComplete: return "Complete your first Milestone"
        case .hundredTasks: return "Complete 100 tasks total"
        case .fiveHundredTasks: return "Complete 500 tasks total"
        case .domainMaster: return "Complete a goal in any domain"
        case .speedDemon: return "Complete 5 tasks in a single day"
        case .earlyBird: return "Complete a task before 8 AM"
        case .nightOwl: return "Complete a task after 10 PM"
        case .researchPro: return "Use AI research 10 times"
        }
    }

    var iconName: String {
        switch self {
        case .sevenDayStreak: return "flame.fill"
        case .first100Tasks: return "star.fill"
        case .fastStart: return "bolt.fill"
        case .thirtyDayStreak: return "flame.fill"
        case .weekPerfect: return "crown.fill"
        case .firstGoalComplete: return "trophy.fill"
        case .hundredTasks: return "star.circle.fill"
        case .fiveHundredTasks: return "star.square.fill"
        case .domainMaster: return "rosette"
        case .speedDemon: return "hare.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .researchPro: return "magnifyingglass"
        }
    }

    var accentColor: Color {
        switch self {
        case .sevenDayStreak, .thirtyDayStreak: return .momentumWarning
        case .first100Tasks, .hundredTasks, .fiveHundredTasks: return .momentumGold
        case .fastStart, .speedDemon: return .momentumCoral
        case .weekPerfect: return .momentumViolet
        case .firstGoalComplete, .domainMaster: return .momentumSuccess
        case .earlyBird: return .momentumBlueLight
        case .nightOwl: return .momentumViolet
        case .researchPro: return .momentumBlue
        }
    }
}

// MARK: - Onboarding Models
struct OnboardingQuestion: Identifiable {
    let id: UUID = UUID()
    let question: String
    let options: [String]?
    let allowsTextInput: Bool

    init(question: String, options: [String]? = nil, allowsTextInput: Bool = false) {
        self.question = question
        self.options = options
        self.allowsTextInput = allowsTextInput
    }
}

struct OnboardingAnswers {
    var visionText: String = ""
    var experienceLevel: String = ""
    var weeklyHours: Int = 5            // Default 5 hours per week
    var availableDays: Set<Int> = [2, 3, 4, 5, 6]  // Mon-Fri default
    var timeline: String = ""
    var biggestConcern: String = ""
    var passions: String = ""
    var identityMeaning: String = ""
}

// MARK: - AI Generation Response

struct AIGeneratedPlan: Codable {
    let visionRefined: String
    let milestones: [GeneratedMilestone]
    let firstWeekTasks: [GeneratedTaskWithChecklist]

    enum CodingKeys: String, CodingKey {
        case visionRefined = "vision_refined"
        case milestones
        case firstWeekTasks = "first_week_tasks"
    }
}

struct GeneratedMilestone: Codable {
    let sequence: Int
    let title: String
    let description: String
}

struct GeneratedTaskWithChecklist: Codable {
    let title: String
    let description: String
    let outcomeGoal: String
    let checklist: [GeneratedChecklistItem]
    let scheduledDay: Int  // Day of week (1=Sun, 2=Mon, etc.)

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case outcomeGoal = "outcome_goal"
        case checklist
        case scheduledDay = "scheduled_day"
    }
}

struct GeneratedChecklistItem: Codable {
    let text: String
    let estimatedMinutes: Int

    enum CodingKeys: String, CodingKey {
        case text
        case estimatedMinutes = "estimated_minutes"
    }
}

// MARK: - Task Notes & Knowledge Base

struct TaskNotes: Codable, Equatable {
    var conversationHistory: [ConversationMessage]
    var researchFindings: [ResearchFinding]
    var userBrainstorms: [BrainstormNote]
    var lastUpdated: Date

    init() {
        self.conversationHistory = []
        self.researchFindings = []
        self.userBrainstorms = []
        self.lastUpdated = Date()
    }
}

struct ConversationMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let metadata: MessageMetadata?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct MessageMetadata: Codable, Equatable {
    let messageType: MessageType
    let relatedResearchId: UUID?

    enum MessageType: String, Codable {
        case clarifyingQuestion
        case researchRequest
        case researchResult
        case generalHelp
    }
}

struct ResearchFinding: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let clarifyingQA: [QAPair]
    let searchResults: String
    let timestamp: Date
    let wasAutoSaved: Bool

    init(
        id: UUID = UUID(),
        query: String,
        clarifyingQA: [QAPair] = [],
        searchResults: String,
        timestamp: Date = Date(),
        wasAutoSaved: Bool = true
    ) {
        self.id = id
        self.query = query
        self.clarifyingQA = clarifyingQA
        self.searchResults = searchResults
        self.timestamp = timestamp
        self.wasAutoSaved = wasAutoSaved
    }
}

// Helper struct for Q&A pairs (Codable compatible)
struct QAPair: Codable, Equatable {
    let question: String
    let answer: String
}

struct BrainstormNote: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    let createdAt: Date
    var lastModified: Date

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}

// MARK: - Briefing Report (Morning briefing data)

struct BriefingReport: Identifiable, Codable {
    let id: UUID
    let generatedAt: Date
    let greeting: String
    let insight: String
    let focusArea: String
    let tasksToday: Int
    let tasksCompletedYesterday: Int
    let currentStreak: Int
    let milestoneProgress: Double
    let milestoneName: String?
    let goalDomain: GoalDomain?

    init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        greeting: String,
        insight: String,
        focusArea: String,
        tasksToday: Int = 0,
        tasksCompletedYesterday: Int = 0,
        currentStreak: Int = 0,
        milestoneProgress: Double = 0,
        milestoneName: String? = nil,
        goalDomain: GoalDomain? = nil
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.greeting = greeting
        self.insight = insight
        self.focusArea = focusArea
        self.tasksToday = tasksToday
        self.tasksCompletedYesterday = tasksCompletedYesterday
        self.currentStreak = currentStreak
        self.milestoneProgress = milestoneProgress
        self.milestoneName = milestoneName
        self.goalDomain = goalDomain
    }
}

// MARK: - AI Work Items (for background processing)

struct AIWorkItem: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let taskId: UUID?
    let type: AIWorkType
    let title: String
    var status: AIWorkStatus
    var result: AIWorkResult?
    let createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        goalId: UUID,
        taskId: UUID? = nil,
        type: AIWorkType,
        title: String,
        status: AIWorkStatus = .pending,
        result: AIWorkResult? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.taskId = taskId
        self.type = type
        self.title = title
        self.status = status
        self.result = result
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

enum AIWorkType: String, Codable {
    case research
    case report
    case toolPrompt
    case ideaGeneration
}

enum AIWorkStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

struct AIWorkResult: Codable {
    let summary: String           // Always shown
    let details: String?          // Expandable
    let sources: [String]?        // For research
    let toolName: String?         // For tool prompts
    let prompt: String?           // Copy-paste prompt

    init(
        summary: String,
        details: String? = nil,
        sources: [String]? = nil,
        toolName: String? = nil,
        prompt: String? = nil
    ) {
        self.summary = summary
        self.details = details
        self.sources = sources
        self.toolName = toolName
        self.prompt = prompt
    }
}

// MARK: - Draft Content (AI-generated drafts for user review)

enum DraftType: String, Codable, CaseIterable {
    case email
    case linkedInPost
    case businessPlan
    case coverLetter
    case pitchOutline
    case custom

    var displayName: String {
        switch self {
        case .email: return "Email"
        case .linkedInPost: return "LinkedIn Post"
        case .businessPlan: return "Business Plan"
        case .coverLetter: return "Cover Letter"
        case .pitchOutline: return "Pitch Outline"
        case .custom: return "Custom"
        }
    }
}

enum DraftStatus: String, Codable {
    case draft
    case reviewed
    case approved
}

struct DraftContent: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let taskId: UUID?
    let type: DraftType
    let title: String
    var content: String
    var status: DraftStatus
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        goalId: UUID,
        taskId: UUID? = nil,
        type: DraftType,
        title: String,
        content: String,
        status: DraftStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.taskId = taskId
        self.type = type
        self.title = title
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - AI Memory Entry (Persistent AI memory system)

enum MemoryCategory: String, Codable, CaseIterable {
    case skill
    case preference
    case decision
    case research
    case pattern
    case personal

    var displayName: String {
        switch self {
        case .skill: return "Skill"
        case .preference: return "Preference"
        case .decision: return "Decision"
        case .research: return "Research"
        case .pattern: return "Pattern"
        case .personal: return "Personal"
        }
    }
}

struct AIMemoryEntry: Identifiable, Codable {
    let id: UUID
    let category: MemoryCategory
    let key: String
    let value: String
    var confidence: Double
    let createdAt: Date
    var updatedAt: Date
    var source: String

    init(
        id: UUID = UUID(),
        category: MemoryCategory,
        key: String,
        value: String,
        confidence: Double = 0.8,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        source: String = "chat"
    ) {
        self.id = id
        self.category = category
        self.key = key
        self.value = value
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.source = source
    }
}

// MARK: - Weekly Task Evaluation Response

struct WeeklyTasksResponse: Codable {
    let tasks: [GeneratedTaskWithChecklist]
}

// MARK: - Compatibility Types (Legacy support)

/// Legacy TaskDifficulty for backward compatibility
enum TaskDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var emoji: String {
        switch self {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }

    var points: Int {
        switch self {
        case .easy: return 1
        case .medium: return 3
        case .hard: return 5
        }
    }
}

/// Legacy Microstep for backward compatibility
struct Microstep: Identifiable, Codable, Equatable {
    let id: UUID
    let taskId: UUID
    var stepText: String
    var isCompleted: Bool
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        taskId: UUID,
        stepText: String,
        isCompleted: Bool = false,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.taskId = taskId
        self.stepText = stepText
        self.isCompleted = isCompleted
        self.orderIndex = orderIndex
    }
}

/// Time estimate for microsteps
struct MicrostepTimeEstimate: Codable, Equatable {
    let microstep: String
    let estimatedMinutes: Int
    let rationale: String
}

/// Enhanced task details from AI
struct EnhancedTaskDetails: Codable {
    let difficultyExplanation: String
    let timeBreakdown: [MicrostepTimeEstimate]
    let tips: [String]
}

/// AI Question for gathering user input
struct AIQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let taskId: UUID?
    let goalId: UUID
    let question: String
    let options: [QuestionOption]
    let allowsCustomInput: Bool
    var answer: String?
    var answeredAt: Date?
    let createdAt: Date
    let priority: QuestionPriority

    init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        goalId: UUID,
        question: String,
        options: [QuestionOption] = [],
        allowsCustomInput: Bool = false,
        answer: String? = nil,
        answeredAt: Date? = nil,
        createdAt: Date = Date(),
        priority: QuestionPriority = .important
    ) {
        self.id = id
        self.taskId = taskId
        self.goalId = goalId
        self.question = question
        self.options = options
        self.allowsCustomInput = allowsCustomInput
        self.answer = answer
        self.answeredAt = answeredAt
        self.createdAt = createdAt
        self.priority = priority
    }
}

struct QuestionOption: Identifiable, Codable, Equatable {
    let id: UUID
    let label: String
    let value: String

    init(id: UUID = UUID(), label: String, value: String? = nil) {
        self.id = id
        self.label = label
        self.value = value ?? label
    }
}

enum QuestionPriority: String, Codable {
    case blocking
    case important
    case optional
}

/// AI Task Analysis result
struct AITaskAnalysis: Codable {
    let questionsNeeded: [AIQuestion]
    let researchNeeded: [String]
    let canProceed: Bool
}

struct TaskEvaluationResponse: Codable {
    let canAIDo: Bool
    let canUserDo: Bool
    let skillsRequired: [String]
    let approach: String
    let skillQuestions: [GeneratedSkillQuestion]?
    let toolSuggestion: GeneratedToolSuggestion?
    let guidanceNeeded: Bool

    enum CodingKeys: String, CodingKey {
        case canAIDo = "can_ai_do"
        case canUserDo = "can_user_do"
        case skillsRequired = "skills_required"
        case approach
        case skillQuestions = "skill_questions"
        case toolSuggestion = "tool_suggestion"
        case guidanceNeeded = "guidance_needed"
    }
}

struct GeneratedSkillQuestion: Codable {
    let skill: String
    let question: String
    let options: [String]
}

struct GeneratedToolSuggestion: Codable {
    let toolName: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case reason
    }
}
