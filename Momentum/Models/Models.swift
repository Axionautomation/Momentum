//
//  Models.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import Foundation

// MARK: - User Model
struct MomentumUser: Identifiable, Codable {
    let id: UUID
    var email: String
    var createdAt: Date
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?
    var aiPersonality: AIPersonality
    var streakCount: Int
    var longestStreak: Int
    var lastTaskCompletedAt: Date?

    init(
        id: UUID = UUID(),
        email: String,
        createdAt: Date = Date(),
        subscriptionTier: SubscriptionTier = .free,
        subscriptionExpiresAt: Date? = nil,
        aiPersonality: AIPersonality = .energetic,
        streakCount: Int = 0,
        longestStreak: Int = 0,
        lastTaskCompletedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.aiPersonality = aiPersonality
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.lastTaskCompletedAt = lastTaskCompletedAt
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
    var isIdentityBased: Bool                // Kept for backward compatibility
    var status: GoalStatus
    var createdAt: Date
    var targetCompletionDate: Date?
    var currentPowerGoalIndex: Int
    var completionPercentage: Double
    var powerGoals: [PowerGoal]
    var habitConfig: HabitConfig?            // Only used for habit goals
    var identityConfig: IdentityConfig?      // Only used for identity goals

    init(
        id: UUID = UUID(),
        userId: UUID,
        visionText: String,
        visionRefined: String? = nil,
        goalType: GoalType = .project,
        isIdentityBased: Bool = false,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        targetCompletionDate: Date? = nil,
        currentPowerGoalIndex: Int = 0,
        completionPercentage: Double = 0,
        powerGoals: [PowerGoal] = [],
        habitConfig: HabitConfig? = nil,
        identityConfig: IdentityConfig? = nil
    ) {
        self.id = id
        self.userId = userId
        self.visionText = visionText
        self.visionRefined = visionRefined
        self.goalType = goalType
        self.isIdentityBased = isIdentityBased
        self.status = status
        self.createdAt = createdAt
        self.targetCompletionDate = targetCompletionDate
        self.currentPowerGoalIndex = currentPowerGoalIndex
        self.completionPercentage = completionPercentage
        self.powerGoals = powerGoals
        self.habitConfig = habitConfig
        self.identityConfig = identityConfig
    }
}

enum GoalStatus: String, Codable {
    case active
    case completed
    case archived
}

enum GoalType: String, Codable {
    case project      // 12-month structured goal
    case habit        // Ongoing lifestyle habit
    case identity     // Identity-based with evidence collection
}

// MARK: - Power Goal Model (12 per Goal)
struct PowerGoal: Identifiable, Codable {
    let id: UUID
    var goalId: UUID
    var monthNumber: Int
    var title: String
    var description: String?
    var status: PowerGoalStatus
    var startDate: Date?
    var completionPercentage: Double
    var weeklyMilestones: [WeeklyMilestone]

    init(
        id: UUID = UUID(),
        goalId: UUID,
        monthNumber: Int,
        title: String,
        description: String? = nil,
        status: PowerGoalStatus = .locked,
        startDate: Date? = nil,
        completionPercentage: Double = 0,
        weeklyMilestones: [WeeklyMilestone] = []
    ) {
        self.id = id
        self.goalId = goalId
        self.monthNumber = monthNumber
        self.title = title
        self.description = description
        self.status = status
        self.startDate = startDate
        self.completionPercentage = completionPercentage
        self.weeklyMilestones = weeklyMilestones
    }
}

enum PowerGoalStatus: String, Codable {
    case locked
    case active
    case completed
}

// MARK: - Habit Models

enum HabitFrequency: String, Codable {
    case daily
    case weekdays
    case weekends
    case custom
}

struct HabitConfig: Codable {
    var frequency: HabitFrequency
    var customDays: [Int]?           // 0=Sunday, 6=Saturday (only used if frequency is custom)
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var skipHistory: [Date]
    var reminderTime: Date?
    var weeklyGoal: Int?             // e.g., "Do this 5x per week"

    init(
        frequency: HabitFrequency = .daily,
        customDays: [Int]? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        skipHistory: [Date] = [],
        reminderTime: Date? = nil,
        weeklyGoal: Int? = nil
    ) {
        self.frequency = frequency
        self.customDays = customDays
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
        self.skipHistory = skipHistory
        self.reminderTime = reminderTime
        self.weeklyGoal = weeklyGoal
    }
}

struct HabitCheckIn: Identifiable, Codable {
    let id: UUID
    var habitGoalId: UUID
    var scheduledDate: Date
    var isCompleted: Bool
    var completedAt: Date?
    var notes: String?
    var skipped: Bool

