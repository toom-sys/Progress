import Foundation

// MARK: - OpenAI API Models

/// Request structure for OpenAI Chat Completions API
struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
    let maxTokens: Int?
    let temperature: Double?
    let topP: Double?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_completion_tokens"
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
    }
}

/// Chat message for OpenAI API
struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

/// Response structure from OpenAI Chat Completions API
struct OpenAIChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChatChoice]
    let usage: OpenAIUsage?
}

/// Individual choice in OpenAI response
struct OpenAIChatChoice: Codable {
    let index: Int
    let message: OpenAIChatMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

/// Token usage information from OpenAI
struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - OpenAI Service Errors

/// Comprehensive error handling for OpenAI API interactions
enum OpenAIServiceError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case networkUnavailable
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case quotaExceeded
    case invalidRequest(message: String)
    case serverError(statusCode: Int)
    case timeout
    case invalidResponse
    case parsingFailed(message: String)
    case contentFiltered
    case modelUnavailable
    case unknown(message: String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .invalidAPIKey:
            return "Invalid OpenAI API key"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait before making more requests"
        case .quotaExceeded:
            return "API quota exceeded"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .timeout:
            return "Request timed out"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .parsingFailed(let message):
            return "Failed to parse response: \(message)"
        case .contentFiltered:
            return "Content was filtered by OpenAI safety systems"
        case .modelUnavailable:
            return "Requested model is not available"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey, .invalidAPIKey:
            return "Please check your OpenAI API key configuration"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .rateLimitExceeded:
            return "Wait a few minutes before making more requests"
        case .quotaExceeded:
            return "Check your OpenAI account billing and usage limits"
        case .timeout:
            return "Check your connection and try again"
        case .contentFiltered:
            return "Try rephrasing your request"
        case .modelUnavailable:
            return "Try using a different model"
        default:
            return "Please try again"
        }
    }
    
    /// Whether this error should trigger a retry
    var shouldRetry: Bool {
        switch self {
        case .rateLimitExceeded, .timeout, .networkUnavailable:
            return true
        case .serverError(let code) where code >= 500:
            return true
        default:
            return false
        }
    }
}

// MARK: - OpenAI Service Configuration

/// Configuration options for OpenAI service
struct OpenAIServiceConfiguration {
    let model: String
    let maxTokens: Int?
    let temperature: Double
    let topP: Double?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    let timeoutInterval: TimeInterval
    let maxRetries: Int
    let baseRetryDelay: TimeInterval
    
    static let `default` = OpenAIServiceConfiguration(
        model: "gpt-5.4-nano",
        maxTokens: 1000,
        temperature: 0.7,
        topP: nil,
        frequencyPenalty: nil,
        presencePenalty: nil,
        timeoutInterval: 30.0,
        maxRetries: 3,
        baseRetryDelay: 2.0
    )
    
    static let workoutGeneration = OpenAIServiceConfiguration(
        model: "gpt-5.4-nano",
        maxTokens: 2000,
        temperature: 0.3, // Lower temperature for more consistent workout generation
        topP: nil,
        frequencyPenalty: 0.1,
        presencePenalty: 0.1,
        timeoutInterval: 45.0,
        maxRetries: 3,
        baseRetryDelay: 2.0
    )

    /// Multi-workout training-plan generation needs a larger response budget
    /// than a single workout, but only one retry so onboarding can fall back
    /// to the rule-based generator quickly.
    static let planGeneration = OpenAIServiceConfiguration(
        model: "gpt-5.4-nano",
        maxTokens: 4000,
        temperature: 0.3,
        topP: nil,
        frequencyPenalty: 0.1,
        presencePenalty: 0.1,
        timeoutInterval: 60.0,
        maxRetries: 1,
        baseRetryDelay: 2.0
    )
}

// MARK: - OpenAI Service

/// Service for interacting with OpenAI's Chat Completions API
/// Handles authentication, rate limiting, error handling, and response parsing
@MainActor
class OpenAIService: ObservableObject {
    
    // MARK: - Properties
    
    private let backend: AIBackend?
    private let modelsURL = "https://api.openai.com/v1/models"
    
    @Published var isProcessing = false
    @Published var lastError: OpenAIServiceError?
    
    // Rate limiting
    private var lastRequestTime: Date = Date.distantPast
    private let minimumRequestInterval: TimeInterval = 1.0 // 1 second between requests
    
    // MARK: - Initialization
    
    init() {
        // Release uses the production proxy; Debug may use Secrets.xcconfig.
        self.backend = AIBackend.resolve()
        if backend == nil {
            print("⚠️ OpenAIService: No AI backend configured — see Secrets.example.xcconfig")
        }
    }
    
