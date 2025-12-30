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
    }

    // MARK: - Groq API Request/Response Models

    private struct GroqRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int?
        let responseFormat: ResponseFormat?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
            case responseFormat = "response_format"
        }

        struct Message: Codable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Codable {
            let type: String // "json_object" for JSON mode
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
        requireJSON: Bool = false
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw GroqError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = [
            GroqRequest.Message(role: "system", content: systemPrompt),
            GroqRequest.Message(role: "user", content: userPrompt)
        ]

        let groqRequest = GroqRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: requireJSON ? GroqRequest.ResponseFormat(type: "json_object") : nil
        )

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(groqRequest)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GroqError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    throw GroqError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                }
                throw GroqError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let groqResponse = try decoder.decode(GroqResponse.self, from: data)

            guard let content = groqResponse.choices.first?.message.content else {
                throw GroqError.invalidResponse
            }

            return content

        } catch let error as GroqError {
            throw error
        } catch {
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
        answers: OnboardingAnswers
    ) async throws -> AIGeneratedPlan {
        let systemPrompt = """
        You are Momentum's AI coach. Generate a structured goal achievement plan using the Dan Martell framework combined with James Clear's 1% improvement philosophy.

        Framework:
        1. North Star Vision - One SMART annual goal (refined from user's vision)
        2. 12 Power Goals - Monthly projects that build toward the vision
        3. Weekly Milestones - 5 concrete outcomes per Power Goal
        4. Daily Tasks - 3 tasks per day (easy anchor task, medium progress task, challenging stretch task)

        Task Difficulty Balance:
        - EASY (15 min): Consistent anchor task that doesn't change much
        - MEDIUM (30 min): Meaningful progress on the goal
        - HARD (45 min): Stretching challenge that's still achievable

        Be encouraging, specific, and action-oriented. Use the user's experience level and available time to create realistic, achievable tasks.

        Return ONLY valid JSON matching this exact structure:
        {
          "vision_refined": "SMART version of the user's vision",
          "power_goals": [
            {"month": 1, "goal": "Title", "description": "What this achieves"}
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
        """

        let userPrompt = """
        Vision: "\(visionText)"

        User Background:
        - Experience Level: \(answers.experienceLevel.isEmpty ? "Not specified" : answers.experienceLevel)
        - Weekly Time Available: \(answers.weeklyHours.isEmpty ? "Not specified" : answers.weeklyHours)
        - Target Timeline: \(answers.timeline.isEmpty ? "1 year" : answers.timeline)
        - Main Concern: \(answers.biggestConcern.isEmpty ? "Getting started" : answers.biggestConcern)
        - Passions/Interests: \(answers.passions.isEmpty ? "Not specified" : answers.passions)

        Generate a complete, personalized action plan that transforms this vision into daily tasks.
        """

        let responseText = try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 4000,
            requireJSON: true
        )

        // Parse JSON response
        guard let data = responseText.data(using: .utf8) else {
            throw GroqError.decodingError("Could not convert response to data")
        }

        do {
            let decoder = JSONDecoder()
            let plan = try decoder.decode(AIGeneratedPlan.self, from: data)
            return plan
        } catch {
            print("Decoding error: \(error)")
            print("Response text: \(responseText)")
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
