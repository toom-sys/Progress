//
//  AITrainingPlanGenerator.swift
//  Progress
//

import Foundation

// MARK: - Plan Generation Context

/// Everything collected during onboarding that should shape the generated plan.
struct PlanGenerationContext {
    let questionnaire: PlanQuestionnaire
    let age: Int
    let biologicalSex: BiologicalSex
    let heightCm: Double
    let weightKg: Double
    let activityLevel: ActivityLevel
    let gymChallenge: GymChallenge?
    let motivationBarrier: MotivationBarrier?
    let preferredUnits: UnitSystem

    /// Builds a context from a persisted user profile plus plan-setup answers.
    static func from(
        user: User,
        questionnaire: PlanQuestionnaire,
        gymChallenge: GymChallenge?,
        motivationBarrier: MotivationBarrier?
    ) -> PlanGenerationContext {
        PlanGenerationContext(
            questionnaire: questionnaire,
            age: user.age,
            biologicalSex: user.biologicalSex,
            heightCm: user.heightCm,
            weightKg: user.weightKg,
            activityLevel: user.activityLevel,
            gymChallenge: gymChallenge,
            motivationBarrier: motivationBarrier,
            preferredUnits: user.preferredUnits
        )
    }
}

// MARK: - Errors

enum AIPlanGenerationError: LocalizedError {
    case invalidResponse
    case wrongWorkoutCount
    case insufficientExercises

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The AI response could not be parsed"
        case .wrongWorkoutCount: return "The AI returned the wrong number of workouts"
        case .insufficientExercises: return "The AI plan did not include enough valid exercises"
        }
    }
}

// MARK: - AI Training Plan Generator

/// Generates a personalized training plan via OpenAI using the full onboarding
/// profile. Falls back to `TrainingPlanGenerator` at the call site when the
/// request or parsing fails.
@MainActor
final class AITrainingPlanGenerator {

    private let openAIService = OpenAIService()

    private static let minExercisesPerWorkout = 3
    private static let maxExercisesPerWorkout = 7

    // MARK: - Public

    func generatePlan(
        from context: PlanGenerationContext
    ) async throws -> (split: PlanSplitType, workouts: [GeneratedWorkout]) {
        let prompt = buildPrompt(for: context)

        #if DEBUG
        print("🤖 AITrainingPlanGenerator: requesting plan (\(context.questionnaire.clampedWorkoutCount) workouts, \(context.questionnaire.environment.displayName))")
        #endif

        let response = try await openAIService.sendPrompt(prompt, configuration: .planGeneration)
        let result = try parse(response, context: context)

        #if DEBUG
        print("🤖 AITrainingPlanGenerator: parsed \(result.workouts.count) workouts (\(result.split.displayName))")
        for workout in result.workouts {
            let summary = workout.baselines
                .map { "\($0.exerciseName) \($0.setCount)x\($0.mode == .timed ? "\(Int($0.durationSec))s" : "\($0.reps)")" }
                .joined(separator: ", ")
            print("   \(workout.name): \(summary)")
        }
        #endif

        return result
    }

    // MARK: - Prompt

    private func buildPrompt(for context: PlanGenerationContext) -> String {
        let questionnaire = context.questionnaire

        return """
        You are an expert personal trainer designing a personalized training plan baseline for a new client.

        \(buildClientProfile(context))

        \(buildPlanRequirements(context))

        \(buildTargetGuidelines(context))

        AVAILABLE EXERCISES — format: Name [progression type] (muscle group):
        \(buildExerciseCatalog(environment: questionnaire.environment))

        \(buildResponseFormat(workoutCount: questionnaire.clampedWorkoutCount))
        """
    }

    private func buildClientProfile(_ context: PlanGenerationContext) -> String {
        var lines = [
            "CLIENT PROFILE:",
            "- Age: \(context.age) years old",
            "- Sex: \(context.biologicalSex.displayName)",
            "- Height: \(Int(context.heightCm.rounded())) cm",
            "- Body weight: \(Int(context.weightKg.rounded())) kg",
            "- Daily activity level: \(context.activityLevel.displayName) (\(context.activityLevel.description))",
            "- Fitness goal: \(context.questionnaire.goal.displayName) (\(context.questionnaire.goal.description))",
            "- Experience: \(context.questionnaire.experience.displayName) (\(context.questionnaire.experience.description))"
        ]

        if let challenge = context.gymChallenge {
            lines.append("- Biggest gym challenge: \(challenge.displayName) (\(challenge.description))")
        }
        if let barrier = context.motivationBarrier {
            lines.append("- Main barrier to training: \(barrier.displayName) (\(barrier.description))")
        }

        return lines.joined(separator: "\n")
    }

