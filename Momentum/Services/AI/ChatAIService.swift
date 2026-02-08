//
//  ChatAIService.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Handles chat completions, message analysis, and personality messages via AIServiceRouter.
//

import Foundation
import Combine

@MainActor
class ChatAIService: ObservableObject {
    static let shared = ChatAIService()

    private let router = AIServiceRouter.shared

    private init() {}

    // MARK: - Analyze Message Intent

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

        let response = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.3,
            maxTokens: 10,
            preferredTier: .fast
        )

        return MessageIntent(rawValue: response.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .taskHelp
    }

    // MARK: - Personality Messages

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

        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.8,
            maxTokens: 100,
            preferredTier: .fast
        )
    }

    // MARK: - Morning Briefing

    func generateMorningBriefing(
        goalVision: String,
        milestoneName: String,
        milestoneProgress: Double,
        todayTaskTitles: [String],
        yesterdayCompletedCount: Int,
        streakCount: Int,
        personality: AIPersonality
    ) async throws -> GroqService.BriefingContent {
        let personalityStyle: String
        switch personality {
        case .energetic:
            personalityStyle = "energetic and enthusiastic"
        case .calm:
            personalityStyle = "calm and thoughtful"
        case .direct:
            personalityStyle = "direct and concise"
        case .motivational:
            personalityStyle = "inspiring and motivational"
        }

        let systemPrompt = """
        You are Momentum's AI coworker generating a morning briefing. Your tone is \(personalityStyle).

        Generate TWO things:
        1. "insight" — A personalized 1-2 sentence observation about the user's progress, momentum, or a strategic tip for today. Reference their specific goal or milestone when possible. Be specific, not generic.
        2. "focus_area" — A short phrase (3-8 words) recommending what to focus on today based on their tasks and progress.

        Return ONLY valid JSON:
        {
          "insight": "Your insight here",
          "focus_area": "Your focus recommendation"
        }
        """

        let taskList = todayTaskTitles.isEmpty ? "No tasks scheduled yet" : todayTaskTitles.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        let userPrompt = """
        Goal: \(goalVision)
        Current Milestone: \(milestoneName) (\(Int(milestoneProgress))% complete)
        Today's Tasks:
        \(taskList)
        Yesterday: \(yesterdayCompletedCount) tasks completed
        Current Streak: \(streakCount) days

        Generate the morning briefing.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.8,
            maxTokens: 200,
            requireJSON: true,
            preferredTier: .fast
        )

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert briefing response to data")
        }

        return try JSONDecoder().decode(GroqService.BriefingContent.self, from: data)
    }

    // MARK: - Streaming Chat (OpenAI)

    func streamChat(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 4096
    ) -> AsyncThrowingStream<String, Error>? {
        guard let openAIProvider = router.streamingProvider() else {
            return nil
        }
        return openAIProvider.stream(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }

    // MARK: - General Chat Completion

    func chatCompletion(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        preferComplex: Bool = false
    ) async throws -> String {
        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            preferredTier: preferComplex ? .premium : .fast
        )
    }

    // MARK: - Quiz Help Methods

    func getQuizOptionRecommendation(
        question: String,
        options: [String],
        skill: String,
        goalContext: String
    ) async throws -> String {
        let optionsText = options.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        let systemPrompt = """
        You are Momentum's helpful AI coach. The user is being asked a skill assessment question and wants guidance on which option to choose.

        Analyze the question and options, then provide:
        1. A brief recommendation for which option best fits most users starting out
        2. A helpful explanation of what each option means
        3. Encourage honest self-assessment

        Be warm, encouraging, and concise (3-5 sentences). Focus on helping them make the right choice for their situation.
        """

        let userPrompt = """
        SKILL BEING ASSESSED: \(skill)
        GOAL CONTEXT: \(goalContext)

        QUESTION: \(question)

        OPTIONS:
        \(optionsText)

        Help the user understand the options and guide them toward an honest answer.
        """

        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 400,
            preferredTier: .fast
        )
    }

    func getQuizHelpResponse(
        question: String,
        options: [String],
        skill: String,
        userMessage: String,
        previousMessages: [(role: String, content: String)],
        goalContext: String
    ) async throws -> String {
        let optionsText = options.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        let conversationContext = previousMessages.isEmpty
            ? "No previous messages."
            : previousMessages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")

        let systemPrompt = """
        You are Momentum's helpful AI coach. The user is deciding how to answer a skill assessment question and has a follow-up question.

        Context:
        - Skill: \(skill)
        - Question: \(question)
        - Options:
        \(optionsText)

        Be helpful, encouraging, and concise. Answer their question directly and help them make an informed choice.
        """

        let userPrompt = """
        PREVIOUS CONVERSATION:
        \(conversationContext)

        USER'S NEW MESSAGE: \(userMessage)

        Respond helpfully to guide their decision.
        """

        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            preferredTier: .fast
        )
    }

    func getOptionExplanation(
        question: String,
        selectedOption: String,
        allOptions: [String],
        skill: String,
        goalContext: String
    ) async throws -> String {
        let otherOptions = allOptions.filter { $0 != selectedOption }
        let otherOptionsText = otherOptions.joined(separator: ", ")

        let systemPrompt = """
        You are Momentum's helpful AI coach. The user is about to select an option for a skill assessment question. Explain what this choice means for them.

        Provide:
        1. What selecting this option indicates about their skill level
        2. How this will affect their personalized experience (task difficulty, AI assistance level)
        3. Reassurance that they can always update this later

        Be warm, encouraging, and concise (3-4 sentences). Help them feel confident in their choice.
        """

        let userPrompt = """
        SKILL: \(skill)
        QUESTION: \(question)
        SELECTED OPTION: "\(selectedOption)"
        OTHER OPTIONS WERE: \(otherOptionsText)
        GOAL CONTEXT: \(goalContext)

        Explain what choosing "\(selectedOption)" means for the user's experience.
        """

        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            preferredTier: .fast
        )
    }
}
