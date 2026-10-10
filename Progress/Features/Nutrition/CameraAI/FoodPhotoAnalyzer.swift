//
//  FoodPhotoAnalyzer.swift
//  Progress
//
//  Created by Progress Team on 10/10/2026.
//

import Foundation

/// One label returned by on-device image classification.
struct FoodClassification: Equatable, Sendable {
    let label: String
    let confidence: Double
}

/// Nutrition guess for a photographed meal.
struct FoodPhotoGuess: Equatable, Sendable {
    let foodName: String
    let servingSize: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let confidence: Double

    var needsVerification: Bool {
        confidence < FoodPhotoAnalyzer.verificationThreshold
    }
}

enum FoodPhotoAnalysisError: Error, Equatable, LocalizedError {
    case unreadableImage
    case noFoodDetected
    case analysisFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "That photo couldn't be read. Try another one."
        case .noFoodDetected:
            return "No food was recognised. Enter the details to log it."
        case .analysisFailed(let message):
            return message
        }
    }
}

/// Maps on-device classification labels to nutrition, without a network call.
enum FoodPhotoAnalyzer {
    static let verificationThreshold = 0.8
    static let minimumConfidence = 0.2

    static func analyze(
        _ classifications: [FoodClassification]
    ) -> Result<FoodPhotoGuess, FoodPhotoAnalysisError> {
        let ranked = classifications.sorted { $0.confidence > $1.confidence }

        for classification in ranked where classification.confidence >= minimumConfidence {
            let candidates = normalizedCandidates(classification.label)
            if let profile = profile(matching: candidates) {
                return .success(guess(from: profile, confidence: classification.confidence))
            }
        }

        return .failure(.noFoodDetected)
    }

