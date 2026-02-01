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
            lastTaskCompletedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            preferences: UserPreferences(
                weeklyTimeMinutes: 300,
                preferredSessionMinutes: 30,
                availableDays: [2, 3, 4, 5, 6],
                userSkills: [:]
            )
        )
    }

    // MARK: - Mock Goal with Milestones
    var mockGoal: Goal {
        let goalId = UUID()
        let userId = mockUser.id

        // Create 12 Milestones (sequential, not month-based)
        var milestones: [Milestone] = []

        let milestoneTitles = [
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

        for (index, (title, description)) in milestoneTitles.enumerated() {
            let milestoneId = UUID()
            var tasks: [MomentumTask] = []

            // Create tasks for the first milestone only
            if index == 0 {
                let weekStart = Calendar.current.startOfDay(for: Date())

                for dayOffset in 0..<5 { // 5 available days (Mon-Fri)
                    let taskDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)!
                    let dayTask = getDayTask(for: dayOffset, date: taskDate, milestoneId: milestoneId, goalId: goalId)
                    tasks.append(dayTask)
                }
            }

            milestones.append(Milestone(
                id: milestoneId,
                goalId: goalId,
                sequenceNumber: index + 1,
                title: title,
                description: description,
                status: index == 0 ? .active : .locked,
                completionPercentage: index == 0 ? 0.2 : 0,
                tasks: tasks,
                startedAt: index == 0 ? Date() : nil
            ))
        }

        return Goal(
            id: goalId,
            userId: userId,
            visionText: "Start a consulting agency",
            visionRefined: "Launch my consulting agency with 3 paying clients by June 2026",
            goalType: .project,
            status: .active,
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            targetCompletionDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()),
            currentMilestoneIndex: 0,
            completionPercentage: 0.04,
            milestones: milestones,
            knowledgeBase: []
        )
    }

    private func getDayTask(for dayOffset: Int, date: Date, milestoneId: UUID, goalId: UUID) -> MomentumTask {
        let taskData: [(String, String, String, [(String, Int)])] = [
            // Day 0 (Today)
            (
                "Research 3 competitors",
                "Analyze their pricing, services, and positioning to understand market landscape",
                "Have a document with 3 competitor analyses including pricing, services offered, and key differentiators",
                [
                    ("Find 3 direct competitors in your niche", 10),
                    ("Document their service offerings", 15),
                    ("Analyze their pricing structure", 15),
                    ("Note their unique selling points", 10)
                ]
            ),
            // Day 1
            (
                "Draft service packages",
                "Create 3-tier pricing structure based on competitor research",
                "Have 3 service tiers defined with clear pricing and deliverables for each",
                [
                    ("Define what's included in basic tier", 15),
                    ("Define what's included in standard tier", 15),
                    ("Define what's included in premium tier", 15),
                    ("Set pricing for each tier", 15)
                ]
            ),
            // Day 2
            (
                "Create LinkedIn outreach template",
                "Write personalized message templates for prospect outreach",
                "Have 2-3 message templates ready to customize for individual prospects",
                [
                    ("Research effective outreach patterns", 10),
                    ("Write initial connection message", 15),
                    ("Write follow-up message template", 15),
                    ("Create value-offering message", 10)
                ]
            ),
            // Day 3
            (
                "Reach out to 5 prospects",
                "Send personalized messages to potential clients on LinkedIn",
                "Have sent 5 customized outreach messages with connection requests",
                [
                    ("Identify 5 ideal prospects", 10),
                    ("Customize messages for each", 20),
                    ("Send all 5 connection requests", 10),
                    ("Log outreach in tracking sheet", 5)
                ]
            ),
            // Day 4
            (
                "Create pitch deck outline",
                "Structure your presentation for discovery calls",
                "Have a 10-slide pitch deck outline with key talking points",
                [
                    ("Define the problem you solve", 10),
                    ("Outline your solution approach", 15),
                    ("Document case studies or results", 15),
                    ("Create pricing slide structure", 10)
                ]
            )
        ]

        let index = min(dayOffset, taskData.count - 1)
        let (title, description, outcome, checklistItems) = taskData[index]

        let checklist = checklistItems.enumerated().map { idx, item in
            ChecklistItem(
                text: item.0,
                estimatedMinutes: item.1,
                isCompleted: dayOffset == 0 && idx == 0, // First item of first task is completed
                orderIndex: idx
            )
        }

        let totalMinutes = checklist.reduce(0) { $0 + $1.estimatedMinutes }

        return MomentumTask(
            milestoneId: milestoneId,
            goalId: goalId,
            title: title,
            taskDescription: description,
            checklist: checklist,
            outcomeGoal: outcome,
            totalEstimatedMinutes: totalMinutes,
            scheduledDate: date,
            status: .pending
        )
    }

    // MARK: - Today's Tasks
    var todaysTasks: [MomentumTask] {
        guard let firstMilestone = mockGoal.milestones.first else {
            return []
        }

        let today = Calendar.current.startOfDay(for: Date())
        return firstMilestone.tasks.filter {
            $0.status == .pending &&
            Calendar.current.startOfDay(for: $0.scheduledDate) <= today
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
            ("Mon", 1),
            ("Tue", 1),
            ("Wed", 1),
            ("Thu", 1),
            ("Fri", 1),
            ("Sat", 0),
            ("Sun", 0)
        ]
    }

    var totalTasksCompleted: Int { 12 }
    var completionRate: Double { 0.89 }
}
