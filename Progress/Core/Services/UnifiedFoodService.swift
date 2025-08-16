//
//  UnifiedFoodService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

/// Unified service that coordinates multiple food data sources with fallback logic
@MainActor
final class UnifiedFoodService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [UnifiedFoodItem] = []
    
    // MARK: - Private Properties
    
    private var foodServices: [CachedFoodDataService] = []
    private let cache = FoodDataCache.shared
    
    // MARK: - Initialization
    
    init() {
        setupFoodServices()
        
        // Clean expired cache entries on startup
        Task {
            cache.clearExpired()
        }
    }
    
    // MARK: - Public Methods
    
    /// Search for foods across all available data sources
    func searchFoods(query: String, limit: Int = 25) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await searchWithFallback(query: query, limit: limit, offset: 0)
            searchResults = results.items.sorted { $0.priorityScore > $1.priorityScore }
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
        
        isLoading = false
    }
    
    /// Search for a food item by barcode
    func searchByBarcode(_ barcode: String) async -> UnifiedFoodItem? {
        guard !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Try each service in priority order
        for service in foodServices {
            do {
                if let item = try await service.searchByBarcode(barcode) {
                    return item
                }
            } catch {
                // Log error but continue to next service
                print("Barcode search failed for \(service.source): \(error)")
                
                // Only set error message if this is the last service
                if service === foodServices.last {
                    errorMessage = "Failed to find product with barcode: \(barcode)"
                }
            }
        }
        
        return nil
    }
    
    /// Get food details by ID (tries to determine source from ID format)
    func getFoodDetails(_ itemId: String) async -> UnifiedFoodItem? {
        // Try to determine which service based on ID format
        for service in foodServices {
            do {
                if let item = try await service.getFoodDetails(itemId) {
                    return item
                }
            } catch {
                // Continue to next service
                continue
            }
        }
        
        return nil
    }
    
    /// Clear all cached data
    func clearCache() {
        cache.clearAll()
    }
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        return cache.getCacheStats()
    }
    
    // MARK: - Private Methods
    
    private func setupFoodServices() {
        // Initialize services in priority order
        let openFoodFactsClient = OpenFoodFactsClient()
        
        // Wrap services with caching
        foodServices = [
            CachedFoodDataService(wrapping: openFoodFactsClient)
            // Add more services here as they're implemented:
            // CachedFoodDataService(wrapping: EdamamClient()),
            // CachedFoodDataService(wrapping: USDAClient())
        ]
    }
    
    private func searchWithFallback(query: String, limit: Int, offset: Int) async throws -> UnifiedFoodSearchResult {
        var allItems: [UnifiedFoodItem] = []
        var totalCount = 0
        var searchTime: TimeInterval = 0
        var lastError: Error?
        
        // Try each service and combine results
        for service in foodServices {
            do {
                let result = try await service.searchFoods(query: query, limit: limit, offset: offset)
                allItems.append(contentsOf: result.items)
                totalCount = max(totalCount, result.totalCount)
                searchTime += result.searchTime
                
                // If we got good results from a high-priority source, we can return early
                if !result.items.isEmpty && service.source.priority <= 2 {
                    break
                }
                
            } catch {
                lastError = error
                print("Search failed for \(service.source): \(error)")
                
                // If this is a rate limit or quota error, try next service
                if let foodError = error as? FoodDataServiceError,
                   foodError.shouldFallbackToNextSource {
                    continue
                }
            }
        }
        
        // If we got no results from any service, throw the last error
        if allItems.isEmpty, let error = lastError {
            throw error
        }
        
        // Remove duplicates (items with same barcode or very similar names)
        let uniqueItems = removeDuplicates(from: allItems)
        
        return UnifiedFoodSearchResult(
            items: Array(uniqueItems.prefix(limit)),
            totalCount: totalCount,
            source: .openFoodFacts, // Primary source used
            query: query,
            searchTime: searchTime
        )
    }
    
    private func removeDuplicates(from items: [UnifiedFoodItem]) -> [UnifiedFoodItem] {
        var seen = Set<String>()
        var unique: [UnifiedFoodItem] = []
        
        for item in items {
            // Create a key for deduplication
            let key: String
            if let barcode = item.barcode, !barcode.isEmpty {
                key = "barcode_\(barcode)"
            } else {
                // Use normalized name + brand for deduplication
                let normalizedName = item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedBrand = item.brand?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                key = "name_\(normalizedName)_\(normalizedBrand)"
            }
            
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(item)
            }
        }
        
        return unique
    }
}
