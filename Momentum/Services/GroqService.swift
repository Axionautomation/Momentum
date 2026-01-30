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
                print("🌐 Protocol: \(protocolName) | Duration: \(duration)s")
            }
        }

        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            if let error = error {
                print("❌ URLSession invalidated: \(error.localizedDescription)")
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

        print("📡 Making Groq API request (Attempt \(retryCount + 1))...")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw GroqError.invalidResponse
            }

            print("📊 HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                // Retry on server errors or rate limiting
                if (500...599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429 {
                    if retryCount < 3 {
                        let delay = Double(retryCount + 1) * 2
                        print("⚠️ Server error \(httpResponse.statusCode), retrying in \(delay)s...")
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

        } catch let error as GroqError {
            throw error
        } catch {
            let nsError = error as NSError
            // Retry on common network errors
            let retryableCodes = [-1001, -1004, -1005, -1009, -1020]
            if nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code) && retryCount < 3 {
                let delay = pow(2.0, Double(retryCount + 1))
                print("⚠️ Network error (\(nsError.code)), retrying in \(delay)s...")
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

    // MARK: - Project Plan Generation

    func generateProjectPlan(
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

        print("📡 Making browser search request...")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }

        print("📊 Browser search HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("❌ Browser search error: \(errorMessage)")
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

        print("✅ Browser search completed")
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

    // MARK: - AI Task Analysis

    /// Analyze a task to determine what AI can do autonomously
    func analyzeTaskForAI(
        task: MomentumTask,
        goalContext: String
    ) async throws -> TaskAIAnalysis {
        let systemPrompt = """
        You are an AI project manager. Analyze this task and determine:
        1. What type of completion this task requires
        2. What parts AI can handle autonomously
        3. What the user must do themselves
        4. What decisions need user input
        5. What research topics would help

        Completion types:
        - manual: User must do entirely themselves (e.g., physical tasks, meetings)
        - aiAssisted: AI can help with parts but user completes (e.g., writing, coding)
        - requiresInput: Needs user decisions before AI can act (e.g., strategic choices)
        - aiAutonomous: AI can complete entirely (e.g., research, data gathering)

        Return ONLY valid JSON in this format:
        {
          "completionType": "aiAssisted",
          "aiCanDo": ["Research competitors", "Draft initial outline"],
          "userMustDo": ["Review and approve", "Make final decisions"],
          "questionsNeeded": [
            {
              "question": "What's your target audience?",
              "options": [
                {"label": "B2B Enterprise", "description": "Large companies"},
                {"label": "B2B SMB", "description": "Small businesses"},
                {"label": "B2C", "description": "Direct consumers"}
              ],
              "priority": "blocking"
            }
          ],
          "researchNeeded": ["Market size data", "Competitor analysis"]
        }
        """

        let userPrompt = """
        Task: \(task.title)
        Description: \(task.taskDescription ?? "No description")
        Difficulty: \(task.difficulty.displayName)
        Goal Context: \(goalContext)

        Analyze what AI can do for this task vs what the user must do.
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
            let analysis = try decoder.decode(TaskAIAnalysis.self, from: data)
            return analysis
        } catch {
            throw GroqError.decodingError(error.localizedDescription)
        }
    }

    /// Generate AI questions for user decisions
    func generateDecisionQuestions(
        context: String,
        topic: String
    ) async throws -> [AIQuestion] {
        let systemPrompt = """
        Generate 2-4 decision questions to help clarify user intent for an AI to act autonomously.
        Each question should:
        - Be specific and actionable
        - Have 2-4 clear options
        - Help the AI understand what the user wants

        Return ONLY valid JSON:
        {
          "questions": [
            {
              "question": "The question text?",
              "options": [
                {"label": "Option 1", "description": "What this means"},
                {"label": "Option 2", "description": "What this means"}
              ],
              "priority": "important"
            }
          ]
        }
        """

        let userPrompt = """
        Context: \(context)
        Topic: \(topic)

        Generate decision questions to clarify user preferences.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 800,
            requireJSON: true
        )

        struct QuestionsResponse: Codable {
            struct QuestionData: Codable {
                let question: String
                let options: [OptionData]
                let priority: String
            }
            struct OptionData: Codable {
                let label: String
                let description: String?
            }
            let questions: [QuestionData]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(QuestionsResponse.self, from: data)

        return response.questions.map { q in
            AIQuestion(
                goalId: UUID(), // Will be set by caller
                question: q.question,
                options: q.options.map { QuestionOption(label: $0.label, description: $0.description) },
                priority: QuestionPriority(rawValue: q.priority) ?? .important
            )
        }
    }

    /// Generate a tool prompt for external tools
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
    case allTasksCompleted = "User completed all 3 daily tasks"
    case streakMilestone = "User reached a streak milestone"
    case weekCompleted = "User completed a full week"
    case goalProgress = "User made significant progress on their goal"
    case encouragement = "User needs encouragement to keep going"
    case morningMotivation = "Start of day motivation"
}
