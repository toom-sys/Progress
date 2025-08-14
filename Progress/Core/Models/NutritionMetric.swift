//
//  NutritionMetric.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftUI

// MARK: - Nutrition Metric Type

enum NutritionMetricType: String, CaseIterable, Codable {
    // Essential Macros (already in current cards)
    case calories = "calories"
    case protein = "protein"
    case carbohydrates = "carbohydrates"
    case fat = "fat"
    
    // Secondary Macros & Fiber
    case fiber = "fiber"
    case sugar = "sugar"
    case saturatedFat = "saturated_fat"
    case sodium = "sodium"
    
    // Essential Vitamins
    case vitaminA = "vitamin_a"
    case vitaminC = "vitamin_c"
    case vitaminD = "vitamin_d"
    case vitaminE = "vitamin_e"
    case vitaminK = "vitamin_k"
    case vitaminB6 = "vitamin_b6"
    case vitaminB12 = "vitamin_b12"
    case folate = "folate"
    case thiamine = "thiamine"
    case riboflavin = "riboflavin"
    case niacin = "niacin"
    case biotin = "biotin"
    case pantothenicAcid = "pantothenic_acid"
    
    // Essential Minerals
    case calcium = "calcium"
    case iron = "iron"
    case magnesium = "magnesium"
    case phosphorus = "phosphorus"
    case potassium = "potassium"
    case zinc = "zinc"
    case copper = "copper"
    case manganese = "manganese"
    case selenium = "selenium"
    case iodine = "iodine"
    case chromium = "chromium"
    case molybdenum = "molybdenum"
    
    // Performance & Supplement Metrics
    case creatine = "creatine"
    case caffeine = "caffeine"
    case omega3 = "omega_3"
    case betaAlanine = "beta_alanine"
    case citrulline = "citrulline"
    case leucine = "leucine"
    case glutamine = "glutamine"
    case taurine = "taurine"
    case choline = "choline"
    case inositol = "inositol"
    
