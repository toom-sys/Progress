import Foundation
import SwiftData

// MARK: - Parsed Workout Models

/// Represents a parsed workout from ChatGPT response
struct ParsedWorkout {
    let name: String
    let description: String
    let estimatedDuration: String
    let exercises: [ParsedExercise]
    let notes: String?
    
    var isValid: Bool {
        return !name.isEmpty && 
               !description.isEmpty && 
               !exercises.isEmpty &&
               exercises.allSatisfy { $0.isValid }
    }
}

/// Represents a parsed exercise with sanitized parameters
struct ParsedExercise {
    let name: String
    let category: String
    let sets: Int
    let reps: RepRange
    let weight: WeightRange
    let restPeriod: RestPeriod
    let notes: String?
    let isValidExercise: Bool // Whether exercise exists in database
    
    var isValid: Bool {
        return !name.isEmpty &&
               sets > 0 && sets <= 10 &&
               reps.isValid &&
               weight.isValid &&
               restPeriod.isValid
    }
}

/// Represents a range of repetitions
struct RepRange {
    let min: Int
    let max: Int?
    
    var displayString: String {
        if let max = max, max != min {
            return "\(min)-\(max)"
        } else {
            return "\(min)"
        }
    }
    
    var isValid: Bool {
        return min > 0 && min <= 100 && (max == nil || max! >= min)
    }
}

/// Represents a weight range with units
struct WeightRange {
    let min: Double
    let max: Double?
    let unit: String
    let isBodyweight: Bool
    
    var displayString: String {
        if isBodyweight {
            return "bodyweight"
        } else if let max = max, max != min {
            return "\(Int(min))-\(Int(max)) \(unit)"
        } else {
            return "\(Int(min)) \(unit)"
        }
    }
    
    var isValid: Bool {
        if isBodyweight { return true }
        return min >= 0 && min <= 1000 && (max == nil || max! >= min)
    }
}

/// Represents rest period between sets
struct RestPeriod {
    let seconds: TimeInterval
    
    var displayString: String {
        if seconds < 60 {
            return "\(Int(seconds)) seconds"
        } else {
            let minutes = Int(seconds / 60)
            let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
            if remainingSeconds == 0 {
                return "\(minutes) minute\(minutes == 1 ? "" : "s")"
            } else {
                return "\(minutes):\(String(format: "%02d", remainingSeconds))"
            }
        }
    }
    
    var isValid: Bool {
        return seconds >= 15 && seconds <= 600 // 15 seconds to 10 minutes
    }
}

// MARK: - Parsing Result Models

/// Result of parsing a workout response
struct WorkoutParsingResult {
    let workout: ParsedWorkout?
    let success: Bool
    let errors: [WorkoutParsingError]
    let warnings: [WorkoutParsingWarning]
    let sanitizedParameters: [ParameterSanitization]
    
    var hasErrors: Bool { !errors.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
    var hasSanitizations: Bool { !sanitizedParameters.isEmpty }
}

/// Errors that can occur during parsing
enum WorkoutParsingError: Error, LocalizedError {
    case invalidJSON(String)
    case missingRequiredField(String)
    case invalidExerciseName(String)
    case unrealisticParameter(String, String)
    case unsupportedFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON(let details):
            return "Invalid JSON format: \(details)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidExerciseName(let name):
            return "Exercise '\(name)' not found in database"
        case .unrealisticParameter(let exercise, let parameter):
            return "Unrealistic \(parameter) for \(exercise)"
        case .unsupportedFormat(let details):
            return "Unsupported response format: \(details)"
        }
    }
}

/// Warnings for issues that were handled but user should know about
enum WorkoutParsingWarning {
    case exerciseSubstituted(original: String, replacement: String)
    case parameterAdjusted(exercise: String, parameter: String, reason: String)
    case formatVariationHandled(String)
    
    var description: String {
        switch self {
        case .exerciseSubstituted(let original, let replacement):
            return "Substituted '\(original)' with '\(replacement)'"
        case .parameterAdjusted(let exercise, let parameter, let reason):
            return "Adjusted \(parameter) for \(exercise): \(reason)"
        case .formatVariationHandled(let details):
            return "Handled format variation: \(details)"
        }
    }
}

