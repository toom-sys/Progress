//
//  UnifiedFoodItem.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

// MARK: - Food Data Source

/// Enum representing different food data sources with their priorities
enum FoodDataSource: String, CaseIterable, Codable {
    case openFoodFacts = "open_food_facts"
    case edamam = "edamam"
    case usdaFdc = "usda_fdc"
    case userCreated = "user_created"
    
    /// Priority level for data source (lower number = higher priority)
    var priority: Int {
        switch self {
        case .openFoodFacts: return 1  // Primary source
        case .edamam: return 2         // Secondary source (paid)
        case .usdaFdc: return 3        // Backfill source
        case .userCreated: return 4    // Lowest priority
        }
    }
    
    /// Display name for the data source
    var displayName: String {
        switch self {
        case .openFoodFacts: return "Open Food Facts"
        case .edamam: return "Edamam"
        case .usdaFdc: return "USDA Food Data Central"
        case .userCreated: return "User Created"
        }
    }
    
    /// Whether items from this source are typically verified
    var isVerified: Bool {
        switch self {
        case .openFoodFacts: return true  // Community verified
        case .edamam: return true         // Commercial database
        case .usdaFdc: return true        // Government database
        case .userCreated: return false   // User input
        }
    }
    
    /// Whether this is a paid data source
    var isPaid: Bool {
        switch self {
        case .edamam: return true
        case .openFoodFacts, .usdaFdc, .userCreated: return false
        }
    }
    
    /// Icon representation for the source
    var icon: String {
        switch self {
        case .openFoodFacts: return "globe"
        case .edamam: return "star.fill"
        case .usdaFdc: return "building.columns"
        case .userCreated: return "person.fill"
        }
    }
}

// MARK: - Unified Food Item

/// Unified model representing food data from any source
struct UnifiedFoodItem: Codable, Identifiable, Hashable {
    
    // MARK: - Identity
    
    let id: UUID
    let sourceId: String
    let source: FoodDataSource
    
    // MARK: - Basic Information
    
    let name: String
    let brand: String?
    let barcode: String?
    
    // MARK: - Serving Information
    
    let servingSize: String
    let servingSizeGrams: Double?
    let servingsPerContainer: Double?
    
    // MARK: - Nutritional Information (per serving)
    
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    
    // Optional nutrients
    let fiber: Double?
    let sugar: Double?
    let saturatedFat: Double?
    let sodium: Double?
    let cholesterol: Double?
    let transFat: Double?
    
    // MARK: - Extended Nutrition
    
    /// Additional nutrition metrics (vitamins, minerals, etc.)
    let extendedNutrition: [String: Double]?
    
    // MARK: - Metadata
    
    let imageUrl: String?
    let ingredients: String?
    let allergens: [String]?
    let categories: [String]?
    let lastUpdated: Date
    
    // MARK: - Quality Indicators
    
    /// Confidence score for AI-detected foods (0.0 - 1.0)
    let confidence: Double?
    
    /// Completeness score based on available nutrition data (0.0 - 1.0)
    let completenessScore: Double
    
    // MARK: - Computed Properties
    
