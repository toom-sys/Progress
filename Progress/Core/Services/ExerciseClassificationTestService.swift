//
//  ExerciseClassificationTestService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

/// Service for testing and validating exercise muscle group classifications
class ExerciseClassificationTestService {
    
    // MARK: - Test Results
    
    struct TestResults {
        let totalTests: Int
        let passedTests: Int
        let failedTests: [TestFailure]
        let timestamp: Date
        
        var successRate: Double {
            guard totalTests > 0 else { return 0.0 }
            return Double(passedTests) / Double(totalTests) * 100.0
        }
        
        var allTestsPassed: Bool {
            return failedTests.isEmpty
        }
    }
    
    struct TestFailure {
        let testName: String
        let exerciseName: String?
        let expectedValue: String
        let actualValue: String
        let description: String
    }
    
    // MARK: - Main Test Runner
    
    /// Runs all exercise classification tests
    @MainActor
    static func runAllTests() -> TestResults {
        print("🧪 Running Exercise Classification Tests...")
        print(String(repeating: "=", count: 60))
        
        var totalTests = 0
        var passedTests = 0
        var failures: [TestFailure] = []
        
        // Test 1: All default exercises have classifications
        let (test1Passed, test1Failures) = testAllExercisesHaveClassifications()
        totalTests += 1
        if test1Passed { passedTests += 1 }
        failures.append(contentsOf: test1Failures)
        
        // Test 2: All classifications are valid
        let (test2Passed, test2Failures) = testAllClassificationsAreValid()
        totalTests += 1
        if test2Passed { passedTests += 1 }
        failures.append(contentsOf: test2Failures)
        
        // Test 3: Muscle group coverage is comprehensive
        let (test3Passed, test3Failures) = testMuscleGroupCoverage()
        totalTests += 1
        if test3Passed { passedTests += 1 }
        failures.append(contentsOf: test3Failures)
        
        // Test 4: Exercise type coverage is appropriate
        let (test4Passed, test4Failures) = testExerciseTypeCoverage()
        totalTests += 1
        if test4Passed { passedTests += 1 }
        failures.append(contentsOf: test4Failures)
        
        // Test 5: Specific exercise classifications are correct
        let (test5Passed, test5Failures) = testSpecificExerciseClassifications()
        totalTests += 1
        if test5Passed { passedTests += 1 }
        failures.append(contentsOf: test5Failures)
        
        // Test 6: Secondary muscle group intensities are reasonable
        let (test6Passed, test6Failures) = testSecondaryMuscleGroupIntensities()
        totalTests += 1
        if test6Passed { passedTests += 1 }
        failures.append(contentsOf: test6Failures)
        
        let results = TestResults(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failures,
            timestamp: Date()
        )
        
        printTestResults(results)
        return results
    }
    
    // MARK: - Individual Tests
    
    /// Test 1: Verify all default exercises have classifications
    @MainActor
    private static func testAllExercisesHaveClassifications() -> (Bool, [TestFailure]) {
        print("🔍 Test 1: All default exercises have classifications...")
        
        let missingClassifications = ExerciseValidationService.validateAllExercises().unclassifiedExercises
        
        var failures: [TestFailure] = []
        
        for exerciseName in missingClassifications {
            failures.append(TestFailure(
                testName: "All exercises have classifications",
                exerciseName: exerciseName,
                expectedValue: "Has classification",
                actualValue: "Missing classification",
                description: "Exercise '\(exerciseName)' does not have a muscle group classification"
            ))
        }
        
        let passed = failures.isEmpty
        print(passed ? "✅ PASSED" : "❌ FAILED (\(failures.count) missing classifications)")
        return (passed, failures)
    }
    
    /// Test 2: Verify all classifications are valid
    @MainActor
    private static func testAllClassificationsAreValid() -> (Bool, [TestFailure]) {
        print("🔍 Test 2: All classifications are valid...")
        
        let validationReport = ExerciseValidationService.validateAllExercises()
        var failures: [TestFailure] = []
        
        for error in validationReport.invalidClassifications {
            failures.append(TestFailure(
                testName: "All classifications are valid",
                exerciseName: error.exerciseName,
                expectedValue: "Valid classification",
                actualValue: "Invalid: \(error.errorType)",
                description: error.description
            ))
        }
        
        let passed = failures.isEmpty
        print(passed ? "✅ PASSED" : "❌ FAILED (\(failures.count) validation errors)")
        return (passed, failures)
    }
    
    /// Test 3: Verify comprehensive muscle group coverage
    @MainActor
    private static func testMuscleGroupCoverage() -> (Bool, [TestFailure]) {
        print("🔍 Test 3: Comprehensive muscle group coverage...")
        
        let coverage = ExerciseValidationService.analyzeMuscleGroupCoverage()
        var failures: [TestFailure] = []
        
        let requiredMinimum = 3 // Each major muscle group should have at least 3 exercises
        let majorMuscleGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .quads, .posteriorChain, .core]
        
