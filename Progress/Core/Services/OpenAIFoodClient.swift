import Foundation
import UIKit

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

// MARK: - Food Recognition Result
struct FoodRecognitionResult {
    let foods: [RecognizedFood]
    let confidence: Double
    let rawResponse: String
}

struct RecognizedFood {
    let name: String
    let quantity: String
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let confidence: Double
    
    // Extended nutrition data for supplements and vitamins/minerals
    let extendedNutrition: [String: Double]?
    
    init(name: String, quantity: String, calories: Double?, protein: Double?, carbs: Double?, fat: Double?, confidence: Double, extendedNutrition: [String: Double]? = nil) {
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.confidence = confidence
        self.extendedNutrition = extendedNutrition
    }
}

// MARK: - OpenAI Food Client
@MainActor
class OpenAIFoodClient: ObservableObject {
    private let backend: AIBackend?
    
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    // Rate limiting
    private var lastRequestTime: Date = Date.distantPast
    private let minimumRequestInterval: TimeInterval = 2.0 // 2 seconds between requests
    
    init() {
        // Proxy URL or dev key from Secrets.xcconfig — see AIBackend.
        self.backend = AIBackend.resolve()
        if backend == nil {
            print("⚠️ OpenAIFoodClient: No AI backend configured — see Secrets.example.xcconfig")
        }
    }
    
