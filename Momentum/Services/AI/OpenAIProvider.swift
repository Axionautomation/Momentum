//
//  OpenAIProvider.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Implements the OpenAI Chat Completions API for complex reasoning tasks.
//

import Foundation

final class OpenAIProvider: AIProvider, @unchecked Sendable {
    let name = "OpenAI"
    let costTier: CostTier = .premium

    private let apiKey: String
    private let model: String
    private let baseURL: String
    private let session: URLSession

    init(
        apiKey: String = Config.openAIAPIKey,
        model: String = Config.openAIModel,
        baseURL: String = "https://api.openai.com/v1"
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Request/Response Models

    private struct OpenAIRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let maxTokens: Int?
        let responseFormat: ResponseFormat?
        let stream: Bool?

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature, stream
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

    private struct OpenAIResponse: Codable {
        let id: String
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Codable {
            let message: ChoiceMessage

            struct ChoiceMessage: Codable {
                let role: String
                let content: String?
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

    private struct OpenAIErrorResponse: Codable {
        let error: ErrorDetail

        struct ErrorDetail: Codable {
            let message: String
            let type: String?
            let code: String?
        }
    }

    // MARK: - Streaming Event Models

    private struct StreamChoice: Codable {
        let delta: StreamDelta?
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }

    private struct StreamDelta: Codable {
        let content: String?
    }

    private struct StreamChunk: Codable {
        let choices: [StreamChoice]
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
            maxTokens: maxTokens ?? 4096,
            requireJSON: requireJSON,
            retryCount: 0
        )
    }

    // MARK: - Streaming Support

    /// Stream a completion as an AsyncSequence of text chunks
    func stream(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 4096
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.performStreamingRequest(
                        systemPrompt: systemPrompt,
                        userPrompt: userPrompt,
                        temperature: temperature,
                        maxTokens: maxTokens,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Core Request

    private func makeRequest(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        maxTokens: Int,
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
        request.timeoutInterval = 60

        let messages = [
            OpenAIRequest.Message(role: "system", content: systemPrompt),
            OpenAIRequest.Message(role: "user", content: userPrompt)
        ]

        let openAIRequest = OpenAIRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: requireJSON ? OpenAIRequest.ResponseFormat(type: "json_object") : nil,
            stream: nil
        )

        request.httpBody = try JSONEncoder().encode(openAIRequest)

        print("[OpenAIProvider] Making request (attempt \(retryCount + 1))...")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            print("[OpenAIProvider] HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                // Retry on server errors or rate limiting
                if (500...599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429 {
                    if retryCount < 3 {
                        let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after")
                        let delay = Double(retryAfter ?? "") ?? Double(retryCount + 1) * 2
                        print("[OpenAIProvider] Error \(httpResponse.statusCode), retrying in \(delay)s...")
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

                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    throw AIError.apiError("\(errorResponse.error.type ?? "error"): \(errorResponse.error.message)")
                }
                if let errorString = String(data: data, encoding: .utf8) {
                    throw AIError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                }
                throw AIError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

            guard let content = openAIResponse.choices.first?.message.content else {
                throw AIError.invalidResponse
            }

            if let usage = openAIResponse.usage {
                print("[OpenAIProvider] Tokens — in: \(usage.promptTokens), out: \(usage.completionTokens)")
            }

            print("[OpenAIProvider] Received response (\(content.count) characters)")
            return content

        } catch let error as AIError {
            throw error
        } catch {
            let nsError = error as NSError
            let retryableCodes = [-1001, -1004, -1005, -1009, -1020]
            if nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code) && retryCount < 3 {
                let delay = pow(2.0, Double(retryCount + 1))
                print("[OpenAIProvider] Network error (\(nsError.code)), retrying in \(delay)s...")
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

    // MARK: - Streaming Request

    private func performStreamingRequest(
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        maxTokens: Int,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let messages = [
            OpenAIRequest.Message(role: "system", content: systemPrompt),
            OpenAIRequest.Message(role: "user", content: userPrompt)
        ]

        let streamRequest = OpenAIRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: nil,
            stream: true
        )

        request.httpBody = try JSONEncoder().encode(streamRequest)

        print("[OpenAIProvider] Starting streaming request...")

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AIError.apiError("Streaming failed with status \(statusCode)")
        }

        // Parse SSE events (OpenAI format: "data: {json}\n" or "data: [DONE]\n")
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }

            let dataString = String(line.dropFirst(6))

            if dataString == "[DONE]" {
                break
            }

            if let data = dataString.data(using: .utf8),
               let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
               let content = chunk.choices.first?.delta?.content {
                continuation.yield(content)
            }
        }

        print("[OpenAIProvider] Streaming complete")
    }
}
