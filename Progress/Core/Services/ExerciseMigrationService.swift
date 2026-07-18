//
//  ExerciseMigrationService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

/// Service for migrating existing exercises to include muscle group classifications
@MainActor
class ExerciseMigrationService {
    
    // MARK: - Migration Status
    
    private static let migrationVersionKey = "ExerciseMigrationVersion"
    private static let currentMigrationVersion = 1
    
    /// Checks if migration is needed
    static var needsMigration: Bool {
        let currentVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)
        return currentVersion < currentMigrationVersion
    }
    
    // MARK: - Migration Methods
    
    /// Performs the complete migration process
    @MainActor
    static func performMigration(modelContext: ModelContext) async throws {
        print("🔄 Starting exercise muscle group migration...")
        
        // Step 1: Migrate existing exercises in workouts
        try await migrateWorkoutExercises(modelContext: modelContext)
        
        // Step 2: Update predefined exercise mappings
        try await updatePredefinedExerciseMappings(modelContext: modelContext)
        
        // Step 3: Mark migration as complete
        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
        
        print("✅ Exercise muscle group migration completed successfully!")
    }
    
    /// Migrates all exercises in existing workouts
    private static func migrateWorkoutExercises(modelContext: ModelContext) async throws {
        print("🔄 Migrating workout exercises...")
        
        // Fetch all workouts
        let workoutDescriptor = FetchDescriptor<Workout>()
        let workouts = try modelContext.fetch(workoutDescriptor)
        
        var migratedCount = 0
        var skippedCount = 0
        
        for workout in workouts {
            for exercise in workout.exercises {
                // Skip if already has muscle group classification
                if exercise.hasMuscleGroupClassification {
                    skippedCount += 1
                    continue
                }
                
                // Apply classification based on exercise name
                ExerciseClassificationService.applyClassification(to: exercise)
                migratedCount += 1
            }
        }
        
        // Save changes
        try modelContext.save()
        
        print("✅ Migrated \(migratedCount) exercises, skipped \(skippedCount) already classified")
    }
    
    /// Updates predefined exercise mappings in the database
    @MainActor
    private static func updatePredefinedExerciseMappings(modelContext: ModelContext) async throws {
        print("🔄 Updating predefined exercise mappings...")
        
        // This would update the ExerciseDatabase if needed
        // For now, we'll just validate that all predefined exercises have classifications
        let missingClassifications = ExerciseClassificationService.validateExerciseClassifications()
        
        if !missingClassifications.isEmpty {
            print("⚠️ Found \(missingClassifications.count) exercises without classifications:")
            for exerciseName in missingClassifications.prefix(10) {
                print("  - \(exerciseName)")
            }
            if missingClassifications.count > 10 {
                print("  ... and \(missingClassifications.count - 10) more")
            }
        } else {
            print("✅ All predefined exercises have muscle group classifications")
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates the migration was successful
    static func validateMigration(modelContext: ModelContext) throws -> MigrationValidationResult {
        print("🔍 Validating exercise migration...")
        
        // Fetch all exercises
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseDescriptor)
        
        var totalExercises = 0
        var classifiedExercises = 0
        var customExercises = 0
        var predefinedExercises = 0
        var missingClassifications: [String] = []
        
        for exercise in exercises {
            totalExercises += 1
            
            if exercise.isCustom {
                customExercises += 1
            } else {
                predefinedExercises += 1
            }
            
            if exercise.hasMuscleGroupClassification {
                classifiedExercises += 1
            } else {
                missingClassifications.append(exercise.name)
            }
        }
        
        let result = MigrationValidationResult(
            totalExercises: totalExercises,
            classifiedExercises: classifiedExercises,
            customExercises: customExercises,
            predefinedExercises: predefinedExercises,
            missingClassifications: missingClassifications
        )
        
        print("📊 Migration validation results:")
        print("  Total exercises: \(totalExercises)")
        print("  Classified exercises: \(classifiedExercises)")
        print("  Custom exercises: \(customExercises)")
        print("  Predefined exercises: \(predefinedExercises)")
        print("  Missing classifications: \(missingClassifications.count)")
        
        return result
    }
    
    /// Forces re-migration of all exercises (for development/testing)
    @MainActor
    static func forceMigration(modelContext: ModelContext) async throws {
        print("🔄 Forcing complete re-migration...")
        
        // Reset migration version
        UserDefaults.standard.set(0, forKey: migrationVersionKey)
        
        // Clear existing classifications
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseDescriptor)
        
        for exercise in exercises {
            exercise.primaryMuscleGroup = nil
            exercise.secondaryMuscleGroups = nil
            exercise.exerciseClassification = nil
        }
        
        try modelContext.save()
        
        // Perform migration
        try await performMigration(modelContext: modelContext)
    }
}

// MARK: - Migration Validation Result

struct MigrationValidationResult {
    let totalExercises: Int
    let classifiedExercises: Int
    let customExercises: Int
    let predefinedExercises: Int
    let missingClassifications: [String]
    
    var classificationPercentage: Double {
        guard totalExercises > 0 else { return 0.0 }
        return Double(classifiedExercises) / Double(totalExercises) * 100.0
    }
    
    var isSuccessful: Bool {
        // Migration is successful if at least 90% of exercises are classified
        // and all predefined exercises are classified
        return classificationPercentage >= 90.0 && 
               missingClassifications.filter { !isCustomExerciseName($0) }.isEmpty
    }
    
    private func isCustomExerciseName(_ name: String) -> Bool {
        // Simple heuristic: if it's not in our classification service, it's likely custom
        return ExerciseClassificationService.getClassification(for: name) == nil
    }
}

// MARK: - Migration Extensions

extension Exercise {
    
    /// Applies muscle group classification if not already present
    func applyClassificationIfNeeded() {
        guard !hasMuscleGroupClassification else { return }
        ExerciseClassificationService.applyClassification(to: self)
    }
    
    /// Forces reapplication of muscle group classification
    func reapplyClassification() {
        ExerciseClassificationService.applyClassification(to: self)
    }
}
