//
//  MockDataService.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import Foundation

class MockDataService {
    static let shared = MockDataService()

    private init() {}

    // MARK: - Mock User
    var mockUser: MomentumUser {
        MomentumUser(
            email: "henry@example.com",
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            subscriptionTier: .free,
            aiPersonality: .energetic,
            streakCount: 5,
            longestStreak: 12,
            lastTaskCompletedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
        )
    }

    // MARK: - Mock Goal with full hierarchy
    var mockGoal: Goal {
        let goalId = UUID()
        let userId = mockUser.id

        // Create 12 Power Goals
        var powerGoals: [PowerGoal] = []

        let powerGoalTitles = [
            ("Build Foundation", "Define service packages & validate market fit"),
            ("First Clients", "Acquire your first 3 paying clients"),
            ("Scale Systems", "Create repeatable sales and delivery processes"),
            ("Team Building", "Hire first contractor or assistant"),
            ("Marketing Engine", "Build consistent lead generation"),
            ("Productize Services", "Create standardized service offerings"),
            ("Raise Prices", "Increase rates based on proven value"),
            ("Expand Offerings", "Add complementary services"),
            ("Build Authority", "Establish thought leadership"),
            ("Optimize Operations", "Streamline for profitability"),
            ("Growth Push", "Aggressive client acquisition"),
            ("Vision Achieved", "Celebrate & plan next chapter")
        ]

        for (index, (title, description)) in powerGoalTitles.enumerated() {
            let powerGoalId = UUID()
            var milestones: [WeeklyMilestone] = []

            // Create 5 weekly milestones for the first power goal
            if index == 0 {
                let milestoneTitles = [
                    "Market Research",
                    "Service Definition",
                    "Pricing Strategy",
                    "Initial Outreach",
                    "Validation & Adjustment"
                ]

                for (weekIndex, milestoneTitle) in milestoneTitles.enumerated() {
                    let milestoneId = UUID()
                    var tasks: [MomentumTask] = []

                    // Create 21 tasks (3 per day for 7 days) for week 1
                    if weekIndex == 0 {
                        let weekStart = Calendar.current.startOfDay(for: Date())

                        for dayOffset in 0..<7 {
                            let taskDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)!

                            let dayTasks = getDayTasks(for: dayOffset, date: taskDate, milestoneId: milestoneId, goalId: goalId)
                            tasks.append(contentsOf: dayTasks)
                        }
                    }

                    milestones.append(WeeklyMilestone(
                        powerGoalId: powerGoalId,
                        weekNumber: weekIndex + 1,
                        milestoneText: milestoneTitle,
                        status: weekIndex == 0 ? .inProgress : .pending,
                        startDate: weekIndex == 0 ? Date() : nil,
                        tasks: tasks
                    ))
                }
            }

            powerGoals.append(PowerGoal(
                id: powerGoalId,
                goalId: goalId,
                monthNumber: index + 1,
                title: title,
                description: description,
                status: index == 0 ? .active : .locked,
                startDate: index == 0 ? Date() : nil,
                completionPercentage: index == 0 ? 0.47 : 0,
                weeklyMilestones: milestones
            ))
        }

