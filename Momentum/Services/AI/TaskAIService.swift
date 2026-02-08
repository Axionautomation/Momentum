//
//  TaskAIService.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Handles task evaluation, checklist generation, and weekly task generation via AIServiceRouter.
//

import Foundation
import Combine

@MainActor
class TaskAIService: ObservableObject {
    static let shared = TaskAIService()

    private let router = AIServiceRouter.shared

    private init() {}

    // MARK: - Daily Task Evaluation

    func evaluateTodaysTasks(
        tasks: [MomentumTask],
        userSkills: [String: String],
        goalContext: String
    ) async throws -> [TaskEvaluationResponse] {
        let tasksDescription = tasks.enumerated().map { index, task in
            """
            Task \(index + 1): \(task.title)
            Description: \(task.taskDescription ?? "No description")
            Outcome Goal: \(task.outcomeGoal)
            Checklist: \(task.checklist.map { $0.text }.joined(separator: ", "))
            """
        }.joined(separator: "\n\n")

        let knownSkillsList = userSkills.isEmpty
            ? "No known skills yet"
            : userSkills.map { "- \($0.key): \($0.value)" }.joined(separator: "\n")

        let systemPrompt = """
        Evaluate tasks to determine the best approach for completion.

        For each task, determine:
        1. Can AI do this autonomously? (research, writing, analysis)
        2. Can the user do this with their current skills?
        3. What skills are required?
        4. Best approach: userDirect, aiAssisted, toolHandoff, needsGuidance
        5. If skills are unknown, generate a skill question
        6. If user can't do it, suggest an external tool

        IMPORTANT: DO NOT generate skill_questions for skills that are already in the KNOWN USER SKILLS list below. Only ask about skills that have NOT been answered yet.

        Return ONLY valid JSON:
        {
          "evaluations": [
            {
              "can_ai_do": false,
              "can_user_do": true,
              "skills_required": ["coding", "design"],
              "approach": "userDirect",
              "skill_questions": [
                {"skill": "coding", "question": "Can you code?", "options": ["Yes", "No", "Learning"]}
              ],
              "tool_suggestion": {"tool_name": "Cursor", "reason": "For code generation"},
              "guidance_needed": false
            }
          ]
        }
        """

        let userPrompt = """
        GOAL CONTEXT: \(goalContext)

        KNOWN USER SKILLS (DO NOT ask about these):
        \(knownSkillsList)

        TASKS TO EVALUATE:
        \(tasksDescription)

        Evaluate each task and return an evaluation for each one in order.
        Remember: Do NOT generate skill_questions for any skill already listed in KNOWN USER SKILLS above.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.5,
            maxTokens: 2000,
            requireJSON: true,
            preferredTier: .fast
        )

        struct EvaluationsResponse: Codable {
            let evaluations: [TaskEvaluationResponse]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        return try JSONDecoder().decode(EvaluationsResponse.self, from: data).evaluations
    }

    // MARK: - Generate Weekly Tasks

    func generateWeeklyTasks(
        milestone: Milestone,
        weeklyTimeBudget: Int,
        availableDays: [Int],
        userSkills: [String: String],
        previousTasks: [MomentumTask],
        goalContext: String
    ) async throws -> [GeneratedTaskWithChecklist] {
        let tasksPerWeek = availableDays.count
        let availableDaysString = availableDays.map { dayNumber -> String in
            let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days[dayNumber]
        }.joined(separator: ", ")

        let previousTasksSummary = previousTasks.prefix(5).map { $0.title }.joined(separator: ", ")
        let skillsSummary = userSkills.map { "\($0.key): \($0.value)" }.joined(separator: ", ")

        let systemPrompt = """
        Generate tasks for the next week of a milestone-based goal plan.

        REQUIREMENTS:
        - Generate exactly \(tasksPerWeek) tasks (one per available day)
        - Total time must NOT exceed \(weeklyTimeBudget) minutes
        - Each task needs:
          - Clear outcome goal (definition of "done")
          - 3-5 checklist items with time estimates
          - Specific, actionable steps
        - Build on previous progress
        - Account for user's skill levels

        Return ONLY valid JSON:
        {
          "tasks": [
            {
              "title": "Task name",
              "description": "What to do",
              "outcome_goal": "Definition of done",
              "checklist": [
                {"text": "Step description", "estimated_minutes": 10}
              ],
              "scheduled_day": 2
            }
          ]
        }
        """

        let userPrompt = """
        MILESTONE: \(milestone.title)
        Milestone Description: \(milestone.description ?? "No description")
        Goal Context: \(goalContext)

        Weekly Time Budget: \(weeklyTimeBudget) minutes
        Available Days: \(availableDaysString)
        User Skills: \(skillsSummary.isEmpty ? "Unknown" : skillsSummary)
        Recent Tasks Completed: \(previousTasksSummary.isEmpty ? "None" : previousTasksSummary)

        Generate \(tasksPerWeek) tasks that advance this milestone.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 2000,
            requireJSON: true,
            preferredTier: .fast
        )

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        return try JSONDecoder().decode(WeeklyTasksResponse.self, from: data).tasks
    }

    // MARK: - Generate Checklist Items

    func generateChecklistItems(
        taskTitle: String,
        taskDescription: String?,
        totalMinutes: Int
    ) async throws -> [ChecklistItem] {
        let systemPrompt = """
        Break down a task into 3-5 specific checklist items with time estimates.

        Each item should be:
        - A single, concrete action
        - Have a realistic time estimate
        - Be specific and actionable

        Total time should approximately equal the provided budget.

        Return ONLY valid JSON:
        {
          "checklist": [
            {"text": "Step description", "estimated_minutes": 10}
          ]
        }
        """

        let taskInfo = taskDescription ?? taskTitle
        let userPrompt = """
        Task: \(taskTitle)
        Description: \(taskInfo)
        Time Budget: \(totalMinutes) minutes

        Break this into 3-5 checklist items with time estimates.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 500,
            requireJSON: true,
            preferredTier: .fast
        )

        struct ChecklistResponse: Codable {
            let checklist: [GeneratedChecklistItem]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(ChecklistResponse.self, from: data)

        return response.checklist.enumerated().map { index, item in
            ChecklistItem(
                text: item.text,
                estimatedMinutes: item.estimatedMinutes,
                orderIndex: index
            )
        }
    }

    // MARK: - Task Help

    func getTaskHelp(
        taskTitle: String,
        taskDescription: String?,
        userQuestion: String
    ) async throws -> String {
        let systemPrompt = """
        You are Momentum's helpful AI coach. A user is working on a task and needs guidance.

        Provide specific, actionable advice that helps them make progress. Be:
        - Encouraging and supportive
        - Concrete and specific (not vague)
        - Brief but helpful (2-4 sentences)

        Your tone should be warm and energetic, like a coach who believes in them.
        """

        let taskInfo = taskDescription ?? taskTitle
        let userPrompt = """
        Task: \(taskTitle)
        Details: \(taskInfo)

        User's question: \(userQuestion)

        Provide helpful guidance to help them complete this task.
        """

        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            preferredTier: .fast
        )
    }

    // MARK: - Generate Skill Question

    func generateSkillQuestion(
        task: MomentumTask,
        skill: String
    ) async throws -> SkillQuestion {
        let systemPrompt = """
        Generate a skill assessment question for a specific skill needed for a task.
        The question should be friendly and help determine the user's level.

        Return ONLY valid JSON:
        {
          "skill": "the skill name",
          "question": "The question to ask",
          "options": ["Yes, confident", "Somewhat", "No, but willing to learn", "No"]
        }
        """

        let userPrompt = """
        Task: \(task.title)
        Skill to assess: \(skill)

        Generate a friendly skill assessment question.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            requireJSON: true,
            preferredTier: .fast
        )

        struct SkillQuestionResponse: Codable {
            let skill: String
            let question: String
            let options: [String]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(SkillQuestionResponse.self, from: data)

        return SkillQuestion(
            taskId: task.id,
            skill: response.skill,
            question: response.question,
            options: response.options
        )
    }

    // MARK: - Generate Tool Prompt

    func generateToolPromptForTask(
        task: MomentumTask,
        tool: String,
        userSkillLevel: String?,
        goalContext: String
    ) async throws -> ToolPrompt {
        let systemPrompt = """
        Generate a detailed, copy-paste ready prompt for an external tool.

        The prompt should:
        - Be specific and detailed
        - Include all relevant context
        - Be formatted properly for the tool
        - Account for the user's skill level
        - Be ready to copy and paste directly into the tool

        Return ONLY valid JSON:
        {
          "tool_name": "\(tool)",
          "prompt": "The full prompt text",
          "context": "Brief explanation of why this prompt"
        }
        """

        let userPrompt = """
        TASK: \(task.title)
        Description: \(task.taskDescription ?? "No description")
        Outcome Goal: \(task.outcomeGoal)
        Goal Context: \(goalContext)
        Tool: \(tool)
        User Skill Level: \(userSkillLevel ?? "Unknown")

        Generate a comprehensive prompt for \(tool) that will help complete this task.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1500,
            requireJSON: true,
            preferredTier: .fast
        )

        struct ToolPromptResponse: Codable {
            let tool_name: String
            let prompt: String
            let context: String
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(ToolPromptResponse.self, from: data)

        return ToolPrompt(
            taskId: task.id,
            toolName: response.tool_name,
            prompt: response.prompt,
            context: response.context
        )
    }
}
