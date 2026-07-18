import Foundation

// MARK: - Workout Generation Response Models

/// Response structure from AI workout generation
struct WorkoutGenerationResponse: Codable {
    let workoutName: String
    let description: String
    let estimatedDuration: String
    let exercises: [GeneratedExercise]
    let workoutNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case workoutName = "workout_name"
        case description
        case estimatedDuration = "estimated_duration"
        case exercises
        case workoutNotes = "workout_notes"
    }
}

/// Individual exercise in generated workout
struct GeneratedExercise: Codable {
    let name: String
    let category: String
    let sets: Int
    let reps: RepsValue
    let weight: WeightValue
    let rest: String
    let notes: String?
}

/// Flexible reps value that can handle both strings and numbers
enum RepsValue: Codable {
    case string(String)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(RepsValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
    
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return "\(value)"
        }
    }
}

/// Flexible weight value that can handle both strings and numbers
enum WeightValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(WeightValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String, Int, or Double"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }
    
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return "\(value)"
        case .double(let value):
            return "\(value)"
        }
    }
}

// MARK: - Test Result Models

/// Result of a single workout generation test
struct WorkoutGenerationTestResult {
    let request: WorkoutGenerationRequest
    let prompt: String
    let rawResponse: String
    let parsedResponse: WorkoutGenerationResponse?
    let validationResults: ValidationResults
    let duration: TimeInterval
    let success: Bool
    let error: String?
    
    struct ValidationResults {
        let allExercisesValid: Bool
        let invalidExercises: [String]
        let hasValidStructure: Bool
        let exerciseCountAppropriate: Bool
        let setsReasonable: Bool
        let repsAppropriate: Bool
        let weightSuggestionsReasonable: Bool
        let restPeriodsAppropriate: Bool
        let matchesUserRequest: Bool
        let appropriateForFitnessLevel: Bool
        let alignsWithGoals: Bool
        
        var overallScore: Double {
            let checks = [
                allExercisesValid,
                hasValidStructure,
                exerciseCountAppropriate,
                setsReasonable,
                repsAppropriate,
                weightSuggestionsReasonable,
                restPeriodsAppropriate,
                matchesUserRequest,
                appropriateForFitnessLevel,
                alignsWithGoals
            ]
            
            let passedChecks = checks.filter { $0 }.count
            return Double(passedChecks) / Double(checks.count)
        }
        
        var grade: String {
            switch overallScore {
            case 0.9...1.0: return "A"
            case 0.8..<0.9: return "B"
            case 0.7..<0.8: return "C"
            case 0.6..<0.7: return "D"
            default: return "F"
            }
        }
    }
}

/// Batch test results for multiple scenarios
struct BatchTestResults {
    let results: [WorkoutGenerationTestResult]
    let averageScore: Double
    let successRate: Double
    let averageDuration: TimeInterval
    let commonIssues: [String]
    
    var overallGrade: String {
        switch averageScore {
        case 0.9...1.0: return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        case 0.6..<0.7: return "D"
        default: return "F"
        }
    }
}

// MARK: - Workout Prompt Tester Service

/// Service for testing and validating AI workout generation prompts
@MainActor
class WorkoutPromptTester: ObservableObject {
    
    // MARK: - Properties
    
    private let openAIService = OpenAIService()
    private let promptBuilder = WorkoutPromptBuilder()
    private let responseParser = WorkoutResponseParser()
    
    @Published var isRunningTests = false
    @Published var currentTestProgress: Double = 0.0
    @Published var lastTestResults: BatchTestResults?
    @Published var lastError: String?
    @Published var lastParsingResult: WorkoutParsingResult?
    
    // MARK: - Public Methods
    
