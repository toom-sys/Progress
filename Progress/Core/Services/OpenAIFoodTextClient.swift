//
//  OpenAIFoodTextClient.swift
//  Progress
//
//  Text-only forgotten-meal logging. Separate from camera / image analysis.
//

import Foundation

/// Clarifying question shown after the user describes a meal in text.
struct FoodClarifyingQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    /// Optional quick-pick answers; empty means free-text only
    let options: [String]
}

/// Result of phase-1 text meal analysis.
enum FoodDescriptionAnalysis {
    case needsClarification(questions: [FoodClarifyingQuestion])
    case ready(FoodRecognitionResult)
}

/// AI client for describe-food → clarify → estimate macros (no images).
@MainActor
final class OpenAIFoodTextClient: ObservableObject {
    @Published var isAnalyzing = false
    @Published var lastError: String?

    private let openAI = OpenAIService()

    private static let configuration = OpenAIServiceConfiguration(
        model: "gpt-5.4-nano",
        maxTokens: 2000,
        temperature: 0.3,
        topP: nil,
        frequencyPenalty: nil,
        presencePenalty: nil,
        timeoutInterval: 45.0,
        maxRetries: 3,
        baseRetryDelay: 2.0
    )

    /// Phase 1: description → clarifying questions, or ready macros if already specific.
    func analyzeDescription(_ description: String) async throws -> FoodDescriptionAnalysis {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OpenAIFoodTextError.emptyDescription
        }

        isAnalyzing = true
        lastError = nil
        defer { isAnalyzing = false }

