//
//  TrainingPlanGenerator.swift
//  Progress
//

import Foundation

/// A named repeating workout with exercise baselines for plan creation.
struct GeneratedWorkout: Equatable {
    let name: String
    let baselines: [ExerciseBaseline]
}

/// Rule-based generator for a user's initial training plan baseline.
struct TrainingPlanGenerator {

    // MARK: - Exercise Pools

    private enum BeginnerWeightKg {
        static let benchPress = 30.0
        static let squat = 40.0
        static let barbellRow = 25.0
        static let overheadPress = 20.0
        static let deadlift = 50.0
        static let defaultWeight = 20.0

        static func forExercise(named name: String) -> Double {
            switch name {
            case "Bench Press": return benchPress
            case "Back Squat": return squat
            case "Barbell Row": return barbellRow
            case "Overhead Press": return overheadPress
            case "Conventional Deadlift": return deadlift
            case "Pull-Ups", "Chin-Ups", "Push-Ups", "Incline Push-Ups": return 0
            default: return defaultWeight
            }
        }
    }

    private static let defaultSets = 4
    private static let defaultReps = 8
    private static let defaultTimedDurationSec = 30.0
    private static let weightIncrement = 2.5

    private static let timedExerciseNames: Set<String> = [
        "Plank",
        "Side Plank",
        "Weighted Plank",
        "Hollow Body Hold",
        "Ab Rollout (Wheel)",
        "Stability Ball Rollout"
    ]

    private static let bodyweightExerciseNames: Set<String> = [
        "Push-Ups", "Incline Push-Ups", "Pull-Ups", "Chin-Ups", "Wide-Grip Pull-Ups",
        "Crunches", "Sit-Ups", "Lunges", "Walking Lunges", "Glute Bridge",
        "Mountain Climbers", "V-Ups", "Flutter Kicks", "Bicycle Crunch",
        "Lying Leg Raise", "Russian Twists", "Bench Dips", "Burpees",
        "Jump Squats", "High Knees", "Nordic Curl"
    ]

    private static let upperBodyPool = [
        "Bench Press", "Overhead Press", "Dumbbell Bench Press", "Dumbbell Shoulder Press",
        "Barbell Row", "Dumbbell Row", "Pull-Ups", "Chin-Ups", "Push-Ups", "Incline Push-Ups",
        "Lateral Raises", "Face Pulls", "Bicep Curls", "Tricep Dips"
    ]

    private static let lowerBodyPool = [
        "Back Squat", "Front Squat", "Goblet Squat", "Conventional Deadlift",
        "Romanian Deadlift", "Lunges", "Bulgarian Split Squat", "Step-Ups",
        "Glute Bridge", "Hip Thrust", "Leg Press", "Leg Extension", "Leg Curl Machine"
    ]

    private static let corePool = [
        "Plank", "Side Plank", "Crunches", "Sit-Ups", "Lying Leg Raise",
        "Bicycle Crunch", "Hollow Body Hold", "Russian Twists", "V-Ups",
        "Mountain Climbers", "Flutter Kicks"
    ]

    private static let pushPool = [
        "Bench Press", "Overhead Press", "Dumbbell Bench Press", "Dumbbell Shoulder Press",
        "Push-Ups", "Incline Push-Ups", "Lateral Raises", "Tricep Dips", "Close Grip Bench Press"
    ]

    private static let pullPool = [
        "Pull-Ups", "Chin-Ups", "Barbell Row", "Dumbbell Row", "Lat Pulldown",
        "Seated Cable Row", "Face Pulls", "Pendlay Row"
    ]

    private static let legsPool = [
        "Back Squat", "Front Squat", "Conventional Deadlift", "Romanian Deadlift",
        "Goblet Squat", "Lunges", "Leg Press", "Leg Extension", "Leg Curl Machine",
        "Glute Bridge", "Hip Thrust"
    ]

    private static let fullBodyPool = [
        "Bench Press", "Back Squat", "Barbell Row", "Overhead Press", "Pull-Ups",
        "Goblet Squat", "Push-Ups", "Lunges", "Conventional Deadlift", "Romanian Deadlift",
        "Glute Bridge", "Dumbbell Row"
    ]