    /// Tests a single workout generation request
    func testSingleWorkout(request: WorkoutGenerationRequest) async -> WorkoutGenerationTestResult {
        let startTime = Date()
        
        // Build prompt
        let prompt = promptBuilder.buildWorkoutPrompt(for: request)
        
        do {
            // Send to OpenAI
            let rawResponse = try await openAIService.sendPrompt(
                prompt,
                configuration: .workoutGeneration
            )
            
            let duration = Date().timeIntervalSince(startTime)

            // Parse response using the new parser
            let parsingResult = responseParser.parseWorkoutResponse(
                rawResponse,
                userProfile: request.userProfile
            )
            
            // Store parsing result for detailed analysis
            lastParsingResult = parsingResult

            // Convert to legacy format for compatibility
            let parsedResponse = parsingResult.workout.map { workout in
                WorkoutGenerationResponse(
                    workoutName: workout.name,
                    description: workout.description,
                    estimatedDuration: workout.estimatedDuration,
                    exercises: workout.exercises.map { exercise in
                        GeneratedExercise(
                            name: exercise.name,
                            category: exercise.category,
                            sets: exercise.sets,
                            reps: .string(exercise.reps.displayString),
                            weight: .string(exercise.weight.displayString),
                            rest: exercise.restPeriod.displayString,
                            notes: exercise.notes
                        )
                    },
                    workoutNotes: workout.notes
                )
            }

            // Enhanced validation using parsing results
            let validationResults = validateWorkoutResponseEnhanced(
                parsingResult: parsingResult,
                request: request
            )
            
            return WorkoutGenerationTestResult(
                request: request,
                prompt: prompt,
                rawResponse: rawResponse,
                parsedResponse: parsedResponse,
                validationResults: validationResults,
                duration: duration,
                success: parsingResult.success && validationResults.overallScore >= 0.7,
                error: parsingResult.hasErrors ? parsingResult.errors.first?.localizedDescription : nil
            )
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            return WorkoutGenerationTestResult(
                request: request,
                prompt: prompt,
                rawResponse: "",
                parsedResponse: nil,
                validationResults: createFailedValidation(),
                duration: duration,
                success: false,
                error: error.localizedDescription
            )
        }
    }
    
    /// Tests all predefined validation scenarios
    func testAllScenarios() async -> BatchTestResults {
        isRunningTests = true
        currentTestProgress = 0.0
        lastError = nil
        
        let scenarios = WorkoutPromptBuilder.ValidationScenario.allCases
        var results: [WorkoutGenerationTestResult] = []
        
        for (index, scenario) in scenarios.enumerated() {
            let request = promptBuilder.getValidationPrompt(for: scenario)
            let result = await testSingleWorkout(request: request)
            results.append(result)
            
            currentTestProgress = Double(index + 1) / Double(scenarios.count)
        }
        
        let batchResults = analyzeBatchResults(results)
        lastTestResults = batchResults
        isRunningTests = false
        
        return batchResults
    }
    
    /// Tests a custom workout request
    func testCustomWorkout(
        userInput: String,
        userProfile: WorkoutGenerationRequest.UserProfile
    ) async -> WorkoutGenerationTestResult {
        
        let availableExercises = promptBuilder.getAvailableExercises()
        let (workoutType, duration, equipment) = promptBuilder.analyzeUserInput(userInput)
        
        let request = WorkoutGenerationRequest(
            userInput: userInput,
            userProfile: userProfile,
            availableExercises: availableExercises,
            workoutType: workoutType,
            duration: duration,
            equipment: equipment
        )
        
        return await testSingleWorkout(request: request)
    }
    
    /// Gets a formatted test report
    func getTestReport(for results: BatchTestResults) -> String {
        var report = """
        WORKOUT GENERATION TEST REPORT
        ==============================
        
        OVERALL RESULTS:
        - Success Rate: \(String(format: "%.1f", results.successRate * 100))%
        - Average Score: \(String(format: "%.2f", results.averageScore)) (\(results.overallGrade))
        - Average Duration: \(String(format: "%.1f", results.averageDuration))s
        - Tests Run: \(results.results.count)
        
        """
        
        if !results.commonIssues.isEmpty {
            report += """
            COMMON ISSUES:
            \(results.commonIssues.map { "- \($0)" }.joined(separator: "\n"))
            
            """
        }
        
        report += "INDIVIDUAL TEST RESULTS:\n"
        
        for (index, result) in results.results.enumerated() {
            let status = result.success ? "✅ PASS" : "❌ FAIL"
            let score = String(format: "%.2f", result.validationResults.overallScore)
            
            report += """
            
            \(index + 1). \(result.request.userInput)
               Status: \(status) (Score: \(score)/1.00, Grade: \(result.validationResults.grade))
               Profile: \(result.request.userProfile.fitnessLevel.displayName) \(result.request.userProfile.fitnessGoal.displayName)
            """
            
            if !result.success {
                if let error = result.error {
                    report += "\n   Error: \(error)"
                }
                
                if !result.validationResults.invalidExercises.isEmpty {
                    report += "\n   Invalid Exercises: \(result.validationResults.invalidExercises.joined(separator: ", "))"
                }
            }
        }
        
        return report
    }
    
