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
            let url = URL(string: "\(baseURL)/\(barcode).json")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
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
        
        // Try to get serving size, fallback to 100g
        if let servingQuantity = product.serving_quantity {
            self.servingSize = "\(Int(servingQuantity))g"
        } else {
            self.servingSize = "100g"
        }
        
        // Get nutritional info per 100g
        let nutrients = product.nutriments
        self.calories = nutrients?.energy_kcal_100g
        self.protein = nutrients?.proteins_100g
        self.carbohydrates = nutrients?.carbohydrates_100g
        self.fat = nutrients?.fat_100g
        self.fiber = nutrients?.fiber_100g
        
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

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let product_name: String?
    let brands: String?
    let serving_quantity: Double?
    let nutriments: OpenFoodFactsNutriments?
}

struct OpenFoodFactsNutriments: Codable {
    let energy_kcal_100g: Double?
    let proteins_100g: Double?
    let carbohydrates_100g: Double?
    let fat_100g: Double?
    let fiber_100g: Double?
}