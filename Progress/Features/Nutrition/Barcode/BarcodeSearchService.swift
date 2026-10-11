//
//  BarcodeSearchService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

/// Service for looking up food products by barcode using Open Food Facts API
@MainActor
class BarcodeSearchService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Constants
    
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    
    // MARK: - Search Methods
    
    func searchByBarcode(_ barcode: String) async -> BarcodeResult? {
        guard !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            guard let encodedBarcode = barcode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let url = URL(string: "\(baseURL)/\(encodedBarcode).json") else {
                errorMessage = "Invalid barcode"
                return nil
            }

            var request = URLRequest(url: url)
            request.setValue("Progress/1.0 (com.tom.progress)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return nil
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    errorMessage = "Product not found"
                } else {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                }
                return nil
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
            
            guard apiResponse.status == 1, let product = apiResponse.product else {
                errorMessage = "Product not found"
                return nil
            }
            
            return BarcodeResult(from: product, barcode: barcode)

        } catch is DecodingError {
            errorMessage = "Couldn't read the product details. Try searching instead."
            return nil
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - Models

struct BarcodeResult {
    let barcode: String
    let productName: String
    let brandName: String?
    let servingSize: String
    let calories: Double?
    let protein: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let isVerified: Bool
    
    init(from product: OpenFoodFactsProduct, barcode: String) {
        self.barcode = barcode
        self.productName = product.product_name ?? "Unknown Product"
        self.brandName = product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let grams = product.serving_quantity ?? 100
        self.servingSize = "\(Int(grams.rounded()))g"

        // Open Food Facts reports nutrients per 100g. Scale them to the serving.
        let nutrients = product.nutriments
        let scale = grams / 100
        self.calories = nutrients?.energy_kcal_100g.map { $0 * scale }
        self.protein = nutrients?.proteins_100g.map { $0 * scale }
        self.carbohydrates = nutrients?.carbohydrates_100g.map { $0 * scale }
        self.fat = nutrients?.fat_100g.map { $0 * scale }
        self.fiber = nutrients?.fiber_100g.map { $0 * scale }
        
        // Consider verified if it has nutritional data
        self.isVerified = nutrients?.energy_kcal_100g != nil
    }
    
    var displayName: String {
        if let brand = brandName {
            return "\(brand) \(productName)"
        }
        return productName
    }
}

// MARK: - Open Food Facts API Models

struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Decodable {
    let product_name: String?
    let brands: String?
    let serving_quantity: Double?
    let nutriments: OpenFoodFactsNutriments?

    enum CodingKeys: String, CodingKey {
        case product_name
        case brands
        case serving_quantity
        case nutriments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        product_name = try container.decodeIfPresent(String.self, forKey: .product_name)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        serving_quantity = JSONFlexibleNumber.double(from: container, forKey: .serving_quantity)
        nutriments = try container.decodeIfPresent(OpenFoodFactsNutriments.self, forKey: .nutriments)
    }
}

struct OpenFoodFactsNutriments: Decodable {
    let energy_kcal_100g: Double?
    let proteins_100g: Double?
    let carbohydrates_100g: Double?
    let fat_100g: Double?
    let fiber_100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case energyKcalLegacy = "energy_kcal_100g"
        case proteins_100g
        case carbohydrates_100g
        case fat_100g
        case fiber_100g
        case fibrePer100g = "fibre_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hyphenated = JSONFlexibleNumber.double(from: container, forKey: .energyKcal)
        let legacy = JSONFlexibleNumber.double(from: container, forKey: .energyKcalLegacy)
        energy_kcal_100g = hyphenated ?? legacy
        proteins_100g = JSONFlexibleNumber.double(from: container, forKey: .proteins_100g)
        carbohydrates_100g = JSONFlexibleNumber.double(from: container, forKey: .carbohydrates_100g)
        fat_100g = JSONFlexibleNumber.double(from: container, forKey: .fat_100g)
        let fiber = JSONFlexibleNumber.double(from: container, forKey: .fiber_100g)
        let fibre = JSONFlexibleNumber.double(from: container, forKey: .fibrePer100g)
        fiber_100g = fiber ?? fibre
    }
}

enum JSONFlexibleNumber {
    static func double<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) -> Double? {
        guard container.contains(key) else { return nil }
        if (try? container.decodeNil(forKey: key)) == true {
            return nil
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let raw = try? container.decode(String.self, forKey: key) {
            return double(parsing: raw)
        }
        return nil
    }

    static func double(parsing raw: String) -> Double? {
        let filtered = raw
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." || $0 == "-" }
        guard !filtered.isEmpty else { return nil }
        return Double(filtered)
    }
}