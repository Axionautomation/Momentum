//
//  GroqService.swift
//  Momentum
//
//  Created by Henry Bowman on 12/29/25.
//

import Foundation
import Combine

enum GroqError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let message):
            return "AI service error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class GroqService: ObservableObject {
    static let shared = GroqService()

    private let apiKey: String
    private let baseURL: String
    private let model: String
    private var session: URLSession!

    private init() {
        self.apiKey = Config.groqAPIKey
        self.baseURL = Config.groqAPIBaseURL
        self.model = Config.groqModel
        self.session = createSession()
    }

    private func createSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 2
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true

        #if os(iOS)
        config.multipathServiceType = .none
        #endif

        let delegate = NetworkDebugDelegate()
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }

    /// Delegate for debugging network protocol and connection info
    private class NetworkDebugDelegate: NSObject, URLSessionTaskDelegate, URLSessionDelegate, @unchecked Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
            if let transaction = metrics.transactionMetrics.first {
                let protocolName = transaction.networkProtocolName ?? "unknown"
                let duration = String(format: "%.2f", transaction.responseEndDate?.timeIntervalSince(transaction.fetchStartDate ?? Date()) ?? 0)
                print("Protocol: \(protocolName) | Duration: \(duration)s")
            }
        }

        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            if let error = error {
                print("URLSession invalidated: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Groq API Request/Response Models

    private struct GroqRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int?
        let responseFormat: ResponseFormat?
        let tools: [Tool]?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
            case responseFormat = "response_format"
            case tools
        }

        struct Message: Codable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Codable {
            let type: String // "json_object" for JSON mode
        }

        struct Tool: Codable {
            let type: String // "browser_search"
        }
    }

    private struct GroqResponse: Codable {
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let role: String
                let content: String
            }
        }

        struct Usage: Codable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }

    // MARK: - Core AI Request Method

    private func makeRequest(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        requireJSON: Bool = false,
        retryCount: Int = 0
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw GroqError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let messages = [
            GroqRequest.Message(role: "system", content: systemPrompt),
            GroqRequest.Message(role: "user", content: userPrompt)
        ]

        let groqRequest = GroqRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: requireJSON ? GroqRequest.ResponseFormat(type: "json_object") : nil,
            tools: nil
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(groqRequest)

        print("Making Groq API request (Attempt \(retryCount + 1))...")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                throw GroqError.invalidResponse
            }

            print("HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                // Retry on server errors or rate limiting
                if (500...599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429 {
                    if retryCount < 3 {
                        let delay = Double(retryCount + 1) * 2
                        print("Server error \(httpResponse.statusCode), retrying in \(delay)s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        return try await makeRequest(
                            systemPrompt: systemPrompt,
                            userPrompt: userPrompt,
                            temperature: temperature,
                            maxTokens: maxTokens,
                            requireJSON: requireJSON,
                            retryCount: retryCount + 1
                        )
                    }
                }

                if let errorString = String(data: data, encoding: .utf8) {
                    print("API Error: \(errorString)")
                    throw GroqError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                }
                throw GroqError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let groqResponse = try decoder.decode(GroqResponse.self, from: data)

            guard let content = groqResponse.choices.first?.message.content else {
                print("No content in response")
                throw GroqError.invalidResponse
            }

            print("Received response (\(content.count) characters)")
            return content

        } catch let error as GroqError {
            throw error
        } catch {
            let nsError = error as NSError
            // Retry on common network errors
            let retryableCodes = [-1001, -1004, -1005, -1009, -1020]
            if nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code) && retryCount < 3 {
                let delay = pow(2.0, Double(retryCount + 1))
                print("Network error (\(nsError.code)), retrying in \(delay)s...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await makeRequest(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    temperature: temperature,
                    maxTokens: maxTokens,
                    requireJSON: requireJSON,
                    retryCount: retryCount + 1
                )
            }
            print("Request failed: \(error.localizedDescription)")
            throw GroqError.networkError(error)
        }
    }

    // MARK: - Generate Personalized Onboarding Questions

    func generateOnboardingQuestions(visionText: String) async throws -> [OnboardingQuestion] {
        let systemPrompt = """
        You are Momentum's AI coach, designed to help users achieve their goals through personalized planning.
        Generate 3-5 adaptive questions to better understand the user's vision and create a tailored plan.

        For goal-based visions (e.g., "Start a consulting agency"), ask about:
        - Experience level
        - Main challenges or concerns
        - Specific interests within the domain

        IMPORTANT:
        - Make questions specific to their exact vision domain
        - For multiple choice, provide 3-4 specific options
        - Set "allowsTextInput" to true if you want to also allow custom text input
        - DO NOT include "Other (please specify)" as an option - use allowsTextInput instead
        - Keep options concise and relevant
        - DO NOT ask about time commitment or available days - we collect that separately

        Be warm, encouraging, and specific. Each question should help create a better action plan.

        Return ONLY valid JSON in this exact format:
        {
          "questions": [
            {
              "question": "What's your current experience level with [domain]?",
              "options": ["Complete beginner", "Some experience", "Intermediate", "Advanced"],
              "allowsTextInput": true
            }
          ]
        }
        """

        let userPrompt = """
        User's vision: "\(visionText)"

        Generate 3-5 personalized questions to understand their background and create an effective action plan.
        Remember: DO NOT ask about time commitment or available days.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.8,
            maxTokens: 1500,
            requireJSON: true
        )

        // Parse JSON response
        struct QuestionsResponse: Codable {
            let questions: [QuestionData]

            struct QuestionData: Codable {
                let question: String
                let options: [String]?
                let allowsTextInput: Bool
            }
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(QuestionsResponse.self, from: data)

            return response.questions.map { questionData in
                OnboardingQuestion(
                    question: questionData.question,
                    options: questionData.options,
                    allowsTextInput: questionData.allowsTextInput
                )
            }
        } catch {
            throw GroqError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Project Plan Generation (New Milestone-based System)

    func generateProjectPlan(
        visionText: String,
        answers: OnboardingAnswers
    ) async throws -> AIGeneratedPlan {
        let weeklyMinutes = answers.weeklyHours * 60
        let availableDaysString = answers.availableDays.sorted().map { dayNumber -> String in
            let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days[dayNumber]
        }.joined(separator: ", ")
        let tasksPerWeek = answers.availableDays.count // One task per available day

        let systemPrompt = """
        You are Momentum's AI coach. Generate a HYPER-PERSONALIZED goal achievement plan.

        CRITICAL: The plan MUST be 100% specific to the user's EXACT vision. DO NOT use generic examples.

        Framework:
        1. North Star Vision - One SMART annual goal (refined from user's vision)
        2. 12 Milestones - Sequential achievements (NOT month-based) that build toward the vision
        3. First Week Tasks - Tasks with detailed checklists for the first week only

        TASK REQUIREMENTS:
        - Generate exactly \(tasksPerWeek) tasks for the first week (one per available day)
        - Total time for all tasks must NOT exceed \(weeklyMinutes) minutes
        - Each task MUST have:
          - A clear outcome goal (definition of "done")
          - 3-5 checklist items with time estimates per item
          - Checklist items should be specific, actionable steps
        - NO difficulty levels (easy/medium/hard) - just well-scoped tasks
        - Distribute tasks across available days: \(availableDaysString)

        PERSONALIZATION REQUIREMENTS:
        - Every task must directly relate to their SPECIFIC vision
        - Use their exact context (experience level, concerns)
        - Make tasks actionable with specific details
        - Reference their actual situation and adjust accordingly

        Return ONLY valid JSON matching this EXACT structure:
        {
          "vision_refined": "SMART version of the user's vision",
          "milestones": [
            {"sequence": 1, "title": "Title", "description": "What this achieves"},
            {"sequence": 2, "title": "Title", "description": "What this achieves"}
          ],
          "first_week_tasks": [
            {
              "title": "Task name",
              "description": "What to do and why",
              "outcome_goal": "Clear definition of done",
              "checklist": [
                {"text": "Step 1 description", "estimated_minutes": 10},
                {"text": "Step 2 description", "estimated_minutes": 15}
              ],
              "scheduled_day": 2
            }
          ]
        }

        Generate all 12 milestones and \(tasksPerWeek) first-week tasks.
        VERIFY: Ensure total time <= \(weeklyMinutes) minutes.
        """

        let userPrompt = """
        USER'S SPECIFIC VISION: "\(visionText)"

        USER CONTEXT:
        - Experience Level: \(answers.experienceLevel.isEmpty ? "Not specified" : answers.experienceLevel)
        - Weekly Time Available: \(answers.weeklyHours) hours (\(weeklyMinutes) minutes)
        - Available Days: \(availableDaysString)
        - Main Concern: \(answers.biggestConcern.isEmpty ? "Getting started" : answers.biggestConcern)
        - Passions/Interests: \(answers.passions.isEmpty ? "Not specified" : answers.passions)
        - Additional Context: \(answers.identityMeaning.isEmpty ? "Not specified" : answers.identityMeaning)

        CRITICAL INSTRUCTIONS:
        1. Read the vision carefully - this is about "\(visionText)"
        2. Every single task must be 100% relevant to THIS SPECIFIC vision
        3. Use concrete, actionable language specific to their domain
        4. Adjust task complexity based on their experience level
        5. Fit all tasks within their \(weeklyMinutes) minute weekly budget
        6. Create \(tasksPerWeek) tasks, one for each available day

        Generate a complete, HYPER-PERSONALIZED action plan.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 4000,
            requireJSON: true
        )

        // Clean up the JSON response
        var cleanedJSON = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove trailing commas before closing brackets
        cleanedJSON = cleanedJSON.replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
        cleanedJSON = cleanedJSON.replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)

        // Fix missing closing brace if needed
        let openBraces = cleanedJSON.filter { $0 == "{" }.count
        let closeBraces = cleanedJSON.filter { $0 == "}" }.count
        if openBraces > closeBraces {
            cleanedJSON += String(repeating: "}", count: openBraces - closeBraces)
        }

        guard let data = cleanedJSON.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let plan = try decoder.decode(AIGeneratedPlan.self, from: data)
            return plan
        } catch {
            print("Decoding error: \(error)")
            print("Original response: \(responseText)")
            print("Cleaned response: \(cleanedJSON)")
            throw GroqError.decodingError(error.localizedDescription)
        }
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

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 2000,
            requireJSON: true
        )

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(WeeklyTasksResponse.self, from: data)
        return response.tasks
    }

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

        let skillsSummary = userSkills.isEmpty ? "No skills data" : userSkills.map { "\($0.key): \($0.value)" }.joined(separator: ", ")

        let systemPrompt = """
        Evaluate tasks to determine the best approach for completion.

        For each task, determine:
        1. Can AI do this autonomously? (research, writing, analysis)
        2. Can the user do this with their current skills?
        3. What skills are required?
        4. Best approach: userDirect, aiAssisted, toolHandoff, needsGuidance
        5. If skills are unknown, generate a skill question
        6. If user can't do it, suggest an external tool

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
        USER SKILLS: \(skillsSummary)

        TASKS TO EVALUATE:
        \(tasksDescription)

        Evaluate each task and return an evaluation for each one in order.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.5,
            maxTokens: 2000,
            requireJSON: true
        )

        struct EvaluationsResponse: Codable {
            let evaluations: [TaskEvaluationResponse]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(EvaluationsResponse.self, from: data)
        return response.evaluations
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

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            requireJSON: true
        )

        struct SkillQuestionResponse: Codable {
            let skill: String
            let question: String
            let options: [String]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
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

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1500,
            requireJSON: true
        )

        struct ToolPromptResponse: Codable {
            let tool_name: String
            let prompt: String
            let context: String
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(ToolPromptResponse.self, from: data)

        return ToolPrompt(
            taskId: task.id,
            toolName: response.tool_name,
            prompt: response.prompt,
            context: response.context
        )
    }

    // MARK: - Generate Guidance Questionnaire

    func generateGuidanceQuestionnaire(
        task: MomentumTask,
        goalContext: String
    ) async throws -> AIQuestionnaire {
        let systemPrompt = """
        Generate a brainstorming questionnaire to help the user think through a task.

        The questionnaire should:
        - Help clarify their approach
        - Surface important decisions
        - Guide their thinking
        - Be 3-5 questions
        - Mix multiple choice and free text

        Return ONLY valid JSON:
        {
          "title": "Short questionnaire title",
          "questions": [
            {"question": "Question text?", "options": ["Option 1", "Option 2"]},
            {"question": "Free text question?", "options": null}
          ]
        }
        """

        let userPrompt = """
        TASK: \(task.title)
        Description: \(task.taskDescription ?? "No description")
        Outcome Goal: \(task.outcomeGoal)
        Goal Context: \(goalContext)

        Generate a questionnaire to help the user think through this task.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1000,
            requireJSON: true
        )

        struct QuestionnaireResponse: Codable {
            let title: String
            let questions: [QuestionData]

            struct QuestionData: Codable {
                let question: String
                let options: [String]?
            }
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(QuestionnaireResponse.self, from: data)

        let brainstormQuestions = response.questions.map { q in
            BrainstormQuestion(question: q.question, options: q.options)
        }

        return AIQuestionnaire(
            taskId: task.id,
            title: response.title,
            questions: brainstormQuestions
        )
    }

    // MARK: - AI Assistant for Task Help

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

        return try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300
        )
    }

    // MARK: - Generate Checklist Items for Tasks

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

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 500,
            requireJSON: true
        )

        struct ChecklistResponse: Codable {
            let checklist: [GeneratedChecklistItem]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
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

    // MARK: - AI Personality Messages

    func getPersonalizedMessage(
        event: MessageEvent,
        personality: AIPersonality,
        context: String? = nil
    ) async throws -> String {
        let personalityDescription: String
        switch personality {
        case .energetic:
            personalityDescription = "energetic, enthusiastic, very encouraging"
        case .calm:
            personalityDescription = "calm, mindful, focused, gentle and steady"
        case .direct:
            personalityDescription = "direct, no-nonsense, brief, to the point"
        case .motivational:
            personalityDescription = "motivational, inspiring, like a champion coach"
        }

        let systemPrompt = """
        You are Momentum's AI coach with a \(personalityDescription) personality.
        Generate a brief message (1-2 sentences max) for the following event.
        Keep it authentic to your personality style.
        """

        let userPrompt = """
        Event: \(event.rawValue)
        \(context.map { "Context: \($0)" } ?? "")

        Generate an appropriate message.
        """

        return try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.8,
            maxTokens: 100
        )
    }

    // MARK: - Enhanced AI Companion Methods

    /// Analyze user message intent to determine if it's a research request, help question, or brainstorming
    func analyzeMessageIntent(
        message: String,
        taskContext: String
    ) async throws -> MessageIntent {
        let systemPrompt = """
        Analyze the user's message and determine their intent.

        Categories:
        - researchRequest: User wants you to look up information, find data, or investigate something
        - taskHelp: User needs advice, guidance, or explanation about how to do the task
        - brainstorming: User wants to ideate, explore options, or think through approaches
        - statusUpdate: User is sharing progress or asking "what's next"

        Respond with ONLY the category name, nothing else.
        """

        let userPrompt = """
        Task Context: \(taskContext)

        User Message: "\(message)"

        Intent:
        """

        let response = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.3,
            maxTokens: 10
        )

        return MessageIntent(rawValue: response.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .taskHelp
    }

    /// Generate 2-3 clarifying questions to help focus a research request
    func generateResearchClarifications(
        query: String,
        taskContext: String,
        taskTitle: String
    ) async throws -> [String] {
        let systemPrompt = """
        Generate 2-3 clarifying questions to help focus a research request.

        Questions should:
        - Be specific and actionable
        - Help narrow the scope
        - Relate to the user's task context
        - Avoid yes/no questions

        Return ONLY valid JSON:
        {
          "questions": ["Question 1?", "Question 2?", "Question 3?"]
        }
        """

        let userPrompt = """
        Task: \(taskTitle)
        Context: \(taskContext)

        Research Request: "\(query)"

        Generate 2-3 clarifying questions to make this research more effective.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            requireJSON: true
        )

        struct QuestionsResponse: Codable {
            let questions: [String]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let response = try JSONDecoder().decode(QuestionsResponse.self, from: data)
            return response.questions
        } catch {
            throw GroqError.decodingError(error.localizedDescription)
        }
    }

    /// Synthesize web search results into a clear, actionable summary
    func synthesizeResearchResults(
        query: String,
        clarifications: [QAPair],
        rawSearchResults: String,
        taskContext: String
    ) async throws -> String {
        let systemPrompt = """
        You are synthesizing web search results into a clear, actionable summary for a user working on a specific task.

        Output Format:
        - Start with 1-2 sentence executive summary
        - Key findings (3-5 bullet points)
        - Specific recommendations relevant to their task
        - Sources (mention where the information came from)

        Tone: Helpful and concise. Focus on actionable insights.

        CRITICAL: Only include information actually present in the search results. Do not hallucinate or add external knowledge. If results are insufficient, say so clearly.
        """

        let clarificationsText = clarifications.map { "Q: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n")

        let userPrompt = """
        Original Query: \(query)

        Clarifying Q&A:
        \(clarificationsText)

        Task Context: \(taskContext)

        Web Search Results:
        \(rawSearchResults)

        Synthesize these results into an actionable summary for the user.
        """

        return try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 800
        )
    }

    /// Perform browser search using Groq's built-in browser_search tool
    func performBrowserSearch(
        query: String,
        clarifications: [QAPair],
        taskContext: String,
        taskTitle: String
    ) async throws -> String {
        let systemPrompt = """
        You are Momentum's AI companion performing research for a user working on a specific task.

        Use the browser_search tool to find relevant information, then synthesize it into a clear, actionable summary.

        Output Format:
        - Start with 1-2 sentence executive summary
        - Key findings (3-5 bullet points with specific data/facts)
        - Specific recommendations relevant to their task
        - Sources (include URLs where possible)

        Tone: Helpful, competent, friendly. Focus on actionable insights.
        """

        let clarificationsText = clarifications.isEmpty
            ? "No additional clarifications provided."
            : clarifications.map { "Q: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n")

        let userPrompt = """
        Research Request: \(query)

        Clarifying Details:
        \(clarificationsText)

        Task Context: Working on "\(taskTitle)" - \(taskContext)

        Please search for relevant information and provide a comprehensive summary with actionable insights.
        """

        // Use gpt-oss-120b model with browser_search tool
        let groqRequest = GroqRequest(
            model: "openai/gpt-oss-120b",
            messages: [
                GroqRequest.Message(role: "system", content: systemPrompt),
                GroqRequest.Message(role: "user", content: userPrompt)
            ],
            temperature: 0.7,
            maxTokens: 1200,
            responseFormat: nil,
            tools: [GroqRequest.Tool(type: "browser_search")]
        )

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw GroqError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(groqRequest)

        print("Making browser search request...")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }

        print("Browser search HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("Browser search error: \(errorMessage)")
                throw GroqError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            } else {
                throw GroqError.apiError("HTTP \(httpResponse.statusCode)")
            }
        }

        let decoder = JSONDecoder()
        let groqResponse = try decoder.decode(GroqResponse.self, from: data)

        guard let firstChoice = groqResponse.choices.first else {
            throw GroqError.invalidResponse
        }

        print("Browser search completed")
        return firstChoice.message.content
    }

    // MARK: - Generate Tool Prompt (Legacy)

    func generateToolPrompt(
        tool: String,
        context: String,
        goal: String
    ) async throws -> AIWorkResult {
        let systemPrompt = """
        Generate a detailed prompt that a user can copy-paste into \(tool) to accomplish their goal.

        The prompt should:
        - Be specific and detailed
        - Include all relevant context
        - Be formatted properly for the tool
        - Include any necessary instructions

        Return ONLY valid JSON:
        {
          "summary": "Brief description of what the prompt does",
          "details": "Why this approach works",
          "toolName": "\(tool)",
          "prompt": "The full prompt to copy"
        }
        """

        let userPrompt = """
        Tool: \(tool)
        Goal: \(goal)
        Context: \(context)

        Generate a comprehensive prompt for this tool.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1500,
            requireJSON: true
        )

        struct ToolPromptResponse: Codable {
            let summary: String
            let details: String?
            let toolName: String
            let prompt: String
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(ToolPromptResponse.self, from: data)

        return AIWorkResult(
            summary: response.summary,
            details: response.details,
            toolName: response.toolName,
            prompt: response.prompt
        )
    }

    /// Generate a tiered research report
    func generateResearchReport(
        query: String,
        context: String
    ) async throws -> AIWorkResult {
        let systemPrompt = """
        Generate a research summary with tiered depth:
        1. Summary: 1-2 sentence executive summary
        2. Details: Key findings and analysis
        3. Sources: Where the information came from

        Return ONLY valid JSON:
        {
          "summary": "Brief executive summary",
          "details": "Detailed findings and analysis",
          "sources": ["Source 1", "Source 2"]
        }
        """

        let userPrompt = """
        Research Query: \(query)
        Context: \(context)

        Provide a tiered research report.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1200,
            requireJSON: true
        )

        struct ResearchResponse: Codable {
            let summary: String
            let details: String
            let sources: [String]?
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(ResearchResponse.self, from: data)

        return AIWorkResult(
            summary: response.summary,
            details: response.details,
            sources: response.sources
        )
    }
}

// MARK: - Message Intent Types

enum MessageIntent: String {
    case researchRequest
    case taskHelp
    case brainstorming
    case statusUpdate
}

// MARK: - Message Event Types

enum MessageEvent: String {
    case taskCompleted = "User completed a task"
    case allTasksCompleted = "User completed all daily tasks"
    case streakMilestone = "User reached a streak milestone"
    case weekCompleted = "User completed a full week"
    case goalProgress = "User made significant progress on their goal"
    case encouragement = "User needs encouragement to keep going"
    case morningMotivation = "Start of day motivation"
}
