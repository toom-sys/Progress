import Foundation

// MARK: - Workout Generation Request

/// Request structure for AI workout generation
struct WorkoutGenerationRequest {
    let userInput: String
    let userProfile: UserProfile
    let availableExercises: [String]
    let workoutType: WorkoutType?
    let duration: WorkoutDuration?
    let equipment: Equipment?
    
    struct UserProfile {
        let age: Int
        let fitnessGoal: FitnessGoal
        let fitnessLevel: FitnessLevel
        let preferredUnits: UnitSystem
    }
}

/// Expected workout type based on user input analysis
enum WorkoutType: String, CaseIterable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case core = "core"
    case cardio = "cardio"
    case strength = "strength"
    case hiit = "hiit"
    case recovery = "recovery"
    
    var displayName: String {
        switch self {
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .fullBody: return "Full Body"
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        case .cardio: return "Cardio"
        case .strength: return "Strength"
        case .hiit: return "HIIT"
        case .recovery: return "Recovery"
        }
    }
}

/// Expected workout duration
enum WorkoutDuration: String, CaseIterable {
    case short = "short"      // 15-30 minutes
    case medium = "medium"    // 30-60 minutes
    case long = "long"        // 60+ minutes
    
    var displayName: String {
        switch self {
        case .short: return "Short (15-30 min)"
        case .medium: return "Medium (30-60 min)"
        case .long: return "Long (60+ min)"
        }
    }
    
    var recommendedExerciseCount: ClosedRange<Int> {
        switch self {
        case .short: return 3...5
        case .medium: return 5...8
        case .long: return 8...12
        }
    }
}

/// Available equipment type
enum Equipment: String, CaseIterable {
    case bodyweight = "bodyweight"
    case dumbbells = "dumbbells"
    case barbell = "barbell"
    case gym = "gym"
    case home = "home"
    
    var displayName: String {
        switch self {
        case .bodyweight: return "Bodyweight Only"
        case .dumbbells: return "Dumbbells"
        case .barbell: return "Barbell"
        case .gym: return "Full Gym"
        case .home: return "Home Equipment"
        }
    }
}

// MARK: - Workout Prompt Builder Service

/// Service for building structured prompts for AI workout generation
@MainActor
class WorkoutPromptBuilder: ObservableObject {
    
    // MARK: - Properties
    
    private let exerciseDatabase = ExerciseDatabase.shared
    
    // MARK: - Public Methods
    
    /// Builds a structured prompt for workout generation
    func buildWorkoutPrompt(for request: WorkoutGenerationRequest) -> String {
        let userContext = buildUserContext(request.userProfile)
        let exerciseConstraints = buildExerciseConstraints(request.availableExercises)
        let workoutGuidelines = buildWorkoutGuidelines(
            userInput: request.userInput,
            workoutType: request.workoutType,
            duration: request.duration,
            equipment: request.equipment,
            fitnessLevel: request.userProfile.fitnessLevel,
            fitnessGoal: request.userProfile.fitnessGoal
        )
        let responseFormat = buildResponseFormat(request.userProfile.preferredUnits)
        
        return """
        \(userContext)
        
        \(workoutGuidelines)
        
        \(exerciseConstraints)
        
        \(responseFormat)
        """
    }
    
    /// Analyzes user input to suggest workout type and parameters
    func analyzeUserInput(_ input: String) -> (workoutType: WorkoutType?, duration: WorkoutDuration?, equipment: Equipment?) {
        let lowercased = input.lowercased()
        
        // Analyze workout type
        let workoutType = detectWorkoutType(from: lowercased)
        
        // Analyze duration
        let duration = detectDuration(from: lowercased)
        
        // Analyze equipment
        let equipment = detectEquipment(from: lowercased)
        
        return (workoutType, duration, equipment)
    }
    
    /// Gets all available exercises as a formatted list
    func getAvailableExercises() -> [String] {
        var allExercises: [String] = []
        
        for category in exerciseDatabase.getCategories() {
            for type in category.types {
                allExercises.append(contentsOf: type.exercises)
            }
        }
        
        return allExercises.sorted()
    }
    
