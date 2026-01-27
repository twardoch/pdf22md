// this_file: pdf22md/Sources/PDF22MD/AI/OpenAIClient.swift

import Foundation

// MARK: - Request/Response Types

/// A chat message for the OpenAI API
struct ChatMessage: Codable {
    let role: String
    let content: String

    static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: "system", content: content)
    }

    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: "user", content: content)
    }

    static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: "assistant", content: content)
    }
}

/// Request body for chat completions API
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    let max_tokens: Int?

    init(model: String, messages: [ChatMessage], temperature: Double? = nil, maxTokens: Int? = nil) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.max_tokens = maxTokens
    }
}

/// Response from chat completions API
struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String?
            let content: String?
        }
        let index: Int
        let message: Message
        let finish_reason: String?
    }

    struct Usage: Codable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }

    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    let usage: Usage?
}

/// Error response from the API
struct APIErrorResponse: Codable {
    struct APIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
    let error: APIError
}

// MARK: - Errors

enum OpenAIClientError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, message: String?)
    case noResponse
    case decodingError(Error)
    case emptyContent
    case rateLimited(retryAfter: Int?)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "HTTP \(statusCode): \(message)"
            }
            return "HTTP error: \(statusCode)"
        case .noResponse:
            return "No response from API"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .emptyContent:
            return "Empty content in response"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Retry after \(seconds) seconds"
            }
            return "Rate limited"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Client

/// OpenAI-compatible HTTP client for chat completions
final class OpenAIClient {
    let baseURL: URL
    let apiKey: String
    let model: String

    /// Default timeout in seconds
    var timeout: TimeInterval = 60.0

    /// Default temperature for generation
    var temperature: Double = 0.3

    /// Default max tokens
    var maxTokens: Int? = 4000

    /// Maximum retry attempts
    var maxRetries: Int = 2

    private let session: URLSession

    init(baseURL: URL, apiKey: String, model: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    /// Initialize from APIConfiguration
    convenience init(config: APIConfiguration) {
        self.init(baseURL: config.baseURL, apiKey: config.apiKey, model: config.model)
    }

    /// Send a chat completion request
    /// - Parameters:
    ///   - messages: Array of chat messages
    ///   - temperature: Override default temperature
    ///   - maxTokens: Override default max tokens
    /// - Returns: The assistant's response content
    func complete(
        messages: [ChatMessage],
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) async throws -> String {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await sendRequest(
                    messages: messages,
                    temperature: temperature ?? self.temperature,
                    maxTokens: maxTokens ?? self.maxTokens
                )
            } catch OpenAIClientError.rateLimited(let retryAfter) {
                // Wait before retry
                let waitTime = retryAfter ?? (2 * (attempt + 1))
                try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                lastError = OpenAIClientError.rateLimited(retryAfter: retryAfter)
            } catch OpenAIClientError.networkError(let error) {
                // Retry on network errors with exponential backoff
                let waitTime = 2 * (attempt + 1)
                try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                lastError = OpenAIClientError.networkError(error)
            } catch {
                // Don't retry other errors
                throw error
            }
        }

        throw lastError ?? OpenAIClientError.noResponse
    }

    /// Send a single chat completion request (no retry)
    private func sendRequest(
        messages: [ChatMessage],
        temperature: Double,
        maxTokens: Int?
    ) async throws -> String {
        // Build URL for chat completions endpoint
        let endpoint = baseURL.appendingPathComponent("chat/completions")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization header if API key is provided
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        // Build request body
        let requestBody = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        // Send request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw OpenAIClientError.timeout
        } catch {
            throw OpenAIClientError.networkError(error)
        }

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIClientError.noResponse
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Int($0) }
            throw OpenAIClientError.rateLimited(retryAfter: retryAfter)
        }

        // Handle other errors
        if httpResponse.statusCode >= 400 {
            let errorMessage: String?
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
                
                if isContextLimitError(errorResponse.error) {
                    throw AIProcessingError.contextWindowExceeded
                }
            } else {
                errorMessage = String(data: data, encoding: .utf8)
                
                if let msg = errorMessage, isContextLimitError(msg) {
                    throw AIProcessingError.contextWindowExceeded
                }
            }
            throw OpenAIClientError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Decode response
        let completionResponse: ChatCompletionResponse
        do {
            completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw OpenAIClientError.decodingError(error)
        }

        // Extract content from first choice
        guard let content = completionResponse.choices.first?.message.content, !content.isEmpty else {
            throw OpenAIClientError.emptyContent
        }

        return content
    }
    
    private func isContextLimitError(_ error: APIErrorResponse.APIError) -> Bool {
        let message = error.message.lowercased()
        let code = error.code?.lowercased() ?? ""
        let type = error.type?.lowercased() ?? ""
        
        return message.contains("context") && (message.contains("length") || message.contains("limit") || message.contains("exceeded") || message.contains("token"))
            || code.contains("context_length_exceeded")
            || type.contains("context_length_exceeded")
    }
    
    private func isContextLimitError(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return (lowercased.contains("context") || lowercased.contains("token")) 
            && (lowercased.contains("limit") || lowercased.contains("length") || lowercased.contains("exceeded") || lowercased.contains("maximum"))
    }

    /// Simple completion with a single user message
    func complete(_ prompt: String) async throws -> String {
        try await complete(messages: [.user(prompt)])
    }

    /// Completion with system prompt and user message
    func complete(systemPrompt: String, userMessage: String) async throws -> String {
        try await complete(messages: [
            .system(systemPrompt),
            .user(userMessage)
        ])
    }
}

// MARK: - Convenience Extensions

extension OpenAIClient {
    /// Create a client for OpenAI API
    static func openAI(apiKey: String, model: String = "gpt-4o") -> OpenAIClient {
        OpenAIClient(
            baseURL: URL(string: "https://api.openai.com/v1")!,
            apiKey: apiKey,
            model: model
        )
    }

    /// Create a client for local Ollama
    static func ollama(model: String = "llama3", baseURL: String = "http://localhost:11434/v1") -> OpenAIClient {
        OpenAIClient(
            baseURL: URL(string: baseURL)!,
            apiKey: "",
            model: model
        )
    }
}