    init(
        id: UUID = UUID(),
        habitGoalId: UUID,
        scheduledDate: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notes: String? = nil,
        skipped: Bool = false
    ) {
        self.id = id
        self.habitGoalId = habitGoalId
        self.scheduledDate = scheduledDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
        self.skipped = skipped
    }
}

// MARK: - Identity Models

enum EvidenceMood: String, Codable {
    case struggled
    case okay
    case good
    case great
}

struct EvidenceEntry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var description: String
    var category: String?
    var photoURL: String?
    var mood: EvidenceMood

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        description: String,
        category: String? = nil,
        photoURL: String? = nil,
        mood: EvidenceMood = .good
    ) {
        self.id = id
        self.date = date
        self.description = description
        self.category = category
        self.photoURL = photoURL
        self.mood = mood
    }
}

struct IdentityMilestone: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var completedDate: Date?
    var evidenceId: UUID?            // Link to evidence entry that completed this

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        evidenceId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.evidenceId = evidenceId
    }
}

struct IdentityConfig: Codable {
    var identityStatement: String    // "I am a piano player"
    var evidenceEntries: [EvidenceEntry]
    var milestones: [IdentityMilestone]

    init(
        identityStatement: String,
        evidenceEntries: [EvidenceEntry] = [],
        milestones: [IdentityMilestone] = []
    ) {
        self.identityStatement = identityStatement
        self.evidenceEntries = evidenceEntries
        self.milestones = milestones
    }
}

// MARK: - Weekly Milestone Model (5 per Power Goal)
struct WeeklyMilestone: Identifiable, Codable {
    let id: UUID
    var powerGoalId: UUID
    var weekNumber: Int
    var milestoneText: String
    var status: MilestoneStatus
    var startDate: Date?
    var tasks: [MomentumTask]

    init(
        id: UUID = UUID(),
        powerGoalId: UUID,
        weekNumber: Int,
        milestoneText: String,
        status: MilestoneStatus = .pending,
        startDate: Date? = nil,
        tasks: [MomentumTask] = []
    ) {
        self.id = id
        self.powerGoalId = powerGoalId
        self.weekNumber = weekNumber
        self.milestoneText = milestoneText
        self.status = status
        self.startDate = startDate
        self.tasks = tasks
    }
}

enum MilestoneStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
}

// MARK: - Task Model (3 per day)
struct MomentumTask: Identifiable, Codable {
    let id: UUID
    var weeklyMilestoneId: UUID
    var goalId: UUID
    var title: String
    var taskDescription: String?
    var difficulty: TaskDifficulty
    var estimatedMinutes: Int
    var isAnchorTask: Bool
    var scheduledDate: Date
    var status: TaskStatus
    var completedAt: Date?
    var calendarEventId: String?
    var microsteps: [Microstep]
    var notes: TaskNotes

    init(
        id: UUID = UUID(),
        weeklyMilestoneId: UUID,
        goalId: UUID,
        title: String,
        taskDescription: String? = nil,
        difficulty: TaskDifficulty,
        estimatedMinutes: Int,
        isAnchorTask: Bool = false,
        scheduledDate: Date,
        status: TaskStatus = .pending,
        completedAt: Date? = nil,
        calendarEventId: String? = nil,
        microsteps: [Microstep] = [],
        notes: TaskNotes = TaskNotes()
    ) {
        self.id = id
        self.weeklyMilestoneId = weeklyMilestoneId
        self.goalId = goalId
        self.title = title
        self.taskDescription = taskDescription
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.isAnchorTask = isAnchorTask
        self.scheduledDate = scheduledDate
        self.status = status
        self.completedAt = completedAt
        self.calendarEventId = calendarEventId
        self.microsteps = microsteps
        self.notes = notes
    }
}

// MARK: - Enhanced Task Details

struct EnhancedTaskDetails: Codable {
    let difficultyExplanation: String
    let timeBreakdown: [MicrostepTimeEstimate]
    let tips: [String]
}

struct MicrostepTimeEstimate: Codable {
    let microstep: String
    let estimatedMinutes: Int
    let rationale: String
}

enum TaskDifficulty: String, Codable {
    case easy
    case medium
    case hard

    var emoji: String {
        switch self {
        case .easy: return ""
        case .medium: return ""
        case .hard: return ""
        }
    }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Challenge"
        }
    }

    var color: String {
        switch self {
        case .easy: return "10B981"
        case .medium: return "F59E0B"
        case .hard: return "EF4444"
        }
    }
}