    // MARK: - Private Helper Methods
    
    private func parseWorkoutResponse(_ rawResponse: String) -> WorkoutGenerationResponse? {
        // Clean up the response (remove any markdown formatting)
        let cleanResponse = rawResponse
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanResponse.data(using: .utf8) else {
            return nil
        }
        
        do {
            let response = try JSONDecoder().decode(WorkoutGenerationResponse.self, from: data)
            return response
        } catch {
            print("❌ Failed to parse workout response: \(error)")
            print("Raw response: \(cleanResponse)")
            return nil
        }
    }
    
    /// Enhanced validation using parsing results
    private func validateWorkoutResponseEnhanced(
        parsingResult: WorkoutParsingResult,
        request: WorkoutGenerationRequest
    ) -> WorkoutGenerationTestResult.ValidationResults {
        
        guard let workout = parsingResult.workout else {
            return createFailedValidation()
        }
        
        // Check if all exercises are valid (already validated by parser)
        let invalidExercises = workout.exercises.compactMap { exercise in
            exercise.isValidExercise ? nil : exercise.name
        }
        let allExercisesValid = invalidExercises.isEmpty
        
        // Check structure (already validated by parser)
        let hasValidStructure = workout.isValid
        
        // Check exercise count
        let exerciseCount = workout.exercises.count
        let exerciseCountAppropriate = exerciseCount >= 3 && exerciseCount <= 12
        
        // Check sets (already sanitized by parser)
        let setsReasonable = workout.exercises.allSatisfy { exercise in
            exercise.sets >= 1 && exercise.sets <= 6
        }
        
        // Check reps (already sanitized by parser)
        let repsAppropriate = workout.exercises.allSatisfy { exercise in
            exercise.reps.isValid
        }
        
        // Check weight suggestions (already sanitized by parser)
        let weightSuggestionsReasonable = workout.exercises.allSatisfy { exercise in
            exercise.weight.isValid
        }
        
        // Check rest periods (already sanitized by parser)
        let restPeriodsAppropriate = workout.exercises.allSatisfy { exercise in
            exercise.restPeriod.isValid
        }
        
        // Check if matches user request
        let userInput = request.userInput.lowercased()
        let workoutName = workout.name.lowercased()
        let description = workout.description.lowercased()
        let matchesUserRequest = workoutName.contains(where: { char in
            userInput.contains(char)
        }) || description.contains(where: { char in
            userInput.contains(char)
        }) || workout.exercises.contains { exercise in
            exercise.name.lowercased().contains(where: { char in
                userInput.contains(char)
            })
        }
        
        // Check if appropriate for fitness level
        let appropriateForFitnessLevel = validateFitnessLevelAppropriateEnhanced(
            workout: workout,
            fitnessLevel: request.userProfile.fitnessLevel
        )
        
        // Check if aligns with goals
        let alignsWithGoals = validateGoalAlignmentEnhanced(
            workout: workout,
            fitnessGoal: request.userProfile.fitnessGoal
        )
        
        return WorkoutGenerationTestResult.ValidationResults(
            allExercisesValid: allExercisesValid,
            invalidExercises: invalidExercises,
            hasValidStructure: hasValidStructure,
            exerciseCountAppropriate: exerciseCountAppropriate,
            setsReasonable: setsReasonable,
            repsAppropriate: repsAppropriate,
            weightSuggestionsReasonable: weightSuggestionsReasonable,
            restPeriodsAppropriate: restPeriodsAppropriate,
            matchesUserRequest: matchesUserRequest,
            appropriateForFitnessLevel: appropriateForFitnessLevel,
            alignsWithGoals: alignsWithGoals
        )
    }
    
