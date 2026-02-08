//
//  ClaudeProvider.swift
//  Momentum
//
//  Phase 3: Multi-Model AI Architecture
//  Implements the Anthropic Messages API for complex reasoning tasks.
//

import Foundation

final class ClaudeProvider: AIProvider, @unchecked Sendable {
    let name = "Claude"
    let costTier: CostTier = .premium

    private let apiKey: String
    private let model: String
    private let apiVersion: String
    private let baseURL: String
    private let session: URLSession

    init(
        apiKey: String = Config.claudeAPIKey,
        model: String = Config.claudeModel,
        apiVersion: String = "2023-06-01",
        baseURL: String = "https://api.anthropic.com/v1"
    ) {
        self.apiKey = apiKey
        self.model = model
        self.apiVersion = apiVersion
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

    private struct ClaudeRequest: Codable {
        let model: String
        let maxTokens: Int
        let system: String?
        let messages: [Message]
        let temperature: Double?

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case system, messages, temperature
        }

        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    private struct ClaudeResponse: Codable {
        let id: String
        let type: String
        let role: String
        let content: [ContentBlock]
        let model: String
        let usage: Usage?

        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }

        struct Usage: Codable {
            let inputTokens: Int
            let outputTokens: Int

            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
            }
        }
    }

    private struct ClaudeErrorResponse: Codable {
        let type: String
        let error: ErrorDetail

        struct ErrorDetail: Codable {
            let type: String
            let message: String
        }
    }

    // MARK: - Streaming Event Models

    private struct StreamEvent {
        let type: String
        let data: String
    }

    private struct StreamDelta: Codable {
        let type: String?
        let text: String?
    }

    private struct StreamContentBlockDelta: Codable {
        let type: String
        let index: Int?
        let delta: StreamDelta?
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
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        // If JSON is required, prepend instruction to the system prompt
        let effectiveSystemPrompt = requireJSON
            ? systemPrompt + "\n\nIMPORTANT: You MUST respond with ONLY valid JSON. No markdown, no explanation, just the JSON object."
            : systemPrompt

        let claudeRequest = ClaudeRequest(
            model: model,
            maxTokens: maxTokens,
            system: effectiveSystemPrompt,
            messages: [
                ClaudeRequest.Message(role: "user", content: userPrompt)
            ],
            temperature: temperature
        )

        request.httpBody = try JSONEncoder().encode(claudeRequest)

        print("[ClaudeProvider] Making request (attempt \(retryCount + 1))...")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            print("[ClaudeProvider] HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                // Retry on server errors or rate limiting
                if (500...599).contains(httpResponse.statusCode) || httpResponse.statusCode == 429 {
                    if retryCount < 3 {
                        let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after")
                        let delay = Double(retryAfter ?? "") ?? Double(retryCount + 1) * 2
                        print("[ClaudeProvider] Error \(httpResponse.statusCode), retrying in \(delay)s...")
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
                if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                    throw AIError.apiError("\(errorResponse.error.type): \(errorResponse.error.message)")
                }
                if let errorString = String(data: data, encoding: .utf8) {
                    throw AIError.apiError("Status \(httpResponse.statusCode): \(errorString)")
                }
                throw AIError.apiError("Status code: \(httpResponse.statusCode)")
            }

            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

            guard let textBlock = claudeResponse.content.first(where: { $0.type == "text" }),
                  let text = textBlock.text else {
                throw AIError.invalidResponse
            }

            if let usage = claudeResponse.usage {
                print("[ClaudeProvider] Tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)")
            }

            print("[ClaudeProvider] Received response (\(text.count) characters)")
            return text

        } catch let error as AIError {
            throw error
        } catch {
            let nsError = error as NSError
            let retryableCodes = [-1001, -1004, -1005, -1009, -1020]
            if nsError.domain == NSURLErrorDomain && retryableCodes.contains(nsError.code) && retryCount < 3 {
                let delay = pow(2.0, Double(retryCount + 1))
                print("[ClaudeProvider] Network error (\(nsError.code)), retrying in \(delay)s...")
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
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        struct StreamingClaudeRequest: Codable {
            let model: String
            let maxTokens: Int
            let system: String?
            let messages: [ClaudeRequest.Message]
            let temperature: Double?
            let stream: Bool

            enum CodingKeys: String, CodingKey {
                case model
                case maxTokens = "max_tokens"
                case system, messages, temperature, stream
            }
        }

        let streamRequest = StreamingClaudeRequest(
            model: model,
            maxTokens: maxTokens,
            system: systemPrompt,
            messages: [
                ClaudeRequest.Message(role: "user", content: userPrompt)
            ],
            temperature: temperature,
            stream: true
        )

        request.httpBody = try JSONEncoder().encode(streamRequest)

        print("[ClaudeProvider] Starting streaming request...")

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AIError.apiError("Streaming failed with status \(statusCode)")
        }

        // Parse SSE events
        var currentEventType = ""

        for try await line in bytes.lines {
            if line.hasPrefix("event: ") {
                currentEventType = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                let dataString = String(line.dropFirst(6))

                if currentEventType == "content_block_delta" {
                    if let data = dataString.data(using: .utf8),
                       let delta = try? JSONDecoder().decode(StreamContentBlockDelta.self, from: data),
                       let text = delta.delta?.text {
                        continuation.yield(text)
                    }
                } else if currentEventType == "message_stop" {
                    break
                } else if currentEventType == "error" {
                    throw AIError.apiError("Stream error: \(dataString)")
                }
            }
        }

        print("[ClaudeProvider] Streaming complete")
    }
}
