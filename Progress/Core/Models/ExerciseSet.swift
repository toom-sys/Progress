//
//  ExerciseSet.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
final class ExerciseSet {
    
    // MARK: - Properties
    
    /// Unique identifier for the set
    var id: UUID
    
    /// Order of this set within the exercise
    var order: Int
    
    /// When this set was created
    var createdAt: Date
    
    /// When this set was completed (nil if not completed)
    var completedAt: Date?
    
    /// Whether this set has been marked as completed
    var isCompleted: Bool
    
    // MARK: - Resistance Exercise Properties
    
    /// Weight used for resistance exercises (in user's preferred units)
    var weight: Double
    
    /// Number of repetitions completed
    var reps: Int
    
    /// Target reps (for planning vs actual)
    var targetReps: Int?
    
    /// Target weight (for planning vs actual)
    var targetWeight: Double?
    
    // MARK: - Cardio Exercise Properties
    
    /// Duration of the set in seconds
    var duration: TimeInterval
    
    /// Distance covered (in user's preferred units)
    var distance: Double
    
    /// Average heart rate during the set (if available)
    var averageHeartRate: Int?
    
    /// Calories burned during the set (if available)
    var caloriesBurned: Double?
    
    // MARK: - Recovery Exercise Properties
    
    /// Intensity level for recovery exercises (1-10 scale)
    var intensityLevel: Int?
    
    /// Notes about the set (form, feeling, etc.)
    var notes: String?
    
    // MARK: - Relationships
    
    /// The exercise this set belongs to
    var exercise: Exercise?
    
    // MARK: - Computed Properties
    
    /// Volume for this set (weight × reps)
    var volume: Double {
        weight * Double(reps)
    }
    
    /// Whether this set hit the target (if target was set)
    var hitTarget: Bool {
        if let targetReps = targetReps, let targetWeight = targetWeight {
            return reps >= targetReps && weight >= targetWeight
        } else if let targetReps = targetReps {
            return reps >= targetReps
        } else if let targetWeight = targetWeight {
            return weight >= targetWeight
        }
        return true // No target set, so consider it hit
    }
    
    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Performance rating compared to previous sets
    var performanceRating: PerformanceRating {
        // This would typically compare against previous sets
        // For now, return neutral
        return .maintained
    }
    
    // MARK: - Initialization
    
    init(
        weight: Double = 0,
        reps: Int = 0,
        duration: TimeInterval = 0,
        distance: Double = 0,
        order: Int = 0
    ) {
        self.id = UUID()
        self.order = order
        self.createdAt = Date()
        self.isCompleted = false
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.distance = distance
    }
    
    // MARK: - Methods
    
    /// Mark this set as completed
    func complete() {
        isCompleted = true
        completedAt = Date()
        exercise?.completeSet() // Notify exercise to start rest timer
    }
    
    /// Reset this set to incomplete
    func reset() {
        isCompleted = false
        completedAt = nil
    }
    
    /// Update the set with new values
    func update(
        weight: Double? = nil,
        reps: Int? = nil,
        duration: TimeInterval? = nil,
        distance: Double? = nil,
        notes: String? = nil
    ) {
        if let weight = weight { self.weight = weight }
        if let reps = reps { self.reps = reps }
        if let duration = duration { self.duration = duration }
        if let distance = distance { self.distance = distance }
        if let notes = notes { self.notes = notes }
    }
    
    /// Set targets for this set
    func setTargets(weight: Double? = nil, reps: Int? = nil) {
        self.targetWeight = weight
        self.targetReps = reps
    }
    
    /// Duplicate this set for templates
    func duplicate() -> ExerciseSet {
        let newSet = ExerciseSet(
            weight: weight,
            reps: reps,
            duration: duration,
            distance: distance,
            order: order
        )
        
        newSet.targetWeight = targetWeight
        newSet.targetReps = targetReps
        newSet.intensityLevel = intensityLevel
        newSet.notes = notes
        
        // Don't copy completion status for templates
        return newSet
    }
    
    /// Create a copy with increased weight/reps for progressive overload
    func createProgressiveSet() -> ExerciseSet {
        let newSet = ExerciseSet(
            weight: weight,
            reps: reps,
            duration: duration,
            distance: distance,
            order: order
        )
        
        // Apply progressive overload logic
        if weight > 0 {
            // Increase weight by 2.5kg (or smallest increment)
            newSet.weight = weight + 2.5
        } else if reps > 0 {
            // Increase reps by 1
            newSet.reps = reps + 1
        }
        
        return newSet
    }
}

// MARK: - Enums

enum PerformanceRating: String, CaseIterable, Codable {
    case improved = "improved"
    case maintained = "maintained"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .improved: return "Improved"
        case .maintained: return "Maintained"
        case .declined: return "Declined"
        }
    }
    
    var color: String {
        switch self {
        case .improved: return "green"
        case .maintained: return "blue"
        case .declined: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .improved: return "arrow.up"
        case .maintained: return "minus"
        case .declined: return "arrow.down"
        }
    }
}