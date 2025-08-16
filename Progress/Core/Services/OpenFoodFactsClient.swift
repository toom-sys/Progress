//
//  OpenFoodFactsClient.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

/// Enhanced Open Food Facts client with text search and barcode lookup
final class OpenFoodFactsClient: FoodDataService {
    
    // MARK: - FoodDataService Protocol
    
    let source: FoodDataSource = .openFoodFacts
    let isAvailable: Bool = true
    
    var apiUsage: APIUsageStatus {
        return APIUsageStatus(
            requestsUsed: requestCount,
            requestsLimit: 1000, // Open Food Facts is free but we'll track usage
            resetDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            costUsed: 0.0,
            costLimit: 0.0 // Free service
        )
    }
    
    // MARK: - Private Properties
    
    private let baseURL = "https://world.openfoodfacts.org"
    private let userAgent = "Progress-iOS/1.0"
    private var requestCount = 0
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Search Methods
    
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult {
        let startTime = Date()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodDataServiceError.invalidQuery
        }
        
        // Build search URL
        var components = URLComponents(string: "\(baseURL)/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: String(limit)),
            URLQueryItem(name: "page", value: String((offset / limit) + 1)),
            URLQueryItem(name: "fields", value: "product_name,brands,code,nutriments,serving_quantity,serving_size,image_url,categories,ingredients_text")
        ]
        
        guard let url = components.url else {
            throw FoodDataServiceError.invalidQuery
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            requestCount += 1
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FoodDataServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 429 {
                    throw FoodDataServiceError.rateLimitExceeded
                } else {
                    throw FoodDataServiceError.serviceUnavailable
                }
            }
            
            let searchResponse = try JSONDecoder().decode(OpenFoodFactsSearchResponse.self, from: data)
            
            let unifiedItems = searchResponse.products.compactMap { product in
                convertToUnifiedFoodItem(from: product)
            }
            
            let searchTime = Date().timeIntervalSince(startTime)
            