    // MARK: - API Key Validation
    
    /// Validates the configuration. In proxy mode the proxy owns the key, so
    /// only being configured matters; in direct mode this pings the models
    /// endpoint with the local key.
    func validateAPIKey() async -> Bool {
        guard let backend else {
            print("❌ OpenAIService: No AI backend configured")
            return false
        }
        
        guard case .direct(let apiKey) = backend else {
            return true
        }
        
        do {
            guard let url = URL(string: modelsURL) else {
                print("❌ OpenAIService: Invalid models URL")
                return false
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isValid = httpResponse.statusCode == 200
                print("🔑 OpenAIService: API Key validation - Status \(httpResponse.statusCode) - \(isValid ? "Valid" : "Invalid")")
                return isValid
            }
            
            return false
        } catch {
            print("❌ OpenAIService: API Key validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Main Chat Completion Method
    
    /// Sends a chat completion request to OpenAI
    /// - Parameters:
    ///   - messages: Array of chat messages
    ///   - configuration: Service configuration options
    /// - Returns: The assistant's response content
    func sendChatCompletion(
        messages: [OpenAIChatMessage],
        configuration: OpenAIServiceConfiguration = .default
    ) async throws -> String {
        
        guard backend != nil else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        // Validate API key on first use
        if lastRequestTime == Date.distantPast {
            let isValid = await validateAPIKey()
            if !isValid {
                throw OpenAIServiceError.invalidAPIKey
            }
        }
        
        // Rate limiting
        await enforceRateLimit()
        
        isProcessing = true
        lastError = nil
        
        defer {
            isProcessing = false
        }
        
        // Retry logic with exponential backoff
        var lastError: OpenAIServiceError?
        
        for attempt in 1...configuration.maxRetries {
            do {
                let response = try await performChatRequest(
                    messages: messages,
                    configuration: configuration
                )
                
                guard let firstChoice = response.choices.first else {
                    throw OpenAIServiceError.invalidResponse
                }
                
                // Check for content filtering
                if firstChoice.finishReason == "content_filter" {
                    throw OpenAIServiceError.contentFiltered
                }
                
                let content = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if content.isEmpty {
                    throw OpenAIServiceError.invalidResponse
                }
                
                print("✅ OpenAIService: Successfully received response (\(content.count) characters)")
                return content
                
            } catch let error as OpenAIServiceError {
                lastError = error
                self.lastError = error
                
                print("⚠️ OpenAIService: Attempt \(attempt)/\(configuration.maxRetries) failed: \(error.localizedDescription)")
                
                // Handle rate limiting with exponential backoff
                if case .rateLimitExceeded(let retryAfter) = error {
                    if attempt < configuration.maxRetries {
                        let delay = retryAfter ?? (configuration.baseRetryDelay * Double(attempt))
                        print("⏱️ OpenAIService: Rate limited, retrying in \(String(format: "%.1f", delay)) seconds...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                // For non-retryable errors, fail immediately
                if !error.shouldRetry {
                    throw error
                }
                
                // For retryable errors, wait before next attempt
                if attempt < configuration.maxRetries {
                    let delay = configuration.baseRetryDelay * Double(attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
            } catch {
                let serviceError = OpenAIServiceError.unknown(message: error.localizedDescription)
                lastError = serviceError
                self.lastError = serviceError
                
                print("❌ OpenAIService: Unexpected error: \(error)")
                
                if attempt < configuration.maxRetries {
                    let delay = configuration.baseRetryDelay * Double(attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw serviceError
                }
            }
        }
        
        // All retries exhausted
        if let error = lastError {
            throw error
        } else {
            throw OpenAIServiceError.unknown(message: "All retry attempts failed")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Sends a simple text prompt to ChatGPT
    /// - Parameters:
    ///   - prompt: The text prompt to send
    ///   - configuration: Service configuration options
    /// - Returns: The assistant's response
    func sendPrompt(
        _ prompt: String,
        configuration: OpenAIServiceConfiguration = .default
    ) async throws -> String {
        let messages = [
            OpenAIChatMessage(role: "user", content: prompt)
        ]
        
        return try await sendChatCompletion(messages: messages, configuration: configuration)
    }
    
    /// Sends a conversation with system prompt and user message
    /// - Parameters:
    ///   - systemPrompt: System instruction for the AI
    ///   - userMessage: User's message
    ///   - configuration: Service configuration options
    /// - Returns: The assistant's response
    func sendConversation(
        systemPrompt: String,
        userMessage: String,
        configuration: OpenAIServiceConfiguration = .default
    ) async throws -> String {
        let messages = [
            OpenAIChatMessage(role: "system", content: systemPrompt),
            OpenAIChatMessage(role: "user", content: userMessage)
        ]
        
        return try await sendChatCompletion(messages: messages, configuration: configuration)
    }
    
    // MARK: - Private Helper Methods
    
    /// Enforces rate limiting between requests
    private func enforceRateLimit() async {
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < minimumRequestInterval {
            let waitTime = minimumRequestInterval - timeSinceLastRequest
            print("⏱️ OpenAIService: Rate limiting - waiting \(String(format: "%.1f", waitTime)) seconds...")
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        lastRequestTime = Date()
    }
    
    /// Performs the actual HTTP request to OpenAI API
    private func performChatRequest(
        messages: [OpenAIChatMessage],
        configuration: OpenAIServiceConfiguration
    ) async throws -> OpenAIChatResponse {
        
        guard let backend else {
            throw OpenAIServiceError.missingAPIKey
        }
        
        // Create request
        var request = URLRequest(url: backend.chatCompletionsURL)
        request.httpMethod = "POST"
        request.setValue(try await backend.authorizationValue(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = configuration.timeoutInterval
        
        // Create request body
        let requestBody = OpenAIChatRequest(
            model: configuration.model,
            messages: messages,
            maxTokens: configuration.maxTokens,
            temperature: configuration.temperature,
            topP: configuration.topP,
            frequencyPenalty: configuration.frequencyPenalty,
            presencePenalty: configuration.presencePenalty
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw OpenAIServiceError.parsingFailed(message: "Failed to encode request: \(error)")
        }
        
        print("🌐 OpenAIService: Making API request to \(configuration.model)...")
        
        // Perform request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIServiceError.invalidResponse
            }
            
            print("📡 OpenAIService: Received response - Status \(httpResponse.statusCode)")
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - parse response
                do {
                    let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                    return chatResponse
                } catch {
                    // Log response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ OpenAIService: Failed to parse response: \(responseString)")
                    }
                    throw OpenAIServiceError.parsingFailed(message: error.localizedDescription)
                }
                
            case 400:
                // Bad request
                let errorMessage = parseErrorMessage(from: data) ?? "Bad request"
                throw OpenAIServiceError.invalidRequest(message: errorMessage)
                
            case 401:
                // Unauthorized
                throw OpenAIServiceError.invalidAPIKey
                
            case 429:
                // Rate limit exceeded
                let retryAfter = parseRetryAfter(from: httpResponse)
                throw OpenAIServiceError.rateLimitExceeded(retryAfter: retryAfter)
                
            case 500...599:
                // Server error
                throw OpenAIServiceError.serverError(statusCode: httpResponse.statusCode)
                
            default:
                let errorMessage = parseErrorMessage(from: data) ?? "Unknown error"
                throw OpenAIServiceError.unknown(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
            
        } catch let error as URLError {
            // Handle network errors
            switch error.code {
            case .notConnectedToInternet:
                throw OpenAIServiceError.networkUnavailable
            case .timedOut:
                throw OpenAIServiceError.timeout
            case .cannotConnectToHost:
                throw OpenAIServiceError.networkUnavailable
            default:
                throw OpenAIServiceError.unknown(message: error.localizedDescription)
            }
        }
    }
    
    /// Parses error message from API response
    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }
    
    /// Parses retry-after header for rate limiting
    private func parseRetryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        if let retryAfterString = response.value(forHTTPHeaderField: "Retry-After"),
           let retryAfter = TimeInterval(retryAfterString) {
            return retryAfter
        }
        return nil
    }
}

// MARK: - Test Interface Extension

extension OpenAIService {
    
    /// Simple test method for validating API integration
    /// This is intended for development and debugging purposes
    func testConnection() async -> (success: Bool, message: String) {
        do {
            let response = try await sendPrompt("Hello! Please respond with 'API connection successful'")
            return (true, "✅ Connection successful: \(response)")
        } catch let error as OpenAIServiceError {
            return (false, "❌ Connection failed: \(error.localizedDescription)")
        } catch {
            return (false, "❌ Unexpected error: \(error.localizedDescription)")
        }
    }
    
    /// Test method for checking different prompt types
    func testPrompt(_ prompt: String) async -> (success: Bool, response: String?, error: String?) {
        do {
            let response = try await sendPrompt(prompt)
            return (true, response, nil)
        } catch let error as OpenAIServiceError {
            return (false, nil, error.localizedDescription)
        } catch {
            return (false, nil, error.localizedDescription)
        }
    }
}
