//
//  BarcodeSearchService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

/// Enhanced service for looking up food products by barcode using unified food system
@MainActor
class BarcodeSearchService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let unifiedFoodService = UnifiedFoodService()
    
    // MARK: - Search Methods
    
    func searchByBarcode(_ barcode: String) async -> BarcodeResult? {
        guard !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Use the unified food service for barcode lookup
        if let unifiedItem = await unifiedFoodService.searchByBarcode(barcode) {
            return BarcodeResult(from: unifiedItem)
        } else {
            errorMessage = unifiedFoodService.errorMessage ?? "Product not found"
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
        self.brandName = product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
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
    
    // New initializer for UnifiedFoodItem
    init(from unifiedItem: UnifiedFoodItem) {
        self.barcode = unifiedItem.barcode ?? unifiedItem.sourceId
        self.productName = unifiedItem.name
        self.brandName = unifiedItem.brand
        self.servingSize = unifiedItem.servingSize
        self.calories = unifiedItem.calories
        self.protein = unifiedItem.protein
        self.carbohydrates = unifiedItem.carbohydrates
        self.fat = unifiedItem.fat
        self.fiber = unifiedItem.fiber
        self.isVerified = unifiedItem.source.isVerified
    }
    
    var displayName: String {
        if let brand = brandName {
            return "\(brand) \(productName)"
        }
        return productName
    }
}

// Note: OpenFoodFacts API models are now defined in OpenFoodFactsClient.swift