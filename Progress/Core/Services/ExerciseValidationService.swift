//
//  ExerciseValidationService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

/// Service for validating exercise muscle group classifications and ensuring data consistency
class ExerciseValidationService {
    
    // MARK: - Validation Result Types
    
    struct ValidationReport {
        let totalExercises: Int
        let classifiedExercises: Int
        let unclassifiedExercises: [String]
        let invalidClassifications: [ValidationError]
        let muscleGroupCoverage: [MuscleGroup: Int]
        let exerciseTypeCoverage: [ExerciseType: Int]
        let timestamp: Date
        
        var classificationPercentage: Double {
            guard totalExercises > 0 else { return 0.0 }
            return Double(classifiedExercises) / Double(totalExercises) * 100.0
        }
        
        var isValid: Bool {
            return unclassifiedExercises.isEmpty && invalidClassifications.isEmpty
        }
        
        var isHealthy: Bool {
            // A healthy classification system should have:
            // 1. 100% classification coverage
            // 2. No invalid classifications
            // 3. Good muscle group coverage (at least 3 exercises per major muscle group)
            let majorMuscleGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .quads, .posteriorChain, .core]
            let goodCoverage = majorMuscleGroups.allSatisfy { muscleGroup in
                (muscleGroupCoverage[muscleGroup] ?? 0) >= 3
            }
            
