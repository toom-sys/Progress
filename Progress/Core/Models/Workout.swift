//
//  Workout.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
final class Workout {
    
    // MARK: - Properties
    
    /// Unique identifier for the workout
    var id: UUID
    
    /// User-defined name for the workout
    var name: String
    
    /// Optional notes about the workout
    var notes: String?
    
    /// When the workout was created
    var createdAt: Date
    
    /// When the workout was started (nil if not started yet)
    var startedAt: Date?
    
    /// When the workout was completed (nil if not completed)
    var completedAt: Date?
    
    /// Current status of the workout
    var status: WorkoutStatus
    
    /// Template this workout was created from (if any)
    var templateId: UUID?
    
    /// Whether this workout can be used as a template
    var isTemplate: Bool
    
    // MARK: - Relationships
    
    /// The user who owns this workout
    var user: User?
    
    /// All exercises in this workout
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]
    
    // MARK: - Computed Properties
    
    /// Total duration of the workout (if completed)
    var duration: TimeInterval? {
        guard let start = startedAt, let end = completedAt else { return nil }
        return end.timeIntervalSince(start)
    }
    
    /// Whether the workout is currently in progress
    var isInProgress: Bool {
        status == .inProgress
    }
    
    /// Whether the workout is completed
    var isCompleted: Bool {
        status == .completed
    }
    
    /// Total number of sets across all exercises
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    /// Total weight lifted (for resistance exercises)
    var totalWeight: Double {
        exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                setTotal + (set.weight * Double(set.reps))
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        notes: String? = nil,
        isTemplate: Bool = false,
        templateId: UUID? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.status = .planned
        self.isTemplate = isTemplate
        self.templateId = templateId
        self.exercises = []
    }
    
    // MARK: - Methods
    
    /// Start the workout
    func start() {
        guard status == .planned else { return }
        status = .inProgress
        startedAt = Date()
    }
    
    /// Complete the workout
    func complete() {
        guard status == .inProgress else { return }
        status = .completed
        completedAt = Date()
    }
    
    /// Cancel the workout
    func cancel() {
        guard status == .inProgress else { return }
        status = .cancelled
    }
    
    /// Add an exercise to the workout
    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        exercise.workout = self
    }
    
    /// Remove an exercise from the workout
    func removeExercise(_ exercise: Exercise) {
        if let index = exercises.firstIndex(of: exercise) {
            exercises.remove(at: index)
        }
    }
    
    /// Duplicate this workout as a new template
    func duplicateAsTemplate(name: String) -> Workout {
        let newWorkout = Workout(
            name: name,
            notes: notes,
            isTemplate: true,
            templateId: self.id
        )
        
        // Copy exercises
        for exercise in exercises {
            let newExercise = exercise.duplicate()
            newWorkout.addExercise(newExercise)
        }
        
        return newWorkout
    }
}

// MARK: - Enums

enum WorkoutStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .planned: return "blue"
        case .inProgress: return "orange"
        case .completed: return "green"
        case .cancelled: return "red"
        }
    }
}