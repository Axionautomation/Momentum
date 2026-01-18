//
//  ConversationOrchestrator.swift
//  Momentum
//
//  Created by Henry Bowman on 12/31/25.
//

import Foundation
import SwiftUI
import Combine

/// Orchestrates multi-turn research conversations between user, AI, and web search
@MainActor
class ConversationOrchestrator: ObservableObject {
    @Published var currentConversation: [ConversationMessage] = []
    @Published var isProcessing: Bool = false
    @Published var awaitingClarification: Bool = false
    @Published var clarifyingQuestions: [String] = []

    private let groqService = GroqService.shared

    // Temporary storage for research flow
    private var pendingResearchQuery: String?

    // MARK: - Main Conversation Flow

    /// Process a user message and determine the appropriate response
    func processUserMessage(
        _ message: String,
        taskContext: MomentumTask,
        existingConversation: [ConversationMessage]
    ) async throws -> ConversationUpdate {
        isProcessing = true
        defer { isProcessing = false }

        // Add user message to conversation
        let userMessage = ConversationMessage(
            role: .user,
            content: message
        )

        currentConversation.append(userMessage)

        // Build task context string
        let contextString = buildTaskContext(taskContext)

        // Detect user intent
        let intent = try await groqService.analyzeMessageIntent(
            message: message,
            taskContext: contextString
        )

        switch intent {
        case .researchRequest:
            // Generate clarifying questions
            let questions = try await groqService.generateResearchClarifications(
                query: message,
                taskContext: contextString,
                taskTitle: taskContext.title
            )

            clarifyingQuestions = questions
            awaitingClarification = true
            pendingResearchQuery = message

            // Create system message about clarification
            let systemMessage = ConversationMessage(
                role: .system,
                content: "I have a few questions to help me research this better:",
                metadata: MessageMetadata(
                    messageType: .clarifyingQuestion,
                    relatedResearchId: nil
                )
            )

            currentConversation.append(systemMessage)

            return ConversationUpdate(
                newMessages: [userMessage, systemMessage],
                researchFinding: nil,
                requiresClarification: true,
                clarifyingQuestions: questions
            )

        case .taskHelp, .brainstorming, .statusUpdate:
            // Use standard task help
            let response = try await groqService.getTaskHelp(
                taskTitle: taskContext.title,
                taskDescription: taskContext.taskDescription ?? "",
                userQuestion: message
            )

            let assistantMessage = ConversationMessage(
                role: .assistant,
                content: response,
                metadata: MessageMetadata(
                    messageType: .generalHelp,
                    relatedResearchId: nil
                )
            )

            currentConversation.append(assistantMessage)

            return ConversationUpdate(
                newMessages: [userMessage, assistantMessage],
                researchFinding: nil,
                requiresClarification: false,
                clarifyingQuestions: nil
            )
        }
    }

    // MARK: - Research Flow

    /// Perform research with user's clarification answers
    func performResearch(
        query: String,
        clarifications: [QAPair],
        taskContext: MomentumTask
    ) async throws -> ResearchFinding {
        isProcessing = true
        awaitingClarification = false
        defer { isProcessing = false }

        // Build task context string
        let taskContextString = buildTaskContext(taskContext)

        // Perform browser search using Groq's built-in tool
        // This searches the web AND synthesizes results in one call
        let synthesis = try await groqService.performBrowserSearch(
            query: query,
            clarifications: clarifications,
            taskContext: taskContextString,
            taskTitle: taskContext.title
        )

        // Create research finding
        let finding = ResearchFinding(
            query: query,
            clarifyingQA: clarifications,
            searchResults: synthesis,
            timestamp: Date(),
            wasAutoSaved: true
        )

        // Add to conversation
        let resultMessage = ConversationMessage(
            role: .assistant,
            content: synthesis,
            metadata: MessageMetadata(
                messageType: .researchResult,
                relatedResearchId: finding.id
            )
        )

        currentConversation.append(resultMessage)

        // Clear pending state
        pendingResearchQuery = nil
        clarifyingQuestions = []

        return finding
    }

    // MARK: - Helper Methods

    private func buildTaskContext(_ task: MomentumTask) -> String {
        var context = """
        Task: \(task.title)
        Difficulty: \(task.difficulty.displayName)
        Estimated Time: \(task.estimatedMinutes) minutes
        """

        if let description = task.taskDescription {
            context += "\nDescription: \(description)"
        }

        // Include previous research findings
        if !task.notes.researchFindings.isEmpty {
            context += "\n\nPrevious Research:\n"
            for finding in task.notes.researchFindings.prefix(3) {
                context += "- \(finding.query): \(finding.searchResults.prefix(200))...\n"
            }
        }

        // Include brainstorms
        if !task.notes.userBrainstorms.isEmpty {
            context += "\n\nUser Brainstorms:\n"
            for brainstorm in task.notes.userBrainstorms {
                context += "- \(brainstorm.content)\n"
            }
        }

        return context
    }

    /// Reset orchestrator state
    func reset() {
        currentConversation = []
        isProcessing = false
        awaitingClarification = false
        clarifyingQuestions = []
        pendingResearchQuery = nil
    }
}

// MARK: - Conversation Update Model

struct ConversationUpdate {
    let newMessages: [ConversationMessage]
    let researchFinding: ResearchFinding?
    let requiresClarification: Bool
    let clarifyingQuestions: [String]?
}