/// Record of parameter sanitizations
struct ParameterSanitization {
    let exerciseName: String
    let parameter: String
    let originalValue: String
    let sanitizedValue: String
    let reason: String
}

// MARK: - Workout Response Parser Service

/// Service for parsing ChatGPT workout responses into structured data
@MainActor
class WorkoutResponseParser: ObservableObject {
    
    // MARK: - Properties
    
    private let exerciseDatabase = ExerciseDatabase.shared
    private let exerciseValidator = ExerciseValidator()
    
    @Published var lastParsingResult: WorkoutParsingResult?
    
    // MARK: - Public Methods
    
    /// Parse a ChatGPT response into a structured workout
    @MainActor
    func parseWorkoutResponse(
        _ rawResponse: String,
        userProfile: WorkoutGenerationRequest.UserProfile
    ) -> WorkoutParsingResult {
        
        var errors: [WorkoutParsingError] = []
        var warnings: [WorkoutParsingWarning] = []
        var sanitizations: [ParameterSanitization] = []
        
        // Clean the response
        let cleanedResponse = cleanResponse(rawResponse)
        
        // Try to parse as JSON first
        if let jsonWorkout = tryParseJSON(cleanedResponse, errors: &errors) {
            let (parsedWorkout, parseWarnings, parseSanitizations) = processWorkout(
                jsonWorkout, 
                userProfile: userProfile
            )
            warnings.append(contentsOf: parseWarnings)
            sanitizations.append(contentsOf: parseSanitizations)
            
            let result = WorkoutParsingResult(
                workout: parsedWorkout,
                success: parsedWorkout != nil,
                errors: errors,
                warnings: warnings,
                sanitizedParameters: sanitizations
            )
            
            lastParsingResult = result
            return result
        }
        
        // Try fallback parsing methods
        if let fallbackWorkout = tryFallbackParsing(cleanedResponse, userProfile: userProfile, warnings: &warnings, sanitizations: &sanitizations) {
            let result = WorkoutParsingResult(
                workout: fallbackWorkout,
                success: true,
                errors: errors,
                warnings: warnings,
                sanitizedParameters: sanitizations
            )
            
            lastParsingResult = result
            return result
        }
        
        // Parsing failed
        errors.append(.unsupportedFormat("Could not parse response in any supported format"))
        let result = WorkoutParsingResult(
            workout: nil,
            success: false,
            errors: errors,
            warnings: warnings,
            sanitizedParameters: sanitizations
        )
        
        lastParsingResult = result
        return result
    }
    
    /// Create SwiftData workout models from parsed workout
    @MainActor
    func createWorkoutModels(
        from parsedWorkout: ParsedWorkout,
        userProfile: WorkoutGenerationRequest.UserProfile,
        modelContext: ModelContext
    ) throws -> Workout {
        
        // Create the workout
        let workout = Workout(
            name: parsedWorkout.name,
            notes: parsedWorkout.notes
        )
        
        // Add exercises
        for (index, parsedExercise) in parsedWorkout.exercises.enumerated() {
            let exercise = try createExerciseModel(
                from: parsedExercise,
                order: index,
                userProfile: userProfile
            )
            workout.addExercise(exercise)
        }
        
        // Insert into context
        modelContext.insert(workout)
        
        return workout
    }
    
    // MARK: - Private Parsing Methods
    
