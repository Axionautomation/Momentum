//
//  HTTPClientService.swift
//  Momentum
//
//  Created by Claude on 1/25/26.
//
//  Actor-based wrapper around AsyncHTTPClient to eliminate HTTP/3 (QUIC) connection errors.
//  SwiftNIO only supports HTTP/1.1 and HTTP/2 - no HTTP/3 implementation exists.
//

import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import NIOFoundationCompat

/// HTTP client service that guarantees HTTP/1.1 or HTTP/2 connections (no HTTP/3/QUIC)
actor HTTPClientService {
    static let shared = HTTPClientService()

    private let client: HTTPClient

    private init() {
        // Configure HTTP client with HTTP/1.1 and HTTP/2 only (no HTTP/3)
        var configuration = HTTPClient.Configuration()
        configuration.timeout = HTTPClient.Configuration.Timeout(
            connect: .seconds(15),
            read: .seconds(60)
        )
        configuration.httpVersion = .automatic // HTTP/1.1 + HTTP/2, never HTTP/3
        configuration.decompression = .enabled(limit: .ratio(10))

        self.client = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )

        print("✅ HTTPClientService initialized (HTTP/1.1 + HTTP/2 only, no QUIC)")
    }

    deinit {
        try? client.syncShutdown()
    }

    /// Perform a POST request with JSON body
    /// - Parameters:
    ///   - url: The endpoint URL
    ///   - headers: HTTP headers (Authorization, Content-Type, etc.)
    ///   - body: JSON-encoded request body
    /// - Returns: Response data and status code
    func post(
        url: String,
        headers: [(String, String)],
        body: Data
    ) async throws -> (data: Data, statusCode: Int) {
        var request = HTTPClientRequest(url: url)
        request.method = .POST

        // Add headers
        for (name, value) in headers {
            request.headers.add(name: name, value: value)
        }

        // Set body
        request.body = .bytes(ByteBuffer(data: body))

        print("📡 Making Groq API request via HTTP/2...")

        let response = try await client.execute(request, timeout: .seconds(60))

        // Collect response body
        var responseData = Data()
        for try await buffer in response.body {
            responseData.append(contentsOf: buffer.readableBytesView)
        }

        let statusCode = Int(response.status.code)
        print("✅ Received response (HTTP \(statusCode), \(responseData.count) bytes)")

        return (responseData, statusCode)
    }

    /// Gracefully shutdown the HTTP client
    func shutdown() async throws {
        try await client.shutdown()
    }
}

// MARK: - HTTP Client Errors

enum HTTPClientServiceError: LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int, message: String?)
    case timeout
    case connectionError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let statusCode, let message):
            return "HTTP \(statusCode): \(message ?? "Unknown error")"
        case .timeout:
            return "Request timed out"
        case .connectionError(let error):
            return "Connection error: \(error.localizedDescription)"
        }
    }
}
