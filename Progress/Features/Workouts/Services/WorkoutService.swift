//
//  WorkoutService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

/// Service layer for workout data operations
/// Handles all CRUD operations for workouts, separating business logic from UI concerns
@MainActor
final class WorkoutService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all active (non-deleted) workouts from the database
    /// - Returns: Array of workouts sorted by updatedAt (newest first)
    /// - Throws: Database fetch errors
    func fetchWorkouts() throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter { !$0.isDeleted }
    }
    
    /// Create a new workout
    /// - Parameters:
    ///   - name: The workout name
    ///   - notes: Optional notes for the workout
    ///   - isTemplate: Whether this workout is a template
    /// - Returns: The created workout
    /// - Throws: Database save errors
    @discardableResult
    func createWorkout(name: String, notes: String? = nil, isTemplate: Bool = false) throws -> Workout {
        let workout = Workout(
            name: name,
            notes: notes,
            isTemplate: isTemplate
        )
        
        modelContext.insert(workout)
        try saveContext()
        
        return workout
    }
    
    /// Save changes to an existing workout
    /// - Parameter workout: The workout to save
    /// - Throws: Database save errors
    func saveWorkout(_ workout: Workout) throws {
        workout.updateTimestamp()
        try saveContext()
    }
    
    /// Soft-delete a workout (moves it to Recently Deleted)
    /// - Parameter workout: The workout to delete
    /// - Throws: Database save errors
    func deleteWorkout(_ workout: Workout) throws {
        workout.softDelete()
        try saveContext()
    }
    
    /// Restore a soft-deleted workout
    /// - Parameter workout: The workout to restore
    /// - Throws: Database save errors
    func restoreWorkout(_ workout: Workout) throws {
        workout.restoreFromDeletion()
        try saveContext()
    }
    
    /// Permanently delete a workout and its cascaded exercises/sets
    /// - Parameter workout: The workout to remove forever
    /// - Throws: Database save errors
    func permanentlyDeleteWorkout(_ workout: Workout) throws {
        let planService = TrainingPlanService(modelContext: modelContext)
        try? planService.rewindPlanProgressIfNeeded(afterDeleting: workout)
        modelContext.delete(workout)
        try saveContext()
    }
    
    /// Soft-deleted workouts still within the retention window, newest first
    /// - Throws: Database fetch errors
    func fetchRecentlyDeletedWorkouts() throws -> [Workout] {
        purgeExpiredDeletedWorkouts()
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter { $0.isDeleted }
    }
    
    /// Hard-delete soft-deleted workouts past the retention window
    func purgeExpiredDeletedWorkouts() {
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -Workout.softDeleteRetentionDays,
            to: Date()
        ) ?? Date()
        
        let descriptor = FetchDescriptor<Workout>()
        guard let workouts = try? modelContext.fetch(descriptor) else { return }
        
        let expired = workouts.filter { workout in
            guard let deletedAt = workout.deletedAt else { return false }
            return deletedAt < cutoff
        }
        
        guard !expired.isEmpty else { return }
        
        let planService = TrainingPlanService(modelContext: modelContext)
        for workout in expired {
            try? planService.rewindPlanProgressIfNeeded(afterDeleting: workout)
            modelContext.delete(workout)
        }
        try? saveContext()
    }
    
    /// Duplicate a workout as a template
    /// - Parameters:
    ///   - workout: The workout to duplicate
    ///   - name: The name for the new template
    /// - Returns: The created template workout
    /// - Throws: Database save errors
    @discardableResult
    func duplicateAsTemplate(_ workout: Workout, name: String) throws -> Workout {
        let template = workout.duplicateAsTemplate(name: name)
        modelContext.insert(template)
        try saveContext()
        
        return template
    }
    
    /// Start a workout (changes status to in progress)
    /// - Parameter workout: The workout to start
    /// - Throws: Database save errors
    func startWorkout(_ workout: Workout) throws {
        workout.start()
        try saveContext()
    }
    
    /// Complete a workout (changes status to completed)
    /// - Parameter workout: The workout to complete
    /// - Throws: Database save errors
    func completeWorkout(_ workout: Workout) throws {
        workout.complete()
        try saveContext()
    }
    
    /// Cancel a workout (changes status to cancelled)
    /// - Parameter workout: The workout to cancel
    /// - Throws: Database save errors
    func cancelWorkout(_ workout: Workout) throws {
        workout.cancel()
        try saveContext()
    }
    
    // MARK: - Query Operations
    
    /// Fetch workouts with specific status
    /// - Parameter status: The workout status to filter by
    /// - Returns: Array of workouts with the specified status
    /// - Throws: Database fetch errors
    func fetchWorkouts(withStatus status: WorkoutStatus) throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let allWorkouts = try modelContext.fetch(descriptor)
        return allWorkouts.filter { !$0.isDeleted && $0.status == status }
    }
    
    /// Fetch template workouts
    /// - Returns: Array of template workouts
    /// - Throws: Database fetch errors
    func fetchTemplates() throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let allWorkouts = try modelContext.fetch(descriptor)
        return allWorkouts.filter { !$0.isDeleted && $0.isTemplate == true }
    }
    
    /// Fetch workouts updated within a specific time period
    /// - Parameter days: Number of days to look back
    /// - Returns: Array of recently updated workouts
    /// - Throws: Database fetch errors
    func fetchRecentWorkouts(days: Int = 7) throws -> [Workout] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.updatedAt >= cutoffDate },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter { !$0.isDeleted }
    }
    
    // MARK: - Private Methods
    
    /// Save the model context
    /// - Throws: Database save errors
    private func saveContext() throws {
        try modelContext.save()
    }
}

// MARK: - Convenience Extensions

extension WorkoutService {
    
    /// Get workout statistics
    /// - Returns: Statistics about all workouts
    /// - Throws: Database fetch errors
    func getWorkoutStats() throws -> WorkoutStats {
        let allWorkouts = try fetchWorkouts()
        
        return WorkoutStats(
            total: allWorkouts.count,
            completed: allWorkouts.filter { $0.status == .completed }.count,
            inProgress: allWorkouts.filter { $0.status == .inProgress }.count,
            planned: allWorkouts.filter { $0.status == .planned }.count,
            templates: allWorkouts.filter { $0.isTemplate }.count
        )
    }
}


