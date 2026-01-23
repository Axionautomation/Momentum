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

    private init() {
        self.apiKey = Config.groqAPIKey
        self.baseURL = Config.groqAPIBaseURL
        self.model = Config.groqModel
        self.session = createSession()
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

    private var session: URLSession!

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

        let delegate = HTTP1Delegate()
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }


    private class HTTP1Delegate: NSObject, URLSessionTaskDelegate, URLSessionDelegate, @unchecked Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
            if let transaction = metrics.transactionMetrics.first {
                let protocolName = transaction.networkProtocolName ?? "unknown"
                print("🌐 Connection protocol: \(protocolName)")

                if protocolName == "h3" {
                    print("⚠️ WARNING: HTTP/3 still detected - may need AsyncHTTPClient fallback")
                } else if protocolName == "h2" {
                    print("✅ Using HTTP/2 - optimal performance")
                } else if protocolName.starts(with: "http/1") {
                    print("✅ Using HTTP/1.x - connection stable")
                }
            }
        }

        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            if let error = error {
                print("❌ URLSession became invalid: \(error)")
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
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        // CRITICAL: Explicitly disable HTTP/3 to avoid QUIC connection errors
        request.assumesHTTP3Capable = false

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
            tools: nil  // No tools for standard requests
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(groqRequest)

        print("📡 Making Groq API request (Attempt \(retryCount + 1))...")
        
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw GroqError.invalidResponse
            }

            print("📊 HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                // If 5xx error or 429, maybe retry
                if (500...599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429 {
                    if retryCount < 3 {
                        print("⚠️ Server error, retrying in \(Double(retryCount + 1) * 2)s...")
                        try await Task.sleep(nanoseconds: UInt64(Double(retryCount + 1) * 2 * 1_000_000_000))
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
                    print("❌ API Error: \(errorString)")
                    throw GroqError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                }
                throw GroqError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let groqResponse = try decoder.decode(GroqResponse.self, from: data)

            guard let content = groqResponse.choices.first?.message.content else {
                print("❌ No content in response")
                throw GroqError.invalidResponse
            }

            print("✅ Received response (\(content.count) characters)")
            return content
            
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                let retryableCodes = [-1001, -1004, -1005, -1009, -1020]
                if retryableCodes.contains(nsError.code) && retryCount < 3 {
                    // Standard exponential backoff: 2s, 4s, 8s
                    let delay = Double(pow(2.0, Double(retryCount + 1)))
                    print("⚠️ Network error (\(nsError.code): \(nsError.localizedDescription)), retrying in \(delay)s...")

                    // -1005 should be extremely rare now
                    if nsError.code == -1005 {
                        print("⚠️ Unexpected -1005 with HTTP/3 disabled - network instability")
                    }

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
            print("❌ Request failed: \(error.localizedDescription)")
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
        - Available time commitment
        - Timeline expectations
        - Main challenges or concerns

        For identity-based visions (e.g., "Become an entrepreneur"), ask about:
        - Specific interests or passions
        - What this identity means to them
        - Any concrete goals this leads to
        - What's holding them back

        IMPORTANT:
        - Make questions specific to their exact vision domain
        - For multiple choice, provide 3-4 specific options
        - Set "allowsTextInput" to true if you want to also allow custom text input
        - DO NOT include "Other (please specify)" as an option - use allowsTextInput instead
        - Keep options concise and relevant

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

    // MARK: - Generate Complete Goal Plan

    func generateGoalPlan(
        visionText: String,
        goalType: GoalType = .project,
        answers: OnboardingAnswers
    ) async throws -> AIGoalPlanResponse {
        switch goalType {
        case .project:
            let plan = try await generateProjectPlan(visionText: visionText, answers: answers)
            return .project(plan)
        case .habit:
            let plan = try await generateHabitPlan(visionText: visionText, answers: answers)
            return .habit(plan)
        case .identity:
            let plan = try await generateIdentityPlan(visionText: visionText, answers: answers)
            return .identity(plan)
        }
    }

    // MARK: - Project Plan Generation

    private func generateProjectPlan(
        visionText: String,
        answers: OnboardingAnswers
    ) async throws -> AIGeneratedPlan {
        let systemPrompt = """
        You are Momentum's AI coach. Generate a HYPER-PERSONALIZED goal achievement plan using the Dan Martell framework combined with James Clear's 1% improvement philosophy.

        CRITICAL: The plan MUST be 100% specific to the user's EXACT vision. DO NOT use generic examples or templates.

        Framework:
        1. North Star Vision - One SMART annual goal (refined from user's vision)
        2. 12 Power Goals - Monthly projects that build toward the vision
        3. Weekly Milestones - 5 concrete outcomes per Power Goal
        4. Daily Tasks - 3 tasks per day (easy anchor task, medium progress task, challenging stretch task)

        Task Difficulty Balance:
        - EASY (15 min): Consistent anchor task that doesn't change much
        - MEDIUM (30 min): Meaningful progress on the goal
        - HARD (45 min): Stretching challenge that's still achievable

        PERSONALIZATION REQUIREMENTS:
        - Every task must directly relate to their SPECIFIC vision
        - Use their exact context (experience level, time available, concerns)
        - Make tasks actionable with specific details (not "research competitors" but "research 3 [specific type] competitors in [specific niche]")
        - Reference their actual timeline and adjust pace accordingly

        Be encouraging, specific, and action-oriented. Use the user's experience level and available time to create realistic, achievable tasks.

        CRITICAL JSON FORMATTING RULES:
        - Return ONLY valid JSON with NO additional text
        - Ensure all brackets and braces are properly closed
        - Use double quotes for all keys and string values
        - No trailing commas
        - The anchor_task field is a simple string at the root level

        Return ONLY valid JSON matching this EXACT structure:
        {
          "vision_refined": "SMART version of the user's vision",
          "power_goals": [
            {"month": 1, "goal": "Title", "description": "What this achieves"},
            {"month": 2, "goal": "Title", "description": "What this achieves"}
          ],
          "current_power_goal": {
            "goal": "Month 1 title",
            "weekly_milestones": [
              {
                "week": 1,
                "milestone": "What to achieve this week",
                "daily_tasks": [
                  {
                    "day": 1,
                    "tasks": [
                      {
                        "title": "Task name",
                        "difficulty": "easy",
                        "estimated_minutes": 15,
                        "description": "What to do and why"
                      }
                    ]
                  }
                ]
              }
            ]
          },
          "anchor_task": "The consistent daily task"
        }

        Generate all 12 Power Goals, and for Power Goal #1, create 5 weekly milestones with 21 daily tasks (3 per day for 7 days).

        VERIFY: Before returning, ensure your JSON is valid and properly closed.
        """

        let userPrompt = """
        USER'S SPECIFIC VISION: "\(visionText)"

        USER CONTEXT:
        - Experience Level: \(answers.experienceLevel.isEmpty ? "Not specified" : answers.experienceLevel)
        - Weekly Time Available: \(answers.weeklyHours.isEmpty ? "Not specified" : answers.weeklyHours)
        - Target Timeline: \(answers.timeline.isEmpty ? "1 year" : answers.timeline)
        - Main Concern: \(answers.biggestConcern.isEmpty ? "Getting started" : answers.biggestConcern)
        - Passions/Interests: \(answers.passions.isEmpty ? "Not specified" : answers.passions)
        - Additional Context: \(answers.identityMeaning.isEmpty ? "Not specified" : answers.identityMeaning)

        CRITICAL INSTRUCTIONS:
        1. Read the vision carefully - this is about "\(visionText)", NOT about consulting or business unless explicitly stated
        2. Every single task must be 100% relevant to THIS SPECIFIC vision
        3. Use concrete, actionable language specific to their domain
        4. Adjust task complexity based on their experience level
        5. Fit the pace to their available time and timeline

        Generate a complete, HYPER-PERSONALIZED action plan that transforms THIS EXACT vision into daily tasks.
        DO NOT use generic templates or examples from other domains.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 4000,
            requireJSON: true
        )

        // Clean up the JSON response (fix common AI formatting errors)
        var cleanedJSON = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fix common malformed JSON patterns from AI
        // Fix: "anchor_task",":", "value"] -> "anchor_task": "value"
        cleanedJSON = cleanedJSON.replacingOccurrences(
            of: "\"anchor_task\"\\s*,\\s*\":\"\\s*,\\s*\"([^\"]+)\"\\s*\\]",
            with: "\"anchor_task\": \"$1\"",
            options: .regularExpression
        )

        // Fix: "anchor_task",":", -> "anchor_task":
        cleanedJSON = cleanedJSON.replacingOccurrences(of: "\"anchor_task\",\":\",", with: "\"anchor_task\":")
        cleanedJSON = cleanedJSON.replacingOccurrences(of: "\"anchor_task\", \":\",", with: "\"anchor_task\":")
        cleanedJSON = cleanedJSON.replacingOccurrences(of: "\"anchor_task\" , \":\" ,", with: "\"anchor_task\":")

        // Remove any trailing commas before closing brackets
        cleanedJSON = cleanedJSON.replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
        cleanedJSON = cleanedJSON.replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)

        // Ensure proper closing: }}} should be }}
        cleanedJSON = cleanedJSON.replacingOccurrences(of: "}}}", with: "}}")

        // Fix missing closing brace if needed
        let openBraces = cleanedJSON.filter { $0 == "{" }.count
        let closeBraces = cleanedJSON.filter { $0 == "}" }.count
        if openBraces > closeBraces {
            cleanedJSON += String(repeating: "}", count: openBraces - closeBraces)
        }

        // Parse JSON response
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

    // MARK: - Habit Plan Generation

    private func generateHabitPlan(
        visionText: String,
        answers: OnboardingAnswers
    ) async throws -> AIGeneratedHabitPlan {
        let systemPrompt = """
        You are Momentum's AI coach. Generate a simple, focused habit-building plan.

        A habit goal is a SINGLE recurring action done daily (or on a schedule). Examples:
        - "Meditate 10 minutes daily"
        - "Read for 30 minutes every evening"
        - "Practice piano 30 minutes daily"

        Return ONLY valid JSON in this EXACT format:
        {
          "vision_refined": "Clear, specific habit description",
          "frequency": "daily" | "weekdays" | "weekends",
          "habit_description": "What exactly to do and when",
          "weekly_goal": 7,
          "milestones": [
            {"streak": 7, "title": "First Week Complete"},
            {"streak": 30, "title": "One Month Strong"},
            {"streak": 100, "title": "100 Day Champion"}
          ]
        }

        Keep it simple and achievable. Focus on consistency over complexity.
        """

        let userPrompt = """
        USER'S HABIT VISION: "\(visionText)"

        USER CONTEXT:
        - Experience Level: \(answers.experienceLevel.isEmpty ? "Beginner" : answers.experienceLevel)
        - Weekly Time Available: \(answers.weeklyHours.isEmpty ? "30 minutes daily" : answers.weeklyHours)

        Generate a habit plan focused on building consistency with this specific habit.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 800,
            requireJSON: true
        )

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let plan = try decoder.decode(AIGeneratedHabitPlan.self, from: data)
            return plan
        } catch {
            print("Decoding error: \(error)")
            print("Response: \(responseText)")
            throw GroqError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Identity Plan Generation

    private func generateIdentityPlan(
        visionText: String,
        answers: OnboardingAnswers
    ) async throws -> AIGeneratedIdentityPlan {
        let systemPrompt = """
        You are Momentum's AI coach. Generate an identity-based goal plan.

        Identity goals are about BECOMING someone, not just achieving something.

        COMPLEXITY DETECTION:
        - SIMPLE (is_complex: false): Single recurring action to embody the identity
          Examples: "Become a reader" (read daily), "Become a pianist" (practice daily)
        - COMPLEX (is_complex: true): Multi-faceted identity requiring various actions
          Examples: "Become an entrepreneur" (needs product, marketing, sales, etc.)

        Return ONLY valid JSON in this EXACT format:
        {
          "vision_refined": "Clear identity goal",
          "identity_statement": "I am a [identity]",
          "is_complex": true | false,
          "evidence_categories": ["Practice", "Performance", "Learning"],
          "milestones": [
            {"title": "First public performance", "category": "Performance"},
            {"title": "10 hours of practice", "category": "Practice"}
          ],
          "daily_task_description": "What to do daily to build this identity"
        }

        For SIMPLE identities, focus on the daily evidence collection.
        For COMPLEX identities, suggest varied evidence categories.
        """

        let userPrompt = """
        USER'S IDENTITY VISION: "\(visionText)"

        USER CONTEXT:
        - Experience Level: \(answers.experienceLevel.isEmpty ? "Beginner" : answers.experienceLevel)
        - Passions: \(answers.passions.isEmpty ? "Not specified" : answers.passions)
        - What this identity means to them: \(answers.identityMeaning.isEmpty ? "Not specified" : answers.identityMeaning)

        Generate an identity plan with appropriate complexity level.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1000,
            requireJSON: true
        )

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let plan = try decoder.decode(AIGeneratedIdentityPlan.self, from: data)
            return plan
        } catch {
            print("Decoding error: \(error)")
            print("Response: \(responseText)")
            throw GroqError.decodingError(error.localizedDescription)
        }
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

    // MARK: - Generate Microsteps for Tasks

    func generateMicrosteps(
        taskTitle: String,
        taskDescription: String?,
        difficulty: TaskDifficulty
    ) async throws -> [String] {
        let systemPrompt = """
        You are Momentum's AI coach. Break down a task into 3-5 specific microsteps that make it easy to start and complete.

        Each microstep should be:
        - A single, concrete action
        - Something that takes 5-15 minutes
        - Clear and specific (no vague advice)

        Return ONLY valid JSON in this format:
        {
          "microsteps": ["First specific action", "Second specific action", ...]
        }
        """

        let taskInfo = taskDescription ?? taskTitle
        let userPrompt = """
        Task: \(taskTitle)
        Description: \(taskInfo)
        Difficulty: \(difficulty.displayName)

        Break this into 3-5 specific, actionable microsteps.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 500,
            requireJSON: true
        )

        struct MicrostepsResponse: Codable {
            let microsteps: [String]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MicrostepsResponse.self, from: data)
            return response.microsteps
        } catch {
            throw GroqError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Generate Enhanced Task Details

    func generateTaskDetails(
        task: MomentumTask,
        context: String
    ) async throws -> EnhancedTaskDetails {
        let systemPrompt = """
        You are Momentum's AI coach. Generate detailed task information to help the user understand and complete this task effectively.

        Provide:
        1. Difficulty Explanation - Why this task is rated easy/medium/hard
        2. Time Breakdown - Suggest time allocation for each microstep
        3. Tips - 2-3 actionable tips specific to this task

        Return ONLY valid JSON in this format:
        {
          "difficultyExplanation": "Clear explanation of difficulty rating",
          "timeBreakdown": [
            {
              "microstep": "Step description",
              "estimatedMinutes": 10,
              "rationale": "Why this takes ~10 minutes"
            }
          ],
          "tips": ["Tip 1", "Tip 2", "Tip 3"]
        }
        """

        let microstepsText = task.microsteps.isEmpty
            ? "No microsteps yet"
            : task.microsteps.map { $0.stepText }.joined(separator: "\n")

        let userPrompt = """
        Task: \(task.title)
        Description: \(task.taskDescription ?? "No description")
        Difficulty: \(task.difficulty.displayName)
        Estimated Time: \(task.estimatedMinutes) minutes
        Goal Context: \(context)

        Microsteps:
        \(microstepsText)

        Generate detailed task information to help the user complete this task.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 800,
            requireJSON: true
        )

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let details = try decoder.decode(EnhancedTaskDetails.self, from: data)
            return details
        } catch {
            throw GroqError.decodingError(error.localizedDescription)
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
            personalityDescription = "energetic, enthusiastic, uses emojis, very encouraging"
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

        Examples:
        "can you research the best demographics for my app?" -> researchRequest
        "how should I structure my pitch deck?" -> taskHelp
        "what are some creative ways to market this?" -> brainstorming
        "I finished the research, what's next?" -> statusUpdate
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

        Example:
        "Based on your research on virtual try-on demographics:

        The primary market is women aged 18-35 who shop online frequently. Key insights:
        • 67% of online fashion shoppers want AR try-on features
        • Gen Z consumers (18-24) are 2x more likely to use virtual try-on
        • Main motivation is reducing returns (reported by 73% of users)

        Recommendations for your app:
        - Focus marketing on Instagram/TikTok where Gen Z fashion shoppers are active
        - Emphasize 'try before you buy' and return reduction in messaging
        - Consider starting with women's fashion accessories (highest adoption)

        Sources: McKinsey Fashion Technology Report, Shopify AR Commerce Study, RetailDive Consumer Survey"
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
    /// NOTE: Uses openai/gpt-oss-120b model (not llama) because browser_search tool
    /// is only available on specific models. Other methods use llama-3.3-70b-versatile.
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

        CRITICAL: Only include information from your search results. Do not hallucinate. If results are insufficient, clearly state what information is missing.
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
        let request = GroqRequest(
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

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("close", forHTTPHeaderField: "Connection")
        // CRITICAL: Explicitly disable HTTP/3 to avoid QUIC connection errors
        urlRequest.assumesHTTP3Capable = false

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        print("📡 Making browser search request...")
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorMessage = String(data: data, encoding: .utf8) {
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

        return firstChoice.message.content
    }

    // MARK: - Companion System Prompt

    /// System prompt for companion tone (helpful assistant, not motivational coach)
    private func companionSystemPrompt() -> String {
        """
        You are Momentum's AI companion - a maximally helpful research and planning assistant.

        Your role is to DO THINGS for the user, not just advise them:
        - When asked to research something, you ASK CLARIFYING QUESTIONS then PERFORM ACTUAL RESEARCH
        - When asked for help, you provide SPECIFIC, ACTIONABLE guidance
        - You are their partner in achieving goals, not a motivational poster

        Tone: Helpful, competent, friendly. Think "capable assistant" not "cheerleader coach"

        Key behaviors:
        - Ask 2-3 specific questions to understand user's exact need
        - Do the research/thinking work for them
        - Present findings clearly with sources
        - Offer next steps
        """
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
    case allTasksCompleted = "User completed all 3 daily tasks"
    case streakMilestone = "User reached a streak milestone"
    case weekCompleted = "User completed a full week"
    case goalProgress = "User made significant progress on their goal"
    case encouragement = "User needs encouragement to keep going"
    case morningMotivation = "Start of day motivation"
}
