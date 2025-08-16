//
//  FoodDataService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

// MARK: - Unified Food Search Result

/// Result container for unified food search operations across multiple data sources
struct UnifiedFoodSearchResult: Codable {
    let items: [UnifiedFoodItem]
    let totalCount: Int
    let source: FoodDataSource
    let query: String
    let searchTime: TimeInterval
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var hasMoreResults: Bool {
        return totalCount > items.count
    }
}

// MARK: - Food Data Service Protocol

/// Protocol defining the interface for food data services
protocol FoodDataService {
    
    // MARK: - Configuration
    
    /// The data source this service represents
    var source: FoodDataSource { get }
    
    /// Whether this service is currently available
    var isAvailable: Bool { get }
    
    /// Current API usage status for budget management
    var apiUsage: APIUsageStatus { get }
    
    // MARK: - Search Methods
    
    /// Search for foods by text query
    /// - Parameters:
    ///   - query: Search text
    ///   - limit: Maximum number of results to return
    ///   - offset: Number of results to skip (for pagination)
    /// - Returns: Search results containing food items
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult
    
    /// Search for food by barcode/UPC
    /// - Parameter barcode: Barcode string
    /// - Returns: Food item if found, nil otherwise
    func searchByBarcode(_ barcode: String) async throws -> UnifiedFoodItem?
    
    // MARK: - Individual Item Methods
    
    /// Get detailed information for a specific food item
    /// - Parameter itemId: Source-specific food item ID
    /// - Returns: Detailed food item information
    func getFoodDetails(_ itemId: String) async throws -> UnifiedFoodItem?
    
    /// Get multiple food items by their IDs
    /// - Parameter itemIds: Array of source-specific food item IDs
    /// - Returns: Array of food items (may be partial if some IDs are invalid)
    func getFoodDetails(_ itemIds: [String]) async throws -> [UnifiedFoodItem]
    
    // MARK: - Suggestion Methods
    
    /// Get autocomplete suggestions for a partial query
    /// - Parameters:
    ///   - partialQuery: Partial search text
    ///   - limit: Maximum number of suggestions
    /// - Returns: Array of suggested search terms
    func getAutocompleteSuggestions(
        for partialQuery: String,
        limit: Int
    ) async throws -> [String]
    
    /// Get popular/trending foods
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of popular food items
    func getPopularFoods(limit: Int) async throws -> [UnifiedFoodItem]
    
    // MARK: - Category Methods
    
    /// Get foods by category
    /// - Parameters:
    ///   - category: Food category name
    ///   - limit: Maximum number of results
    ///   - offset: Number of results to skip
    /// - Returns: Foods in the specified category
    func getFoodsByCategory(
        _ category: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult
    
    /// Get available food categories
    /// - Returns: Array of category names
    func getAvailableCategories() async throws -> [String]
}

// MARK: - API Usage Status

/// Represents current API usage for budget management
struct APIUsageStatus {
    let requestsUsed: Int
    let requestsLimit: Int
    let resetDate: Date
    let costUsed: Double // In currency units
    let costLimit: Double
    
    var requestsRemaining: Int {
        return max(0, requestsLimit - requestsUsed)
    }
    
    var costRemaining: Double {
        return max(0, costLimit - costUsed)
    }
    
    var usagePercentage: Double {
        return Double(requestsUsed) / Double(requestsLimit)
    }
    
    var isNearLimit: Bool {
        return usagePercentage > 0.8
    }
    
    var isAtLimit: Bool {
        return requestsUsed >= requestsLimit || costUsed >= costLimit
    }
    
    /// Time until the usage resets
    var timeUntilReset: TimeInterval {
        return resetDate.timeIntervalSinceNow
    }
}

// MARK: - Food Data Service Errors

/// Errors that can occur when using food data services
enum FoodDataServiceError: LocalizedError, Equatable {
    case networkUnavailable
    case invalidAPIKey
    case rateLimitExceeded
    case quotaExceeded
    case invalidQuery
    case itemNotFound
    case malformedResponse
    case serviceUnavailable
    case timeout
    case unknown(String)
    case invalidResponse
    
    /// Whether this error should trigger fallback to the next data source
    var shouldFallbackToNextSource: Bool {
        switch self {
        case .quotaExceeded, .rateLimitExceeded, .serviceUnavailable, .timeout:
            return true
        case .invalidQuery, .invalidResponse, .malformedResponse, .networkUnavailable, .invalidAPIKey, .itemNotFound, .unknown:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .quotaExceeded:
            return "API quota exceeded"
        case .invalidQuery:
            return "Invalid search query"
        case .itemNotFound:
            return "Food item not found"
        case .malformedResponse:
            return "Invalid response from server"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .timeout:
            return "Request timed out"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .rateLimitExceeded:
            return "Wait a few minutes before making more requests"
        case .quotaExceeded:
            return "Daily quota exceeded. Try again tomorrow"
        case .invalidQuery:
            return "Try a different search term"
        case .serviceUnavailable:
            return "The service is temporarily down. Try again later"
        case .timeout:
            return "Check your connection and try again"
        default:
            return "Please try again"
        }
    }
}

// MARK: - Default Implementations

extension FoodDataService {
    
    /// Default implementation for multiple food details
    func getFoodDetails(_ itemIds: [String]) async throws -> [UnifiedFoodItem] {
        var results: [UnifiedFoodItem] = []
        
        for itemId in itemIds {
            if let item = try await getFoodDetails(itemId) {
                results.append(item)
            }
        }
        
        return results
    }
    
    /// Default implementation for autocomplete (returns empty array)
    func getAutocompleteSuggestions(
        for partialQuery: String,
        limit: Int
    ) async throws -> [String] {
        return []
    }
    
    /// Default implementation for popular foods (returns empty array)
    func getPopularFoods(limit: Int) async throws -> [UnifiedFoodItem] {
        return []
    }
    
    /// Default implementation for category search (returns empty result)
    func getFoodsByCategory(
        _ category: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult {
        return UnifiedFoodSearchResult(
            items: [],
            totalCount: 0,
            source: source,
            query: "category:\(category)",
            searchTime: 0
        )
    }
    
    /// Default implementation for available categories (returns empty array)
    func getAvailableCategories() async throws -> [String] {
        return []
    }
}

// MARK: - Mock Implementation

/// Mock food data service for testing and development
final class MockFoodDataService: FoodDataService {
    
    let source: FoodDataSource = .userCreated
    let isAvailable: Bool = true
    
    var apiUsage: APIUsageStatus {
        return APIUsageStatus(
            requestsUsed: 10,
            requestsLimit: 1000,
            resetDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            costUsed: 0.50,
            costLimit: 10.0
        )
    }
    
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult {
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Filter sample items based on query
        let filteredItems = UnifiedFoodItem.samples.filter { item in
            item.matches(query: query)
        }
        
        let startIndex = min(offset, filteredItems.count)
        let endIndex = min(startIndex + limit, filteredItems.count)
        let pageItems = Array(filteredItems[startIndex..<endIndex])
        
        return UnifiedFoodSearchResult(
            items: pageItems,
            totalCount: filteredItems.count,
            source: source,
            query: query,
            searchTime: 0.5
        )
    }
    
    func searchByBarcode(_ barcode: String) async throws -> UnifiedFoodItem? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return UnifiedFoodItem.samples.first { $0.barcode == barcode }
    }
    
    func getFoodDetails(_ itemId: String) async throws -> UnifiedFoodItem? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return UnifiedFoodItem.samples.first { $0.sourceId == itemId }
    }
}