            return UnifiedFoodSearchResult(
                items: unifiedItems,
                totalCount: searchResponse.count ?? unifiedItems.count,
                source: source,
                query: query,
                searchTime: searchTime
            )
            
        } catch {
            if error is FoodDataServiceError {
                throw error
            } else if error is URLError {
                throw FoodDataServiceError.networkUnavailable
            } else {
                throw FoodDataServiceError.malformedResponse
            }
        }
    }
    
    func searchByBarcode(_ barcode: String) async throws -> UnifiedFoodItem? {
        guard !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodDataServiceError.invalidQuery
        }
        
        let url = URL(string: "\(baseURL)/api/v2/product/\(barcode).json")!
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            requestCount += 1
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FoodDataServiceError.invalidResponse
            }
            
            if httpResponse.statusCode == 404 {
                return nil // Product not found
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 429 {
                    throw FoodDataServiceError.rateLimitExceeded
                } else {
                    throw FoodDataServiceError.serviceUnavailable
                }
            }
            
            let barcodeResponse = try JSONDecoder().decode(OpenFoodFactsBarcodeResponse.self, from: data)
            
            guard barcodeResponse.status == 1, let product = barcodeResponse.product else {
                return nil // Product not found or invalid
            }
            
            return convertToUnifiedFoodItem(from: product, barcode: barcode)
            
        } catch {
            if error is FoodDataServiceError {
                throw error
            } else if error is URLError {
                throw FoodDataServiceError.networkUnavailable
            } else {
                throw FoodDataServiceError.malformedResponse
            }
        }
    }
    
    func getFoodDetails(_ itemId: String) async throws -> UnifiedFoodItem? {
        // For Open Food Facts, the itemId is the barcode
        return try await searchByBarcode(itemId)
    }
    
    // MARK: - Model Conversion
    
    private func convertToUnifiedFoodItem(from product: OpenFoodFactsProduct, barcode: String? = nil) -> UnifiedFoodItem? {
        guard let productName = product.product_name, !productName.isEmpty else {
            return nil // Skip products without names
        }
        
        // Extract brand information
        let brand = product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Determine serving size
        let servingSize: String
        let servingSizeGrams: Double?
        
        if let quantity = product.serving_quantity {
            servingSize = "\(Int(quantity))g"
            servingSizeGrams = quantity
        } else if let size = product.serving_size {
            servingSize = size
            servingSizeGrams = extractGramsFromServingSize(size)
        } else {
            servingSize = "100g"
            servingSizeGrams = 100
        }
        
        // Extract nutritional information (per 100g)
        let nutrients = product.nutriments
        let calories = nutrients?.energy_kcal_100g ?? 0
        let protein = nutrients?.proteins_100g ?? 0
        let carbohydrates = nutrients?.carbohydrates_100g ?? 0
        let fat = nutrients?.fat_100g ?? 0
        let fiber = nutrients?.fiber_100g
        let sugar = nutrients?.sugars_100g
        let sodium = nutrients?.sodium_100g != nil ? (nutrients!.sodium_100g! * 1000) : nil // Convert to mg
        let saturatedFat = nutrients?.saturated_fat_100g
        
        // Extract categories and allergens
        let categories = product.categories?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Calculate completeness score based on available data
        let hasBasicNutrition = calories > 0 || protein > 0 || carbohydrates > 0 || fat > 0
        let confidence = hasBasicNutrition ? 0.9 : 0.6 // High confidence for OFF data if nutrition exists
        
        return UnifiedFoodItem(
            sourceId: barcode ?? product.code ?? UUID().uuidString,
            source: .openFoodFacts,
            name: productName,
            brand: brand,
            barcode: barcode ?? product.code,
            servingSize: servingSize,
            servingSizeGrams: servingSizeGrams,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            saturatedFat: saturatedFat,
            sodium: sodium,
            imageUrl: product.image_url,
            ingredients: product.ingredients_text,
            categories: categories,
            confidence: confidence
        )
    }
    
    private func extractGramsFromServingSize(_ servingSize: String) -> Double? {
        // Simple regex to extract grams from serving size strings like "150g", "1 cup (240g)", etc.
        let pattern = #"(\d+(?:\.\d+)?)\s*g"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(servingSize.startIndex..<servingSize.endIndex, in: servingSize)
            if let match = regex.firstMatch(in: servingSize, options: [], range: range) {
                if let gramsRange = Range(match.range(at: 1), in: servingSize) {
                    return Double(servingSize[gramsRange])
                }
            }
        }
        
        return nil
    }
}

// MARK: - Open Food Facts API Models

struct OpenFoodFactsSearchResponse: Codable {
    let count: Int?
    let page: Int?
    let page_count: Int?
    let page_size: Int?
    let products: [OpenFoodFactsProduct]
}

struct OpenFoodFactsBarcodeResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let code: String?
    let product_name: String?
    let brands: String?
    let serving_quantity: Double?
    let serving_size: String?
    let nutriments: OpenFoodFactsNutriments?
    let image_url: String?
    let categories: String?
    let ingredients_text: String?
}

struct OpenFoodFactsNutriments: Codable {
    let energy_kcal_100g: Double?
    let proteins_100g: Double?
    let carbohydrates_100g: Double?
    let fat_100g: Double?
    let fiber_100g: Double?
    let sugars_100g: Double?
    let sodium_100g: Double?
    let saturated_fat_100g: Double?
    
    // Alternative naming conventions that OFF sometimes uses
    let energy_100g: Double?
    let protein_100g: Double?
    let carbs_100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energy_kcal_100g = "energy-kcal_100g"
        case proteins_100g = "proteins_100g"
        case carbohydrates_100g = "carbohydrates_100g"
        case fat_100g = "fat_100g"
        case fiber_100g = "fiber_100g"
        case sugars_100g = "sugars_100g"
        case sodium_100g = "sodium_100g"
        case saturated_fat_100g = "saturated-fat_100g"
        case energy_100g = "energy_100g"
        case protein_100g = "protein_100g"
        case carbs_100g = "carbs_100g"
    }
}