    /// Gets exercises filtered by category
    func getExercisesForCategory(_ category: String) -> [String] {
        guard let categoryData = exerciseDatabase.getCategories().first(where: { $0.category == category }) else {
            return []
        }
        
        var exercises: [String] = []
        for type in categoryData.types {
            exercises.append(contentsOf: type.exercises)
        }
        
        return exercises.sorted()
    }
    
    // MARK: - Private Helper Methods
    
    private func buildUserContext(_ profile: WorkoutGenerationRequest.UserProfile) -> String {
        return """
        USER PROFILE:
        - Age: \(profile.age) years old
        - Fitness Goal: \(profile.fitnessGoal.displayName) (\(profile.fitnessGoal.description))
        - Fitness Level: \(profile.fitnessLevel.displayName) (\(profile.fitnessLevel.description))
        - Preferred Units: \(profile.preferredUnits.weightUnit) for weight
        """
    }
    
    private func buildWorkoutGuidelines(
        userInput: String,
        workoutType: WorkoutType?,
        duration: WorkoutDuration?,
        equipment: Equipment?,
        fitnessLevel: FitnessLevel,
        fitnessGoal: FitnessGoal
    ) -> String {
        
        var guidelines = """
        WORKOUT REQUEST: "\(userInput)"
        
        GUIDELINES:
        Create a workout that matches the user's request while considering their profile.
        """
        
        if let workoutType = workoutType {
            guidelines += "\n- Focus: \(workoutType.displayName) workout"
        }
        
        if let duration = duration {
            guidelines += "\n- Duration: \(duration.displayName)"
            guidelines += "\n- Exercise Count: \(duration.recommendedExerciseCount.lowerBound)-\(duration.recommendedExerciseCount.upperBound) exercises"
        }
        
        if let equipment = equipment {
            guidelines += "\n- Equipment: \(equipment.displayName)"
        }
        
        // Add fitness level specific guidelines
        switch fitnessLevel {
        case .beginner:
            guidelines += """
            
            BEGINNER CONSIDERATIONS:
            - Use 2-3 sets per exercise
            - Rep ranges: 8-12 for strength, 12-15 for endurance
            - Include basic compound movements
            - Avoid overly complex exercises
            - Suggest lighter weights to focus on form
            """
        case .intermediate:
            guidelines += """
            
            INTERMEDIATE CONSIDERATIONS:
            - Use 3-4 sets per exercise
            - Rep ranges: 6-12 for strength, 8-15 for hypertrophy
            - Mix compound and isolation exercises
            - Can include moderate complexity exercises
            - Progressive weight suggestions
            """
        case .advanced:
            guidelines += """
            
            ADVANCED CONSIDERATIONS:
            - Use 3-5 sets per exercise
            - Rep ranges: 1-6 for strength, 6-12 for hypertrophy, 12+ for endurance
            - Include complex compound movements
            - Advanced techniques acceptable
            - Higher intensity and volume
            """
        }
        
        // Add goal-specific guidelines
        switch fitnessGoal {
        case .weightLoss:
            guidelines += """
            
            WEIGHT LOSS FOCUS:
            - Emphasize compound movements for higher calorie burn
            - Include some cardio or HIIT elements if appropriate
            - Higher rep ranges (12-20)
            - Shorter rest periods
            """
        case .muscleGain:
            guidelines += """
            
            MUSCLE GAIN FOCUS:
            - Emphasize progressive overload
            - Rep ranges: 6-12 for hypertrophy
            - Include both compound and isolation exercises
            - Adequate rest between sets
            """
        case .strengthTraining:
            guidelines += """
            
            STRENGTH FOCUS:
            - Emphasize heavy compound movements
            - Lower rep ranges (1-6)
            - Focus on major lifts
            - Longer rest periods
            """
        case .endurance:
            guidelines += """
            
            ENDURANCE FOCUS:
            - Higher rep ranges (15+)
            - Circuit-style training if appropriate
            - Include cardio elements
            - Shorter rest periods
            """
        case .generalFitness, .maintenance:
            guidelines += """
            
            GENERAL FITNESS FOCUS:
            - Balanced approach with variety
            - Moderate rep ranges (8-15)
            - Mix of exercise types
            - Sustainable intensity
            """
        }
        
        return guidelines
    }
    
