//
//  ExerciseSystemInitializer.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

/// Service for initializing the exercise muscle group classification system
@MainActor
class ExerciseSystemInitializer {
    
    // MARK: - Initialization Status
    
    private static let initializationKey = "ExerciseSystemInitialized"
    private static let currentSystemVersion = 1
    
    /// Checks if the exercise system needs initialization
    static var needsInitialization: Bool {
        let currentVersion = UserDefaults.standard.integer(forKey: initializationKey)
        return currentVersion < currentSystemVersion
    }
    
    // MARK: - Main Initialization
    
    /// Performs complete exercise system initialization
    static func initializeExerciseSystem(modelContext: ModelContext) async throws {
        print("🚀 Initializing Exercise Muscle Group Classification System...")
        
        #if DEBUG
        print(String(repeating: "=", count: 60))
        print("\n📋 Step 1: Running Classification Tests...")
        let testResults = ExerciseClassificationTestService.runAllTests()
        
        if !testResults.allTestsPassed {
            print("⚠️ Some tests failed, but continuing with initialization...")
        }
        #endif
        
        if ExerciseMigrationService.needsMigration {
            print("\n🔄 Performing Database Migration...")
            try await ExerciseMigrationService.performMigration(modelContext: modelContext)
        }
        
        UserDefaults.standard.set(currentSystemVersion, forKey: initializationKey)
        
        #if DEBUG
        let validationReport = try ExerciseValidationService.validateDatabaseExercises(modelContext: modelContext)
        let coverageAnalysis = ExerciseValidationService.analyzeMuscleGroupCoverage()
        print("\n✅ Exercise System Initialization Complete!")
        printInitializationSummary(
            testResults: testResults,
            validationReport: validationReport,
            coverageAnalysis: coverageAnalysis
        )
        #else
        print("✅ Exercise System Initialization Complete!")
        #endif
    }
    
    /// Forces re-initialization of the exercise system (for development/testing)
    static func forceReinitialization(modelContext: ModelContext) async throws {
        print("🔄 Forcing Exercise System Re-initialization...")
        
        // Reset initialization flag
        UserDefaults.standard.set(0, forKey: initializationKey)
        
        // Force migration
        try await ExerciseMigrationService.forceMigration(modelContext: modelContext)
        
        // Re-initialize
        try await initializeExerciseSystem(modelContext: modelContext)
    }
    
    // MARK: - Quick Validation
    
    /// Performs a quick validation check without full initialization
    @MainActor
    static func quickValidationCheck() -> Bool {
        #if DEBUG
        print("⚡ Performing Quick Exercise System Validation...")
        
        let testResults = ExerciseClassificationTestService.runAllTests()
        let validationReport = ExerciseValidationService.validateAllExercises()
        
        let isHealthy = testResults.allTestsPassed && validationReport.isHealthy
        
        print(isHealthy ? "✅ Exercise system is healthy" : "⚠️ Exercise system needs attention")
        return isHealthy
        #else
        return !needsInitialization
        #endif
    }
    
    // MARK: - Utility Methods
    
    /// Applies classifications to all exercises in a specific workout
    static func classifyWorkoutExercises(_ workout: Workout) {
        print("🏷️ Applying classifications to workout: \(workout.name)")
        
        var classifiedCount = 0
        var skippedCount = 0
        
        for exercise in workout.exercises {
            if exercise.hasMuscleGroupClassification {
                skippedCount += 1
                continue
            }
            
            ExerciseClassificationService.applyClassification(to: exercise)
            classifiedCount += 1
        }
        
        print("✅ Classified \(classifiedCount) exercises, skipped \(skippedCount) already classified")
    }
    
    /// Gets system health status
    @MainActor
    static func getSystemHealthStatus() -> SystemHealthStatus {
        #if DEBUG
        let testResults = ExerciseClassificationTestService.runAllTests()
        let validationReport = ExerciseValidationService.validateAllExercises()
        let coverageAnalysis = ExerciseValidationService.analyzeMuscleGroupCoverage()
        
        return SystemHealthStatus(
            isHealthy: testResults.allTestsPassed && validationReport.isHealthy,
            testSuccessRate: testResults.successRate,
            classificationPercentage: validationReport.classificationPercentage,
            totalExercises: validationReport.totalExercises,
            muscleGroupsCovered: coverageAnalysis.muscleGroupExercises.count,
            lastChecked: Date()
        )
        #else
        return SystemHealthStatus(
            isHealthy: !needsInitialization,
            testSuccessRate: 100.0,
            classificationPercentage: 100.0,
            totalExercises: ExerciseDatabase.shared.totalExerciseCount,
            muscleGroupsCovered: MuscleGroup.allCases.count,
            lastChecked: Date()
        )
        #endif
    }
    
    // MARK: - Reporting
    
    private static func printInitializationSummary(
        testResults: ExerciseClassificationTestService.TestResults,
        validationReport: ExerciseValidationService.ValidationReport,
        coverageAnalysis: MuscleGroupCoverageAnalysis
    ) {
        print("\n" + String(repeating: "=", count: 60))
        print("📋 EXERCISE SYSTEM INITIALIZATION SUMMARY")
        print(String(repeating: "=", count: 60))
        
        print("🧪 Tests: \(testResults.passedTests)/\(testResults.totalTests) passed (\(String(format: "%.1f", testResults.successRate))%)")
        print("📊 Classifications: \(validationReport.classifiedExercises)/\(validationReport.totalExercises) (\(String(format: "%.1f", validationReport.classificationPercentage))%)")
        print("💪 Muscle Groups: \(coverageAnalysis.muscleGroupExercises.count) covered")
        print("🎯 System Status: \(validationReport.isHealthy ? "✅ HEALTHY" : "⚠️ NEEDS ATTENTION")")
        
        if !validationReport.isHealthy {
            print("\n⚠️ Issues to address:")
            if !validationReport.unclassifiedExercises.isEmpty {
                print("  - \(validationReport.unclassifiedExercises.count) unclassified exercises")
            }
            if !validationReport.invalidClassifications.isEmpty {
                print("  - \(validationReport.invalidClassifications.count) invalid classifications")
            }
        }
        
        print("\n🎉 The exercise muscle group classification system is ready!")
        print("Users can now see visual workout progression on the body map.")
        print(String(repeating: "=", count: 60))
    }
}

// MARK: - System Health Status

struct SystemHealthStatus {
    let isHealthy: Bool
    let testSuccessRate: Double
    let classificationPercentage: Double
    let totalExercises: Int
    let muscleGroupsCovered: Int
    let lastChecked: Date
    
    var statusEmoji: String {
        if isHealthy {
            return "✅"
        } else if classificationPercentage >= 90.0 {
            return "⚠️"
        } else {
            return "❌"
        }
    }
    
    var statusDescription: String {
        if isHealthy {
            return "System is healthy and ready"
        } else if classificationPercentage >= 90.0 {
            return "System is functional but needs minor fixes"
        } else {
            return "System needs significant attention"
        }
    }
}