    // Health Metrics
    case cholesterol = "cholesterol"
    case transFat = "trans_fat"
    case waterIntake = "water_intake"
    case glycemicLoad = "glycemic_load"
    
    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbohydrates: return "Carbs"
        case .fat: return "Fat"
        case .fiber: return "Fiber"
        case .sugar: return "Sugar"
        case .saturatedFat: return "Saturated Fat"
        case .sodium: return "Sodium"
        case .vitaminA: return "Vitamin A"
        case .vitaminC: return "Vitamin C"
        case .vitaminD: return "Vitamin D"
        case .vitaminE: return "Vitamin E"
        case .vitaminK: return "Vitamin K"
        case .vitaminB6: return "Vitamin B6"
        case .vitaminB12: return "Vitamin B12"
        case .folate: return "Folate"
        case .thiamine: return "Thiamine"
        case .riboflavin: return "Riboflavin"
        case .niacin: return "Niacin"
        case .biotin: return "Biotin"
        case .pantothenicAcid: return "Pantothenic Acid"
        case .calcium: return "Calcium"
        case .iron: return "Iron"
        case .magnesium: return "Magnesium"
        case .phosphorus: return "Phosphorus"
        case .potassium: return "Potassium"
        case .zinc: return "Zinc"
        case .copper: return "Copper"
        case .manganese: return "Manganese"
        case .selenium: return "Selenium"
        case .iodine: return "Iodine"
        case .chromium: return "Chromium"
        case .molybdenum: return "Molybdenum"
        case .creatine: return "Creatine"
        case .caffeine: return "Caffeine"
        case .omega3: return "Omega-3"
        case .betaAlanine: return "Beta-Alanine"
        case .citrulline: return "Citrulline"
        case .leucine: return "Leucine"
        case .glutamine: return "Glutamine"
        case .taurine: return "Taurine"
        case .choline: return "Choline"
        case .inositol: return "Inositol"
        case .cholesterol: return "Cholesterol"
        case .transFat: return "Trans Fat"
        case .waterIntake: return "Water"
        case .glycemicLoad: return "Glycemic Load"
        }
    }
    
    var unit: String {
        switch self {
        case .calories: return "cal"
        case .protein, .carbohydrates, .fat, .fiber, .sugar, .saturatedFat, .transFat: return "g"
        case .sodium, .potassium, .calcium, .phosphorus, .magnesium, .cholesterol: return "mg"
        case .vitaminA: return "μg RAE"
        case .vitaminC, .vitaminE: return "mg"
        case .vitaminD: return "μg"
        case .vitaminK: return "μg"
        case .vitaminB6, .riboflavin, .thiamine, .niacin: return "mg"
        case .vitaminB12, .folate, .biotin: return "μg"
        case .pantothenicAcid: return "mg"
        case .iron, .zinc, .copper, .manganese: return "mg"
        case .selenium, .iodine, .chromium, .molybdenum: return "μg"
        case .creatine, .betaAlanine, .citrulline, .leucine, .glutamine: return "g"
        case .caffeine, .taurine: return "mg"
        case .omega3: return "g"
        case .choline: return "mg"
        case .inositol: return "mg"
        case .waterIntake: return "L"
        case .glycemicLoad: return "GL"
        }
    }
    
    var shortUnit: String {
        switch self {
        case .calories: return ""
        case .vitaminA, .vitaminD, .vitaminK, .vitaminB12, .folate, .biotin, .selenium, .iodine, .chromium, .molybdenum: return "μg"
        case .waterIntake: return "L"
        case .glycemicLoad: return "GL"
        default: return unit
        }
    }
    
    var icon: String {
        switch self {
        case .calories: return "flame.fill"
        case .protein: return "fish.fill"
        case .carbohydrates: return "leaf.fill"
        case .fat: return "drop.fill"
        case .fiber: return "windmill"
        case .sugar: return "cube.fill"
        case .saturatedFat, .transFat: return "drop.triangle.fill"
        case .sodium: return "shippingbox.fill"
        case .vitaminA: return "eye.fill"
        case .vitaminC: return "cross.case.fill"
        case .vitaminD: return "sun.max.fill"
        case .vitaminE: return "shield.fill"
        case .vitaminK: return "bolt.fill"
        case .vitaminB6, .vitaminB12, .folate, .thiamine, .riboflavin, .niacin, .biotin, .pantothenicAcid: return "brain.head.profile"
        case .calcium: return "figure.strengthtraining.traditional"
        case .iron: return "dumbbell.fill"
        case .magnesium: return "heart.fill"
        case .phosphorus: return "figure.run"
        case .potassium: return "waveform.path.ecg"
        case .zinc: return "bandage.fill"
        case .copper, .manganese, .selenium, .iodine, .chromium, .molybdenum: return "atom"
        case .creatine: return "bolt.circle.fill"
        case .caffeine: return "cup.and.saucer.fill"
        case .omega3: return "fish.circle.fill"
        case .betaAlanine, .citrulline, .leucine, .glutamine: return "pills.fill"
        case .taurine: return "speedometer"
        case .choline, .inositol: return "brain.head.profile.fill"
        case .cholesterol: return "heart.text.square.fill"
        case .waterIntake: return "drop.circle.fill"
        case .glycemicLoad: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .calories: return .orange
        case .protein: return .red
        case .carbohydrates: return .green
        case .fat: return .blue
        case .fiber: return .brown
        case .sugar: return .pink
        case .saturatedFat, .transFat: return .red
        case .sodium: return .gray
        case .vitaminA: return .orange
        case .vitaminC: return .yellow
        case .vitaminD: return .orange
        case .vitaminE: return .green
        case .vitaminK: return .purple
        case .vitaminB6, .vitaminB12, .folate, .thiamine, .riboflavin, .niacin, .biotin, .pantothenicAcid: return .blue
        case .calcium: return .gray
        case .iron: return .red
        case .magnesium: return .green
        case .phosphorus: return .orange
        case .potassium: return .purple
        case .zinc: return .blue
        case .copper: return .orange
        case .manganese, .selenium, .iodine, .chromium, .molybdenum: return .gray
        case .creatine: return .purple
        case .caffeine: return .brown
        case .omega3: return .blue
        case .betaAlanine: return .red
        case .citrulline: return .green
        case .leucine, .glutamine: return .purple
        case .taurine: return .red
        case .choline, .inositol: return .blue
        case .cholesterol: return .red
        case .waterIntake: return .blue
        case .glycemicLoad: return .orange
        }
    }
    
    var category: NutritionCategory {
        switch self {
        case .calories, .protein, .carbohydrates, .fat:
            return .primaryMacros
        case .fiber, .sugar, .saturatedFat, .sodium, .transFat, .cholesterol:
            return .secondaryMacros
        case .vitaminA, .vitaminC, .vitaminD, .vitaminE, .vitaminK, .vitaminB6, .vitaminB12, .folate, .thiamine, .riboflavin, .niacin, .biotin, .pantothenicAcid:
            return .vitamins
        case .calcium, .iron, .magnesium, .phosphorus, .potassium, .zinc, .copper, .manganese, .selenium, .iodine, .chromium, .molybdenum:
            return .minerals
        case .creatine, .caffeine, .omega3, .betaAlanine, .citrulline, .leucine, .glutamine, .taurine, .choline, .inositol:
            return .performance
        case .waterIntake, .glycemicLoad:
            return .health
        }
    }
    
    /// Recommended daily value for adults (general guidelines)
    var recommendedDailyValue: Double {
        switch self {
        case .calories: return 2000
        case .protein: return 150
        case .carbohydrates: return 200
        case .fat: return 65
        case .fiber: return 25
        case .sugar: return 50 // Maximum recommended
        case .saturatedFat: return 20 // Maximum recommended
        case .sodium: return 2300 // Maximum recommended
        case .vitaminA: return 900
        case .vitaminC: return 90
        case .vitaminD: return 20
        case .vitaminE: return 15
        case .vitaminK: return 120
        case .vitaminB6: return 1.3
        case .vitaminB12: return 2.4
        case .folate: return 400
        case .thiamine: return 1.2
        case .riboflavin: return 1.3
        case .niacin: return 16
        case .biotin: return 30
        case .pantothenicAcid: return 5
        case .calcium: return 1000
        case .iron: return 8
        case .magnesium: return 400
        case .phosphorus: return 700
        case .potassium: return 3500
        case .zinc: return 11
        case .copper: return 0.9
        case .manganese: return 2.3
        case .selenium: return 55
        case .iodine: return 150
        case .chromium: return 35
        case .molybdenum: return 45
        case .creatine: return 3 // Typical supplementation
        case .caffeine: return 400 // Maximum safe daily
        case .omega3: return 1.6
        case .betaAlanine: return 3 // Typical supplementation
        case .citrulline: return 6 // Typical supplementation
        case .leucine: return 2.5 // Typical supplementation
        case .glutamine: return 5 // Typical supplementation
        case .taurine: return 500 // Typical supplementation
        case .choline: return 550
        case .inositol: return 500 // Typical supplementation
        case .cholesterol: return 300 // Maximum recommended
        case .transFat: return 0 // Should be avoided
        case .waterIntake: return 3.7 // Liters per day
        case .glycemicLoad: return 100 // Moderate daily GL
        }
    }
    
    /// Whether this metric is typically obtained through supplements
    var isSupplementFriendly: Bool {
        switch self {
        case .creatine, .betaAlanine, .citrulline, .leucine, .glutamine, .taurine, .omega3, .vitaminD, .vitaminB12, .magnesium, .zinc, .iron, .caffeine:
            return true
        default:
            return false
        }
    }
    
    /// Whether higher values are generally better (vs. should be limited)
    var higherIsBetter: Bool {
        switch self {
        case .sodium, .saturatedFat, .transFat, .cholesterol, .sugar, .caffeine, .glycemicLoad:
            return false
        default:
            return true
        }
    }
}