    private func buildPlanRequirements(_ context: PlanGenerationContext) -> String {
        let questionnaire = context.questionnaire
        let count = questionnaire.clampedWorkoutCount
        let focusList = questionnaire.focus.map(\.displayName).joined(separator: ", ")

        return """
        PLAN REQUIREMENTS:
        - Create EXACTLY \(count) repeating workout\(count == 1 ? "" : "s") the client cycles through every week.
        - Training environment: \(questionnaire.environment.displayName). Only use exercises from the AVAILABLE EXERCISES list.
        - Requested focus areas: \(focusList.isEmpty ? "balanced" : focusList).
        - Choose the split that best suits this client: "full_body", "upper_lower", or "push_pull_legs".
        - The \(count) workout\(count == 1 ? "" : "s") together must cover the focus areas without overworking any single muscle group across the week.
        - Give each workout a short, specific name (maximum 24 characters) reflecting its focus.
        - Each workout must have \(exerciseCountGuidance(for: questionnaire.experience)) exercises.
        - Order exercises within each workout: compound movements first, isolation and core work last.
        - Tailor exercise selection to the client's challenge and barrier (e.g. plateaus → varied stimulus; lack of confidence → simple, easy-to-learn movements).
        """
    }

    private func buildTargetGuidelines(_ context: PlanGenerationContext) -> String {
        """
        STARTING TARGETS:
        These are session-1 baselines. The app automatically increases the targets every session for 4 sessions and then deloads, so all starting targets must be conservative — something the client can complete for every set with good form.
        - [weighted] exercises: choose sets (3-5), reps, and a starting "weight_kg" estimated from the client's sex, body weight, age, and experience. Use realistic loads and round to 2.5 kg. Set "duration_sec" to 0.
        - [bodyweight] exercises: "weight_kg" must be 0; choose achievable reps. Set "duration_sec" to 0.
        - [timed] exercises: "reps" must be 0 and "weight_kg" must be 0; choose a hold "duration_sec" between 20 and 60.
        - Rep guidance for the client's goal: \(repGuidance(for: context.questionnaire.goal)).
        """
    }

    private func exerciseCountGuidance(for level: FitnessLevel) -> String {
        switch level {
        case .beginner: return "4 to 5"
        case .intermediate: return "5 to 6"
        case .advanced: return "5 to 6"
        }
    }

    private func repGuidance(for goal: FitnessGoal) -> String {
        switch goal {
        case .strengthTraining:
            return "4-6 reps on heavy compounds, 6-10 on accessories"
        case .muscleGain:
            return "6-12 reps for hypertrophy"
        case .weightLoss, .endurance:
            return "12-15 reps with lighter loads"
        case .generalFitness, .maintenance:
            return "8-12 reps at a sustainable intensity"
        }
    }

    private func buildExerciseCatalog(environment: WorkoutEnvironment) -> String {
        Self.availableExercises(in: environment)
            .map { exercise in
                let mode = TrainingPlanGenerator.progressionMode(for: exercise.name)
                return "- \(exercise.name) [\(mode.rawValue)] (\(exercise.type))"
            }
            .joined(separator: "\n")
    }

    private func buildResponseFormat(workoutCount: Int) -> String {
        """
        RESPONSE FORMAT:
        Respond with ONLY a valid JSON object in this exact format. No other text, explanations, or markdown formatting.

        {
          "split_type": "full_body" | "upper_lower" | "push_pull_legs",
          "workouts": [
            {
              "name": "Workout name",
              "exercises": [
                { "name": "Bench Press", "sets": 4, "reps": 8, "weight_kg": 30, "duration_sec": 0 }
              ]
            }
          ]
        }

        VALIDATION:
        - "workouts" must contain exactly \(workoutCount) item\(workoutCount == 1 ? "" : "s").
        - Every exercise "name" must match the AVAILABLE EXERCISES list exactly.
        - All values must be specific numbers, never ranges.
        """
    }

    /// Resistance exercises usable in the selected environment. Plans only
    /// support weighted/bodyweight/timed progression, so cardio and recovery
    /// entries are excluded.
    private static func availableExercises(
        in environment: WorkoutEnvironment
    ) -> [ExerciseDatabase.PredefinedExercise] {
        ExerciseEnvironmentService.exercises(in: environment)
            .filter { $0.category == "Resistance" }
    }

    // MARK: - Parsing

    private struct AIPlanResponse: Decodable {
        let splitType: String?
        let workouts: [AIPlanWorkout]
    }

    private struct AIPlanWorkout: Decodable {
        let name: String?
        let exercises: [AIPlanExercise]
    }