    private func cleanResponse(_ response: String) -> String {
        return response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @MainActor
    private func tryParseJSON(
        _ response: String,
        errors: inout [WorkoutParsingError]
    ) -> WorkoutGenerationResponse? {
        
        guard let data = response.data(using: .utf8) else {
            errors.append(.invalidJSON("Could not convert to UTF-8 data"))
            return nil
        }
        
        do {
            let workout = try JSONDecoder().decode(WorkoutGenerationResponse.self, from: data)
            return workout
        } catch {
            errors.append(.invalidJSON(error.localizedDescription))
            return nil
        }
    }
    
    @MainActor
    private func processWorkout(
        _ jsonWorkout: WorkoutGenerationResponse,
        userProfile: WorkoutGenerationRequest.UserProfile
    ) -> (ParsedWorkout?, [WorkoutParsingWarning], [ParameterSanitization]) {
        
        var warnings: [WorkoutParsingWarning] = []
        var sanitizations: [ParameterSanitization] = []
        var parsedExercises: [ParsedExercise] = []
        
        for jsonExercise in jsonWorkout.exercises {
            if let parsedExercise = processExercise(
                jsonExercise,
                userProfile: userProfile,
                warnings: &warnings,
                sanitizations: &sanitizations
            ) {
                parsedExercises.append(parsedExercise)
            }
        }
        
        guard !parsedExercises.isEmpty else {
            return (nil, warnings, sanitizations)
        }
        
        let parsedWorkout = ParsedWorkout(
            name: jsonWorkout.workoutName,
            description: jsonWorkout.description,
            estimatedDuration: jsonWorkout.estimatedDuration,
            exercises: parsedExercises,
            notes: jsonWorkout.workoutNotes
        )
        
        return (parsedWorkout, warnings, sanitizations)
    }
    
    @MainActor
    private func processExercise(
        _ jsonExercise: GeneratedExercise,
        userProfile: WorkoutGenerationRequest.UserProfile,
        warnings: inout [WorkoutParsingWarning],
        sanitizations: inout [ParameterSanitization]
    ) -> ParsedExercise? {
        
        // Validate and potentially substitute exercise name
        let (exerciseName, isValid) = exerciseValidator.validateAndSubstituteExercise(
            jsonExercise.name,
            warnings: &warnings
        )
        
        // Parse and sanitize sets
        let sanitizedSets = sanitizeSets(
            jsonExercise.sets,
            exerciseName: exerciseName,
            fitnessLevel: userProfile.fitnessLevel,
            sanitizations: &sanitizations
        )
        
        // Parse and sanitize reps
        let repRange = parseRepRange(
            jsonExercise.reps.stringValue,
            exerciseName: exerciseName,
            fitnessLevel: userProfile.fitnessLevel,
            sanitizations: &sanitizations
        )
        
        // Parse and sanitize weight
        let weightRange = parseWeightRange(
            jsonExercise.weight.stringValue,
            exerciseName: exerciseName,
            fitnessLevel: userProfile.fitnessLevel,
            preferredUnits: userProfile.preferredUnits,
            sanitizations: &sanitizations
        )
        
        // Parse and sanitize rest period
        let restPeriod = parseRestPeriod(
            jsonExercise.rest,
            exerciseName: exerciseName,
            sanitizations: &sanitizations
        )
        
        return ParsedExercise(
            name: exerciseName,
            category: jsonExercise.category,
            sets: sanitizedSets,
            reps: repRange,
            weight: weightRange,
            restPeriod: restPeriod,
            notes: jsonExercise.notes,
            isValidExercise: isValid
        )
    }
    
    // MARK: - Sanitization Methods
    
    private func sanitizeSets(
        _ sets: Int,
        exerciseName: String,
        fitnessLevel: FitnessLevel,
        sanitizations: inout [ParameterSanitization]
    ) -> Int {
        
        let maxSets: Int
        switch fitnessLevel {
        case .beginner: maxSets = 3
        case .intermediate: maxSets = 4
        case .advanced: maxSets = 5
        }
        
        let minSets = 1
        let originalSets = sets
        let sanitizedSets = max(minSets, min(sets, maxSets))
        
        if sanitizedSets != originalSets {
            sanitizations.append(ParameterSanitization(
                exerciseName: exerciseName,
                parameter: "sets",
                originalValue: "\(originalSets)",
                sanitizedValue: "\(sanitizedSets)",
                reason: "Adjusted for \(fitnessLevel.displayName) level"
            ))
        }
        
        return sanitizedSets
    }
    
    private func parseRepRange(
        _ repsString: String,
        exerciseName: String,
        fitnessLevel: FitnessLevel,
        sanitizations: inout [ParameterSanitization]
    ) -> RepRange {
        
        let cleanReps = repsString.lowercased()
            .replacingOccurrences(of: " reps", with: "")
            .replacingOccurrences(of: " rep", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle ranges like "8-12", "10-15"
        if cleanReps.contains("-") {
            let parts = cleanReps.components(separatedBy: "-")
            if parts.count == 2,
               let min = Int(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
               let max = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                return sanitizeRepRange(RepRange(min: min, max: max), exerciseName: exerciseName, fitnessLevel: fitnessLevel, sanitizations: &sanitizations)
            }
        }
        
        // Handle single numbers
        if let reps = Int(cleanReps) {
            return sanitizeRepRange(RepRange(min: reps, max: nil), exerciseName: exerciseName, fitnessLevel: fitnessLevel, sanitizations: &sanitizations)
        }
        
        // Handle time-based (for cardio) and distance-based
        if cleanReps.contains("minute") || cleanReps.contains("min") || 
           cleanReps.contains("km") || cleanReps.contains("mile") || 
           cleanReps.contains("second") || cleanReps.contains("sec") {
            // For cardio/recovery exercises, use 1 rep to represent the activity
            return RepRange(min: 1, max: nil)
        }
        
        // Fallback to fitness level default
        let defaultReps: Int
        switch fitnessLevel {
        case .beginner: defaultReps = 10
        case .intermediate: defaultReps = 12
        case .advanced: defaultReps = 8
        }
        
        sanitizations.append(ParameterSanitization(
            exerciseName: exerciseName,
            parameter: "reps",
            originalValue: repsString,
            sanitizedValue: "\(defaultReps)",
            reason: "Could not parse, used default for fitness level"
        ))
        
        return RepRange(min: defaultReps, max: nil)
    }
    
    private func sanitizeRepRange(
        _ repRange: RepRange,
        exerciseName: String,
        fitnessLevel: FitnessLevel,
        sanitizations: inout [ParameterSanitization]
    ) -> RepRange {
        
        let maxReps: Int
        switch fitnessLevel {
        case .beginner: maxReps = 20
        case .intermediate: maxReps = 25
        case .advanced: maxReps = 50
        }
        
        let minReps = 1
        let originalMin = repRange.min
        let originalMax = repRange.max
        
        let sanitizedMin = max(minReps, min(repRange.min, maxReps))
        let sanitizedMax = repRange.max.map { max(sanitizedMin, min($0, maxReps)) }
        
        if sanitizedMin != originalMin || sanitizedMax != originalMax {
            let originalValue = originalMax != nil ? "\(originalMin)-\(originalMax!)" : "\(originalMin)"
            let sanitizedValue = sanitizedMax != nil ? "\(sanitizedMin)-\(sanitizedMax!)" : "\(sanitizedMin)"
            
            sanitizations.append(ParameterSanitization(
                exerciseName: exerciseName,
                parameter: "reps",
                originalValue: originalValue,
                sanitizedValue: sanitizedValue,
                reason: "Adjusted to safe range for \(fitnessLevel.displayName) level"
            ))
        }
        
        return RepRange(min: sanitizedMin, max: sanitizedMax)
    }
    
    private func parseWeightRange(
        _ weightString: String,
        exerciseName: String,
        fitnessLevel: FitnessLevel,
        preferredUnits: UnitSystem,
        sanitizations: inout [ParameterSanitization]
    ) -> WeightRange {
        
        let cleanWeight = weightString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle bodyweight exercises
        if cleanWeight.contains("bodyweight") || cleanWeight.contains("body weight") || cleanWeight == "0" {
            return WeightRange(min: 0, max: nil, unit: "", isBodyweight: true)
        }
        
        // Extract unit
        let unit = preferredUnits.weightUnit
        let weightWithoutUnit = cleanWeight
            .replacingOccurrences(of: "kg", with: "")
            .replacingOccurrences(of: "lbs", with: "")
            .replacingOccurrences(of: "pounds", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle ranges like "20-25", "15-20"
        if weightWithoutUnit.contains("-") {
            let parts = weightWithoutUnit.components(separatedBy: "-")
            if parts.count == 2,
               let min = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
               let max = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                return sanitizeWeightRange(
                    WeightRange(min: min, max: max, unit: unit, isBodyweight: false),
                    exerciseName: exerciseName,
                    fitnessLevel: fitnessLevel,
                    sanitizations: &sanitizations
                )
            }
        }
        
        // Handle single numbers
        if let weight = Double(weightWithoutUnit) {
            return sanitizeWeightRange(
                WeightRange(min: weight, max: nil, unit: unit, isBodyweight: false),
                exerciseName: exerciseName,
                fitnessLevel: fitnessLevel,
                sanitizations: &sanitizations
            )
        }
        
        // Fallback to fitness level default
        let defaultWeight: Double
        switch fitnessLevel {
        case .beginner: defaultWeight = preferredUnits == .metric ? 10 : 20
        case .intermediate: defaultWeight = preferredUnits == .metric ? 20 : 45
        case .advanced: defaultWeight = preferredUnits == .metric ? 40 : 90
        }
        
        sanitizations.append(ParameterSanitization(
            exerciseName: exerciseName,
            parameter: "weight",
            originalValue: weightString,
            sanitizedValue: "\(Int(defaultWeight)) \(unit)",
            reason: "Could not parse, used default for fitness level"
        ))
        
        return WeightRange(min: defaultWeight, max: nil, unit: unit, isBodyweight: false)
    }
    
    private func sanitizeWeightRange(
        _ weightRange: WeightRange,
        exerciseName: String,
        fitnessLevel: FitnessLevel,
        sanitizations: inout [ParameterSanitization]
    ) -> WeightRange {
        
        if weightRange.isBodyweight { return weightRange }
        
        let maxWeight: Double
        let minWeight: Double = 0
        
        // Set reasonable maximums based on fitness level and units
        switch fitnessLevel {
        case .beginner:
            maxWeight = weightRange.unit == "kg" ? 50 : 110
        case .intermediate:
            maxWeight = weightRange.unit == "kg" ? 100 : 220
        case .advanced:
            maxWeight = weightRange.unit == "kg" ? 200 : 440
        }
        
        let originalMin = weightRange.min
        let originalMax = weightRange.max
        
        let sanitizedMin = max(minWeight, min(weightRange.min, maxWeight))
        let sanitizedMax = weightRange.max.map { max(sanitizedMin, min($0, maxWeight)) }
        
        if sanitizedMin != originalMin || sanitizedMax != originalMax {
            let originalValue = originalMax != nil ? "\(Int(originalMin))-\(Int(originalMax!)) \(weightRange.unit)" : "\(Int(originalMin)) \(weightRange.unit)"
            let sanitizedValue = sanitizedMax != nil ? "\(Int(sanitizedMin))-\(Int(sanitizedMax!)) \(weightRange.unit)" : "\(Int(sanitizedMin)) \(weightRange.unit)"
            
            sanitizations.append(ParameterSanitization(
                exerciseName: exerciseName,
                parameter: "weight",
                originalValue: originalValue,
                sanitizedValue: sanitizedValue,
                reason: "Adjusted to safe range for \(fitnessLevel.displayName) level"
            ))
        }
        
        return WeightRange(min: sanitizedMin, max: sanitizedMax, unit: weightRange.unit, isBodyweight: false)
    }
    
    private func parseRestPeriod(
        _ restString: String,
        exerciseName: String,
        sanitizations: inout [ParameterSanitization]
    ) -> RestPeriod {
        
        let cleanRest = restString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle minutes
        if cleanRest.contains("minute") || cleanRest.contains("min") {
            let numbers = cleanRest.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            if let minutes = numbers.first {
                return RestPeriod(seconds: TimeInterval(minutes * 60))
            }
        }
        
        // Handle seconds
        if cleanRest.contains("second") || cleanRest.contains("sec") {
            let numbers = cleanRest.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            if let seconds = numbers.first {
                return RestPeriod(seconds: TimeInterval(seconds))
            }
        }
        
        // Handle ranges like "60-90 seconds"
        if cleanRest.contains("-") {
            let parts = cleanRest.components(separatedBy: "-")
            if parts.count == 2 {
                let minNumbers = parts[0].components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                if let minValue = minNumbers.first {
                    let seconds = cleanRest.contains("minute") || cleanRest.contains("min") ? minValue * 60 : minValue
                    return RestPeriod(seconds: TimeInterval(seconds))
                }
            }
        }
        
        // Try to extract any number
        let numbers = cleanRest.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        if let number = numbers.first {
            let seconds = number > 10 ? number : number * 60 // Assume minutes if small number
            return RestPeriod(seconds: TimeInterval(seconds))
        }
        
        // Fallback to default
        let defaultRest: TimeInterval = 90 // 90 seconds
        
        sanitizations.append(ParameterSanitization(
            exerciseName: exerciseName,
            parameter: "rest",
            originalValue: restString,
            sanitizedValue: "90 seconds",
            reason: "Could not parse, used default rest period"
        ))
        
        return RestPeriod(seconds: defaultRest)
    }
    
    // MARK: - Fallback Parsing
    
    @MainActor
    private func tryFallbackParsing(
        _ response: String,
        userProfile: WorkoutGenerationRequest.UserProfile,
        warnings: inout [WorkoutParsingWarning],
        sanitizations: inout [ParameterSanitization]
    ) -> ParsedWorkout? {
        
        warnings.append(.formatVariationHandled("Attempting fallback parsing"))
        
        // Try to extract workout name from first line
        let lines = response.components(separatedBy: .newlines)
        guard let firstLine = lines.first, !firstLine.isEmpty else { return nil }
        
        let workoutName = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find exercises in the text
        var exercises: [ParsedExercise] = []
        
        for line in lines {
            if let exercise = tryParseExerciseLine(line, userProfile: userProfile, warnings: &warnings, sanitizations: &sanitizations) {
                exercises.append(exercise)
            }
        }
        
        guard !exercises.isEmpty else { return nil }
        
        return ParsedWorkout(
            name: workoutName,
            description: "Parsed from text format",
            estimatedDuration: "30-45 minutes",
            exercises: exercises,
            notes: "Generated using fallback parsing"
        )
    }
    
    @MainActor
    private func tryParseExerciseLine(
        _ line: String,
        userProfile: WorkoutGenerationRequest.UserProfile,
        warnings: inout [WorkoutParsingWarning],
        sanitizations: inout [ParameterSanitization]
    ) -> ParsedExercise? {
        
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for patterns like "Exercise Name - 3 sets x 8-12 reps"
        let exercisePatterns = [
            #"^(.+?)\s*[-–]\s*(\d+)\s*sets?\s*[x×]\s*(.+?)(?:\s*@\s*(.+?))?$"#,
            #"^(\d+)\.\s*(.+?)\s*[-–]\s*(\d+)\s*sets?\s*[x×]\s*(.+?)(?:\s*@\s*(.+?))?$"#
        ]
        
        for pattern in exercisePatterns {
            if cleanLine.range(of: pattern, options: .regularExpression) != nil {
                // Extract components and create exercise
                // This is a simplified implementation - would need more robust regex parsing
                let components = cleanLine.components(separatedBy: CharacterSet(charactersIn: "-–"))
                if components.count >= 2 {
                    let exerciseName = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                    
                    let (validatedName, isValid) = exerciseValidator.validateAndSubstituteExercise(
                        exerciseName,
                        warnings: &warnings
                    )
                    
                    return ParsedExercise(
                        name: validatedName,
                        category: "Resistance", // Default category
                        sets: 3, // Default sets
                        reps: RepRange(min: 8, max: 12), // Default rep range
                        weight: WeightRange(min: 20, max: nil, unit: userProfile.preferredUnits.weightUnit, isBodyweight: false),
                        restPeriod: RestPeriod(seconds: 90),
                        notes: nil,
                        isValidExercise: isValid
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - SwiftData Model Creation
    
    @MainActor
    private func createExerciseModel(
        from parsedExercise: ParsedExercise,
        order: Int,
        userProfile: WorkoutGenerationRequest.UserProfile
    ) throws -> Exercise {
        
        // Determine exercise type based on category
        let exerciseType: ExerciseType
        switch parsedExercise.category.lowercased() {
        case "cardio":
            exerciseType = .cardio
        case "recovery", "flexibility":
            exerciseType = .flexibility
        default:
            exerciseType = .strength
        }
        
        // Create the exercise
        let exercise = Exercise(
            name: parsedExercise.name,
            type: exerciseType,
            category: parsedExercise.category,
            notes: parsedExercise.notes,
            order: order,
            restTime: parsedExercise.restPeriod.seconds,
            isCustom: !parsedExercise.isValidExercise
        )
        
        // Add sets based on the parsed data
        for setIndex in 0..<parsedExercise.sets {
            let set = ExerciseSet(
                weight: parsedExercise.weight.isBodyweight ? 0 : parsedExercise.weight.min,
                reps: parsedExercise.reps.min,
                order: setIndex
            )
            
            // Set targets
            set.setTargets(
                weight: parsedExercise.weight.isBodyweight ? nil : parsedExercise.weight.min,
                reps: parsedExercise.reps.min
            )
            
            exercise.addSet(set)
        }
        
        return exercise
    }
}

// MARK: - Exercise Validator

/// Helper class for validating and substituting exercise names
class ExerciseValidator {
    
    /// Validate exercise name and potentially substitute with similar exercise
    @MainActor
    func validateAndSubstituteExercise(
        _ exerciseName: String,
        warnings: inout [WorkoutParsingWarning]
    ) -> (name: String, isValid: Bool) {
        
        let exerciseDatabase = ExerciseDatabase.shared
        var allExercises: [String] = []
        for category in exerciseDatabase.getCategories() {
            for type in category.types {
                allExercises.append(contentsOf: type.exercises)
            }
        }
        
        // Direct match
        if allExercises.contains(exerciseName) {
            return (exerciseName, true)
        }
        
        // Case-insensitive match
        if let match = allExercises.first(where: { $0.lowercased() == exerciseName.lowercased() }) {
            return (match, true)
        }
        
        // Fuzzy matching for common variations
        if let substitute = findBestSubstitute(for: exerciseName, allExercises: allExercises) {
            warnings.append(.exerciseSubstituted(original: exerciseName, replacement: substitute))
            return (substitute, true)
        }
        
        // No match found - return original name but mark as invalid
        return (exerciseName, false)
    }
    
    private func findBestSubstitute(for exerciseName: String, allExercises: [String]) -> String? {
        let lowercaseName = exerciseName.lowercased()
        
        // Common exercise name mappings
        let substitutions: [String: String] = [
            "bench": "Bench Press",
            "squat": "Back Squat",
            "deadlift": "Conventional Deadlift",
            "pull up": "Pull-Ups",
            "pullup": "Pull-Ups",
            "push up": "Push-Ups",
            "pushup": "Push-Ups",
            "bicep curl": "Bicep Curls",
            "tricep dip": "Tricep Dips",
            "shoulder press": "Overhead Press",
            "lat pulldown": "Lat Pulldown",
            "leg press": "Leg Press",
            "calf raise": "Standing Calf Raises",
            "plank": "Plank",
            "crunch": "Crunches"
        ]
        
        // Check direct substitutions
        if let substitute = substitutions[lowercaseName] {
            return substitute
        }
        
        // Check partial matches
        for (key, value) in substitutions {
            if lowercaseName.contains(key) || key.contains(lowercaseName) {
                return value
            }
        }
        
        // Find exercises with similar names (simple string distance)
        let candidates = allExercises.filter { exercise in
            let exerciseLower = exercise.lowercased()
            return exerciseLower.contains(lowercaseName) || 
                   lowercaseName.contains(exerciseLower) ||
                   levenshteinDistance(lowercaseName, exerciseLower) <= 3
        }
        
        return candidates.first
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dp[i][0] = i
        }
        
        for j in 0...n {
            dp[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
                }
            }
        }
        
        return dp[m][n]
    }
}
