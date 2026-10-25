//
//  Workout.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

@Model
final class Workout: Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the workout
    var id: UUID
    
    /// User-defined name for the workout
    var name: String
    
    /// Optional notes about the workout
    var notes: String?
    
    /// When the workout was created
    var createdAt: Date
    
    /// When the workout was last updated
    var updatedAt: Date
    
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
    
    /// Current session within this workout's block (1–5), if part of a plan
    var planSessionIndex: Int?
    
    /// Block number for this repeating plan workout (starts at 1)
    var planBlockNumber: Int?
    
    /// Phase of this plan workout (baseline, progression, deload)
    var planPhase: PlanWorkoutPhase?
    
    /// ID of the training plan this workout belongs to
    var trainingPlanId: UUID?
    
    /// Links a historical clone back to the live repeating plan workout
    var sourceWorkoutId: UUID?
    
    /// When the workout was soft-deleted (nil if active). Kept for restore until purged.
    var deletedAt: Date?
    
    // MARK: - Relationships
    
    /// The user who owns this workout
    var user: User?
    
    /// All exercises in this workout
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]
    
    // MARK: - Soft Delete
    
    /// How long soft-deleted workouts remain restorable before permanent purge
    static let softDeleteRetentionDays = 30
    
    /// Whether this workout is in the Recently Deleted trash
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    /// When this soft-deleted workout will be permanently removed
    var softDeleteExpiresAt: Date? {
        guard let deletedAt else { return nil }
        return Calendar.current.date(
            byAdding: .day,
            value: Self.softDeleteRetentionDays,
            to: deletedAt
        )
    }
    
    /// Days remaining until permanent deletion (0 if expired)
    var daysUntilPermanentDeletion: Int {
        guard let expires = softDeleteExpiresAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
        return max(0, days)
    }
    
    /// Move the workout to Recently Deleted
    func softDelete() {
        deletedAt = Date()
        updateTimestamp()
    }
    
    /// Restore a soft-deleted workout back to its previous location
    func restoreFromDeletion() {
        deletedAt = nil
        updateTimestamp()
    }
    
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
    
    // MARK: - Methods
    
    /// Updates the updatedAt timestamp to the current time
    func updateTimestamp() {
        self.updatedAt = Date()
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
        self.updatedAt = Date()
        self.status = .planned
        self.isTemplate = isTemplate
        self.templateId = templateId
        self.deletedAt = nil
        self.exercises = []
    }
    
    // MARK: - Methods
    
    /// Start the workout. Later ticks leave the original start time in place.
    func start() {
        guard status == .planned else { return }
        status = .inProgress
        startedAt = Date()
        updateTimestamp()
    }

    /// A workout stays in progress only while at least one set is ticked.
    /// Confirming the completion screen finishes it separately.
    func revertToPlannedIfNoSetsTicked() {
        guard status == .inProgress else { return }
        let hasTickedSet = exercises.contains { exercise in
            exercise.sets.contains { $0.isCompleted }
        }
        guard !hasTickedSet else { return }
        status = .planned
        startedAt = nil
        updateTimestamp()
    }
    
    /// Complete the workout
    func complete() {
        print("🏁 Completing workout '\(name)'...")
        print("   Current status: \(status)")
        
        // Log current hidden state before completion
        let hiddenExercises = exercises.filter { $0.isHidden }
        let visibleExercises = exercises.filter { !$0.isHidden }
        
        print("📊 Pre-completion state:")
        print("   Total exercises: \(exercises.count)")
        if !hiddenExercises.isEmpty {
            print("   Hidden exercises: \(hiddenExercises.count) - \(hiddenExercises.map { $0.name })")
        }
        if !visibleExercises.isEmpty {
            print("   Visible exercises: \(visibleExercises.count) - \(visibleExercises.map { $0.name })")
        }
        
        // Always set status and completion time (allow re-completion)
        status = .completed
        completedAt = Date()
        
        // Unhide all exercises when workout is completed
        print("🔄 Unhiding all exercises...")
        var unhiddenCount = 0
        for exercise in exercises {
            if exercise.isHidden {
                print("   Unhiding: '\(exercise.name)'")
                exercise.setHidden(false)
                unhiddenCount += 1
            }
        }
        
        // Log final state after completion
        let stillHiddenExercises = exercises.filter { $0.isHidden }
        print("📊 Post-completion state:")
        print("   Hidden exercises: \(stillHiddenExercises.count)")
        if unhiddenCount > 0 {
            print("   ✅ Successfully unhid \(unhiddenCount) exercises")
        } else {
            print("   ℹ️ No exercises were hidden")
        }
        print("   All exercises visible: \(stillHiddenExercises.isEmpty ? "✅ SUCCESS" : "❌ FAILED")")
        
        print("✅ Workout '\(name)' completed successfully")
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
    
    // MARK: - Hashable
    
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

// MARK: - Supporting Types

/// Statistics about workouts in the database
struct WorkoutStats {
    let total: Int
    let completed: Int
    let inProgress: Int
    let planned: Int
    let templates: Int
}