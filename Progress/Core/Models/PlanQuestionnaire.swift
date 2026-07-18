//
//  PlanQuestionnaire.swift
//  Progress
//

import Foundation

/// User choices that drive training-plan generation.
struct PlanQuestionnaire: Equatable {
    var goal: FitnessGoal
    var experience: FitnessLevel
    var environment: WorkoutEnvironment
    var workoutCount: Int
    var focus: [FocusArea]

    /// Clamped to the supported 1–4 repeating-workout range.
    var clampedWorkoutCount: Int {
        min(4, max(1, workoutCount))
    }
}

/// Muscle-group focus areas used to weight exercise selection.
enum FocusArea: String, Codable, CaseIterable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case core = "core"
    case fullBody = "full_body"

    var displayName: String {
        switch self {
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        }
    }
}