    private struct WorkoutTemplate {
        let name: String
        let pool: [String]
        let isCoreWorkout: Bool
    }

    // MARK: - Public

    /// Builds a plan from questionnaire answers.
    static func generate(from questionnaire: PlanQuestionnaire) -> (split: PlanSplitType, workouts: [GeneratedWorkout]) {
        let count = questionnaire.clampedWorkoutCount
        let (split, templates) = workoutTemplates(for: count, questionnaire: questionnaire)

        let workouts = templates.compactMap { template -> GeneratedWorkout? in
            let exerciseCount = exercisesPerWorkout(for: questionnaire.experience)
            let names = selectExercises(
                from: template.pool,
                count: exerciseCount,
                environment: questionnaire.environment,
                focus: questionnaire.focus,
                isCoreWorkout: template.isCoreWorkout
            )
            guard !names.isEmpty else { return nil }
            let baselines = names.map { makeBaseline(named: $0, level: questionnaire.experience) }
            return GeneratedWorkout(name: template.name, baselines: baselines)
        }

        if workouts.count == count {
            return (split, workouts)
        }

        // Fallback: single full-body workout from whatever is available
        let fallbackNames = selectExercises(
            from: fullBodyPool,
            count: exercisesPerWorkout(for: questionnaire.experience),
            environment: questionnaire.environment,
            focus: questionnaire.focus,
            isCoreWorkout: false
        )
        let baselines = fallbackNames.map { makeBaseline(named: $0, level: questionnaire.experience) }
        return (.fullBody, [GeneratedWorkout(name: "Full Body", baselines: baselines)])
    }

    /// Thin wrapper for existing callers — builds a default questionnaire from profile fields.
    static func generate(for user: User) -> (split: PlanSplitType, workouts: [GeneratedWorkout]) {
        let questionnaire = PlanQuestionnaire(
            goal: user.fitnessGoal,
            experience: user.fitnessLevel,
            environment: .gym,
            workoutCount: defaultWorkoutCount(for: user.fitnessLevel),
            focus: defaultFocus(for: user.fitnessGoal)
        )

        #if DEBUG
        logSampleQuestionnaires()
        #endif

        return generate(from: questionnaire)
    }

    /// Returns the progression mode for a predefined exercise name.
    static func progressionMode(for exerciseName: String) -> ExerciseProgressionMode {
        if timedExerciseNames.contains(exerciseName) {
            return .timed
        }
        if bodyweightExerciseNames.contains(exerciseName) {
            return .bodyweight
        }
        if BeginnerWeightKg.forExercise(named: exerciseName) == 0 {
            return .bodyweight
        }
        return .weighted
    }

    /// Merges user-edited baselines back into the generated workout structure.
    static func applyEditedBaselines(
        _ baselines: [ExerciseBaseline],
        to workouts: [GeneratedWorkout]
    ) -> [GeneratedWorkout] {
        let baselineByName = Dictionary(uniqueKeysWithValues: baselines.map { ($0.exerciseName, $0) })
        return workouts.map { workout in
            GeneratedWorkout(
                name: workout.name,
                baselines: workout.baselines.map { baselineByName[$0.exerciseName] ?? $0 }
            )
        }
    }

    // MARK: - Template Selection

