//
//  GroqProvider.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Extracts the core Groq API request logic into a clean AIProvider.
//

import Foundation

final class GroqProvider: AIProvider, @unchecked Sendable {
    let name = "Groq"
    let costTier: CostTier = .fast

    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let session: URLSession

    init(
        apiKey: String = Config.groqAPIKey,
        baseURL: String = Config.groqAPIBaseURL,
        model: String = Config.groqModel
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 2
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Request/Response Models

    private struct GroqRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int?
        let responseFormat: ResponseFormat?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
            case responseFormat = "response_format"
        }

        struct Message: Codable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Codable {
            let type: String
        }
    }

    private struct GroqResponse: Codable {
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let role: String
                let content: String
            }
        }

        struct Usage: Codable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }

    // MARK: - AIProvider Conformance

    func complete(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        requireJSON: Bool = false
    ) async throws -> String {
        return try await makeRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            requireJSON: requireJSON,
            retryCount: 0
        )
    }

    // MARK: - Core Request with Retry

    private func makeRequest(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        maxTokens: Int?,
        requireJSON: Bool,
        retryCount: Int
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let messages = [
            GroqRequest.Message(role: "system", content: systemPrompt),
            GroqRequest.Message(role: "user", content: userPrompt)
        ]

        let groqRequest = GroqRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: requireJSON ? GroqRequest.ResponseFormat(type: "json_object") : nil
        )

        request.httpBody = try JSONEncoder().encode(groqRequest)

        print("[GroqProvider] Making request (attempt \(retryCount + 1))...")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            print("[GroqProvider] HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                // Retry on server errors or rate limiting
                if (500...599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429 {
                    if retryCount < 3 {
                        let delay = Double(retryCount + 1) * 2
                        print("[GroqProvider] Server error \(httpResponse.statusCode), retrying in \(delay)s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        return try await makeRequest(
                            systemPrompt: systemPrompt,
                            userPrompt: userPrompt,
                            temperature: temperature,
                            maxTokens: maxTokens,
                            requireJSON: requireJSON,
                            retryCount: retryCount + 1
                        )
                    }
                }

                if let errorString = String(data: data, encoding: .utf8) {
                    throw AIError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                }
                throw AIError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let groqResponse = try JSONDecoder().decode(GroqResponse.self, from: data)

            guard let content = groqResponse.choices.first?.message.content else {
                throw AIError.invalidResponse
            }

            print("[GroqProvider] Received response (\(content.count) characters)")
            return content

        } catch let error as AIError {
            throw error
        } catch {
            let nsError = error as NSError
            let retryableCodes = [-1001, -1004, -1005, -1009, -1020]
            if nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code) && retryCount < 3 {
                let delay = pow(2.0, Double(retryCount + 1))
                print("[GroqProvider] Network error (\(nsError.code)), retrying in \(delay)s...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await makeRequest(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    temperature: temperature,
                    maxTokens: maxTokens,
                    requireJSON: requireJSON,
                    retryCount: retryCount + 1
                )
            }
            throw AIError.networkError(error)
        }
    }
}