    /// Display name combining food name and brand
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(name) (\(brand))"
        }
        return name
    }
    
    /// Whether this item has complete basic nutrition data
    var hasCompleteNutrition: Bool {
        return calories > 0 && protein >= 0 && carbohydrates >= 0 && fat >= 0
    }
    
    /// Whether this item has barcode information
    var hasBarcode: Bool {
        return barcode != nil && !barcode!.isEmpty
    }
    
    /// Whether this item needs verification (low confidence or incomplete data)
    var needsVerification: Bool {
        if let confidence = confidence {
            return confidence < 0.8 || completenessScore < 0.7
        }
        return completenessScore < 0.7
    }
    
    /// Priority score for ranking search results (higher is better)
    var priorityScore: Double {
        let sourcePriority = Double(5 - source.priority) // Invert priority so lower numbers = higher score
        let completenessBonus = completenessScore * 2
        let confidenceBonus = (confidence ?? 0.5) * 2
        let barcodeBonus = hasBarcode ? 1.0 : 0.0
        
        return sourcePriority + completenessBonus + confidenceBonus + barcodeBonus
    }
    
    // MARK: - Initialization
    
    init(
        sourceId: String,
        source: FoodDataSource,
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        servingSize: String,
        servingSizeGrams: Double? = nil,
        servingsPerContainer: Double? = nil,
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        saturatedFat: Double? = nil,
        sodium: Double? = nil,
        cholesterol: Double? = nil,
        transFat: Double? = nil,
        extendedNutrition: [String: Double]? = nil,
        imageUrl: String? = nil,
        ingredients: String? = nil,
        allergens: [String]? = nil,
        categories: [String]? = nil,
        confidence: Double? = nil
    ) {
        self.id = UUID()
        self.sourceId = sourceId
        self.source = source
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.servingSize = servingSize
        self.servingSizeGrams = servingSizeGrams
        self.servingsPerContainer = servingsPerContainer
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.saturatedFat = saturatedFat
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.transFat = transFat
        self.extendedNutrition = extendedNutrition
        self.imageUrl = imageUrl
        self.ingredients = ingredients
        self.allergens = allergens
        self.categories = categories
        self.confidence = confidence
        self.lastUpdated = Date()
        
        // Calculate completeness score
        self.completenessScore = Self.calculateCompletenessScore(
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            extendedNutrition: extendedNutrition
        )
    }
    
    // MARK: - Methods
    
    /// Convert to NutritionEntry for logging
    func toNutritionEntry(
        quantity: Double = 1.0,
        mealType: MealType = .other,
        logMethod: LogMethod = .search
    ) -> NutritionEntry {
        let entry = NutritionEntry(
            foodName: name,
            servingSize: servingSize,
            quantity: quantity,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            mealType: mealType,
            logMethod: logMethod
        )
        
        // Set additional properties
        entry.brandName = brand
        entry.fiber = fiber
        entry.sugar = sugar
        entry.sodium = sodium
        entry.extendedNutrition = extendedNutrition
        entry.foodDatabaseId = sourceId
        entry.barcode = barcode
        entry.isVerified = source.isVerified
        
        // Set AI confidence if available
        if let confidence = confidence {
            entry.aiConfidence = confidence
        }
        
        return entry
    }
    
    /// Get value for a specific nutrition metric
    func getValue(for metric: NutritionMetricType) -> Double {
        switch metric {
        case .calories: return calories
        case .protein: return protein
        case .carbohydrates: return carbohydrates
        case .fat: return fat
        case .fiber: return fiber ?? 0
        case .sugar: return sugar ?? 0
        case .saturatedFat: return saturatedFat ?? 0
        case .sodium: return sodium ?? 0
        case .cholesterol: return cholesterol ?? 0
        case .transFat: return transFat ?? 0
        default:
            return extendedNutrition?[metric.rawValue] ?? 0
        }
    }
    
    /// Check if this item matches a search query
    func matches(query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        
        // Check name
        if name.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Check brand
        if let brand = brand, brand.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Check barcode
        if let barcode = barcode, barcode.contains(query) {
            return true
        }
        
        // Check categories
        if let categories = categories {
            for category in categories {
                if category.lowercased().contains(lowercaseQuery) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    /// Calculate completeness score based on available nutrition data
    private static func calculateCompletenessScore(
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        fiber: Double?,
        sugar: Double?,
        sodium: Double?,
        extendedNutrition: [String: Double]?
    ) -> Double {
        var score: Double = 0
        
        // Basic macros (60% of score)
        if calories > 0 { score += 0.15 }
        if protein >= 0 { score += 0.15 }
        if carbohydrates >= 0 { score += 0.15 }
        if fat >= 0 { score += 0.15 }
        
        // Secondary nutrients (30% of score)
        if fiber != nil { score += 0.1 }
        if sugar != nil { score += 0.1 }
        if sodium != nil { score += 0.1 }
        
        // Extended nutrition (10% of score)
        if let extended = extendedNutrition, !extended.isEmpty {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
}

// MARK: - Sample Data

extension UnifiedFoodItem {
    /// Create sample food items for testing
    static let samples: [UnifiedFoodItem] = [
        UnifiedFoodItem(
            sourceId: "OFF_123",
            source: .openFoodFacts,
            name: "Greek Yogurt",
            brand: "Fage",
            barcode: "123456789012",
            servingSize: "1 container (170g)",
            servingSizeGrams: 170,
            calories: 130,
            protein: 20,
            carbohydrates: 6,
            fat: 4,
            fiber: 0,
            sugar: 6,
            sodium: 65,
            confidence: 0.95
        ),
        UnifiedFoodItem(
            sourceId: "USDA_456",
            source: .usdaFdc,
            name: "Banana",
            servingSize: "1 medium (118g)",
            servingSizeGrams: 118,
            calories: 105,
            protein: 1.3,
            carbohydrates: 27,
            fat: 0.4,
            fiber: 3.1,
            sugar: 14,
            sodium: 1
        ),
        UnifiedFoodItem(
            sourceId: "EDAMAM_789",
            source: .edamam,
            name: "Chicken Breast",
            servingSize: "1 breast (174g)",
            servingSizeGrams: 174,
            calories: 284,
            protein: 53.4,
            carbohydrates: 0,
            fat: 6.2,
            fiber: 0,
            sodium: 126
        )
    ]
}
