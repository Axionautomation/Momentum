//
//  OnboardingAIService.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Handles onboarding questions and goal plan generation via AIServiceRouter.
//

import Foundation
import Combine

@MainActor
class OnboardingAIService: ObservableObject {
    static let shared = OnboardingAIService()

    private let router = AIServiceRouter.shared

    private init() {}

    // MARK: - Generate Onboarding Questions

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

        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.8,
            maxTokens: 1500,
            requireJSON: true,
            preferredTier: .fast
        )

        struct QuestionsResponse: Codable {
            let questions: [QuestionData]

            struct QuestionData: Codable {
                let question: String
                let options: [String]?
                let allowsTextInput: Bool
            }
        }

        guard let data = responseText.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        let response = try JSONDecoder().decode(QuestionsResponse.self, from: data)

        return response.questions.map { questionData in
            OnboardingQuestion(
                question: questionData.question,
                options: questionData.options,
                allowsTextInput: questionData.allowsTextInput
            )
        }
    }

    // MARK: - Generate Goal Plan

    func generateProjectPlan(
        visionText: String,
        answers: OnboardingAnswers
    ) async throws -> AIGeneratedPlan {
        let weeklyMinutes = answers.weeklyHours * 60
        let availableDaysString = answers.availableDays.sorted().map { dayNumber -> String in
            let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days[dayNumber]
        }.joined(separator: ", ")
        let tasksPerWeek = answers.availableDays.count

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

        // Plan generation benefits from more capable models
        let responseText = try await router.complete(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: 0.7,
            maxTokens: 4000,
            requireJSON: true,
            preferredTier: .standard
        )

        // Clean up the JSON response
        var cleanedJSON = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedJSON = cleanedJSON.replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
        cleanedJSON = cleanedJSON.replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)

        let openBraces = cleanedJSON.filter { $0 == "{" }.count
        let closeBraces = cleanedJSON.filter { $0 == "}" }.count
        if openBraces > closeBraces {
            cleanedJSON += String(repeating: "}", count: openBraces - closeBraces)
        }

        guard let data = cleanedJSON.data(using: .utf8) else {
            throw AIError.decodingError("Could not convert response to data")
        }

        do {
            return try JSONDecoder().decode(AIGeneratedPlan.self, from: data)
        } catch {
            print("[OnboardingAIService] Decoding error: \(error)")
            throw AIError.decodingError(error.localizedDescription)
        }
    }
}