    private static func workoutTemplates(
        for count: Int,
        questionnaire: PlanQuestionnaire
    ) -> (PlanSplitType, [WorkoutTemplate]) {
        switch count {
        case 1:
            return (.fullBody, [WorkoutTemplate(name: "Full Body", pool: fullBodyPool, isCoreWorkout: false)])

        case 2:
            if prefersFullBodySplit(for: questionnaire.goal) {
                let available = availableExerciseNames(from: fullBodyPool, environment: questionnaire.environment)
                let midpoint = max(1, available.count / 2)
                let poolA = Array(available.prefix(midpoint))
                let poolB = Array(available.dropFirst(midpoint))
                return (.fullBody, [
                    WorkoutTemplate(name: "Full Body A", pool: poolA.isEmpty ? fullBodyPool : poolA, isCoreWorkout: false),
                    WorkoutTemplate(name: "Full Body B", pool: poolB.isEmpty ? fullBodyPool : poolB, isCoreWorkout: false)
                ])
            }
            return (.upperLower, [
                WorkoutTemplate(name: "Upper", pool: upperBodyPool, isCoreWorkout: false),
                WorkoutTemplate(name: "Lower", pool: lowerBodyPool, isCoreWorkout: false)
            ])

        case 3:
            if prefersUpperLowerAbs(for: questionnaire) {
                return (.upperLower, [
                    WorkoutTemplate(name: "Upper", pool: upperBodyPool, isCoreWorkout: false),
                    WorkoutTemplate(name: "Lower", pool: lowerBodyPool, isCoreWorkout: false),
                    WorkoutTemplate(name: "Abs", pool: corePool, isCoreWorkout: true)
                ])
            }
            return (.pushPullLegs, [
                WorkoutTemplate(name: "Push", pool: pushPool, isCoreWorkout: false),
                WorkoutTemplate(name: "Pull", pool: pullPool, isCoreWorkout: false),
                WorkoutTemplate(name: "Legs", pool: legsPool, isCoreWorkout: false)
            ])

        default:
            return (.pushPullLegs, [
                WorkoutTemplate(name: "Push", pool: pushPool, isCoreWorkout: false),
                WorkoutTemplate(name: "Pull", pool: pullPool, isCoreWorkout: false),
                WorkoutTemplate(name: "Legs", pool: legsPool, isCoreWorkout: false),
                WorkoutTemplate(name: "Core", pool: corePool, isCoreWorkout: true)
            ])
        }
    }

    private static func prefersFullBodySplit(for goal: FitnessGoal) -> Bool {
        switch goal {
        case .weightLoss, .endurance, .generalFitness:
            return true
        case .muscleGain, .strengthTraining, .maintenance:
            return false
        }
    }

    private static func prefersUpperLowerAbs(for questionnaire: PlanQuestionnaire) -> Bool {
        if questionnaire.focus.contains(.core) {
            return true
        }
        switch questionnaire.goal {
        case .generalFitness, .weightLoss, .maintenance:
            return true
        case .muscleGain, .strengthTraining, .endurance:
            return false
        }
    }

    // MARK: - Exercise Selection

    private static func selectExercises(
        from pool: [String],
        count: Int,
        environment: WorkoutEnvironment,
        focus: [FocusArea],
        isCoreWorkout: Bool
    ) -> [String] {
        var candidates = pool.filter { name in
            guard isAvailable(name, environment: environment) else { return false }
            if isCoreWorkout {
                return isAllowedInCoreWorkout(name)
            }
            return true
        }

        candidates.sort { lhs, rhs in
            let lhsScore = focusScore(for: lhs, focus: focus)
            let rhsScore = focusScore(for: rhs, focus: focus)
            if lhsScore != rhsScore { return lhsScore > rhsScore }
            return lhs < rhs
        }

        var selected: [String] = []
        for name in candidates where selected.count < count {
            if !selected.contains(name) {
                selected.append(name)
            }
        }
        return selected
    }

    private static func isAvailable(_ name: String, environment: WorkoutEnvironment) -> Bool {
        guard exerciseExistsInDatabase(name) else { return false }
        return ExerciseEnvironmentService.isUsable(
            ExerciseEnvironmentService.environment(for: name),
            in: environment
        )
    }

    private static func availableExerciseNames(from pool: [String], environment: WorkoutEnvironment) -> [String] {
        pool.filter { isAvailable($0, environment: environment) }
    }

    /// Core/abs workouts allow rep-based bodyweight or timed holds only — never weighted progression.
    private static func isAllowedInCoreWorkout(_ name: String) -> Bool {
        let mode = progressionMode(for: name)
        return mode == .bodyweight || mode == .timed
    }

