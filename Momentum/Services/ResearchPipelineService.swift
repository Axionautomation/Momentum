//
//  ResearchPipelineService.swift
//  Momentum
//
//  Created by Claude on 2/8/26.
//

import Foundation
import Combine

/// Orchestrates the full research pipeline: analyze query -> generate search terms -> fetch results -> synthesize -> save
@MainActor
class ResearchPipelineService: ObservableObject {
    @Published var isResearching: Bool = false
    @Published var currentQuery: String?
    @Published var recentResults: [ResearchPipelineResult] = []

    private let groqService = GroqService.shared

    // MARK: - Pipeline Result

    struct ResearchPipelineResult: Identifiable {
        let id: UUID
        let query: String
        let clarifications: [QAPair]
        let synthesizedResult: String
        let knowledgeEntry: KnowledgeBaseEntry?
        let report: AIReport?
        let completedAt: Date

        init(
            id: UUID = UUID(),
            query: String,
            clarifications: [QAPair] = [],
            synthesizedResult: String,
            knowledgeEntry: KnowledgeBaseEntry? = nil,
            report: AIReport? = nil,
            completedAt: Date = Date()
        ) {
            self.id = id
            self.query = query
            self.clarifications = clarifications
            self.synthesizedResult = synthesizedResult
            self.knowledgeEntry = knowledgeEntry
            self.report = report
            self.completedAt = completedAt
        }
    }

    // MARK: - Full Pipeline

    /// Execute the full research pipeline for a query
    func executeResearch(
        query: String,
        taskContext: String = "",
        taskTitle: String = "",
        goalId: UUID,
        taskId: UUID? = nil,
        clarifications: [QAPair] = []
    ) async -> ResearchPipelineResult? {
        guard !isResearching else { return nil }

        isResearching = true
        currentQuery = query
        defer {
            isResearching = false
            currentQuery = nil
        }

        do {
            // Step 1: Perform browser search with existing GroqService method
            let searchResults = try await groqService.performBrowserSearch(
                query: query,
                clarifications: clarifications,
                taskContext: taskContext,
                taskTitle: taskTitle
            )

            // Step 2: Create knowledge base entry
            let knowledgeEntry = KnowledgeBaseEntry(
                goalId: goalId,
                type: .research,
                title: "Research: \(query)",
                content: searchResults,
                tags: ["research", "auto-generated"]
            )

            // Step 3: Create AI report for the feed
            let report = AIReport(
                taskId: taskId,
                goalId: goalId,
                title: "Research: \(query)",
                summary: String(searchResults.prefix(200)),
                details: searchResults,
                sources: nil
            )

            let result = ResearchPipelineResult(
                query: query,
                clarifications: clarifications,
                synthesizedResult: searchResults,
                knowledgeEntry: knowledgeEntry,
                report: report
            )

            recentResults.insert(result, at: 0)
            if recentResults.count > 10 {
                recentResults = Array(recentResults.prefix(10))
            }

            return result

        } catch {
            print("[ResearchPipeline] Research failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Clarification Flow

    /// Generate clarifying questions before running research
    func generateClarifications(
        query: String,
        taskContext: String,
        taskTitle: String
    ) async -> [String] {
        do {
            return try await groqService.generateResearchClarifications(
                query: query,
                taskContext: taskContext,
                taskTitle: taskTitle
            )
        } catch {
            print("[ResearchPipeline] Failed to generate clarifications: \(error)")
            return []
        }
    }

    // MARK: - Auto-Trigger Research

    /// Check if a task needs research based on its AI evaluation
    func shouldAutoTriggerResearch(for task: MomentumTask) -> Bool {
        guard let evaluation = task.aiEvaluation else { return false }
        return evaluation.approach == .aiAssisted && evaluation.skillsRequired.contains("research")
    }

    /// Auto-trigger research for a task that needs it
    func autoResearchForTask(
        _ task: MomentumTask,
        goal: Goal
    ) async -> ResearchPipelineResult? {
        let query = task.taskDescription ?? task.title
        let goalContext = goal.visionRefined ?? goal.visionText

        return await executeResearch(
            query: query,
            taskContext: goalContext,
            taskTitle: task.title,
            goalId: goal.id,
            taskId: task.id
        )
    }
}