    private func buildExerciseConstraints(_ availableExercises: [String]) -> String {
        let exerciseList = availableExercises.joined(separator: ", ")
        
        return """
        EXERCISE CONSTRAINTS:
        You MUST ONLY use exercises from this exact list. Do not suggest any exercises not on this list.
        
        AVAILABLE EXERCISES:
        \(exerciseList)
        
        IMPORTANT: If an exercise you want to suggest is not in this list, find the closest alternative that IS in the list.
        """
    }
    
    private func buildResponseFormat(_ units: UnitSystem) -> String {
        let weightUnit = units.weightUnit
        
        return """
        RESPONSE FORMAT:
        Respond with ONLY a valid JSON object in this exact format. Do not include any other text, explanations, or markdown formatting.
        
        {
          "workout_name": "Descriptive workout name (maximum 32 characters)",
          "description": "Brief workout description",
          "estimated_duration": "30-45 minutes",
          "exercises": [
            {
              "name": "Exercise Name (must match available exercises exactly)",
              "category": "Resistance/Cardio/Recovery",
              "sets": 3,
              "reps": 12,
              "weight": 25,
              "rest": "90 seconds",
              "notes": "Optional form cues or tips"
            }
          ],
          "workout_notes": "Optional overall workout tips"
        }
        
        CRITICAL FORMATTING RULES:
        - Workout name MUST be 32 characters or less
        - Exercise names must match the available exercises list EXACTLY
        - ALL values must be SPECIFIC numbers, not ranges
        
        FOR RESISTANCE EXERCISES:
        - sets: exact number (e.g., 3)
        - reps: exact number (e.g., 12)
        - weight: exact number in \(weightUnit) (e.g., 25)
        - For bodyweight exercises: weight MUST be 0
        - rest: specific time (e.g., "90 seconds")
        
        FOR CARDIO EXERCISES:
        - sets: 1
        - reps: specific distance (e.g., "5 km" or "3 miles")
        - weight: specific duration in minutes (e.g., 30)
        - rest: "0 seconds" (no rest between cardio)
        
        FOR RECOVERY EXERCISES:
        - sets: 1
        - reps: specific duration (e.g., "30 seconds")
        - weight: intensity level 1-10 (e.g., 5)
        - rest: specific time (e.g., "15 seconds")
        
        EXAMPLES:
        Resistance: {"sets": 3, "reps": 10, "weight": 20, "rest": "60 seconds"}
        Bodyweight: {"sets": 3, "reps": 15, "weight": 0, "rest": "45 seconds"}
        Cardio: {"sets": 1, "reps": "3 km", "weight": 25, "rest": "0 seconds"}
        Recovery: {"sets": 1, "reps": "45 seconds", "weight": 6, "rest": "10 seconds"}
        
        VALIDATION:
        - Workout should have 3-8 exercises for most requests
        - Each exercise must exist in the available exercises list
        - NO ranges allowed - all values must be specific numbers
        """
    }
    
    // MARK: - Input Analysis Methods
    
    private func detectWorkoutType(from input: String) -> WorkoutType? {
        let typeKeywords: [WorkoutType: [String]] = [
            .upperBody: ["upper", "upper body", "arms", "chest", "back", "shoulders"],
            .lowerBody: ["lower", "lower body", "legs", "leg day", "glutes", "quads", "hamstrings"],
            .fullBody: ["full body", "full-body", "whole body", "total body"],
            .push: ["push", "push day", "chest", "shoulders", "triceps"],
            .pull: ["pull", "pull day", "back", "biceps", "lats"],
            .legs: ["legs", "leg day", "leg workout", "lower body"],
            .chest: ["chest", "chest day", "pecs", "bench"],
            .back: ["back", "back day", "lats", "rows"],
            .shoulders: ["shoulders", "shoulder day", "delts"],
            .arms: ["arms", "arm day", "biceps", "triceps"],
            .core: ["core", "abs", "abdominal", "stomach"],
            .cardio: ["cardio", "cardio workout", "running", "cycling", "hiit"],
            .strength: ["strength", "power", "heavy", "max"],
            .hiit: ["hiit", "high intensity", "interval", "circuit"],
            .recovery: ["recovery", "stretching", "mobility", "yoga", "cool down"]
        ]
        
        for (type, keywords) in typeKeywords {
            if keywords.contains(where: { input.contains($0) }) {
                return type
            }
        }
        
        return nil
    }
    
