//
//  AITaskProcessor.swift
//  Momentum
//
//  Created by Claude on 1/30/26.
//

import Foundation
import Combine

/// Handles background AI processing for tasks
@MainActor
class AITaskProcessor: ObservableObject {
    @Published var processingItems: [UUID: AIWorkStatus] = [:]
    @Published var pendingQuestions: [AIQuestion] = []
    @Published var completedWorkItems: [AIWorkItem] = []

    private let groqService = GroqService.shared

    // MARK: - Process New Task

    /// Called when a new task is created - analyzes what AI can do
    func processNewTask(_ task: MomentumTask, goal: Goal) async {
        do {
            let goalContext = goal.visionRefined ?? goal.visionText

            // Analyze the task
            let analysis = try await groqService.analyzeTaskForAI(
                task: task,
                goalContext: goalContext
            )

            // Store any questions needed
            for question in analysis.questionsNeeded {
                var mutableQuestion = question
                // Update the goalId to match
                mutableQuestion = AIQuestion(
                    id: question.id,
                    taskId: task.id,
                    goalId: goal.id,
                    question: question.question,
                    options: question.options,
                    allowsCustomInput: question.allowsCustomInput,
                    answer: question.answer,
                    answeredAt: question.answeredAt,
                    createdAt: question.createdAt,
                    priority: question.priority
                )
                pendingQuestions.append(mutableQuestion)
            }

            // Queue research work items
            for researchTopic in analysis.researchNeeded {
                let workItem = AIWorkItem(
                    goalId: goal.id,
                    taskId: task.id,
                    type: .research,
                    title: researchTopic
                )
                await performResearch(item: workItem, context: goalContext)
            }

        } catch {
            print("Failed to analyze task: \(error.localizedDescription)")
        }
    }

    // MARK: - Process All Pending Work

    /// Called periodically or on app launch
    func processAllPendingWork(for goal: Goal) async {
        let goalContext = goal.visionRefined ?? goal.visionText

        // Process any pending work items
        for item in completedWorkItems.filter({ $0.status == .pending }) {
            switch item.type {
            case .research:
                await performResearch(item: item, context: goalContext)
            case .report:
                await generateReport(item: item, context: goalContext)
            case .toolPrompt:
                await generateToolPrompt(item: item, context: goalContext)
            case .ideaGeneration:
                await generateIdeas(item: item, context: goalContext)
            }
        }
    }

    // MARK: - Individual Processors

    private func performResearch(item: AIWorkItem, context: String) async {
        var updatedItem = item
        updatedItem.status = .inProgress
        processingItems[item.id] = .inProgress

        do {
            let result = try await groqService.generateResearchReport(
                query: item.title,
                context: context
            )

            updatedItem.result = result
            updatedItem.status = .completed
            updatedItem.completedAt = Date()

            // Update or add to completed items
            if let index = completedWorkItems.firstIndex(where: { $0.id == item.id }) {
                completedWorkItems[index] = updatedItem
            } else {
                completedWorkItems.append(updatedItem)
            }

            processingItems[item.id] = .completed

        } catch {
            updatedItem.status = .failed
            processingItems[item.id] = .failed
            print("Research failed: \(error.localizedDescription)")
        }
    }

    private func generateReport(item: AIWorkItem, context: String) async {
        var updatedItem = item
        updatedItem.status = .inProgress
        processingItems[item.id] = .inProgress

        do {
            let result = try await groqService.generateResearchReport(
                query: item.title,
                context: context
            )

            updatedItem.result = result
            updatedItem.status = .completed
            updatedItem.completedAt = Date()

            if let index = completedWorkItems.firstIndex(where: { $0.id == item.id }) {
                completedWorkItems[index] = updatedItem
            } else {
                completedWorkItems.append(updatedItem)
            }

            processingItems[item.id] = .completed

        } catch {
            updatedItem.status = .failed
            processingItems[item.id] = .failed
        }
    }

    private func generateToolPrompt(item: AIWorkItem, context: String) async {
        var updatedItem = item
        updatedItem.status = .inProgress
        processingItems[item.id] = .inProgress

        do {
            let result = try await groqService.generateToolPrompt(
                tool: "Cursor", // Default tool - could be parameterized
                context: context,
                goal: item.title
            )

            updatedItem.result = result
            updatedItem.status = .completed
            updatedItem.completedAt = Date()

            if let index = completedWorkItems.firstIndex(where: { $0.id == item.id }) {
                completedWorkItems[index] = updatedItem
            } else {
                completedWorkItems.append(updatedItem)
            }

            processingItems[item.id] = .completed

        } catch {
            updatedItem.status = .failed
            processingItems[item.id] = .failed
        }
    }

    private func generateIdeas(item: AIWorkItem, context: String) async {
        // Similar implementation for idea generation
        var updatedItem = item
        updatedItem.status = .inProgress
        processingItems[item.id] = .inProgress

        do {
            let result = try await groqService.generateResearchReport(
                query: "Ideas for: \(item.title)",
                context: context
            )

            updatedItem.result = result
            updatedItem.status = .completed
            updatedItem.completedAt = Date()

            if let index = completedWorkItems.firstIndex(where: { $0.id == item.id }) {
                completedWorkItems[index] = updatedItem
            } else {
                completedWorkItems.append(updatedItem)
            }

            processingItems[item.id] = .completed

        } catch {
            updatedItem.status = .failed
            processingItems[item.id] = .failed
        }
    }

    // MARK: - Answer Questions

    /// Submit an answer to a pending question
    func submitAnswer(for questionId: UUID, answer: String) {
        if let index = pendingQuestions.firstIndex(where: { $0.id == questionId }) {
            var question = pendingQuestions[index]
            question.answer = answer
            question.answeredAt = Date()
            pendingQuestions[index] = question

            // Could trigger follow-up processing based on the answer
        }
    }

    // MARK: - Queue Management

    /// Add a research work item to the queue
    func queueResearch(title: String, goalId: UUID, taskId: UUID? = nil) {
        let workItem = AIWorkItem(
            goalId: goalId,
            taskId: taskId,
            type: .research,
            title: title
        )
        completedWorkItems.append(workItem)
    }

    /// Add a tool prompt work item to the queue
    func queueToolPrompt(title: String, goalId: UUID, taskId: UUID? = nil) {
        let workItem = AIWorkItem(
            goalId: goalId,
            taskId: taskId,
            type: .toolPrompt,
            title: title
        )
        completedWorkItems.append(workItem)
    }

    // MARK: - Filtering

    /// Get pending questions for a specific goal
    func pendingQuestions(for goalId: UUID) -> [AIQuestion] {
        pendingQuestions.filter { $0.goalId == goalId && $0.answer == nil }
    }

    /// Get completed work items for a specific goal
    func completedWorkItems(for goalId: UUID) -> [AIWorkItem] {
        completedWorkItems.filter { $0.goalId == goalId && $0.status == .completed }
    }
}
