//
//  QuizHelpViewModel.swift
//  Momentum
//
//  Created by Henry Bowman on 2/3/26.
//

import Foundation
import Combine

/// Chat message for the quiz help bubble
struct QuizHelpMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

@MainActor
class QuizHelpViewModel: ObservableObject {
    // MARK: - Published State

    @Published var messages: [QuizHelpMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var inputText: String = ""

    // MARK: - Question Context

    private var currentQuestion: SkillQuestion?
    private var goalContext: String = ""
    private let groqService = GroqService.shared

    // MARK: - Initialization

    func setup(question: SkillQuestion, goalContext: String) {
        self.currentQuestion = question
        self.goalContext = goalContext
        self.messages = []
        self.errorMessage = nil

        // Automatically fetch initial recommendation
        Task {
            await fetchInitialRecommendation()
        }
    }

    func reset() {
        currentQuestion = nil
        goalContext = ""
        messages = []
        errorMessage = nil
        inputText = ""
        isLoading = false
    }

    // MARK: - AI Interactions

    private func fetchInitialRecommendation() async {
        guard let question = currentQuestion else { return }

        isLoading = true
        errorMessage = nil

        do {
            let recommendation = try await groqService.getQuizOptionRecommendation(
                question: question.question,
                options: question.options,
                skill: question.skill,
                goalContext: goalContext
            )

            let assistantMessage = QuizHelpMessage(
                role: .assistant,
                content: recommendation
            )
            messages.append(assistantMessage)

        } catch {
            errorMessage = "Couldn't load recommendation. You can still make your choice!"
            print("Quiz help recommendation error: \(error)")
        }

        isLoading = false
    }

    func sendMessage() async {
        guard let question = currentQuestion else { return }
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""

        // Add user message
        let userMessage = QuizHelpMessage(role: .user, content: userText)
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            // Build previous messages for context
            let previousMessages = messages.dropLast().map { msg in
                (role: msg.role == .user ? "User" : "Assistant", content: msg.content)
            }

            let response = try await groqService.getQuizHelpResponse(
                question: question.question,
                options: question.options,
                skill: question.skill,
                userMessage: userText,
                previousMessages: Array(previousMessages),
                goalContext: goalContext
            )

            let assistantMessage = QuizHelpMessage(
                role: .assistant,
                content: response
            )
            messages.append(assistantMessage)

        } catch {
            errorMessage = "Couldn't get a response. Please try again."
            print("Quiz help response error: \(error)")
        }

        isLoading = false
    }
}
