//
//  ContentDraftingService.swift
//  Momentum
//
//  Created by Claude on 2/8/26.
//

import Foundation
import Combine

/// Generates content drafts (emails, LinkedIn posts, business plans, etc.) via AI
@MainActor
class ContentDraftingService: ObservableObject {
    @Published var isDrafting: Bool = false
    @Published var recentDrafts: [DraftContent] = []

    private let groqService = GroqService.shared

    // MARK: - Generate Draft

    /// Generate a content draft of a specific type
    func generateDraft(
        type: DraftType,
        title: String,
        context: String,
        goalId: UUID,
        taskId: UUID? = nil,
        additionalInstructions: String? = nil
    ) async -> DraftContent? {
        guard !isDrafting else { return nil }

        isDrafting = true
        defer { isDrafting = false }

        let systemPrompt = buildSystemPrompt(for: type)
        let userPrompt = buildUserPrompt(
            type: type,
            title: title,
            context: context,
            additionalInstructions: additionalInstructions
        )

        do {
            let responseText = try await groqService.completePrompt(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.7,
                maxTokens: 1500,
                requireJSON: true
            )

            guard let data = responseText.data(using: .utf8) else { return nil }

            struct DraftResponse: Codable {
                let title: String
                let content: String
            }

            let response = try JSONDecoder().decode(DraftResponse.self, from: data)

            let draft = DraftContent(
                goalId: goalId,
                taskId: taskId,
                type: type,
                title: response.title,
                content: response.content
            )

            recentDrafts.insert(draft, at: 0)
            if recentDrafts.count > 20 {
                recentDrafts = Array(recentDrafts.prefix(20))
            }

            return draft

        } catch {
            print("[ContentDrafting] Failed to generate draft: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Revise Draft

    /// Revise an existing draft with feedback
    func reviseDraft(
        _ draft: DraftContent,
        feedback: String
    ) async -> DraftContent? {
        isDrafting = true
        defer { isDrafting = false }

        let systemPrompt = """
        You are revising a \(draft.type.displayName) based on user feedback.
        Maintain the same format and tone, but incorporate the requested changes.

        Return ONLY valid JSON:
        {
          "title": "Updated title if needed",
          "content": "The revised full content"
        }
        """

        let userPrompt = """
        Original Draft:
        Title: \(draft.title)
        Content:
        \(draft.content)

        User Feedback:
        \(feedback)

        Please revise the draft based on this feedback.
        """

        do {
            let responseText = try await groqService.completePrompt(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.7,
                maxTokens: 1500,
                requireJSON: true
            )

            guard let data = responseText.data(using: .utf8) else { return nil }

            struct DraftResponse: Codable {
                let title: String
                let content: String
            }

            let response = try JSONDecoder().decode(DraftResponse.self, from: data)

            var revised = draft
            revised.content = response.content
            revised.updatedAt = Date()

            // Update in recent drafts
            if let index = recentDrafts.firstIndex(where: { $0.id == draft.id }) {
                recentDrafts[index] = revised
            }

            return revised

        } catch {
            print("[ContentDrafting] Failed to revise draft: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Update Draft Status

    func updateDraftStatus(_ draft: DraftContent, status: DraftStatus) {
        if let index = recentDrafts.firstIndex(where: { $0.id == draft.id }) {
            recentDrafts[index].status = status
            recentDrafts[index].updatedAt = Date()
        }
    }

    // MARK: - Prompt Builders

    private func buildSystemPrompt(for type: DraftType) -> String {
        let typeInstruction: String
        switch type {
        case .email:
            typeInstruction = """
            Write a professional email. Include a clear subject line concept in the title.
            The content should have a greeting, body, and professional sign-off.
            """
        case .linkedInPost:
            typeInstruction = """
            Write an engaging LinkedIn post. Use a hook in the first line.
            Keep it concise (under 300 words), use line breaks for readability.
            Include relevant hashtags at the end.
            """
        case .businessPlan:
            typeInstruction = """
            Write a business plan section. Use clear headings and structured format.
            Include relevant data points and market insights where applicable.
            """
        case .coverLetter:
            typeInstruction = """
            Write a professional cover letter. Highlight relevant skills and experience.
            Keep it concise (3-4 paragraphs), enthusiastic but professional.
            """
        case .pitchOutline:
            typeInstruction = """
            Create a pitch outline with clear sections: Problem, Solution, Market,
            Business Model, Traction, Team, Ask. Keep each section concise.
            """
        case .custom:
            typeInstruction = """
            Write the requested content in a professional, clear style.
            Adapt the tone and format to match the request.
            """
        }

        return """
        You are Momentum's AI content drafting assistant. Generate high-quality, ready-to-use content.

        \(typeInstruction)

        Return ONLY valid JSON:
        {
          "title": "A descriptive title for this draft",
          "content": "The full draft content"
        }
        """
    }

    private func buildUserPrompt(
        type: DraftType,
        title: String,
        context: String,
        additionalInstructions: String?
    ) -> String {
        var prompt = """
        Content Type: \(type.displayName)
        Topic: \(title)
        Context: \(context)
        """

        if let instructions = additionalInstructions, !instructions.isEmpty {
            prompt += "\nAdditional Instructions: \(instructions)"
        }

        prompt += "\n\nGenerate the \(type.displayName.lowercased()) draft."
        return prompt
    }
}
