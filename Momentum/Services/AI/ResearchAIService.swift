//
//  ResearchAIService.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Handles research queries, synthesis, and browser search via AIServiceRouter.
//

import Foundation
import Combine

@MainActor
class ResearchAIService: ObservableObject {
    static let shared = ResearchAIService()

    private let router = AIServiceRouter.shared

    private init() {}

    // MARK: - Generate Research Clarifications

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

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 300,
            requireJSON: true,
            preferredTier: .fast
        )

        struct QuestionsResponse: Codable {
            let questions: [String]
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        return try JSONDecoder().decode(QuestionsResponse.self, from: data).questions
    }

    // MARK: - Synthesize Research Results

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

        // Synthesis benefits from more capable models
        return try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 800,
            preferredTier: .standard
        )
    }

    // MARK: - Generate Research Report

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

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1200,
            requireJSON: true,
            preferredTier: .standard
        )

        struct ResearchResponse: Codable {
            let summary: String
            let details: String
            let sources: [String]?
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(ResearchResponse.self, from: data)

        return AIWorkResult(
            summary: response.summary,
            details: response.details,
            sources: response.sources
        )
    }

    // MARK: - Analyze Task for AI Processing

    func analyzeTaskForAI(
        task: MomentumTask,
        goalContext: String
    ) async throws -> AITaskAnalysis {
        let systemPrompt = """
        Analyze this task to determine:
        1. What questions need to be asked to proceed
        2. What research is needed
        3. Whether AI can proceed without more information

        Return ONLY valid JSON:
        {
          "questions_needed": [
            {
              "question": "The question text",
              "options": [{"label": "Option 1"}, {"label": "Option 2"}],
              "allows_custom_input": true,
              "priority": "important"
            }
          ],
          "research_needed": ["Research topic 1", "Research topic 2"],
          "can_proceed": true
        }
        """

        let userPrompt = """
        Task: \(task.title)
        Description: \(task.taskDescription ?? "No description")
        Goal Context: \(goalContext)

        Analyze what's needed to complete this task.
        """

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 1000,
            requireJSON: true,
            preferredTier: .fast
        )

        struct AnalysisResponse: Codable {
            let questions_needed: [QuestionData]?
            let research_needed: [String]?
            let can_proceed: Bool

            struct QuestionData: Codable {
                let question: String
                let options: [OptionData]?
                let allows_custom_input: Bool?
                let priority: String?

                struct OptionData: Codable {
                    let label: String
                }
            }
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(AnalysisResponse.self, from: data)

        let questions = (response.questions_needed ?? []).map { q in
            AIQuestion(
                taskId: task.id,
                goalId: task.goalId,
                question: q.question,
                options: (q.options ?? []).map { QuestionOption(label: $0.label) },
                allowsCustomInput: q.allows_custom_input ?? false,
                priority: QuestionPriority(rawValue: q.priority ?? "important") ?? .important
            )
        }

        return AITaskAnalysis(
            questionsNeeded: questions,
            researchNeeded: response.research_needed ?? [],
            canProceed: response.can_proceed
        )
    }
}
