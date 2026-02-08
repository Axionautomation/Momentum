//
//  AIServiceRouter.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Routes AI requests to the appropriate provider based on complexity/cost tier.
//

import Foundation
import Combine

// MARK: - AI Error Types

enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError(String)
    case networkError(Error)
    case noProvidersAvailable
    case allProvidersFailed(errors: [Error])
    case streamingNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let message):
            return "AI service error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noProvidersAvailable:
            return "No AI providers available"
        case .allProvidersFailed(let errors):
            let messages = errors.map { $0.localizedDescription }.joined(separator: "; ")
            return "All AI providers failed: \(messages)"
        case .streamingNotSupported:
            return "Streaming is not supported by this provider"
        }
    }
}

// MARK: - Cost Tier

enum CostTier: String, Codable, Comparable {
    case fast       // Groq (llama) — cheapest, fastest
    case standard   // OpenAI GPT-4o-mini — balanced
    case premium    // OpenAI GPT-4o — most capable

    private var sortOrder: Int {
        switch self {
        case .fast: return 0
        case .standard: return 1
        case .premium: return 2
        }
    }

    static func < (lhs: CostTier, rhs: CostTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - AI Provider Protocol

protocol AIProvider: Sendable {
    var name: String { get }
    var costTier: CostTier { get }

    func complete(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        maxTokens: Int?,
        requireJSON: Bool
    ) async throws -> String
}

// MARK: - AI Service Router

@MainActor
class AIServiceRouter: ObservableObject {
    static let shared = AIServiceRouter()

    private var providers: [CostTier: AIProvider] = [:]
    private var fallbackOrder: [CostTier] = [.fast, .standard, .premium]

    private init() {
        // Register Groq as the default fast provider
        let groqProvider = GroqProvider()
        providers[.fast] = groqProvider

        // OpenAI provider — registered if API key is configured
        if !Config.openAIAPIKey.isEmpty && Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" {
            let openAIProvider = OpenAIProvider()
            providers[.standard] = openAIProvider
            providers[.premium] = openAIProvider
        }

        print("[AIServiceRouter] Initialized with providers: \(providers.keys.map { $0.rawValue })")
    }

    // MARK: - Public API

    /// Complete a prompt using the specified cost tier, with automatic fallback
    func complete(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        requireJSON: Bool = false,
        preferredTier: CostTier = .fast
    ) async throws -> String {
        let tiersToTry = buildFallbackChain(from: preferredTier)

        var errors: [Error] = []

        for tier in tiersToTry {
            guard let provider = providers[tier] else { continue }

            do {
                let result = try await provider.complete(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    temperature: temperature,
                    maxTokens: maxTokens,
                    requireJSON: requireJSON
                )
                return result
            } catch {
                print("[AIServiceRouter] \(provider.name) (\(tier.rawValue)) failed: \(error.localizedDescription)")
                errors.append(error)
            }
        }

        if errors.isEmpty {
            throw AIError.noProvidersAvailable
        }
        throw AIError.allProvidersFailed(errors: errors)
    }

    /// Get the streaming provider for real-time chat (OpenAI)
    func streamingProvider() -> OpenAIProvider? {
        providers[.standard] as? OpenAIProvider ?? providers[.premium] as? OpenAIProvider
    }

    // MARK: - Provider Management

    func registerProvider(_ provider: AIProvider, for tier: CostTier) {
        providers[tier] = provider
        print("[AIServiceRouter] Registered \(provider.name) for \(tier.rawValue) tier")
    }

    func availableTiers() -> [CostTier] {
        fallbackOrder.filter { providers[$0] != nil }
    }

    // MARK: - Private

    private func buildFallbackChain(from preferred: CostTier) -> [CostTier] {
        var chain = [preferred]
        // Add fallbacks: try cheaper tiers first, then more expensive
        for tier in fallbackOrder where tier != preferred {
            chain.append(tier)
        }
        return chain
    }
}