        return Goal(
            id: goalId,
            userId: userId,
            visionText: "Start a consulting agency",
            visionRefined: "Launch my consulting agency with 3 paying clients by June 2026",
            isIdentityBased: false,
            status: .active,
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            targetCompletionDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()),
            currentPowerGoalIndex: 0,
            completionPercentage: 0.04,
            powerGoals: powerGoals
        )
    }

    private func getDayTasks(for dayOffset: Int, date: Date, milestoneId: UUID, goalId: UUID) -> [MomentumTask] {
        let taskData: [[(String, String, TaskDifficulty, Int, Bool)]] = [
            // Day 0 (Today)
            [
                ("Research 3 competitors", "Analyze their pricing, services, and positioning", .easy, 15, true),
                ("Draft service packages", "Create 3-tier pricing structure", .medium, 30, false),
                ("Call 3 potential clients", "Validate problem and interest", .hard, 45, false)
            ],
            // Day 1
            [
                ("Review business plan notes", "15 min review of goals", .easy, 15, true),
                ("Define target audience", "Create ideal client profile", .medium, 30, false),
                ("Create LinkedIn outreach template", "Write personalized message", .hard, 45, false)
            ],
            // Day 2
            [
                ("Journal on progress", "Reflect on learnings", .easy, 15, true),
                ("Research industry pricing", "Benchmark against market", .medium, 30, false),
                ("Reach out to 5 prospects", "Send personalized messages", .hard, 45, false)
            ],
            // Day 3
            [
                ("Read industry article", "Stay current on trends", .easy, 15, true),
                ("Refine value proposition", "Clarify unique benefits", .medium, 30, false),
                ("Schedule 2 discovery calls", "Book meetings with prospects", .hard, 45, false)
            ],
            // Day 4
            [
                ("Morning visualization", "Visualize successful client meeting", .easy, 15, true),
                ("Create pitch deck outline", "Structure your presentation", .medium, 30, false),
                ("Conduct first discovery call", "Learn about prospect needs", .hard, 45, false)
            ],
            // Day 5
            [
                ("Review weekly progress", "Assess what's working", .easy, 15, true),
                ("Update service descriptions", "Improve based on feedback", .medium, 30, false),
                ("Follow up with all prospects", "Send personalized follow-ups", .hard, 45, false)
            ],
            // Day 6
            [
                ("Plan next week priorities", "Set clear goals", .easy, 15, true),
                ("Analyze conversion funnel", "Identify drop-off points", .medium, 30, false),
                ("Prepare proposal template", "Create customizable proposal", .hard, 45, false)
            ]
        ]

        let tasks = taskData[min(dayOffset, taskData.count - 1)]
        return tasks.map { (title, description, difficulty, minutes, isAnchor) in
            MomentumTask(
                weeklyMilestoneId: milestoneId,
                goalId: goalId,
                title: title,
                description: description,
                difficulty: difficulty,
                estimatedMinutes: minutes,
                isAnchorTask: isAnchor,
                scheduledDate: date,
                status: .pending,
                microsteps: createMicrosteps(for: title)
            )
        }
    }

    private func createMicrosteps(for taskTitle: String) -> [Microstep] {
        let taskId = UUID()

        switch taskTitle {
        case "Draft service packages":
            return [
                Microstep(taskId: taskId, stepText: "Research competitor pricing", orderIndex: 0),
                Microstep(taskId: taskId, stepText: "List your core services", orderIndex: 1),
                Microstep(taskId: taskId, stepText: "Define tier benefits", orderIndex: 2)
            ]
        case "Call 3 potential clients":
            return [
                Microstep(taskId: taskId, stepText: "Prepare talking points", orderIndex: 0),
                Microstep(taskId: taskId, stepText: "Make first call", orderIndex: 1),
                Microstep(taskId: taskId, stepText: "Make second call", orderIndex: 2),
                Microstep(taskId: taskId, stepText: "Make third call", orderIndex: 3)
            ]
        default:
            return []
        }
    }

    // MARK: - Today's Tasks
    var todaysTasks: [MomentumTask] {
        guard let firstPowerGoal = mockGoal.powerGoals.first,
              let firstMilestone = firstPowerGoal.weeklyMilestones.first else {
            return []
        }

        let today = Calendar.current.startOfDay(for: Date())
        return firstMilestone.tasks.filter {
            Calendar.current.isDate($0.scheduledDate, inSameDayAs: today)
        }
    }

    // MARK: - Mock Achievements
    var mockAchievements: [Achievement] {
        let userId = mockUser.id
        return [
            Achievement(userId: userId, badgeType: .fastStart, unlockedAt: Calendar.current.date(byAdding: .day, value: -11, to: Date())!),
            Achievement(userId: userId, badgeType: .sevenDayStreak, unlockedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
        ]
    }

    // MARK: - Stats Data
    var weeklyCompletionData: [(String, Int)] {
        [
            ("Mon", 3),
            ("Tue", 3),
            ("Wed", 2),
            ("Thu", 3),
            ("Fri", 3),
            ("Sat", 0),
            ("Sun", 1)
        ]
    }

    var totalTasksCompleted: Int { 47 }
    var completionRate: Double { 0.89 }
}
