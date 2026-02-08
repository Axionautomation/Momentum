//
//  AIMemoryService.swift
//  Momentum
//
//  Created by Claude on 2/8/26.
//

import Foundation
import Combine

/// Persistent AI memory system - stores insights about the user for context injection into AI prompts
@MainActor
class AIMemoryService: ObservableObject {
    @Published var memories: [AIMemoryEntry] = []

    private let storageKey = "aiMemoryEntries"

    init() {
        loadMemories()
    }

    // MARK: - CRUD Operations

    /// Store a new memory entry
    func store(
        category: MemoryCategory,
        key: String,
        value: String,
        confidence: Double = 0.8,
        source: String = "chat"
    ) {
        // Update existing entry with same category+key if it exists
        if let index = memories.firstIndex(where: { $0.category == category && $0.key == key }) {
            var updated = memories[index]
            updated = AIMemoryEntry(
                id: updated.id,
                category: category,
                key: key,
                value: value,
                confidence: max(updated.confidence, confidence),
                createdAt: updated.createdAt,
                updatedAt: Date(),
                source: source
            )
            memories[index] = updated
        } else {
            let entry = AIMemoryEntry(
                category: category,
                key: key,
                value: value,
                confidence: confidence,
                source: source
            )
            memories.append(entry)
        }

        saveMemories()
    }

    /// Retrieve memories by category
    func retrieve(category: MemoryCategory) -> [AIMemoryEntry] {
        memories.filter { $0.category == category }
    }

    /// Retrieve a specific memory by key
    func retrieve(key: String) -> AIMemoryEntry? {
        memories.first { $0.key == key }
    }

    /// Search memories by keyword
    func search(query: String) -> [AIMemoryEntry] {
        let lowered = query.lowercased()
        return memories.filter {
            $0.key.lowercased().contains(lowered) ||
            $0.value.lowercased().contains(lowered)
        }
    }

    /// Update an existing memory's value
    func update(id: UUID, value: String? = nil, confidence: Double? = nil) {
        guard let index = memories.firstIndex(where: { $0.id == id }) else { return }

        let existing = memories[index]
        memories[index] = AIMemoryEntry(
            id: existing.id,
            category: existing.category,
            key: existing.key,
            value: value ?? existing.value,
            confidence: confidence ?? existing.confidence,
            createdAt: existing.createdAt,
            updatedAt: Date(),
            source: existing.source
        )

        saveMemories()
    }

    /// Delete a memory entry
    func delete(id: UUID) {
        memories.removeAll { $0.id == id }
        saveMemories()
    }

    /// Delete all memories in a category
    func deleteCategory(_ category: MemoryCategory) {
        memories.removeAll { $0.category == category }
        saveMemories()
    }

    // MARK: - Context Injection

    /// Format relevant memories for injection into AI prompts
    func getContextForPrompt(limit: Int = 20) -> String {
        guard !memories.isEmpty else { return "" }

        let sorted = memories
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)

        var context = "User Context (from memory):\n"

        let grouped = Dictionary(grouping: sorted, by: { $0.category })
        for (category, entries) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            context += "\n[\(category.displayName)]\n"
            for entry in entries {
                context += "- \(entry.key): \(entry.value)\n"
            }
        }

        return context
    }

    /// Get context relevant to a specific topic
    func getContextForTopic(_ topic: String, limit: Int = 10) -> String {
        let relevant = search(query: topic).prefix(limit)
        guard !relevant.isEmpty else { return "" }

        var context = "Relevant memories for \"\(topic)\":\n"
        for entry in relevant {
            context += "- [\(entry.category.displayName)] \(entry.key): \(entry.value)\n"
        }
        return context
    }

    // MARK: - Auto-Learn

    /// Auto-learn from a user interaction
    func learnFromInteraction(type: MemoryCategory, context: String, insight: String, source: String = "auto") {
        store(
            category: type,
            key: context,
            value: insight,
            confidence: 0.6,
            source: source
        )
    }

    /// Learn from task completion patterns
    func learnFromTaskCompletion(task: MomentumTask) {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }

        store(
            category: .pattern,
            key: "preferred_work_time",
            value: "Tends to complete tasks in the \(timeOfDay)",
            confidence: 0.5,
            source: "task_completion"
        )

        // Learn about task duration preferences
        let minutes = task.totalEstimatedMinutes
        let preference: String
        if minutes <= 15 {
            preference = "short tasks (under 15 min)"
        } else if minutes <= 45 {
            preference = "medium tasks (15-45 min)"
        } else {
            preference = "longer tasks (45+ min)"
        }

        store(
            category: .preference,
            key: "task_duration_preference",
            value: "Completes \(preference) regularly",
            confidence: 0.5,
            source: "task_completion"
        )
    }

    /// Learn from onboarding answers
    func learnFromOnboarding(answers: OnboardingAnswers) {
        if !answers.visionText.isEmpty {
            store(category: .personal, key: "vision", value: answers.visionText, confidence: 1.0, source: "onboarding")
        }
        if !answers.experienceLevel.isEmpty {
            store(category: .skill, key: "experience_level", value: answers.experienceLevel, confidence: 1.0, source: "onboarding")
        }
        if !answers.passions.isEmpty {
            store(category: .personal, key: "passions", value: answers.passions, confidence: 1.0, source: "onboarding")
        }
        if !answers.biggestConcern.isEmpty {
            store(category: .personal, key: "biggest_concern", value: answers.biggestConcern, confidence: 1.0, source: "onboarding")
        }
    }

    /// Learn from chat interactions
    func learnFromChat(userMessage: String, aiResponse: String) {
        // Extract potential preferences or decisions from chat
        let lowered = userMessage.lowercased()

        if lowered.contains("i prefer") || lowered.contains("i like") {
            store(
                category: .preference,
                key: "chat_preference_\(Date().timeIntervalSince1970)",
                value: userMessage,
                confidence: 0.7,
                source: "chat"
            )
        }

        if lowered.contains("i decided") || lowered.contains("let's go with") || lowered.contains("i'll do") {
            store(
                category: .decision,
                key: "chat_decision_\(Date().timeIntervalSince1970)",
                value: userMessage,
                confidence: 0.8,
                source: "chat"
            )
        }
    }

    // MARK: - Persistence

    private func saveMemories() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadMemories() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([AIMemoryEntry].self, from: data) else {
            return
        }
        memories = loaded
    }

    // MARK: - Stats

    var totalMemories: Int { memories.count }

    var memoriesByCategory: [MemoryCategory: Int] {
        Dictionary(grouping: memories, by: { $0.category }).mapValues { $0.count }
    }
}