enum TaskStatus: String, Codable {
    case pending
    case completed
    case skipped
}

// MARK: - Microstep Model
struct Microstep: Identifiable, Codable {
    let id: UUID
    var taskId: UUID
    var stepText: String
    var orderIndex: Int
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        taskId: UUID,
        stepText: String,
        orderIndex: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.taskId = taskId
        self.stepText = stepText
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
    }
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

    var emoji: String {
        switch self {
        case .sevenDayStreak: return ""
        case .first100Tasks: return ""
        case .fastStart: return ""
        case .thirtyDayStreak: return ""
        case .weekPerfect: return ""
        case .firstGoalComplete: return ""
        }
    }

    var title: String {
        switch self {
        case .sevenDayStreak: return "7 Day Streak"
        case .first100Tasks: return "First 100"
        case .fastStart: return "Fast Start"
        case .thirtyDayStreak: return "30 Day Streak"
        case .weekPerfect: return "Perfect Week"
        case .firstGoalComplete: return "Goal Crusher"
        }
    }

    var description: String {
        switch self {
        case .sevenDayStreak: return "Complete tasks 7 days in a row"
        case .first100Tasks: return "Complete 100 total tasks"
        case .fastStart: return "Complete 3 tasks in your first 3 days"
        case .thirtyDayStreak: return "Complete tasks 30 days in a row"
        case .weekPerfect: return "Complete all daily tasks for a week"
        case .firstGoalComplete: return "Complete your first Power Goal"
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
    var weeklyHours: String = ""
    var timeline: String = ""
    var biggestConcern: String = ""
    var passions: String = ""
    var identityMeaning: String = ""
}

// MARK: - AI Generation Response
struct AIGeneratedPlan: Codable {
    let visionRefined: String
    let powerGoals: [GeneratedPowerGoal]
    let currentPowerGoal: GeneratedCurrentPowerGoal
    let anchorTask: String?

    enum CodingKeys: String, CodingKey {
        case visionRefined = "vision_refined"
        case powerGoals = "power_goals"
        case currentPowerGoal = "current_power_goal"
        case anchorTask = "anchor_task"
    }
}

struct GeneratedPowerGoal: Codable {
    let month: Int
    let goal: String
    let description: String
}

struct GeneratedCurrentPowerGoal: Codable {
    let goal: String
    let weeklyMilestones: [GeneratedWeeklyMilestone]

    enum CodingKeys: String, CodingKey {
        case goal
        case weeklyMilestones = "weekly_milestones"
    }
}

struct GeneratedWeeklyMilestone: Codable {
    let week: Int
    let milestone: String
    let dailyTasks: [GeneratedDailyTasks]

    enum CodingKeys: String, CodingKey {
        case week
        case milestone
        case dailyTasks = "daily_tasks"
    }
}

struct GeneratedDailyTasks: Codable {
    let day: Int
    let tasks: [GeneratedTask]
}

struct GeneratedTask: Codable {
    let title: String
    let difficulty: String
    let estimatedMinutes: Int
    let description: String

    enum CodingKeys: String, CodingKey {
        case title
        case difficulty
        case estimatedMinutes = "estimated_minutes"
        case description
    }
}

// MARK: - Habit AI Response Models
struct AIGeneratedHabitPlan: Codable {
    let visionRefined: String
    let frequency: String
    let habitDescription: String
    let weeklyGoal: Int?
    let milestones: [GeneratedHabitMilestone]

    enum CodingKeys: String, CodingKey {
        case visionRefined = "vision_refined"
        case frequency
        case habitDescription = "habit_description"
        case weeklyGoal = "weekly_goal"
        case milestones
    }
}

struct GeneratedHabitMilestone: Codable {
    let streak: Int
    let title: String
}

// MARK: - Identity AI Response Models
struct AIGeneratedIdentityPlan: Codable {
    let visionRefined: String
    let identityStatement: String
    let isComplex: Bool
    let evidenceCategories: [String]
    let milestones: [GeneratedIdentityMilestone]
    let dailyTaskDescription: String?

    enum CodingKeys: String, CodingKey {
        case visionRefined = "vision_refined"
        case identityStatement = "identity_statement"
        case isComplex = "is_complex"
        case evidenceCategories = "evidence_categories"
        case milestones
        case dailyTaskDescription = "daily_task_description"
    }
}

struct GeneratedIdentityMilestone: Codable {
    let title: String
    let category: String?
}

// MARK: - Unified AI Response
enum AIGoalPlanResponse {
    case project(AIGeneratedPlan)
    case habit(AIGeneratedHabitPlan)
    case identity(AIGeneratedIdentityPlan)
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