    private struct AIPlanExercise: Decodable {
        let name: String
        let sets: Int?
        let reps: Int?
        let weightKg: Double?
        let durationSec: Double?
    }

    private func parse(
        _ rawResponse: String,
        context: PlanGenerationContext
    ) throws -> (split: PlanSplitType, workouts: [GeneratedWorkout]) {
        let cleaned = cleanResponse(rawResponse)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIPlanGenerationError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let response = try? decoder.decode(AIPlanResponse.self, from: data) else {
            throw AIPlanGenerationError.invalidResponse
        }

        let expectedCount = context.questionnaire.clampedWorkoutCount
        guard response.workouts.count >= expectedCount else {
            throw AIPlanGenerationError.wrongWorkoutCount
        }

        let workouts: [GeneratedWorkout] = try response.workouts.prefix(expectedCount).enumerated().map { index, aiWorkout in
            let baselines = sanitizedBaselines(from: aiWorkout.exercises, context: context)
            guard baselines.count >= Self.minExercisesPerWorkout else {
                throw AIPlanGenerationError.insufficientExercises
            }

            let trimmedName = (aiWorkout.name ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmedName.isEmpty ? "Workout \(index + 1)" : String(trimmedName.prefix(32))
            return GeneratedWorkout(name: name, baselines: baselines)
        }

        let split = parseSplit(response.splitType, workoutCount: expectedCount)
        return (split, workouts)
    }

    /// Validates each AI exercise against the database and environment,
    /// coerces targets to the exercise's progression mode, and clamps values
    /// to sane session-1 ranges.
    private func sanitizedBaselines(
        from exercises: [AIPlanExercise],
        context: PlanGenerationContext
    ) -> [ExerciseBaseline] {
        let environment = context.questionnaire.environment
        var seenNames = Set<String>()
        var baselines: [ExerciseBaseline] = []

        for exercise in exercises {
            guard baselines.count < Self.maxExercisesPerWorkout else { break }

            guard let predefined = ExerciseDatabase.findExerciseStatic(named: exercise.name),
                  predefined.category == "Resistance",
                  ExerciseEnvironmentService.isUsable(
                    ExerciseEnvironmentService.environment(for: predefined.name),
                    in: environment
                  ),
                  seenNames.insert(predefined.name).inserted else {
                #if DEBUG
                print("⚠️ AITrainingPlanGenerator: dropped exercise \"\(exercise.name)\"")
                #endif
                continue
            }

            let setCount = clamp(exercise.sets ?? 4, min: 2, max: 5)
            let mode = TrainingPlanGenerator.progressionMode(for: predefined.name)

            switch mode {
            case .timed:
                let duration = clamp(exercise.durationSec ?? 30, min: 10, max: 180)
                baselines.append(ExerciseBaseline(
                    exerciseName: predefined.name,
                    predefinedExerciseId: predefined.name,
                    mode: .timed,
                    weightKg: 0,
                    reps: 0,
                    durationSec: duration,
                    setCount: setCount
                ))
            case .bodyweight:
                let reps = clamp(exercise.reps ?? 8, min: 3, max: 30)
                baselines.append(ExerciseBaseline(
                    exerciseName: predefined.name,
                    predefinedExerciseId: predefined.name,
                    mode: .bodyweight,
                    weightKg: 0,
                    reps: reps,
                    setCount: setCount
                ))
            case .weighted:
                let reps = clamp(exercise.reps ?? 8, min: 3, max: 20)
                let rawWeight = (exercise.weightKg ?? 0) > 0 ? exercise.weightKg! : 20
                let weightKg = ProgressionEngine.roundToIncrement(
                    clamp(rawWeight, min: 2.5, max: 300),
                    increment: 2.5
                )
                baselines.append(ExerciseBaseline(
                    exerciseName: predefined.name,
                    predefinedExerciseId: predefined.name,
                    mode: .weighted,
                    weightKg: weightKg,
                    reps: reps,
                    setCount: setCount
                ))
            }
        }

        return baselines
    }

    private func parseSplit(_ rawSplit: String?, workoutCount: Int) -> PlanSplitType {
        if let raw = rawSplit?.lowercased() {
            if let direct = PlanSplitType(rawValue: raw) {
                return direct
            }
            if raw.contains("push") || raw.contains("ppl") { return .pushPullLegs }
            if raw.contains("upper") || raw.contains("lower") { return .upperLower }
            if raw.contains("full") { return .fullBody }
        }

        switch workoutCount {
        case 1: return .fullBody
        case 2: return .upperLower
        default: return .pushPullLegs
        }
    }

    private func cleanResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
        min(max(value, minValue), maxValue)
    }
}