        do {
            let content = try await openAI.sendConversation(
                systemPrompt: Self.clarificationSystemPrompt,
                userMessage: """
                The user forgot to log a meal and described it as:

                "\(trimmed)"

                Decide whether you need clarifying questions or can estimate nutrition now.
                Return ONLY valid JSON.
                """,
                configuration: Self.configuration
            )
            return try Self.parseDescriptionAnalysis(content)
                .ensuringDrinkHydration(description: trimmed)
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    /// Phase 2: description + answers → estimated foods/macros.
    func finalizeDescription(
        _ description: String,
        clarifications: [(question: String, answer: String)]
    ) async throws -> FoodRecognitionResult {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OpenAIFoodTextError.emptyDescription
        }

        let clarificationBlock: String
        if clarifications.isEmpty {
            clarificationBlock = "No additional clarifications were provided."
        } else {
            clarificationBlock = clarifications.enumerated().map { index, item in
                "\(index + 1). Q: \(item.question)\n   A: \(item.answer)"
            }.joined(separator: "\n")
        }

        isAnalyzing = true
        lastError = nil
        defer { isAnalyzing = false }

        do {
            let content = try await openAI.sendConversation(
                systemPrompt: Self.finalizeSystemPrompt(forceReady: false),
                userMessage: """
                Original description:
                "\(trimmed)"

                Clarifications:
                \(clarificationBlock)

                Estimate the meal nutrition now. Return ONLY valid JSON with status "ready".
                If this includes any drink, estimated_water_ml MUST be set (not null).
                """,
                configuration: Self.configuration
            )

            let analysis = try Self.parseDescriptionAnalysis(content)
            switch analysis {
            case .ready(let result):
                return result.ensuringDrinkHydration(description: trimmed, clarifications: clarificationBlock)
            case .needsClarification:
                let forced = try await openAI.sendConversation(
                    systemPrompt: Self.finalizeSystemPrompt(forceReady: true),
                    userMessage: """
                    Original description:
                    "\(trimmed)"

                    Clarifications:
                    \(clarificationBlock)

                    Do NOT ask questions. Estimate nutrition now. Return ONLY JSON with status "ready".
                    If this includes any drink, estimated_water_ml MUST be set (not null).
                    """,
                    configuration: Self.configuration
                )
                let forcedAnalysis = try Self.parseDescriptionAnalysis(forced)
                if case .ready(let result) = forcedAnalysis {
                    return result.ensuringDrinkHydration(description: trimmed, clarifications: clarificationBlock)
                }
                throw OpenAIFoodTextError.parsingFailed
            }
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Prompts

    private static let clarificationSystemPrompt = """
    You help users log forgotten meals from a short text description. This is TEXT ONLY — there is no photo.

    Return ONLY valid JSON in one of these two shapes:

    1) Need clarification (prefer this when portion, preparation, or ingredients are unclear):
    {
      "status": "need_clarification",
      "questions": [
        {
          "id": "q1",
          "prompt": "short question",
          "options": ["option A", "option B", "option C"]
        }
      ]
    }

    2) Ready to estimate (only when description already includes clear food + portion):
    {
      "status": "ready",
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
      "estimated_water_ml": number_or_null,
      "overall_confidence": 0.8
    }

    Rules for questions:
    - Ask 1 or 2 questions maximum.
    - Focus on what most changes calories/macros (portion size, cooking method, extras like oil/sauce/cheese).
    - Provide 2–4 short options when useful; use [] for free-text-only questions.
    - Do not ask unnecessary questions if the description is already specific.

    Water / hydration rules (important):
    - Always set estimated_water_ml for drinks (coffee, latte, tea, juice, soft drinks, milk, smoothies, broth) and plain water.
    - Use typical serving volumes when size is missing (e.g. Starbucks Tall/medium coffee ≈ 350, Grande ≈ 470, Venti hot ≈ 590).
    - Coffee, tea, lattes, etc. SHOULD appear in foods for macros AND contribute their liquid volume to estimated_water_ml.
    - Plain water / sparkling water: put volume only in estimated_water_ml (do not list as a food).
    - Exclude alcohol from estimated_water_ml.
    Return only JSON, no markdown.
    """

    private static func finalizeSystemPrompt(forceReady: Bool) -> String {
        let forceLine = forceReady
            ? "You MUST return status \"ready\". Never ask more questions."
            : "Prefer status \"ready\". Only use need_clarification if something critical is still missing (max 1 question)."

        return """
        You help users finish logging a forgotten meal from TEXT only (no photo) after clarifications.

        \(forceLine)

        Return ONLY valid JSON:
        {
          "status": "ready",
          "foods": [
            {
              "name": "food name",
              "quantity": "portion size as a string",
              "calories": 0,
              "protein": 0,
              "carbs": 0,
              "fat": 0,
              "confidence": 0.8
            }
          ],
          "estimated_water_ml": 350,
          "overall_confidence": 0.8
        }

        Rules:
        - Always use status "ready" when forceReady applies; otherwise prefer ready.
        - quantity MUST be a string (e.g. "10 pieces", "1 fillet", "Grande").
        - Use numbers for macros (integers are fine).
        - Split distinct foods into separate items.
        - Omit supplements unless clearly relevant; keep the JSON compact.
        - Hydration: if the meal includes any drink (coffee, latte, tea, juice, soda, milk, smoothie, water, broth), set estimated_water_ml to the total liquid millilitres. Do NOT leave it null for drinks.
        - Typical sizes when unspecified: small/Tall ≈ 350, medium/Grande ≈ 470, large/Venti hot ≈ 590, Venti cold ≈ 710. Default coffee/tea ≈ 350.
        - Plain water belongs only in estimated_water_ml (not in foods).
        - Exclude alcohol from estimated_water_ml.
        - No markdown, no commentary — JSON only.
        """
    }

    // MARK: - Parsing

    private static func parseDescriptionAnalysis(_ content: String) throws -> FoodDescriptionAnalysis {
        let cleanContent = FoodRecognitionJSON.extractJSONObject(from: content)

        guard let data = cleanContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Food text clarify parse failed. Raw:\n\(content)")
            throw OpenAIFoodTextError.parsingFailed
        }

        let status = (json["status"] as? String)?.lowercased() ?? "ready"

        if status == "need_clarification" {
            let questionsArray = json["questions"] as? [[String: Any]] ?? []
            let questions: [FoodClarifyingQuestion] = questionsArray.compactMap { dict in
                let prompt = (dict["prompt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !prompt.isEmpty else { return nil }
                let id = (dict["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString
                let options = (dict["options"] as? [String] ?? [])
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                return FoodClarifyingQuestion(id: id, prompt: prompt, options: options)
            }

            let limited = Array(questions.prefix(2))
            guard !limited.isEmpty else {
                throw OpenAIFoodTextError.parsingFailed
            }
            return .needsClarification(questions: limited)
        }

        do {
            let result = try FoodRecognitionJSON.parse(cleanContent)
            guard !result.foods.isEmpty || (result.estimatedWaterMl ?? 0) > 0 else {
                throw OpenAIFoodTextError.parsingFailed
            }
            return .ready(result)
        } catch {
            print("❌ Food text ready parse failed. Raw:\n\(content)")
            throw OpenAIFoodTextError.parsingFailed
        }
    }
}

// MARK: - Shared JSON food parsing (text + camera)

enum FoodRecognitionJSON {
    static func parse(_ content: String) throws -> FoodRecognitionResult {
        let cleanContent = extractJSONObject(from: content)

        guard let data = cleanContent.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenAIError.parsingFailed
        }

        let foodsArray = json["foods"] as? [[String: Any]] ?? []
        let overallConfidence = parseOptionalDouble(json["overall_confidence"]) ?? 0.5
        let estimatedWaterMl = parseOptionalDouble(json["estimated_water_ml"])

        let recognizedFoods: [RecognizedFood] = foodsArray.compactMap { foodDict in
            guard let name = parseString(foodDict["name"]), !name.isEmpty else {
                return nil
            }
            let quantity = parseString(foodDict["quantity"]) ?? "1 serving"

            var extendedNutrition: [String: Double]?
            if let supplementsDict = foodDict["supplements"] as? [String: Any] {
                var supplements: [String: Double] = [:]
                for (key, value) in supplementsDict {
                    if let doubleValue = parseOptionalDouble(value) {
                        supplements[key] = doubleValue
                    }
                }
                if !supplements.isEmpty {
                    extendedNutrition = supplements
                }
            }

            // Models sometimes use "carbohydrates" instead of "carbs"
            let carbs = parseOptionalDouble(foodDict["carbs"])
                ?? parseOptionalDouble(foodDict["carbohydrates"])

            return RecognizedFood(
                name: name,
                quantity: quantity,
                calories: parseOptionalDouble(foodDict["calories"]),
                protein: parseOptionalDouble(foodDict["protein"]),
                carbs: carbs,
                fat: parseOptionalDouble(foodDict["fat"]),
                confidence: parseOptionalDouble(foodDict["confidence"]) ?? 0.5,
                extendedNutrition: extendedNutrition
            )
        }

        guard !recognizedFoods.isEmpty || (estimatedWaterMl ?? 0) > 0 else {
            throw OpenAIError.parsingFailed
        }

        return FoodRecognitionResult(
            foods: recognizedFoods,
            confidence: overallConfidence,
            rawResponse: cleanContent,
            estimatedWaterMl: estimatedWaterMl.flatMap { $0 > 0 ? $0 : nil }
        )
    }

    /// Pull the first JSON object out of model output that may include markdown or prose.
    static func extractJSONObject(from content: String) -> String {
        let trimmed = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start < end else {
            return trimmed
        }
        return String(trimmed[start...end])
    }

    private static func parseString(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if let intValue = value as? Int {
            return String(intValue)
        }
        if let doubleValue = value as? Double {
            return String(doubleValue)
        }
        return nil
    }

    private static func parseOptionalDouble(_ value: Any?) -> Double? {
        if let doubleValue = value as? Double { return doubleValue }
        if let intValue = value as? Int { return Double(intValue) }
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}

// MARK: - Drink hydration fallback

private extension FoodDescriptionAnalysis {
    func ensuringDrinkHydration(description: String, clarifications: String = "") -> FoodDescriptionAnalysis {
        switch self {
        case .needsClarification:
            return self
        case .ready(let result):
            return .ready(result.ensuringDrinkHydration(description: description, clarifications: clarifications))
        }
    }
}

private extension FoodRecognitionResult {
    func ensuringDrinkHydration(description: String, clarifications: String = "") -> FoodRecognitionResult {
        if let existing = estimatedWaterMl, existing > 0 {
            return self
        }

        let corpus = ([description, clarifications] + foods.map { "\($0.name) \($0.quantity)" })
            .joined(separator: " ")
            .lowercased()

        guard DrinkHydrationEstimate.containsDrink(in: corpus) else {
            return self
        }

        let ml = DrinkHydrationEstimate.millilitres(from: corpus)
        return FoodRecognitionResult(
            foods: foods,
            confidence: confidence,
            rawResponse: rawResponse,
            estimatedWaterMl: ml
        )
    }
}

private enum DrinkHydrationEstimate {
    private static let drinkKeywords = [
        "coffee", "latte", "cappuccino", "espresso", "americano", "mocha", "macchiato",
        "flat white", "cold brew", "frappuccino", "tea", "chai", "matcha", "juice",
        "smoothie", "milkshake", "soda", "cola", "lemonade", "water", "sparkling",
        "broth", "soup", "milk", "hot chocolate", "cocoa"
    ]

    static func containsDrink(in text: String) -> Bool {
        drinkKeywords.contains { text.contains($0) }
    }

    static func millilitres(from text: String) -> Double {
        if text.contains("venti") && (text.contains("iced") || text.contains("cold")) {
            return 710
        }
        if text.contains("venti") { return 590 }
        if text.contains("grande") || text.contains("medium") { return 470 }
        if text.contains("tall") || text.contains("small") { return 350 }
        if text.contains("short") { return 240 }
        if let ml = firstMatch(in: text, pattern: #"(\d{2,4})\s*ml"#) {
            return ml
        }
        if let oz = firstMatch(in: text, pattern: #"(\d{1,2}(?:\.\d+)?)\s*(?:oz|ounces?)"#) {
            return (oz * 29.5735).rounded()
        }
        // Default café drink when size is unknown
        return 350
    }

    private static func firstMatch(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Double(text[range])
    }
}

// MARK: - Errors

enum OpenAIFoodTextError: LocalizedError {
    case emptyDescription
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .emptyDescription:
            return "Please describe what you ate."
        case .parsingFailed:
            return "Couldn't understand the AI response. Please try again."
        }
    }
}