        for muscleGroup in majorMuscleGroups {
            let exerciseCount = coverage.muscleGroupExercises[muscleGroup]?.count ?? 0
            if exerciseCount < requiredMinimum {
                failures.append(TestFailure(
                    testName: "Muscle group coverage",
                    exerciseName: nil,
                    expectedValue: "≥\(requiredMinimum) exercises for \(muscleGroup.displayName)",
                    actualValue: "\(exerciseCount) exercises",
                    description: "\(muscleGroup.displayName) has insufficient exercise coverage"
                ))
            }
        }
        
        let passed = failures.isEmpty
        print(passed ? "✅ PASSED" : "❌ FAILED (\(failures.count) muscle groups under-covered)")
        return (passed, failures)
    }
    
    /// Test 4: Verify appropriate exercise type coverage
    @MainActor
    private static func testExerciseTypeCoverage() -> (Bool, [TestFailure]) {
        print("🔍 Test 4: Exercise type coverage...")
        
        let allClassifications = ExerciseClassificationService.getAllClassifiedExerciseNames()
        var typeCoverage: [ExerciseType: Int] = [:]
        
        for exerciseName in allClassifications {
            if let classification = ExerciseClassificationService.getClassification(for: exerciseName) {
                typeCoverage[classification.exerciseType, default: 0] += 1
            }
        }
        
        var failures: [TestFailure] = []
        
        // Verify we have good coverage of each exercise type
        let minimumStrength = 30 // Should have at least 30 strength exercises
        let minimumCardio = 10   // Should have at least 10 cardio exercises
        let minimumFlexibility = 5 // Should have at least 5 flexibility exercises
        
        let strengthCount = (typeCoverage[.strength] ?? 0) + (typeCoverage[.resistance] ?? 0)
        if strengthCount < minimumStrength {
            failures.append(TestFailure(
                testName: "Exercise type coverage",
                exerciseName: nil,
                expectedValue: "≥\(minimumStrength) strength exercises",
                actualValue: "\(strengthCount) strength exercises",
                description: "Insufficient strength exercise coverage"
            ))
        }
        
        let cardioCount = typeCoverage[.cardio] ?? 0
        if cardioCount < minimumCardio {
            failures.append(TestFailure(
                testName: "Exercise type coverage",
                exerciseName: nil,
                expectedValue: "≥\(minimumCardio) cardio exercises",
                actualValue: "\(cardioCount) cardio exercises",
                description: "Insufficient cardio exercise coverage"
            ))
        }
        
        let flexibilityCount = (typeCoverage[.flexibility] ?? 0) + (typeCoverage[.recovery] ?? 0)
        if flexibilityCount < minimumFlexibility {
            failures.append(TestFailure(
                testName: "Exercise type coverage",
                exerciseName: nil,
                expectedValue: "≥\(minimumFlexibility) flexibility exercises",
                actualValue: "\(flexibilityCount) flexibility exercises",
                description: "Insufficient flexibility exercise coverage"
            ))
        }
        
        let passed = failures.isEmpty
        print(passed ? "✅ PASSED" : "❌ FAILED (\(failures.count) type coverage issues)")
        return (passed, failures)
    }
    
    /// Test 5: Verify specific exercise classifications are correct
    @MainActor
    private static func testSpecificExerciseClassifications() -> (Bool, [TestFailure]) {
        print("🔍 Test 5: Specific exercise classifications...")
        
        var failures: [TestFailure] = []
        
        // Test specific exercises that should have known classifications
        let testCases: [(String, MuscleGroup, ExerciseType)] = [
            ("Bench Press", .chest, .strength),
            ("Pull-Ups", .back, .strength),
            ("Squats", .quads, .strength),
            ("Deadlift", .posteriorChain, .strength),
            ("Overhead Press", .shoulders, .strength),
            ("Bicep Curls", .arms, .strength),
            ("Plank", .core, .strength),
            ("Treadmill Run", .cardio, .cardio),
            ("Burpees", .cardio, .cardio),
            ("Hamstring Stretch", .posteriorChain, .flexibility)
        ]
        
        for (exerciseName, expectedMuscleGroup, expectedType) in testCases {
            // Try different variations of the exercise name
            let variations = [
                exerciseName,
                "Conventional \(exerciseName)",
                "\(exerciseName)s" // plural
            ]
            
            var found = false
            for variation in variations {
                if let classification = ExerciseClassificationService.getClassification(for: variation) {
                    found = true
                    
                    if classification.primaryMuscleGroup != expectedMuscleGroup {
                        failures.append(TestFailure(
                            testName: "Specific exercise classifications",
                            exerciseName: variation,
                            expectedValue: "Primary: \(expectedMuscleGroup.displayName)",
                            actualValue: "Primary: \(classification.primaryMuscleGroup.displayName)",
                            description: "Incorrect primary muscle group for \(variation)"
                        ))
                    }
                    
                    // For legacy compatibility, accept both old and new exercise types
                    let acceptableTypes: [ExerciseType] = {
                        switch expectedType {
                        case .strength: return [.strength, .resistance]
                        case .cardio: return [.cardio]
                        case .flexibility: return [.flexibility, .recovery]
                        default: return [expectedType]
                        }
                    }()
                    
                    if !acceptableTypes.contains(classification.exerciseType) {
                        failures.append(TestFailure(
                            testName: "Specific exercise classifications",
                            exerciseName: variation,
                            expectedValue: "Type: \(expectedType.displayName)",
                            actualValue: "Type: \(classification.exerciseType.displayName)",
                            description: "Incorrect exercise type for \(variation)"
                        ))
                    }
                    break
                }
            }
            
            if !found {
                failures.append(TestFailure(
                    testName: "Specific exercise classifications",
                    exerciseName: exerciseName,
                    expectedValue: "Has classification",
                    actualValue: "Missing classification",
                    description: "Could not find classification for \(exerciseName) or its variations"
                ))
            }
        }
        
        let passed = failures.isEmpty
        print(passed ? "✅ PASSED" : "❌ FAILED (\(failures.count) specific classification issues)")
        return (passed, failures)
    }
    
    /// Test 6: Verify secondary muscle group intensities are reasonable
    @MainActor
    private static func testSecondaryMuscleGroupIntensities() -> (Bool, [TestFailure]) {
        print("🔍 Test 6: Secondary muscle group intensities...")
        
        let allClassifications = ExerciseClassificationService.getAllClassifiedExerciseNames()
        var failures: [TestFailure] = []
        
        for exerciseName in allClassifications {
            guard let classification = ExerciseClassificationService.getClassification(for: exerciseName) else { continue }
            
            let secondaryGroups = classification.secondaryMuscleGroups
            
            // Check that all intensities are between 0.0 and 1.0
            for (muscleGroup, intensity) in secondaryGroups {
                if intensity < 0.0 || intensity > 1.0 {
                    failures.append(TestFailure(
                        testName: "Secondary muscle group intensities",
                        exerciseName: exerciseName,
                        expectedValue: "Intensity 0.0-1.0 for \(muscleGroup.displayName)",
                        actualValue: "Intensity \(intensity)",
                        description: "Invalid intensity value for secondary muscle group"
                    ))
                }
            }
            
            // Check that total secondary intensity is reasonable (shouldn't exceed 2.0)
            let totalIntensity = secondaryGroups.totalIntensity
            if totalIntensity > 2.0 {
                failures.append(TestFailure(
                    testName: "Secondary muscle group intensities",
                    exerciseName: exerciseName,
                    expectedValue: "Total secondary intensity ≤2.0",
                    actualValue: "Total intensity \(totalIntensity)",
                    description: "Total secondary muscle group intensity is too high"
                ))
            }
            
            // Check that primary muscle group is not in secondary
            if secondaryGroups.keys.contains(classification.primaryMuscleGroup) {
                failures.append(TestFailure(
                    testName: "Secondary muscle group intensities",
                    exerciseName: exerciseName,
                    expectedValue: "Primary not in secondary",
                    actualValue: "Primary \(classification.primaryMuscleGroup.displayName) also in secondary",
                    description: "Primary muscle group should not be listed as secondary"
                ))
            }
        }
        
        let passed = failures.isEmpty
        print(passed ? "✅ PASSED" : "❌ FAILED (\(failures.count) intensity issues)")
        return (passed, failures)
    }
    
    // MARK: - Reporting
    
    private static func printTestResults(_ results: TestResults) {
        print("\n" + String(repeating: "=", count: 60))
        print("🧪 EXERCISE CLASSIFICATION TEST RESULTS")
        print(String(repeating: "=", count: 60))
        print("Total Tests: \(results.totalTests)")
        print("Passed: \(results.passedTests)")
        print("Failed: \(results.failedTests.count)")
        print("Success Rate: \(String(format: "%.1f", results.successRate))%")
        print("Overall Status: \(results.allTestsPassed ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED")")
        
        if !results.failedTests.isEmpty {
            print("\n❌ FAILED TESTS:")
            print(String(repeating: "-", count: 40))
            
            for (index, failure) in results.failedTests.enumerated() {
                if index >= 10 { // Limit output to first 10 failures
                    print("... and \(results.failedTests.count - 10) more failures")
                    break
                }
                
                print("\(index + 1). \(failure.testName)")
                if let exerciseName = failure.exerciseName {
                    print("   Exercise: \(exerciseName)")
                }
                print("   Expected: \(failure.expectedValue)")
                print("   Actual: \(failure.actualValue)")
                print("   Description: \(failure.description)")
                print("")
            }
        }
        
        print(String(repeating: "=", count: 60))
        
        if results.allTestsPassed {
            print("🎉 All exercise classifications are properly configured!")
            print("The muscle group classification system is ready for use.")
        } else {
            print("⚠️ Some tests failed. Please review and fix the issues above.")
        }
    }
}

