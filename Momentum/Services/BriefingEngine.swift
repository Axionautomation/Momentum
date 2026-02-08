//
//  BriefingEngine.swift
//  Momentum
//
//  Created by Henry Bowman on 2/8/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BriefingEngine: ObservableObject {
    @Published var currentBriefing: BriefingReport?
    @Published var isGenerating: Bool = false

    private let groqService = GroqService.shared
    private let cacheKey = "cachedBriefingReport"
    private let stalenessInterval: TimeInterval = 4 * 60 * 60 // 4 hours

    init() {
        loadCachedBriefing()
    }

    // MARK: - Public API

    func generateBriefingIfNeeded(
        goal: Goal?,
        tasks: [MomentumTask],
        streak: Int,
        milestone: Milestone?,
        personality: AIPersonality
    ) async {
        // If we have a fresh cached briefing, skip generation
        if let briefing = currentBriefing,
           Date().timeIntervalSince(briefing.generatedAt) < stalenessInterval {
            print("[BriefingEngine] Cached briefing is fresh, skipping generation")
            return
        }

        await generateBriefing(
            goal: goal,
            tasks: tasks,
            streak: streak,
            milestone: milestone,
            personality: personality
        )
    }

    func forceRefreshBriefing(
        goal: Goal?,
        tasks: [MomentumTask],
        streak: Int,
        milestone: Milestone?,
        personality: AIPersonality
    ) async {
        await generateBriefing(
            goal: goal,
            tasks: tasks,
            streak: streak,
            milestone: milestone,
            personality: personality
        )
    }

    // MARK: - Private

    private func generateBriefing(
        goal: Goal?,
        tasks: [MomentumTask],
        streak: Int,
        milestone: Milestone?,
        personality: AIPersonality
    ) async {
        guard !isGenerating else { return }
        isGenerating = true

        defer { isGenerating = false }

        let goalVision = goal?.visionRefined ?? goal?.visionText ?? "Personal growth"
        let milestoneName = milestone?.title ?? "Getting started"
        let milestoneProgress = milestone?.completionPercentage ?? 0

        let todayTaskTitles = tasks.filter { $0.status == .pending }.map { $0.title }

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayCompleted = tasks.filter { task in
            guard task.status == .completed, let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: yesterday)
        }.count

        // Build the greeting based on time of day
        let hour = calendar.component(.hour, from: Date())
        let greeting: String
        switch hour {
        case 0..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        default:
            greeting = "Good evening"
        }

        let pendingCount = todayTaskTitles.count

        do {
            let content = try await groqService.generateMorningBriefing(
                goalVision: goalVision,
                milestoneName: milestoneName,
                milestoneProgress: milestoneProgress,
                todayTaskTitles: todayTaskTitles,
                yesterdayCompletedCount: yesterdayCompleted,
                streakCount: streak,
                personality: personality
            )

            let report = BriefingReport(
                greeting: greeting,
                insight: content.insight,
                focusArea: content.focusArea,
                tasksToday: pendingCount,
                tasksCompletedYesterday: yesterdayCompleted,
                currentStreak: streak,
                milestoneProgress: milestoneProgress,
                milestoneName: milestone?.title,
                goalDomain: goal?.domain
            )

            currentBriefing = report
            cacheBriefing(report)
            print("[BriefingEngine] Briefing generated successfully")

        } catch {
            print("[BriefingEngine] Failed to generate briefing: \(error)")
            // Fall back to a local briefing if AI fails
            let fallback = BriefingReport(
                greeting: greeting,
                insight: "You have \(pendingCount) task\(pendingCount == 1 ? "" : "s") today. Keep your momentum going!",
                focusArea: "Stay focused on \(milestoneName)",
                tasksToday: pendingCount,
                tasksCompletedYesterday: yesterdayCompleted,
                currentStreak: streak,
                milestoneProgress: milestoneProgress,
                milestoneName: milestone?.title,
                goalDomain: goal?.domain
            )
            currentBriefing = fallback
            cacheBriefing(fallback)
        }
    }

    // MARK: - Cache

    private func cacheBriefing(_ briefing: BriefingReport) {
        if let data = try? JSONEncoder().encode(briefing) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCachedBriefing() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let briefing = try? JSONDecoder().decode(BriefingReport.self, from: data) else {
            return
        }
        currentBriefing = briefing
    }
}