    private func validateFitnessLevelAppropriateEnhanced(
        workout: ParsedWorkout,
        fitnessLevel: FitnessLevel
    ) -> Bool {
        let avgSets = Double(workout.exercises.map { $0.sets }.reduce(0, +)) / Double(workout.exercises.count)
        
        switch fitnessLevel {
        case .beginner:
            return avgSets <= 3.5 && workout.exercises.count <= 6
        case .intermediate:
            return avgSets <= 4.0 && workout.exercises.count <= 8
        case .advanced:
            return avgSets <= 5.0 && workout.exercises.count <= 12
        }
    }
    
    private func validateGoalAlignmentEnhanced(
        workout: ParsedWorkout,
        fitnessGoal: FitnessGoal
    ) -> Bool {
        let description = workout.description.lowercased()
        
        switch fitnessGoal {
        case .weightLoss:
            return description.contains("calorie") || description.contains("burn") || description.contains("cardio") ||
                   workout.exercises.contains { $0.category.lowercased() == "cardio" }
        case .muscleGain:
            return description.contains("muscle") || description.contains("hypertrophy") || description.contains("build") ||
                   workout.exercises.allSatisfy { $0.reps.min >= 6 && $0.reps.min <= 15 }
        case .strengthTraining:
            return description.contains("strength") || description.contains("power") || description.contains("heavy") ||
                   workout.exercises.contains { $0.reps.min <= 6 }
        case .endurance:
            return description.contains("endurance") || description.contains("cardio") || description.contains("stamina") ||
                   workout.exercises.contains { $0.reps.min >= 15 }
        case .generalFitness, .maintenance:
            return true // General fitness is always appropriate
        }
    }
    
    private func validateWorkoutResponse(
        response: WorkoutGenerationResponse?,
        request: WorkoutGenerationRequest,
        availableExercises: [String]
    ) -> WorkoutGenerationTestResult.ValidationResults {
        
        guard let response = response else {
            return createFailedValidation()
        }
        
        // Check if all exercises are valid
        let invalidExercises = response.exercises.compactMap { exercise in
            availableExercises.contains(exercise.name) ? nil : exercise.name
        }
        let allExercisesValid = invalidExercises.isEmpty
        
        // Check structure
        let hasValidStructure = !response.workoutName.isEmpty &&
                               !response.description.isEmpty &&
                               !response.exercises.isEmpty
        
        // Check exercise count
        let exerciseCount = response.exercises.count
        let exerciseCountAppropriate = exerciseCount >= 3 && exerciseCount <= 12
        
        // Check sets
        let setsReasonable = response.exercises.allSatisfy { exercise in
            exercise.sets >= 1 && exercise.sets <= 6
        }
        
        // Check reps (basic validation - should contain numbers or ranges)
        let repsAppropriate = response.exercises.allSatisfy { exercise in
            let repsString = exercise.reps.stringValue
            return repsString.contains(where: { $0.isNumber }) || repsString.contains("-")
        }
        
        // Check weight suggestions (should contain numbers and units)
        let weightSuggestionsReasonable = response.exercises.allSatisfy { exercise in
            let weightString = exercise.weight.stringValue
            return weightString.contains(where: { $0.isNumber }) &&
            (weightString.contains("kg") || weightString.contains("lbs") || 
             weightString.lowercased().contains("bodyweight") ||
             weightString.lowercased().contains("moderate") ||
             weightString.lowercased().contains("light") ||
             weightString.lowercased().contains("heavy") ||
             weightString == "0") // Handle new bodyweight format
        }
        
        // Check rest periods
        let restPeriodsAppropriate = response.exercises.allSatisfy { exercise in
            exercise.rest.contains(where: { $0.isNumber }) &&
            (exercise.rest.contains("second") || exercise.rest.contains("minute") || exercise.rest.contains("min"))
        }
        
        // Check if matches user request (basic keyword matching)
        let userInput = request.userInput.lowercased()
        let workoutName = response.workoutName.lowercased()
        let description = response.description.lowercased()
        let matchesUserRequest = workoutName.contains(where: { char in
            userInput.contains(char)
        }) || description.contains(where: { char in
            userInput.contains(char)
        })
        
        // Check if appropriate for fitness level
        let appropriateForFitnessLevel = validateFitnessLevelAppropriate(
            response: response,
            fitnessLevel: request.userProfile.fitnessLevel
        )
        
        // Check if aligns with goals
        let alignsWithGoals = validateGoalAlignment(
            response: response,
            fitnessGoal: request.userProfile.fitnessGoal
        )
        
        return WorkoutGenerationTestResult.ValidationResults(
            allExercisesValid: allExercisesValid,
            invalidExercises: invalidExercises,
            hasValidStructure: hasValidStructure,
            exerciseCountAppropriate: exerciseCountAppropriate,
            setsReasonable: setsReasonable,
            repsAppropriate: repsAppropriate,
            weightSuggestionsReasonable: weightSuggestionsReasonable,
            restPeriodsAppropriate: restPeriodsAppropriate,
            matchesUserRequest: matchesUserRequest,
            appropriateForFitnessLevel: appropriateForFitnessLevel,
            alignsWithGoals: alignsWithGoals
        )
    }
    