    // MARK: - API Key Validation
    /// In proxy mode the proxy owns the key, so only being configured
    /// matters; in direct mode this pings the models endpoint.
    func validateAPIKey() async -> Bool {
        guard let backend else { return false }
        guard case .direct(let apiKey) = backend else { return true }
        
        do {
            let url = URL(string: "https://api.openai.com/v1/models")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔑 API Key validation: Status \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200
            }
            
            return false
        } catch {
            print("❌ API Key validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Main Analysis Function
    func analyzeFoodImage(_ image: UIImage) async throws -> FoodRecognitionResult {
        guard backend != nil else {
            throw OpenAIError.missingAPIKey
        }
        
        // Validate API key first
        let isValidKey = await validateAPIKey()
        if !isValidKey {
            throw OpenAIError.invalidAPIKey
        }
        
        // Rate limiting check
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < minimumRequestInterval {
            let waitTime = minimumRequestInterval - timeSinceLastRequest
            print("⏱️ Rate limiting: waiting \(String(format: "%.1f", waitTime)) seconds...")
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        lastRequestTime = Date()
        
        isAnalyzing = true
        lastError = nil
        
        defer {
            isAnalyzing = false
        }
        
        // Retry logic for rate limits
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                // Convert image to base64 with proper compression and size limits
                let resizedImage = resizeImageIfNeeded(image)
                let finalImageData = resizedImage.jpegData(compressionQuality: 0.8)
                
                guard var imageData = finalImageData else {
                    throw OpenAIError.imageProcessingFailed
                }
                
                // Check image size (OpenAI has a 20MB limit, but we'll keep it smaller)
                let maxSize = 5 * 1024 * 1024 // 5MB
                if imageData.count > maxSize {
                    print("⚠️ Image too large: \(imageData.count) bytes, compressing further...")
                    guard let compressedData = resizedImage.jpegData(compressionQuality: 0.5) else {
                        throw OpenAIError.imageProcessingFailed
                    }
                    imageData = compressedData
                    print("✅ Compressed image to \(imageData.count) bytes")
                } else {
                    print("✅ Image size OK: \(imageData.count) bytes")
                }
                
                let base64Image = imageData.base64EncodedString()
                
                // Create request
                let request = try await createAnalysisRequest(base64Image: base64Image)
                
                // Make API call
                print("🌐 Making OpenAI API request...")
                let (data, response) = try await URLSession.shared.data(for: request)
                print("📡 Received response from OpenAI API")
                
                // Check response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OpenAIError.invalidResponse
                }
                
                // Handle different HTTP status codes
                print("🔍 OpenAI API Response: Status \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    break // Success
                case 429:
                    // Log the response body for rate limit details
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("⚠️ Rate limit response: \(responseString)")
                    }
                    throw OpenAIError.rateLimitExceeded
                case 401:
                    // Log the response body for auth details
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Auth error response: \(responseString)")
                    }
                    throw OpenAIError.invalidAPIKey
                case 400:
                    // Log the response body for bad request details
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Bad request response: \(responseString)")
                    }
                    throw OpenAIError.badRequest
                default:
                    // Log the response body for other errors
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ API error \(httpResponse.statusCode) response: \(responseString)")
                    }
                    throw OpenAIError.apiError(httpResponse.statusCode)
                }
                
                // Parse response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                guard let content = openAIResponse.choices.first?.message.content else {
                    throw OpenAIError.noContent
                }
                
                // Parse the structured response
                let result = try parseAnalysisResult(content)
                
                return result
                
            } catch let error as OpenAIError {
                lastError = error
                
                // Handle rate limit (429) with exponential backoff
                if case .rateLimitExceeded = error {
                    if attempt < maxRetries {
                        let delay = Double(attempt * 2) // 2, 4, 6 seconds
                        print("⚠️ Rate limit hit, retrying in \(delay) seconds... (attempt \(attempt)/\(maxRetries))")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                // For other errors, don't retry
                self.lastError = error.localizedDescription
                throw error
            } catch {
                lastError = error
                print("❌ Network/Other error: \(error)")
                
                // Check if it's a network connectivity issue
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.lastError = "No internet connection"
                    case .timedOut:
                        self.lastError = "Request timed out"
                    case .cannotConnectToHost:
                        self.lastError = "Cannot connect to OpenAI servers"
                    default:
                        self.lastError = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    self.lastError = error.localizedDescription
                }
                
                throw error
            }
        }
        
        // If we get here, all retries failed
        if let error = lastError {
            self.lastError = error.localizedDescription
            
            // For development/testing: provide a fallback mock response for rate limits
            if case .rateLimitExceeded = error as? OpenAIError {
                print("🔄 All retries failed due to rate limits, providing mock response for testing")
                return createMockFoodRecognitionResult()
            }
            
            throw error
        } else {
            throw OpenAIError.rateLimitExceeded
        }
    }
    
    // MARK: - Private Helper Methods
    private func createAnalysisRequest(base64Image: String) async throws -> URLRequest {
        guard let backend else {
            throw OpenAIError.missingAPIKey
        }
        
        var request = URLRequest(url: backend.chatCompletionsURL)
        request.httpMethod = "POST"
        request.setValue(try await backend.authorizationValue(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        
        let prompt = createFoodAnalysisPrompt()
        
        let requestBody: [String: Any] = [
            "model": "gpt-5.4-nano",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
            "max_completion_tokens": 600,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return request
    }
    
    // MARK: - Image Processing
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024 // Max width or height
        let size = image.size
        
        // If image is already small enough, return as-is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Mock Response for Testing
    private func createMockFoodRecognitionResult() -> FoodRecognitionResult {
        let mockFoods = [
            RecognizedFood(
                name: "Apple",
                quantity: "1 medium",
                calories: 95,
                protein: 0.5,
                carbs: 25,
                fat: 0.3,
                confidence: 0.8,
                extendedNutrition: [
                    "fiber": 4.4,
                    "vitamin_c": 8.4,
                    "potassium": 195
                ]
            ),
            RecognizedFood(
                name: "Banana",
                quantity: "1 medium",
                calories: 105,
                protein: 1.3,
                carbs: 27,
                fat: 0.4,
                confidence: 0.7,
                extendedNutrition: [
                    "fiber": 3.1,
                    "vitamin_b6": 0.4,
                    "vitamin_c": 10.3,
                    "potassium": 422
                ]
            )
        ]
        
        return FoodRecognitionResult(
            foods: mockFoods,
            confidence: 0.75,
            rawResponse: "Mock response due to API rate limits"
        )
    }
    
    private func createFoodAnalysisPrompt() -> String {
        return """
        Analyze this food image and return ONLY valid JSON in this format:

        {
          "foods": [
            {
              "name": "food name",
              "quantity": "portion size",
              "calories": number,
              "protein": number,
              "carbs": number,
              "fat": number,
              "confidence": 0.8,
              "supplements": {
                "fiber": number_or_null,
                "vitamin_d": number_or_null,
                "magnesium": number_or_null,
                "zinc": number_or_null,
                "omega_3": number_or_null,
                "creatine": number_or_null
              }
            }
          ],
          "overall_confidence": 0.8
        }

        For each food item:
        1. Identify the food and estimate portion size
        2. Provide basic macros (calories, protein, carbs, fat)
        3. Fill in supplement values where the food naturally contains significant amounts
        4. Use null where the food contains negligible amounts

        Examples:
        - Salmon: high omega_3, vitamin_d
        - Spinach: high magnesium, fiber
        - Beef: high creatine, zinc
        - Nuts: high magnesium, fiber
        - Oats: high fiber, magnesium

        Return only JSON, no other text.
        """
    }
    
    private func parseAnalysisResult(_ content: String) throws -> FoodRecognitionResult {
        // Clean up the response (remove any markdown formatting)
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanContent.data(using: .utf8) else {
            throw OpenAIError.parsingFailed
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let foodsArray = json?["foods"] as? [[String: Any]] else {
                throw OpenAIError.parsingFailed
            }
            
            let overallConfidence = json?["overall_confidence"] as? Double ?? 0.5
            
            let recognizedFoods = try foodsArray.map { foodDict -> RecognizedFood in
                guard let name = foodDict["name"] as? String,
                      let quantity = foodDict["quantity"] as? String else {
                    throw OpenAIError.parsingFailed
                }
                
                // Parse supplement data if available
                var extendedNutrition: [String: Double]? = nil
                if let supplementsDict = foodDict["supplements"] as? [String: Any] {
                    var supplements: [String: Double] = [:]
                    
                    // Map the supplement keys to our nutrition metric types
                    for (key, value) in supplementsDict {
                        if let doubleValue = value as? Double {
                            supplements[key] = doubleValue
                        } else if let intValue = value as? Int {
                            supplements[key] = Double(intValue)
                        }
                        // Skip null values (they won't be added to the dictionary)
                    }
                    
                    if !supplements.isEmpty {
                        extendedNutrition = supplements
                    }
                }
                
                return RecognizedFood(
                    name: name,
                    quantity: quantity,
                    calories: foodDict["calories"] as? Double,
                    protein: foodDict["protein"] as? Double,
                    carbs: foodDict["carbs"] as? Double,
                    fat: foodDict["fat"] as? Double,
                    confidence: foodDict["confidence"] as? Double ?? 0.5,
                    extendedNutrition: extendedNutrition
                )
            }
            
            return FoodRecognitionResult(
                foods: recognizedFoods,
                confidence: overallConfidence,
                rawResponse: cleanContent
            )
            
        } catch {
            throw OpenAIError.parsingFailed
        }
    }
}

// MARK: - Error Types
enum OpenAIError: LocalizedError {
    case missingAPIKey
    case imageProcessingFailed
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case noContent
    case parsingFailed
    case rateLimitExceeded
    case invalidAPIKey
    case badRequest
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error: \(code)"
        case .noContent:
            return "No content in response"
        case .parsingFailed:
            return "Failed to parse response"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key."
        case .badRequest:
            return "Invalid request. Please try again with a different image."
        }
    }
}