    private static func focusScore(for exerciseName: String, focus: [FocusArea]) -> Int {
        guard let predefined = ExerciseDatabase.findExerciseStatic(named: exerciseName) else { return 0 }
        let area = focusArea(for: predefined)
        if focus.contains(area) { return 10 }
        if focus.contains(.fullBody) && area == .fullBody { return 8 }
        return 0
    }

    private static func focusArea(for exercise: ExerciseDatabase.PredefinedExercise) -> FocusArea {
        switch exercise.type {
        case "Legs":
            return .lowerBody
        case "Core":
            return .core
        case "Full Body / Compound":
            return .fullBody
        default:
            return .upperBody
        }
    }

    // MARK: - Defaults & Baselines

    private static func defaultWorkoutCount(for level: FitnessLevel) -> Int {
        switch level {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }

    static func defaultFocus(for goal: FitnessGoal) -> [FocusArea] {
        switch goal {
        case .muscleGain, .strengthTraining:
            return [.upperBody, .lowerBody]
        case .weightLoss, .endurance:
            return [.fullBody]
        case .generalFitness, .maintenance:
            return [.fullBody, .core]
        }
    }

    private static func exercisesPerWorkout(for experience: FitnessLevel) -> Int {
        switch experience {
        case .beginner: return 4
        case .intermediate: return 5
        case .advanced: return 5
        }
    }

    private static func exerciseExistsInDatabase(_ name: String) -> Bool {
        ExerciseDatabase.findExerciseStatic(named: name) != nil
    }

    private static func levelMultiplier(for level: FitnessLevel) -> Double {
        switch level {
        case .beginner: return 1.0
        case .intermediate: return 1.5
        case .advanced: return 2.0
        }
    }

    private static func makeBaseline(named name: String, level: FitnessLevel) -> ExerciseBaseline {
        let mode = progressionMode(for: name)

        if mode == .timed {
            return ExerciseBaseline(
                exerciseName: name,
                predefinedExerciseId: name,
                mode: .timed,
                weightKg: 0,
                reps: 0,
                durationSec: defaultTimedDurationSec,
                setCount: defaultSets
            )
        }

        let beginnerWeight = BeginnerWeightKg.forExercise(named: name)
        let weightKg: Double

        if mode == .bodyweight {
            weightKg = 0
        } else {
            let scaled = beginnerWeight * levelMultiplier(for: level)
            weightKg = ProgressionEngine.roundToIncrement(scaled, increment: weightIncrement)
        }

        return ExerciseBaseline(
            exerciseName: name,
            predefinedExerciseId: name,
            mode: mode,
            weightKg: weightKg,
            reps: defaultReps,
            setCount: defaultSets
        )
    }

    // MARK: - Debug

    #if DEBUG
    private static func logSampleQuestionnaires() {
        let home3 = PlanQuestionnaire(
            goal: .generalFitness,
            experience: .beginner,
            environment: .home,
            workoutCount: 3,
            focus: [.upperBody, .lowerBody, .core]
        )
        let gym2 = PlanQuestionnaire(
            goal: .muscleGain,
            experience: .intermediate,
            environment: .gym,
            workoutCount: 2,
            focus: [.upperBody, .lowerBody]
        )

        for (label, questionnaire) in [("Home/3 workouts", home3), ("Gym/2 workouts", gym2)] {
            let result = generate(from: questionnaire)
            print("📋 \(label) → \(result.workouts.count) workouts (\(result.split.displayName))")
            for workout in result.workouts {
                let summary = workout.baselines.map { baseline in
                    "\(baseline.exerciseName) [\(baseline.mode.rawValue)]"
                }.joined(separator: ", ")
                print("   \(workout.name): \(summary)")
            }
            if let absWorkout = result.workouts.first(where: { $0.name == "Abs" || $0.name == "Core" }) {
                let invalid = absWorkout.baselines.filter { $0.mode == .weighted }
                if invalid.isEmpty {
                    print("   ✅ \(absWorkout.name) workout: rep/timed only")
                } else {
                    print("   ⚠️ \(absWorkout.name) workout contains weighted: \(invalid.map(\.exerciseName))")
                }
            }
        }
    }
    #endif
}
