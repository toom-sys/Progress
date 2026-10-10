//
//  FoodPhotoAnalyzerTests.swift
//  Progress
//
//  Created by Progress Team on 10/10/2026.
//

import Foundation
@testable import Progress
import Testing

struct FoodPhotoAnalyzerTests {
    @Test
    func bananaIsAHighConfidenceGuess() {
        let result = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "banana", confidence: 0.91)
        ])

        guard case .success(let guess) = result else {
            Issue.record("Expected a banana guess")
            return
        }

        #expect(guess.foodName == "Banana")
        #expect(guess.calories == 105)
        #expect(guess.needsVerification == false)
    }

    @Test
    func imageNetCommaLabelUsesTheFirstMatchingName() {
        let result = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "hotdog, hot dog, red hot", confidence: 0.86)
        ])

        guard case .success(let guess) = result else {
            Issue.record("Expected a hot dog guess")
            return
        }

        #expect(guess.foodName == "Hot dog")
        #expect(guess.needsVerification == false)
    }

    @Test
    func lowConfidenceStillReturnsAnEditableGuess() {
        let result = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "pizza, pizza pie", confidence: 0.42)
        ])

        guard case .success(let guess) = result else {
            Issue.record("Expected a pizza guess")
            return
        }

        #expect(guess.foodName == "Pizza")
        #expect(guess.needsVerification == true)
    }

    @Test
    func weakAndNonFoodLabelsAskForManualEntry() {
        let weak = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "banana", confidence: 0.05)
        ])
        let notFood = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "sports car", confidence: 0.99)
        ])
        let squash = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "spaghetti squash", confidence: 0.8)
        ])

        #expect(weak == .failure(.noFoodDetected))
        #expect(notFood == .failure(.noFoodDetected))
        #expect(squash == .failure(.noFoodDetected))
    }

    @Test
    func highestConfidenceFoodWins() {
        let result = FoodPhotoAnalyzer.analyze([
            FoodClassification(label: "sports car", confidence: 0.7),
            FoodClassification(label: "apple", confidence: 0.55)
        ])

        guard case .success(let guess) = result else {
            Issue.record("Expected an apple guess")
            return
        }

        #expect(guess.foodName == "Apple")
    }

    @Test
    func unreadablePhotoMessageIsShownInsteadOfACrash() {
        #expect(
            FoodPhotoAnalysisError.unreadableImage.localizedDescription
                == "That photo couldn't be read. Try another one."
        )
    }
}

struct OpenFoodFactsDecodingTests {
    @Test
    func decodesHyphenatedCaloriesAndStringNumbers() throws {
        let json = """
        {
          "status": 1,
          "product": {
            "product_name": "Nutella",
            "brands": "Ferrero, Nutella",
            "serving_quantity": "15",
            "nutriments": {
              "energy-kcal_100g": 539,
              "proteins_100g": "6.3",
              "carbohydrates_100g": 57.5,
              "fat_100g": 30.9,
              "fibre_100g": "3,4"
            }
          }
        }
        """

        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: Data(json.utf8))
        let product = try #require(response.product)
        #expect(product.serving_quantity == 15)
        #expect(product.nutriments?.energy_kcal_100g == 539)
        #expect(product.nutriments?.proteins_100g == 6.3)
        #expect(product.nutriments?.fiber_100g == 3.4)

        let result = BarcodeResult(from: product, barcode: "3017620422003")
        #expect(result.servingSize == "15g")
        #expect(result.calories == 539 * 0.15)
        #expect(result.brandName == "Ferrero")
        #expect(result.isVerified == true)
    }

    @Test
    func missingServingUsesPerHundredGrams() throws {
        let json = """
        {"status":1,"product":{"product_name":"Oats","nutriments":{"energy_kcal_100g":370}}}
        """
        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: Data(json.utf8))
        let product = try #require(response.product)
        let result = BarcodeResult(from: product, barcode: "123")
        #expect(result.servingSize == "100g")
        #expect(result.calories == 370)
    }
}