// MARK: - Nutrition Category

enum NutritionCategory: String, CaseIterable {
    case primaryMacros = "primary_macros"
    case secondaryMacros = "secondary_macros"
    case vitamins = "vitamins"
    case minerals = "minerals"
    case performance = "performance"
    case health = "health"
    
    var displayName: String {
        switch self {
        case .primaryMacros: return "Primary Macros"
        case .secondaryMacros: return "Secondary Macros"
        case .vitamins: return "Vitamins"
        case .minerals: return "Minerals"
        case .performance: return "Performance & Supplements"
        case .health: return "Health Metrics"
        }
    }
    
    var description: String {
        switch self {
        case .primaryMacros: return "Core macronutrients for energy and body composition"
        case .secondaryMacros: return "Important macronutrients for health and performance"
        case .vitamins: return "Essential vitamins for optimal health"
        case .minerals: return "Essential minerals for body function"
        case .performance: return "Supplements and nutrients for athletic performance"
        case .health: return "General health and wellness metrics"
        }
    }
}

// MARK: - Default Metric Sets

extension NutritionMetricType {
    /// Default metrics for the primary (first) tab
    static let primaryMetrics: [NutritionMetricType] = [
        .calories, .protein, .carbohydrates, .fat
    ]
    
    /// Default metrics for the secondary (second) tab - supplement focused
    static let secondaryMetrics: [NutritionMetricType] = [
        .fiber, .creatine, .zinc, .vitaminD, .omega3, .magnesium
    ]
    
    /// All available metrics grouped by category for customization
    static let availableMetricsByCategory: [NutritionCategory: [NutritionMetricType]] = [
        .secondaryMacros: [.fiber, .sugar, .saturatedFat, .sodium],
        .vitamins: [.vitaminA, .vitaminC, .vitaminD, .vitaminE, .vitaminK, .vitaminB6, .vitaminB12, .folate],
        .minerals: [.calcium, .iron, .magnesium, .phosphorus, .potassium, .zinc, .copper, .selenium],
        .performance: [.creatine, .caffeine, .omega3, .betaAlanine, .citrulline, .leucine, .glutamine, .taurine],
        .health: [.waterIntake, .cholesterol, .choline, .inositol]
    ]
    
    /// Most popular supplement metrics for quick selection
    static let popularSupplements: [NutritionMetricType] = [
        .creatine, .vitaminD, .omega3, .magnesium, .zinc, .vitaminB12, .iron, .caffeine
    ]
}