    private func validateFitnessLevelAppropriate(
        response: WorkoutGenerationResponse,
        fitnessLevel: FitnessLevel
    ) -> Bool {
        let avgSets = Double(response.exercises.map { $0.sets }.reduce(0, +)) / Double(response.exercises.count)
        
        switch fitnessLevel {
        case .beginner:
            return avgSets <= 3.5 && response.exercises.count <= 6
        case .intermediate:
            return avgSets <= 4.0 && response.exercises.count <= 8
        case .advanced:
            return avgSets <= 5.0 && response.exercises.count <= 12
        }
    }
    
    private func validateGoalAlignment(
        response: WorkoutGenerationResponse,
        fitnessGoal: FitnessGoal
    ) -> Bool {
        // Basic validation - could be more sophisticated
        let description = response.description.lowercased()
        
        switch fitnessGoal {
        case .weightLoss:
            return description.contains("calorie") || description.contains("burn") || description.contains("cardio")
        case .muscleGain:
            return description.contains("muscle") || description.contains("hypertrophy") || description.contains("build")
        case .strengthTraining:
            return description.contains("strength") || description.contains("power") || description.contains("heavy")
        case .endurance:
            return description.contains("endurance") || description.contains("cardio") || description.contains("stamina")
        case .generalFitness, .maintenance:
            return true // General fitness is always appropriate
        }
    }
    
    private func createFailedValidation() -> WorkoutGenerationTestResult.ValidationResults {
        return WorkoutGenerationTestResult.ValidationResults(
            allExercisesValid: false,
            invalidExercises: [],
            hasValidStructure: false,
            exerciseCountAppropriate: false,
            setsReasonable: false,
            repsAppropriate: false,
            weightSuggestionsReasonable: false,
            restPeriodsAppropriate: false,
            matchesUserRequest: false,
            appropriateForFitnessLevel: false,
            alignsWithGoals: false
        )
    }
    
    private func analyzeBatchResults(_ results: [WorkoutGenerationTestResult]) -> BatchTestResults {
        let successCount = results.filter { $0.success }.count
        let successRate = Double(successCount) / Double(results.count)
        
        let averageScore = results.map { $0.validationResults.overallScore }.reduce(0, +) / Double(results.count)
        let averageDuration = results.map { $0.duration }.reduce(0, +) / Double(results.count)
        
        // Analyze common issues
        var issueCount: [String: Int] = [:]
        
        for result in results where !result.success {
            if !result.validationResults.allExercisesValid {
                issueCount["Invalid exercises used"] = (issueCount["Invalid exercises used"] ?? 0) + 1
            }
            if !result.validationResults.hasValidStructure {
                issueCount["Invalid JSON structure"] = (issueCount["Invalid JSON structure"] ?? 0) + 1
            }
            if !result.validationResults.exerciseCountAppropriate {
                issueCount["Inappropriate exercise count"] = (issueCount["Inappropriate exercise count"] ?? 0) + 1
            }
            if !result.validationResults.matchesUserRequest {
                issueCount["Doesn't match user request"] = (issueCount["Doesn't match user request"] ?? 0) + 1
            }
        }
        
        let commonIssues = issueCount.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        return BatchTestResults(
            results: results,
            averageScore: averageScore,
            successRate: successRate,
            averageDuration: averageDuration,
            commonIssues: Array(commonIssues)
        )
    }
}
