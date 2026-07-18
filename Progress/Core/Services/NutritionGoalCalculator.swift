//
//  NutritionGoalCalculator.swift
//  Progress
//
//  Created by Progress Team
//
//  Derives personalised daily calorie and macronutrient targets from the
//  user's body metrics and fitness goal using the Mifflin-St Jeor BMR
//  equation combined with an activity-level TDEE multiplier and a
//  goal-based calorie adjustment.
//

import Foundation

/// A set of personalised daily nutrition targets.
struct NutritionGoals: Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let `default` = NutritionGoals(calories: 2000, protein: 150, carbs: 200, fat: 65)
}

enum NutritionGoalCalculator {

    /// Minimum safe calorie floor to avoid unhealthy targets.
    private static let minimumCalories: Double = 1200

    /// Calculates personalised nutrition goals for a given user.
    static func goals(for user: User) -> NutritionGoals {
        goals(
            weightKg: user.weightKg,
            heightCm: user.heightCm,
            age: user.age,
            sex: user.biologicalSex,
            activity: user.activityLevel,
            goal: user.fitnessGoal
        )
    }

    /// Calculates personalised nutrition goals from raw inputs.
    static func goals(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: BiologicalSex,
        activity: ActivityLevel,
        goal: FitnessGoal
    ) -> NutritionGoals {
        let safeWeight = max(30, weightKg)
        let safeHeight = max(120, heightCm)
        let safeAge = max(14, Double(age))

        // Mifflin-St Jeor Basal Metabolic Rate.
        let bmr = (10 * safeWeight) + (6.25 * safeHeight) - (5 * safeAge) + sex.bmrConstant

        // Total Daily Energy Expenditure.
        let tdee = bmr * activity.multiplier

        // Goal-based calorie adjustment.
        let calories = max(minimumCalories, (tdee * calorieMultiplier(for: goal)).rounded())

        // Protein target scales with bodyweight and goal.
        let protein = (safeWeight * proteinPerKg(for: goal)).rounded()

        // Fat target ~25% of calories (min 0.8 g/kg).
        let fatFromCalories = (calories * 0.25) / 9
        let fatFloor = safeWeight * 0.8
        let fat = max(fatFloor, fatFromCalories).rounded()

        // Remaining calories go to carbohydrates.
        let proteinCalories = protein * 4
        let fatCalories = fat * 9
        let remainingCalories = max(0, calories - proteinCalories - fatCalories)
        let carbs = (remainingCalories / 4).rounded()

        return NutritionGoals(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }

    /// Calorie adjustment factor applied to TDEE based on the fitness goal.
    private static func calorieMultiplier(for goal: FitnessGoal) -> Double {
        switch goal {
        case .weightLoss: return 0.80      // ~20% deficit
        case .muscleGain: return 1.10      // ~10% surplus
        case .strengthTraining: return 1.05
        case .endurance: return 1.0
        case .generalFitness: return 1.0
        case .maintenance: return 1.0
        }
    }

    /// Grams of protein per kilogram of bodyweight based on the fitness goal.
    private static func proteinPerKg(for goal: FitnessGoal) -> Double {
        switch goal {
        case .weightLoss: return 2.0
        case .muscleGain: return 2.0
        case .strengthTraining: return 1.8
        case .endurance: return 1.6
        case .generalFitness: return 1.6
        case .maintenance: return 1.6
        }
    }
}

// MARK: - User Convenience

extension User {
    /// The user's current daily nutrition goals as a value type.
    var nutritionGoals: NutritionGoals {
        NutritionGoals(
            calories: dailyCalorieGoal,
            protein: dailyProteinGoal,
            carbs: dailyCarbGoal,
            fat: dailyFatGoal
        )
    }

    /// Applies a set of nutrition goals to the user's stored properties.
    func apply(_ goals: NutritionGoals) {
        dailyCalorieGoal = goals.calories
        dailyProteinGoal = goals.protein
        dailyCarbGoal = goals.carbs
        dailyFatGoal = goals.fat
    }

    /// Recalculates and stores nutrition goals from the profile, unless the
    /// user has manually overridden them. Pass `force: true` to override the
    /// manual flag (e.g. when the user explicitly changes their fitness goal).
    @discardableResult
    func recalculateNutritionGoals(force: Bool = false) -> Bool {
        guard force || !usesCustomNutritionGoals else { return false }
        apply(NutritionGoalCalculator.goals(for: self))
        usesCustomNutritionGoals = false
        return true
    }
}
