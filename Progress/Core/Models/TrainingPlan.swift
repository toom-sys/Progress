//
//  TrainingPlan.swift
//  Progress
//

import Foundation
import SwiftData

@Model
final class TrainingPlan {

    // MARK: - Properties

    var id: UUID
    var name: String
    var splitType: PlanSplitType
    var createdAt: Date
    var isActive: Bool

    // MARK: - Relationships

    var user: User?

    @Relationship(deleteRule: .cascade)
    var workouts: [Workout]

    // MARK: - Initialization

    init(
        name: String,
        splitType: PlanSplitType,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.splitType = splitType
        self.createdAt = Date()
        self.isActive = isActive
        self.workouts = []
    }
}

// MARK: - Enums

enum PlanSplitType: String, Codable, CaseIterable {
    case fullBody = "full_body"
    case upperLower = "upper_lower"
    case pushPullLegs = "push_pull_legs"

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        case .upperLower: return "Upper/Lower"
        case .pushPullLegs: return "Push/Pull/Legs"
        }
    }
}

enum PlanWorkoutPhase: String, Codable {
    case baseline = "baseline"
    case progression = "progression"
    case deload = "deload"

    var displayName: String {
        switch self {
        case .baseline: return "Baseline"
        case .progression: return "Progression"
        case .deload: return "Deload"
        }
    }
}
