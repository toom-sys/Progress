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
    
    /// User's display email (optional, not used for authentication)
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
    
    /// Whether the user has completed the onboarding flow
    var hasCompletedOnboarding: Bool
    
    /// Weekly workout goal (number of workouts per week)
    var weeklyWorkoutGoal: Int
    
    /// Daily step goal (number of steps per day)
    var dailyStepGoal: Int
    
    /// Daily water intake goal in millilitres
    var dailyWaterGoal: Double
    
    // MARK: - Body Metrics (used to personalise nutrition targets)
    
    /// User's biological sex, used for BMR calculations
    var biologicalSex: BiologicalSex = BiologicalSex.unspecified
    
    /// User's height in centimetres
    var heightCm: Double = 170
    
    /// User's body weight in kilograms
    var weightKg: Double = 70
    
    /// User's typical daily activity level, used for TDEE calculations
    var activityLevel: ActivityLevel = ActivityLevel.moderate
    
    // MARK: - Daily Nutrition Goals
    
    /// Daily calorie goal (kcal)
    var dailyCalorieGoal: Double = 2000
    
    /// Daily protein goal in grams
    var dailyProteinGoal: Double = 150
    
    /// Daily carbohydrate goal in grams
    var dailyCarbGoal: Double = 200
    
    /// Daily fat goal in grams
    var dailyFatGoal: Double = 65
    
    /// Whether the user has manually overridden their nutrition goals.
    /// When `false`, goals are recalculated automatically from the profile
    /// whenever body metrics or the fitness goal change.
    var usesCustomNutritionGoals: Bool = false
    
    // MARK: - Relationships
    
    /// All workouts created by this user
    @Relationship(deleteRule: .cascade, inverse: \Workout.user)
    var workouts: [Workout]
    
    /// All nutrition entries logged by this user
    @Relationship(deleteRule: .cascade, inverse: \NutritionEntry.user)
    var nutritionEntries: [NutritionEntry]
    
    /// All water entries logged by this user
    @Relationship(deleteRule: .cascade, inverse: \WaterEntry.user)
    var waterEntries: [WaterEntry]
    
    /// All body weight entries logged by this user
    @Relationship(deleteRule: .cascade, inverse: \BodyWeightEntry.user)
    var weightEntries: [BodyWeightEntry] = []
    
    // MARK: - Initialization
    
    init(
        email: String = "",
        name: String = "Me",
        age: Int = 25,
        fitnessGoal: FitnessGoal = .generalFitness,
        fitnessLevel: FitnessLevel = .beginner,
        subscriptionTier: SubscriptionTier = .pro,
        preferredUnits: UnitSystem = .metric,
        hasCompletedOnboarding: Bool = false,
        weeklyWorkoutGoal: Int = 4,
        dailyStepGoal: Int = 10000,
        dailyWaterGoal: Double = 2500,
        biologicalSex: BiologicalSex = .unspecified,
        heightCm: Double = 170,
        weightKg: Double = 70,
        activityLevel: ActivityLevel = .moderate,
        dailyCalorieGoal: Double = 2000,
        dailyProteinGoal: Double = 150,
        dailyCarbGoal: Double = 200,
        dailyFatGoal: Double = 65,
        usesCustomNutritionGoals: Bool = false
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
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.dailyStepGoal = dailyStepGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.biologicalSex = biologicalSex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevel = activityLevel
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbGoal = dailyCarbGoal
        self.dailyFatGoal = dailyFatGoal
        self.usesCustomNutritionGoals = usesCustomNutritionGoals
        self.workouts = []
        self.nutritionEntries = []
        self.waterEntries = []
        self.weightEntries = []
    }
}

// MARK: - Local User Helper

extension User {
    /// Returns the first existing user, or creates and inserts a default one.
    @discardableResult
    static func current(in context: ModelContext) -> User {
        let descriptor = FetchDescriptor<User>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let newUser = User()
        context.insert(newUser)
        try? context.save()
        return newUser
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
    case pro = "pro"

    var displayName: String { "Progress Pro" }
    var monthlyPrice: String { "£2.99" }

    // Map legacy raw values stored in SwiftData to the current single tier.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "standard", "plus_ai", "pro":
            self = .pro
        default:
            self = .pro
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum BiologicalSex: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case unspecified = "unspecified"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .unspecified: return "Prefer not to say"
        }
    }
    
    var onboardingEmoji: String {
        switch self {
        case .male: return "♂️"
        case .female: return "♀️"
        case .unspecified: return "⚧️"
        }
    }
    
    /// Constant added to the Mifflin-St Jeor BMR equation.
    /// `.unspecified` uses the average of the male (+5) and female (-161) constants.
    var bmrConstant: Double {
        switch self {
        case .male: return 5
        case .female: return -161
        case .unspecified: return -78
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary = "sedentary"
    case light = "light"
    case moderate = "moderate"
    case active = "active"
    case veryActive = "very_active"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise, desk job"
        case .light: return "Light exercise 1-3 days per week"
        case .moderate: return "Moderate exercise 3-5 days per week"
        case .active: return "Hard exercise 6-7 days per week"
        case .veryActive: return "Very hard exercise or a physical job"
        }
    }
    
    var onboardingEmoji: String {
        switch self {
        case .sedentary: return "🪑"
        case .light: return "🚶"
        case .moderate: return "🏃"
        case .active: return "🚴"
        case .veryActive: return "🔥"
        }
    }
    
    /// TDEE multiplier applied to BMR.
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
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