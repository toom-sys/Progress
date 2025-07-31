//
//  Exercise.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
final class Exercise {
    
    // MARK: - Properties
    
    /// Unique identifier for the exercise
    var id: UUID
    
    /// Name of the exercise (e.g., "Bench Press", "Running")
    var name: String
    
    /// Type of exercise (resistance, cardio, recovery)
    var type: ExerciseType
    
    /// Category for organization (e.g., "Chest", "Legs")
    var category: String?
    
    /// Optional notes about the exercise
    var notes: String?
    
    /// Order of this exercise in the workout
    var order: Int
    
    /// When this exercise was created
    var createdAt: Date
    
    // MARK: - Rest Timer Properties
    
    /// Recommended rest time between sets (in seconds)
    var restTime: TimeInterval
    
    /// When the last set was completed (for rest timer)
    var lastSetCompletedAt: Date?
    
    // MARK: - Relationships
    
    /// The workout this exercise belongs to
    var workout: Workout?
    
    /// All sets for this exercise
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]
    
    // MARK: - Computed Properties
    
    /// Whether this exercise is currently in rest period
    var isInRestPeriod: Bool {
        guard let lastCompleted = lastSetCompletedAt else { return false }
        return Date().timeIntervalSince(lastCompleted) < restTime
    }
    
    /// Remaining rest time in seconds
    var remainingRestTime: TimeInterval {
        guard let lastCompleted = lastSetCompletedAt else { return 0 }
        let elapsed = Date().timeIntervalSince(lastCompleted)
        return max(0, restTime - elapsed)
    }
    
    /// Total volume for resistance exercises (weight × reps × sets)
    var totalVolume: Double {
        guard type == .resistance else { return 0 }
        return sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    /// Total duration for cardio exercises
    var totalDuration: TimeInterval {
        guard type == .cardio else { return 0 }
        return sets.reduce(0.0) { $0 + $1.duration }
    }
    
    /// Number of completed sets
    var completedSetsCount: Int {
        sets.filter { $0.isCompleted }.count
    }
    
    /// Whether all sets are completed
    var isCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        type: ExerciseType,
        category: String? = nil,
        notes: String? = nil,
        order: Int = 0,
        restTime: TimeInterval = 60 // Default 60 seconds rest
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.category = category
        self.notes = notes
        self.order = order
        self.restTime = restTime
        self.createdAt = Date()
        self.sets = []
    }
    
    // MARK: - Methods
    
    /// Add a new set to this exercise
    func addSet(_ set: ExerciseSet) {
        set.order = sets.count
        sets.append(set)
        set.exercise = self
    }
    
    /// Remove a set from this exercise
    func removeSet(_ set: ExerciseSet) {
        if let index = sets.firstIndex(of: set) {
            sets.remove(at: index)
            // Reorder remaining sets
            for (newIndex, remainingSet) in sets.enumerated() {
                remainingSet.order = newIndex
            }
        }
    }
    
    /// Mark the current set as completed and start rest timer
    func completeSet() {
        lastSetCompletedAt = Date()
    }
    
    /// Get the default set based on exercise type
    func createDefaultSet() -> ExerciseSet {
        switch type {
        case .resistance:
            return ExerciseSet(weight: 0, reps: 8, order: sets.count)
        case .cardio:
            return ExerciseSet(duration: 300, distance: 0, order: sets.count) // 5 minutes default
        case .recovery:
            return ExerciseSet(duration: 60, order: sets.count) // 1 minute default
        }
    }
    
    /// Duplicate this exercise for templates
    func duplicate() -> Exercise {
        let newExercise = Exercise(
            name: name,
            type: type,
            category: category,
            notes: notes,
            order: order,
            restTime: restTime
        )
        
        // Copy sets but mark them as not completed
        for set in sets {
            let newSet = set.duplicate()
            newExercise.addSet(newSet)
        }
        
        return newExercise
    }
}

// MARK: - Enums

enum ExerciseType: String, CaseIterable, Codable {
    case resistance = "resistance"
    case cardio = "cardio"
    case recovery = "recovery"
    
    var displayName: String {
        switch self {
        case .resistance: return "Resistance"
        case .cardio: return "Cardio"
        case .recovery: return "Recovery"
        }
    }
    
    var icon: String {
        switch self {
        case .resistance: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .recovery: return "moon.fill"
        }
    }
    
    var color: String {
        switch self {
        case .resistance: return "blue"
        case .cardio: return "red"
        case .recovery: return "green"
        }
    }
    
    /// Default rest time for this exercise type
    var defaultRestTime: TimeInterval {
        switch self {
        case .resistance: return 90  // 90 seconds
        case .cardio: return 120     // 2 minutes
        case .recovery: return 30    // 30 seconds
        }
    }
}