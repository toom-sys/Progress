//
//  FoodSearchService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

/// Service for searching foods using USDA FoodData Central API
@MainActor
class FoodSearchService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchResults: [FoodSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Constants
    
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let apiKey = "DEMO_KEY" // TODO: Replace with actual API key from https://fdc.nal.usda.gov/api-guide.html
    
    // MARK: - Search Methods
    
    func searchFoods(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await performFoodSearch(query: query)
            searchResults = results
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
        
        isLoading = false
    }
    
    private func performFoodSearch(query: String) async throws -> [FoodSearchResult] {
        var components = URLComponents(string: "\(baseURL)/foods/search")!
        
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "25"),
            URLQueryItem(name: "pageNumber", value: "1"),
            URLQueryItem(name: "sortBy", value: "dataType.keyword"),
            URLQueryItem(name: "sortOrder", value: "asc"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw FoodSearchError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw FoodSearchError.serverError(httpResponse.statusCode)
        }
        
        let searchResponse = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
        
        return searchResponse.foods.map { apiFood in
            FoodSearchResult(
                fdcId: apiFood.fdcId,
                description: apiFood.description,
                brandName: apiFood.brandName,
                brandOwner: apiFood.brandOwner,
                servingSize: apiFood.servingSize,
                servingSizeUnit: apiFood.servingSizeUnit,
                calories: extractNutrient(nutrients: apiFood.foodNutrients, nutrientId: 1008), // Energy
                protein: extractNutrient(nutrients: apiFood.foodNutrients, nutrientId: 1003), // Protein
                carbohydrates: extractNutrient(nutrients: apiFood.foodNutrients, nutrientId: 1005), // Carbs
                fat: extractNutrient(nutrients: apiFood.foodNutrients, nutrientId: 1004), // Fat
                fiber: extractNutrient(nutrients: apiFood.foodNutrients, nutrientId: 1079), // Fiber
                dataType: apiFood.dataType
            )
        }
    }
    
    private func extractNutrient(nutrients: [FoodNutrient]?, nutrientId: Int) -> Double? {
        return nutrients?.first { $0.nutrientId == nutrientId }?.value
    }
    
    func getFoodDetails(fdcId: Int) async throws -> FoodSearchResult {
        var components = URLComponents(string: "\(baseURL)/food/\(fdcId)")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw FoodSearchError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw FoodSearchError.serverError(httpResponse.statusCode)
        }
        
        let foodDetail = try JSONDecoder().decode(FoodDetail.self, from: data)
        
        return FoodSearchResult(
            fdcId: foodDetail.fdcId,
            description: foodDetail.description,
            brandName: foodDetail.brandName,
            brandOwner: foodDetail.brandOwner,
            servingSize: foodDetail.servingSize,
            servingSizeUnit: foodDetail.servingSizeUnit,
            calories: extractNutrient(nutrients: foodDetail.foodNutrients, nutrientId: 1008),
            protein: extractNutrient(nutrients: foodDetail.foodNutrients, nutrientId: 1003),
            carbohydrates: extractNutrient(nutrients: foodDetail.foodNutrients, nutrientId: 1005),
            fat: extractNutrient(nutrients: foodDetail.foodNutrients, nutrientId: 1004),
            fiber: extractNutrient(nutrients: foodDetail.foodNutrients, nutrientId: 1079),
            dataType: foodDetail.dataType
        )
    }
}

// MARK: - Data Models

struct FoodSearchResult: Identifiable, Hashable {
    let id = UUID()
    let fdcId: Int
    let description: String
    let brandName: String?
    let brandOwner: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let calories: Double?
    let protein: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let dataType: String?
    
    var displayName: String {
        if let brandName = brandName, !brandName.isEmpty {
            return "\(brandName) \(description)"
        }
        return description
    }
    
    var displayBrand: String? {
        brandOwner ?? brandName
    }
    
    var servingText: String {
        guard let size = servingSize, let unit = servingSizeUnit else {
            return "100g"
        }
        return "\(Int(size))\(unit)"
    }
    
    var isVerified: Bool {
        dataType == "Foundation" || dataType == "SR Legacy"
    }
}

// MARK: - API Response Models

private struct FoodSearchResponse: Codable {
    let foods: [APIFood]
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
}

private struct APIFood: Codable {
    let fdcId: Int
    let description: String
    let brandName: String?
    let brandOwner: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [FoodNutrient]?
    let dataType: String?
}

private struct FoodDetail: Codable {
    let fdcId: Int
    let description: String
    let brandName: String?
    let brandOwner: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [FoodNutrient]
    let dataType: String?
}

private struct FoodNutrient: Codable {
    let nutrientId: Int
    let value: Double
}

// MARK: - Errors

enum FoodSearchError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode search results"
        }
    }
}