            return isValid && classificationPercentage >= 100.0 && goodCoverage
        }
    }
    
    struct ValidationError {
        let exerciseName: String
        let errorType: ErrorType
        let description: String
        
        enum ErrorType {
            case missingPrimaryMuscleGroup
            case invalidSecondaryIntensities
            case missingExerciseType
            case inconsistentClassification
            case duplicateExercise
        }
    }
    
    // MARK: - Validation Methods
    
    /// Performs comprehensive validation of all exercise classifications
    @MainActor
    static func validateAllExercises() -> ValidationReport {
        print("🔍 Starting comprehensive exercise validation...")
        
        let allExercises = ExerciseDatabase.shared.getAllExercises()
        let classificationService = ExerciseClassificationService.self
        
        var classifiedCount = 0
        var unclassified: [String] = []
        var validationErrors: [ValidationError] = []
        var muscleGroupCoverage: [MuscleGroup: Int] = [:]
        var exerciseTypeCoverage: [ExerciseType: Int] = [:]
        
        // Track exercise names to detect duplicates
        var exerciseNames: Set<String> = []
        
        for exercise in allExercises {
            // Check for duplicates
            if exerciseNames.contains(exercise.name) {
                validationErrors.append(ValidationError(
                    exerciseName: exercise.name,
                    errorType: .duplicateExercise,
                    description: "Duplicate exercise name found"
                ))
            }
            exerciseNames.insert(exercise.name)
            
            // Check if classification exists
            guard let classification = classificationService.getClassification(for: exercise.name) else {
                unclassified.append(exercise.name)
                continue
            }
            
            classifiedCount += 1
            
            // Validate classification
            let errors = validateClassification(exerciseName: exercise.name, classification: classification)
            validationErrors.append(contentsOf: errors)
            
            // Update coverage statistics
            muscleGroupCoverage[classification.primaryMuscleGroup, default: 0] += 1
            exerciseTypeCoverage[classification.exerciseType, default: 0] += 1
        }
        
        let report = ValidationReport(
            totalExercises: allExercises.count,
            classifiedExercises: classifiedCount,
            unclassifiedExercises: unclassified,
            invalidClassifications: validationErrors,
            muscleGroupCoverage: muscleGroupCoverage,
            exerciseTypeCoverage: exerciseTypeCoverage,
            timestamp: Date()
        )
        
        printValidationReport(report)
        return report
    }
    
    /// Validates a specific exercise classification
    private static func validateClassification(
        exerciseName: String,
        classification: ExerciseClassificationService.ExerciseClassification
    ) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate secondary muscle group intensities
        if !classification.secondaryMuscleGroups.isValid {
            errors.append(ValidationError(
                exerciseName: exerciseName,
                errorType: .invalidSecondaryIntensities,
                description: "Secondary muscle group intensities must be between 0.0 and 1.0"
            ))
        }
        
        // Check for reasonable total secondary intensity (shouldn't exceed 2.0)
        if classification.secondaryMuscleGroups.totalIntensity > 2.0 {
            errors.append(ValidationError(
                exerciseName: exerciseName,
                errorType: .invalidSecondaryIntensities,
                description: "Total secondary muscle group intensity (\(classification.secondaryMuscleGroups.totalIntensity)) is unreasonably high"
            ))
        }
        
        // Validate that primary muscle group is not also in secondary
        if classification.secondaryMuscleGroups.keys.contains(classification.primaryMuscleGroup) {
            errors.append(ValidationError(
                exerciseName: exerciseName,
                errorType: .inconsistentClassification,
                description: "Primary muscle group should not also be listed as secondary"
            ))
        }
        
        return errors
    }
    
    /// Validates exercise classifications in a SwiftData context
    @MainActor
    static func validateDatabaseExercises(modelContext: ModelContext) throws -> ValidationReport {
        print("🔍 Validating exercises in database...")
        
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseDescriptor)
        
        var classifiedCount = 0
        var unclassified: [String] = []
        var validationErrors: [ValidationError] = []
        var muscleGroupCoverage: [MuscleGroup: Int] = [:]
        var exerciseTypeCoverage: [ExerciseType: Int] = [:]
        
        for exercise in exercises {
            if exercise.hasMuscleGroupClassification {
                classifiedCount += 1
                
                // Update coverage statistics
                if let primaryMuscleGroup = exercise.primaryMuscleGroup {
                    muscleGroupCoverage[primaryMuscleGroup, default: 0] += 1
                }
                
                if let exerciseType = exercise.exerciseClassification {
                    exerciseTypeCoverage[exerciseType, default: 0] += 1
                }
                
                // Validate the classification
                let errors = validateExerciseInstance(exercise)
                validationErrors.append(contentsOf: errors)
            } else {
                unclassified.append(exercise.name)
            }
        }
        
        let report = ValidationReport(
            totalExercises: exercises.count,
            classifiedExercises: classifiedCount,
            unclassifiedExercises: unclassified,
            invalidClassifications: validationErrors,
            muscleGroupCoverage: muscleGroupCoverage,
            exerciseTypeCoverage: exerciseTypeCoverage,
            timestamp: Date()
        )
        
        printValidationReport(report)
        return report
    }
    
    /// Validates a specific Exercise instance
    private static func validateExerciseInstance(_ exercise: Exercise) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Check for missing primary muscle group
        if exercise.primaryMuscleGroup == nil {
            errors.append(ValidationError(
                exerciseName: exercise.name,
                errorType: .missingPrimaryMuscleGroup,
                description: "Exercise has no primary muscle group assigned"
            ))
        }
        
        // Validate secondary muscle groups
        let secondaryGroups = exercise.secondaryMuscleGroupsDecoded
        if !secondaryGroups.isValid {
            errors.append(ValidationError(
                exerciseName: exercise.name,
                errorType: .invalidSecondaryIntensities,
                description: "Invalid secondary muscle group intensities"
            ))
        }
        
        // Check for consistency between primary and secondary
        if let primary = exercise.primaryMuscleGroup,
           secondaryGroups.keys.contains(primary) {
            errors.append(ValidationError(
                exerciseName: exercise.name,
                errorType: .inconsistentClassification,
                description: "Primary muscle group is also listed as secondary"
            ))
        }
        
        return errors
    }
    
    // MARK: - Coverage Analysis
    
    /// Analyzes muscle group coverage and identifies gaps
    @MainActor
    static func analyzeMuscleGroupCoverage() -> MuscleGroupCoverageAnalysis {
        let allClassifications = ExerciseClassificationService.getAllClassifiedExerciseNames()
        var coverage: [MuscleGroup: [String]] = [:]
        
        for exerciseName in allClassifications {
            if let classification = ExerciseClassificationService.getClassification(for: exerciseName) {
                coverage[classification.primaryMuscleGroup, default: []].append(exerciseName)
            }
        }
        
        let analysis = MuscleGroupCoverageAnalysis(
            totalExercises: allClassifications.count,
            muscleGroupExercises: coverage,
            timestamp: Date()
        )
        
        printCoverageAnalysis(analysis)
        return analysis
    }
    
    // MARK: - Reporting
    
    private static func printValidationReport(_ report: ValidationReport) {
        print("\n📊 Exercise Validation Report")
        print(String(repeating: "=", count: 50))
        print("Total Exercises: \(report.totalExercises)")
        print("Classified: \(report.classifiedExercises) (\(String(format: "%.1f", report.classificationPercentage))%)")
        print("Unclassified: \(report.unclassifiedExercises.count)")
        print("Validation Errors: \(report.invalidClassifications.count)")
        print("Status: \(report.isHealthy ? "✅ HEALTHY" : report.isValid ? "⚠️ VALID" : "❌ INVALID")")
        
        if !report.unclassifiedExercises.isEmpty {
            print("\n❌ Unclassified Exercises:")
            for exercise in report.unclassifiedExercises.prefix(10) {
                print("  - \(exercise)")
            }
            if report.unclassifiedExercises.count > 10 {
                print("  ... and \(report.unclassifiedExercises.count - 10) more")
            }
        }
        
        if !report.invalidClassifications.isEmpty {
            print("\n⚠️ Validation Errors:")
            for error in report.invalidClassifications.prefix(5) {
                print("  - \(error.exerciseName): \(error.description)")
            }
            if report.invalidClassifications.count > 5 {
                print("  ... and \(report.invalidClassifications.count - 5) more")
            }
        }
        
        print("\n💪 Muscle Group Coverage:")
        for muscleGroup in MuscleGroup.allCases.filter({ $0.isStrengthTraining }) {
            let count = report.muscleGroupCoverage[muscleGroup] ?? 0
            let status = count >= 3 ? "✅" : count >= 1 ? "⚠️" : "❌"
            print("  \(status) \(muscleGroup.displayName): \(count) exercises")
        }
        
        print(String(repeating: "=", count: 50))
    }
    
    private static func printCoverageAnalysis(_ analysis: MuscleGroupCoverageAnalysis) {
        print("\n🎯 Muscle Group Coverage Analysis")
        print(String(repeating: "=", count: 50))
        
        for muscleGroup in MuscleGroup.allCases.filter({ $0.isStrengthTraining }) {
            let exercises = analysis.muscleGroupExercises[muscleGroup] ?? []
            let status = exercises.count >= 5 ? "✅" : exercises.count >= 3 ? "⚠️" : "❌"
            print("\n\(status) \(muscleGroup.displayName) (\(exercises.count) exercises):")
            
            for exercise in exercises.prefix(5) {
                print("  - \(exercise)")
            }
            if exercises.count > 5 {
                print("  ... and \(exercises.count - 5) more")
            }
        }
        
        print(String(repeating: "=", count: 50))
    }
}

// MARK: - Coverage Analysis Types

struct MuscleGroupCoverageAnalysis {
    let totalExercises: Int
    let muscleGroupExercises: [MuscleGroup: [String]]
    let timestamp: Date
    
    var weakestMuscleGroups: [MuscleGroup] {
        return muscleGroupExercises
            .filter { $0.key.isStrengthTraining }
            .sorted { $0.value.count < $1.value.count }
            .prefix(3)
            .map { $0.key }
    }
    
    var strongestMuscleGroups: [MuscleGroup] {
        return muscleGroupExercises
            .filter { $0.key.isStrengthTraining }
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key }
    }
}