    private func detectDuration(from input: String) -> WorkoutDuration? {
        if input.contains("quick") || input.contains("short") || input.contains("15") || input.contains("20") || input.contains("30") {
            return .short
        } else if input.contains("long") || input.contains("extended") || input.contains("60") || input.contains("hour") {
            return .long
        } else {
            return .medium // Default to medium if not specified
        }
    }
    
    private func detectEquipment(from input: String) -> Equipment? {
        if input.contains("bodyweight") || input.contains("no equipment") || input.contains("home") {
            return .bodyweight
        } else if input.contains("dumbbell") || input.contains("dumbbells") {
            return .dumbbells
        } else if input.contains("barbell") || input.contains("bar") {
            return .barbell
        } else if input.contains("gym") || input.contains("machine") {
            return .gym
        }
        
        return nil // Let AI decide based on available exercises
    }
}

// MARK: - Prompt Templates

extension WorkoutPromptBuilder {
    
    /// Gets a validation prompt to test AI response consistency
    func getValidationPrompt(for scenario: ValidationScenario) -> WorkoutGenerationRequest {
        let profile = WorkoutGenerationRequest.UserProfile(
            age: scenario.age,
            fitnessGoal: scenario.fitnessGoal,
            fitnessLevel: scenario.fitnessLevel,
            preferredUnits: .metric
        )
        
        return WorkoutGenerationRequest(
            userInput: scenario.userInput,
            userProfile: profile,
            availableExercises: getAvailableExercises(),
            workoutType: scenario.expectedWorkoutType,
            duration: scenario.expectedDuration,
            equipment: scenario.expectedEquipment
        )
    }
    
    /// Predefined validation scenarios for testing
    enum ValidationScenario: CaseIterable {
        case beginnerChest
        case advancedFullBody
        case intermediateLegs
        case cardioWorkout
        case quickUpperBody
        case strengthFocused
        
        var userInput: String {
            switch self {
            case .beginnerChest: return "chest workout for beginners"
            case .advancedFullBody: return "intense full body strength workout"
            case .intermediateLegs: return "leg day workout"
            case .cardioWorkout: return "cardio and conditioning workout"
            case .quickUpperBody: return "quick 20 minute upper body workout"
            case .strengthFocused: return "heavy strength training session"
            }
        }
        
        var age: Int {
            switch self {
            case .beginnerChest: return 25
            case .advancedFullBody: return 30
            case .intermediateLegs: return 28
            case .cardioWorkout: return 35
            case .quickUpperBody: return 22
            case .strengthFocused: return 32
            }
        }
        
        var fitnessGoal: FitnessGoal {
            switch self {
            case .beginnerChest: return .muscleGain
            case .advancedFullBody: return .strengthTraining
            case .intermediateLegs: return .muscleGain
            case .cardioWorkout: return .weightLoss
            case .quickUpperBody: return .generalFitness
            case .strengthFocused: return .strengthTraining
            }
        }
        
        var fitnessLevel: FitnessLevel {
            switch self {
            case .beginnerChest: return .beginner
            case .advancedFullBody: return .advanced
            case .intermediateLegs: return .intermediate
            case .cardioWorkout: return .intermediate
            case .quickUpperBody: return .beginner
            case .strengthFocused: return .advanced
            }
        }
        
        var expectedWorkoutType: WorkoutType? {
            switch self {
            case .beginnerChest: return .chest
            case .advancedFullBody: return .fullBody
            case .intermediateLegs: return .legs
            case .cardioWorkout: return .cardio
            case .quickUpperBody: return .upperBody
            case .strengthFocused: return .strength
            }
        }
        
        var expectedDuration: WorkoutDuration? {
            switch self {
            case .beginnerChest: return .medium
            case .advancedFullBody: return .long
            case .intermediateLegs: return .medium
            case .cardioWorkout: return .medium
            case .quickUpperBody: return .short
            case .strengthFocused: return .long
            }
        }
        
        var expectedEquipment: Equipment? {
            return nil // Let AI decide based on exercises
        }
    }
}
