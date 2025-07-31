//
//  User.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
final class User {
    
    // MARK: - Properties
    
    /// Unique identifier for the user
    var id: UUID
    
    /// User's email address (for authentication)
    var email: String
    
    /// User's display name
    var name: String
    
    /// User's age (for fitness calculations)
    var age: Int
    
    /// User's fitness goal
    var fitnessGoal: FitnessGoal
    
    /// User's current fitness level
    var fitnessLevel: FitnessLevel
    
    /// User's subscription tier
    var subscriptionTier: SubscriptionTier
    
    /// When the user account was created
    var createdAt: Date
    
    /// When the user profile was last updated
    var updatedAt: Date
    
    /// User's preferred units (metric vs imperial)
    var preferredUnits: UnitSystem
    
    // MARK: - Relationships
    
    /// All workouts created by this user
    @Relationship(deleteRule: .cascade, inverse: \Workout.user)
    var workouts: [Workout]
    
    /// All nutrition entries logged by this user
    @Relationship(deleteRule: .cascade, inverse: \NutritionEntry.user)
    var nutritionEntries: [NutritionEntry]
    
    // MARK: - Initialization
    
    init(
        email: String,
        name: String,
        age: Int,
        fitnessGoal: FitnessGoal = .generalFitness,
        fitnessLevel: FitnessLevel = .beginner,
        subscriptionTier: SubscriptionTier = .standard,
        preferredUnits: UnitSystem = .metric
    ) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.age = age
        self.fitnessGoal = fitnessGoal
        self.fitnessLevel = fitnessLevel
        self.subscriptionTier = subscriptionTier
        self.createdAt = Date()
        self.updatedAt = Date()
        self.preferredUnits = preferredUnits
        self.workouts = []
        self.nutritionEntries = []
    }
}

// MARK: - Enums

enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss = "weight_loss"
    case muscleGain = "muscle_gain"
    case strengthTraining = "strength_training"
    case endurance = "endurance"
    case generalFitness = "general_fitness"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .muscleGain: return "Muscle Gain"
        case .strengthTraining: return "Strength Training"
        case .endurance: return "Endurance"
        case .generalFitness: return "General Fitness"
        case .maintenance: return "Maintenance"
        }
    }
    
    var description: String {
        switch self {
        case .weightLoss: return "Focus on burning calories and losing weight"
        case .muscleGain: return "Build lean muscle mass"
        case .strengthTraining: return "Increase overall strength and power"
        case .endurance: return "Improve cardiovascular fitness"
        case .generalFitness: return "Stay healthy and active"
        case .maintenance: return "Maintain current fitness level"
        }
    }
}

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"  
        case .advanced: return "Advanced"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "New to regular exercise"
        case .intermediate: return "Regular exercise experience"
        case .advanced: return "Experienced athlete"
        }
    }
}

enum SubscriptionTier: String, CaseIterable, Codable {
    case standard = "standard"
    case plusAI = "plus_ai"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .plusAI: return "Plus AI"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .standard: return "£1"
        case .plusAI: return "£3"
        }
    }
}

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric: return "Metric (kg, cm)"
        case .imperial: return "Imperial (lbs, ft)"
        }
    }
    
    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }
    
    var heightUnit: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "ft/in"
        }
    }
}