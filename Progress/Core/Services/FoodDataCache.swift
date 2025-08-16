//
//  FoodDataCache.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

/// Simple UserDefaults-based cache for food data with TTL expiration
final class FoodDataCache: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = FoodDataCache()
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Cache keys
    private let barcodePrefix = "cache_barcode_"
    private let searchPrefix = "cache_search_"
    private let timestampSuffix = "_timestamp"
    
    // Cache settings
    private let defaultTTL: TimeInterval = 3600 // 1 hour
    private let searchTTL: TimeInterval = 1800 // 30 minutes
    private let barcodeTTL: TimeInterval = 86400 // 24 hours (barcodes rarely change)
    
    // MARK: - Initialization
    
    private init() {
        // Setup JSON encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Barcode Cache
    
    /// Cache a food item from barcode lookup
    func cacheBarcodeResult(_ item: UnifiedFoodItem, forBarcode barcode: String) {
        let key = barcodePrefix + barcode
        cacheItem(item, forKey: key, ttl: barcodeTTL)
    }
    
    /// Retrieve cached barcode result
    func getCachedBarcodeResult(forBarcode barcode: String) -> UnifiedFoodItem? {
        let key = barcodePrefix + barcode
        return getCachedItem(forKey: key)
    }
    
    // MARK: - Search Cache
    
    /// Cache search results
    func cacheSearchResult(_ result: UnifiedFoodSearchResult, forQuery query: String, limit: Int, offset: Int) {
        let key = searchKey(query: query, limit: limit, offset: offset)
        cacheSearchResult(result, forKey: key, ttl: searchTTL)
    }
    
    /// Retrieve cached search results
    func getCachedSearchResult(forQuery query: String, limit: Int, offset: Int) -> UnifiedFoodSearchResult? {
        let key = searchKey(query: query, limit: limit, offset: offset)
        return getCachedSearchResult(forKey: key)
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(barcodePrefix) || key.hasPrefix(searchPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    /// Clear expired cache entries
    func clearExpired() {
        let keys = userDefaults.dictionaryRepresentation().keys
        let now = Date()
        
        for key in keys {
            if key.hasPrefix(barcodePrefix) || key.hasPrefix(searchPrefix) {
                let timestampKey = key + timestampSuffix
                if let timestamp = userDefaults.object(forKey: timestampKey) as? Date {
                    let ttl = key.hasPrefix(barcodePrefix) ? barcodeTTL : searchTTL
                    if now.timeIntervalSince(timestamp) > ttl {
                        userDefaults.removeObject(forKey: key)
                        userDefaults.removeObject(forKey: timestampKey)
                    }
                }
            }
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        let keys = userDefaults.dictionaryRepresentation().keys
        var barcodeCount = 0
        var searchCount = 0
        var totalSize = 0
        
        for key in keys {
            if key.hasPrefix(barcodePrefix) && !key.hasSuffix(timestampSuffix) {
                barcodeCount += 1
                if let data = userDefaults.data(forKey: key) {
                    totalSize += data.count
                }
            } else if key.hasPrefix(searchPrefix) && !key.hasSuffix(timestampSuffix) {
                searchCount += 1
                if let data = userDefaults.data(forKey: key) {
                    totalSize += data.count
                }
            }
        }
        
        return CacheStats(
            barcodeEntries: barcodeCount,
            searchEntries: searchCount,
            totalSizeBytes: totalSize
        )
    }
    
    // MARK: - Private Methods
    
    private func cacheItem(_ item: UnifiedFoodItem, forKey key: String, ttl: TimeInterval) {
        do {
            let data = try encoder.encode(item)
            userDefaults.set(data, forKey: key)
            userDefaults.set(Date(), forKey: key + timestampSuffix)
        } catch {
            print("Failed to cache item: \(error)")
        }
    }
    
    private func getCachedItem(forKey key: String) -> UnifiedFoodItem? {
        // Check if item exists and is not expired
        let timestampKey = key + timestampSuffix
        guard let timestamp = userDefaults.object(forKey: timestampKey) as? Date else {
            return nil
        }
        
        let ttl = key.hasPrefix(barcodePrefix) ? barcodeTTL : defaultTTL
        guard Date().timeIntervalSince(timestamp) <= ttl else {
            // Item expired, remove it
            userDefaults.removeObject(forKey: key)
            userDefaults.removeObject(forKey: timestampKey)
            return nil
        }
        
        // Item is valid, decode and return
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try decoder.decode(UnifiedFoodItem.self, from: data)
        } catch {
            print("Failed to decode cached item: \(error)")
            // Remove corrupted cache entry
            userDefaults.removeObject(forKey: key)
            userDefaults.removeObject(forKey: timestampKey)
            return nil
        }
    }
    
    private func cacheSearchResult(_ result: UnifiedFoodSearchResult, forKey key: String, ttl: TimeInterval) {
        do {
            let data = try encoder.encode(result)
            userDefaults.set(data, forKey: key)
            userDefaults.set(Date(), forKey: key + timestampSuffix)
        } catch {
            print("Failed to cache search result: \(error)")
        }
    }
    
    private func getCachedSearchResult(forKey key: String) -> UnifiedFoodSearchResult? {
        // Check if result exists and is not expired
        let timestampKey = key + timestampSuffix
        guard let timestamp = userDefaults.object(forKey: timestampKey) as? Date else {
            return nil
        }
        
        guard Date().timeIntervalSince(timestamp) <= searchTTL else {
            // Result expired, remove it
            userDefaults.removeObject(forKey: key)
            userDefaults.removeObject(forKey: timestampKey)
            return nil
        }
        
        // Result is valid, decode and return
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try decoder.decode(UnifiedFoodSearchResult.self, from: data)
        } catch {
            print("Failed to decode cached search result: \(error)")
            // Remove corrupted cache entry
            userDefaults.removeObject(forKey: key)
            userDefaults.removeObject(forKey: timestampKey)
            return nil
        }
    }
    
    private func searchKey(query: String, limit: Int, offset: Int) -> String {
        // Create a normalized search key
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(searchPrefix)\(normalizedQuery)_\(limit)_\(offset)"
    }
}

// MARK: - Cache Statistics

struct CacheStats {
    let barcodeEntries: Int
    let searchEntries: Int
    let totalSizeBytes: Int
    
    var totalEntries: Int {
        return barcodeEntries + searchEntries
    }
    
    var totalSizeKB: Double {
        return Double(totalSizeBytes) / 1024.0
    }
    
    var totalSizeMB: Double {
        return totalSizeKB / 1024.0
    }
}

// MARK: - Cached Food Data Service

/// Wrapper service that adds caching to any FoodDataService
final class CachedFoodDataService: FoodDataService {
    
    // MARK: - Properties
    
    private let underlyingService: FoodDataService
    private let cache = FoodDataCache.shared
    
    var source: FoodDataSource {
        return underlyingService.source
    }
    
    var isAvailable: Bool {
        return underlyingService.isAvailable
    }
    
    var apiUsage: APIUsageStatus {
        return underlyingService.apiUsage
    }
    
    // MARK: - Initialization
    
    init(wrapping service: FoodDataService) {
        self.underlyingService = service
    }
    
    // MARK: - FoodDataService Implementation
    
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult {
        
        // Check cache first
        if let cachedResult = cache.getCachedSearchResult(forQuery: query, limit: limit, offset: offset) {
            return cachedResult
        }
        
        // Cache miss, fetch from underlying service
        let result = try await underlyingService.searchFoods(query: query, limit: limit, offset: offset)
        
        // Cache the result
        cache.cacheSearchResult(result, forQuery: query, limit: limit, offset: offset)
        
        return result
    }
    
    func searchByBarcode(_ barcode: String) async throws -> UnifiedFoodItem? {
        
        // Check cache first
        if let cachedItem = cache.getCachedBarcodeResult(forBarcode: barcode) {
            return cachedItem
        }
        
        // Cache miss, fetch from underlying service
        let item = try await underlyingService.searchByBarcode(barcode)
        
        // Cache the result if found
        if let item = item {
            cache.cacheBarcodeResult(item, forBarcode: barcode)
        }
        
        return item
    }
    
    func getFoodDetails(_ itemId: String) async throws -> UnifiedFoodItem? {
        return try await underlyingService.getFoodDetails(itemId)
    }
    
    func getAutocompleteSuggestions(
        for partialQuery: String,
        limit: Int
    ) async throws -> [String] {
        return try await underlyingService.getAutocompleteSuggestions(for: partialQuery, limit: limit)
    }
    
    func getPopularFoods(limit: Int) async throws -> [UnifiedFoodItem] {
        return try await underlyingService.getPopularFoods(limit: limit)
    }
    
    func getFoodsByCategory(
        _ category: String,
        limit: Int,
        offset: Int
    ) async throws -> UnifiedFoodSearchResult {
        return try await underlyingService.getFoodsByCategory(category, limit: limit, offset: offset)
    }
    
    func getAvailableCategories() async throws -> [String] {
        return try await underlyingService.getAvailableCategories()
    }
}
