//
//  NutritionEntry.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
final class NutritionEntry {
    
    // MARK: - Properties
    
    /// Unique identifier for the nutrition entry
    var id: UUID
    
    /// Name of the food item
    var foodName: String
    
    /// Brand name (if applicable)
    var brandName: String?
    
    /// Serving size description (e.g., "1 cup", "100g")
    var servingSize: String
    
    /// Quantity of servings consumed
    var quantity: Double
    
    /// When this entry was logged
    var loggedAt: Date
    
    /// Which meal this belongs to
    var mealType: MealType
    
    /// How this food was logged
    var logMethod: LogMethod
    
    // MARK: - Nutritional Information (per serving)
    
    /// Calories per serving
    var calories: Double
    
    /// Protein in grams per serving
    var protein: Double
    
    /// Carbohydrates in grams per serving
    var carbohydrates: Double
    
    /// Fat in grams per serving
    var fat: Double
    
    /// Fiber in grams per serving (optional)
    var fiber: Double?
    
    /// Sugar in grams per serving (optional)
    var sugar: Double?
    
    /// Sodium in milligrams per serving (optional)
    var sodium: Double?
    
    // MARK: - Database Information
    
    /// Food database ID (for verified foods)
    var foodDatabaseId: String?
    
    /// Barcode (if scanned)
    var barcode: String?
    
    /// Confidence level for AI-detected foods (0.0 - 1.0)
    var aiConfidence: Double?
    
    /// Whether this is a verified food from database
    var isVerified: Bool
    
    /// Whether this entry has been marked as favorite
    var isFavorite: Bool
    
    /// User notes about the entry
    var notes: String?
    
    // MARK: - Relationships
    
    /// The user who logged this entry
    var user: User?
    
    // MARK: - Computed Properties
    
    /// Total calories for the quantity consumed
    var totalCalories: Double {
        calories * quantity
    }
    
    /// Total protein for the quantity consumed
    var totalProtein: Double {
        protein * quantity
    }
    
    /// Total carbohydrates for the quantity consumed
    var totalCarbohydrates: Double {
        carbohydrates * quantity
    }
    
    /// Total fat for the quantity consumed
    var totalFat: Double {
        fat * quantity
    }
    
    /// Total fiber for the quantity consumed
    var totalFiber: Double {
        (fiber ?? 0) * quantity
    }
    
    /// Display name combining food and brand
    var displayName: String {
        if let brand = brandName, !brand.isEmpty {
            return "\(foodName) (\(brand))"
        }
        return foodName
    }
    
    /// Whether this entry was logged today
    var isToday: Bool {
        Calendar.current.isDateInToday(loggedAt)
    }
    
    /// Whether this entry needs verification (low AI confidence)
    var needsVerification: Bool {
        if let confidence = aiConfidence {
            return confidence < 0.8 // Below 80% confidence
        }
        return false
    }
    
    // MARK: - Initialization
    
    init(
        foodName: String,
        servingSize: String,
        quantity: Double,
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        mealType: MealType = .other,
        logMethod: LogMethod = .manual
    ) {
        self.id = UUID()
        self.foodName = foodName
        self.servingSize = servingSize
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.mealType = mealType
        self.logMethod = logMethod
        self.loggedAt = Date()
        self.isVerified = false
        self.isFavorite = false
    }
    
    // MARK: - Methods
    
    /// Update the quantity and recalculate totals
    func updateQuantity(_ newQuantity: Double) {
        quantity = newQuantity
    }
    
    /// Mark this entry as favorite
    func markAsFavorite() {
        isFavorite = true
    }
    
    /// Remove from favorites
    func removeFromFavorites() {
        isFavorite = false
    }
    
    /// Update nutritional information
    func updateNutrition(
        calories: Double? = nil,
        protein: Double? = nil,
        carbohydrates: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil
    ) {
        if let calories = calories { self.calories = calories }
        if let protein = protein { self.protein = protein }
        if let carbohydrates = carbohydrates { self.carbohydrates = carbohydrates }
        if let fat = fat { self.fat = fat }
        if let fiber = fiber { self.fiber = fiber }
        if let sugar = sugar { self.sugar = sugar }
        if let sodium = sodium { self.sodium = sodium }
    }
    
    /// Set AI detection data
    func setAIData(confidence: Double, foodDatabaseId: String? = nil) {
        self.aiConfidence = confidence
        self.foodDatabaseId = foodDatabaseId
        self.logMethod = .aiCamera
    }
    
    /// Set barcode data
    func setBarcodeData(_ barcode: String, foodDatabaseId: String) {
        self.barcode = barcode
        self.foodDatabaseId = foodDatabaseId
        self.logMethod = .barcode
        self.isVerified = true
    }
    
    /// Verify this entry (for AI-detected foods)
    func verify() {
        isVerified = true
    }
    
    /// Create a duplicate entry for quick logging
    func duplicate(quantity: Double? = nil, mealType: MealType? = nil) -> NutritionEntry {
        let newEntry = NutritionEntry(
            foodName: foodName,
            servingSize: servingSize,
            quantity: quantity ?? self.quantity,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            mealType: mealType ?? self.mealType,
            logMethod: .manual
        )
        
        newEntry.brandName = brandName
        newEntry.fiber = fiber
        newEntry.sugar = sugar
        newEntry.sodium = sodium
        newEntry.foodDatabaseId = foodDatabaseId
        newEntry.isVerified = isVerified
        
        return newEntry
    }
}

// MARK: - Enums

enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "sunset.fill"
        case .snack: return "leaf.fill"
        case .other: return "circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .breakfast: return "orange"
        case .lunch: return "yellow"
        case .dinner: return "purple"
        case .snack: return "green"
        case .other: return "gray"
        }
    }
    
    /// Typical time range for this meal
    var timeRange: String {
        switch self {
        case .breakfast: return "6:00 - 10:00"
        case .lunch: return "11:00 - 14:00"
        case .dinner: return "17:00 - 21:00"
        case .snack: return "Any time"
        case .other: return "Any time"
        }
    }
}

enum LogMethod: String, CaseIterable, Codable {
    case manual = "manual"
    case search = "search"
    case barcode = "barcode"
    case aiCamera = "ai_camera"
    case favorite = "favorite"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .search: return "Food Search"
        case .barcode: return "Barcode Scan"
        case .aiCamera: return "AI Camera"
        case .favorite: return "Favorite"
        case .recent: return "Recent"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "keyboard"
        case .search: return "magnifyingglass"
        case .barcode: return "barcode.viewfinder"
        case .aiCamera: return "camera.fill"
        case .favorite: return "heart.fill"
        case .recent: return "clock.fill"
        }
    }
    
    /// Whether this method requires AI tier subscription
    var requiresAI: Bool {
        return self == .aiCamera
    }
}