    private static func normalizedCandidates(_ label: String) -> [String] {
        label
            .split(separator: ",")
            .map { segment in
                segment
                    .lowercased()
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }

    private static func profile(matching candidates: [String]) -> FoodNutritionProfile? {
        for candidate in candidates {
            if let profile = catalog.first(where: { profile in
                profile.aliases.contains { normalize($0) == candidate }
            }) {
                return profile
            }
        }
        return nil
    }

    private static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func guess(
        from profile: FoodNutritionProfile,
        confidence: Double
    ) -> FoodPhotoGuess {
        FoodPhotoGuess(
            foodName: profile.name,
            servingSize: profile.servingSize,
            calories: profile.calories,
            protein: profile.protein,
            carbohydrates: profile.carbohydrates,
            fat: profile.fat,
            fiber: profile.fiber,
            confidence: confidence
        )
    }

    private struct FoodNutritionProfile {
        let name: String
        let servingSize: String
        let calories: Double
        let protein: Double
        let carbohydrates: Double
        let fat: Double
        let fiber: Double
        let aliases: [String]
    }

    /// Typical servings from common USDA values.
    /// Columns: name|serving|kcal|protein|carbs|fat|fiber|aliases separated by `;`.
    private static let catalog: [FoodNutritionProfile] = catalogRows.compactMap(profile(from:))

    private static let catalogRows: [String] = [
        "Banana|1 medium|105|1.3|27|0.4|3.1|banana",
        "Apple|1 medium|95|0.5|25|0.3|4.4|apple;granny smith",
        "Orange|1 medium|62|1.2|15.4|0.2|3.1|orange",
        "Strawberries|1 cup|49|1|12|0.5|3|strawberry",
        "Grapes|1 cup|104|1.1|27|0.2|1.4|grape",
        "Pineapple|1 cup|82|0.9|22|0.2|2.3|pineapple",
        "Watermelon|1 wedge|86|1.7|22|0.4|1.1|watermelon",
        "Lemon|1 medium|17|0.6|5|0.2|1.6|lemon",
        "Pizza|1 slice|285|12|36|10|2.5|pizza;pizza pie",
        "Cheeseburger|1 burger|303|17|30|14|1|cheeseburger;hamburger;burger",
        "Hot dog|1 hot dog|290|10|24|17|1|hotdog;hot dog;red hot",
        "French fries|1 medium|365|4|48|17|4|french fries;french fry;fries",
        "Burrito|1 burrito|430|18|45|18|6|burrito",
        "Taco|1 taco|210|9|20|10|2|taco",
        "Guacamole|2 tbsp|50|0.6|3|4.5|2|guacamole",
        "Sushi|6 pieces|300|12|42|6|1|sushi",
        "Sandwich|1 sandwich|350|18|35|14|3|sandwich",
        "Chicken breast|1 breast|165|31|0|3.6|0|chicken breast;roast chicken;chicken",
        "Steak|3 oz|207|23|0|12|0|steak;beef steak",
        "Salmon|3 oz|177|17|0|11|0|salmon",
        "Rice|1 cup cooked|206|4.3|45|0.4|0.6|rice;fried rice",
        "Pasta|1 cup|220|8|43|1.3|2.5|pasta;spaghetti;carbonara;noodles",
        "Egg|1 large|72|6|0.4|5|0|egg;eggs",
        "Bread|1 slice|79|2.7|15|1|0.8|bread;french loaf;toast",
        "Bagel|1 bagel|245|10|48|1.5|2|bagel;beigel",
        "Oatmeal|1 cup|166|6|28|3.6|4|oatmeal;porridge",
        "Yogurt|1 cup|150|8|17|4|0|yogurt;yoghurt",
        "Broccoli|1 cup|55|3.7|11|0.6|5|broccoli",
        "Salad|1 bowl|150|5|12|9|3|salad;green salad",
        "Ice cream|1 scoop|137|2.3|16|7|0.5|ice cream;icecream",
        "Espresso|1 shot|2|0.1|0|0|0|espresso",
        "Coffee|1 cup|2|0.3|0|0|0|coffee",
        "Avocado|1/2 avocado|120|1.5|6|11|5|avocado",
        "Cheese|1 slice|113|7|0.4|9|0|cheese",
        "Milk|1 cup|149|8|12|8|0|milk",
        "Peanut butter|2 tbsp|188|8|6|16|2|peanut butter",
        "Almonds|1 oz|164|6|6|14|3.5|almond",
        "Popcorn|1 cup|31|1|6|0.4|1|popcorn",
        "Chocolate|1 bar|230|3|26|13|2|chocolate;chocolate sauce",
        "Doughnut|1 doughnut|195|2|22|11|0.7|doughnut;donut",
        "Croissant|1 croissant|230|5|26|12|1|croissant",
        "Pancake|1 pancake|90|2.5|14|3|0.5|pancake",
        "Waffle|1 waffle|218|6|25|11|1|waffle",
        "Muffin|1 muffin|340|6|48|14|1|muffin",
        "Pretzel|1 pretzel|110|3|23|1|1|pretzel",
        "Potato|1 medium|161|4.3|37|0.2|3.8|potato;baked potato;mashed potato",
        "Corn|1 cup|143|5|31|2|3.6|corn;ear of corn",
        "Soup|1 cup|120|6|14|4|1.5|soup",
        "Bacon|2 slices|86|6|0.2|6.6|0|bacon",
        "Hummus|2 tbsp|70|2|4|5|1.5|hummus"
    ]

    private static func profile(from row: String) -> FoodNutritionProfile? {
        let parts = row.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 8,
              let calories = Double(parts[2]),
              let protein = Double(parts[3]),
              let carbohydrates = Double(parts[4]),
              let fat = Double(parts[5]),
              let fiber = Double(parts[6]) else {
            return nil
        }

        let aliases = parts[7].split(separator: ";").map(String.init)
        return FoodNutritionProfile(
            name: parts[0],
            servingSize: parts[1],
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            aliases: aliases
        )
    }
}
