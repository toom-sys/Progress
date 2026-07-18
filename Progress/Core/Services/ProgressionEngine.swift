//
//  ProgressionEngine.swift
//  Progress
//

import Foundation

/// How an exercise progresses through a training-plan block.
enum ExerciseProgressionMode: String, Codable {
    case weighted
    case bodyweight
    case timed
}

/// User-confirmed starting point for one exercise in a training plan block.
/// All weights are stored in kilograms regardless of display units.
struct ExerciseBaseline: Equatable {
    let exerciseName: String
    let predefinedExerciseId: String?
    var mode: ExerciseProgressionMode
    var weightKg: Double
    var reps: Int
    var durationSec: Double
    var setCount: Int

    init(
        exerciseName: String,
        predefinedExerciseId: String?,
        mode: ExerciseProgressionMode = .weighted,
        weightKg: Double,
        reps: Int,
        durationSec: Double = 0,
        setCount: Int
    ) {
        self.exerciseName = exerciseName
        self.predefinedExerciseId = predefinedExerciseId
        self.mode = mode
        self.weightKg = weightKg
        self.reps = reps
        self.durationSec = durationSec
        self.setCount = setCount
    }
}

/// Pure projection logic for the 5-session progressive block.
enum ProgressionEngine {

    // MARK: - Block Projection

    /// Projects every exercise in `baseline` to the targets for session `index` (1–5).
    static func project(
        baseline: [ExerciseBaseline],
        toSessionIndex index: Int,
        increment: Double = 2.5
    ) -> [ExerciseBaseline] {
        precondition((1...5).contains(index), "Session index must be between 1 and 5")
        return baseline.map { project($0, toSessionIndex: index, increment: increment) }
    }

    /// Rounds `weight` to the nearest multiple of `increment` (e.g. 2.5 kg plates).
    static func roundToIncrement(_ weight: Double, increment: Double) -> Double {
        guard increment > 0 else { return weight }
        return (weight / increment).rounded() * increment
    }

    /// Maps a 1-based session index to its plan phase.
    static func phase(forSessionIndex index: Int) -> PlanWorkoutPhase {
        switch index {
        case 1: return .baseline
        case 5: return .deload
        default: return .progression
        }
    }

    /// Seeds the next block's S1 baseline from achieved S4 performance.
    static func nextBlockBaseline(from achievedS4: [ExerciseBaseline]) -> [ExerciseBaseline] {
        achievedS4.map { exercise in
            ExerciseBaseline(
                exerciseName: exercise.exerciseName,
                predefinedExerciseId: exercise.predefinedExerciseId,
                mode: exercise.mode,
                weightKg: exercise.weightKg,
                reps: exercise.reps,
                durationSec: exercise.durationSec,
                setCount: exercise.setCount
            )
        }
    }

    /// Seeds the next block's S1 baseline one goal-driven step above achieved S4 performance.
    /// Bumps are deliberately capped at one increment per block to keep progression sustainable.
    static func levelUpBaseline(
        from achievedS4: [ExerciseBaseline],
        goal: FitnessGoal,
        increment: Double = 2.5
    ) -> [ExerciseBaseline] {
        achievedS4.map { levelUp($0, goal: goal, increment: increment) }
    }

    /// Formats a projected baseline for plan UI (e.g. "4 sets × 30s").
    static func formattedTargetLine(for baseline: ExerciseBaseline, units: UnitSystem) -> String {
        switch baseline.mode {
        case .timed:
            return "\(baseline.setCount) sets × \(Int(baseline.durationSec))s"
        case .bodyweight:
            return "\(baseline.setCount) sets × \(baseline.reps) reps"
        case .weighted:
            return "\(baseline.setCount) sets × \(baseline.reps) × \(units.formatWeightWithUnit(baseline.weightKg))"
        }
    }

    /// Formats live workout exercise targets from its sets.
    static func formattedTargetLine(for exercise: Exercise, units: UnitSystem) -> String {
        let sets = exercise.sets.sorted { $0.order < $1.order }
        guard let first = sets.first else { return "No sets" }

        let setCount = sets.count
        if exercise.baselineDurationSec != nil, first.duration > 0 {
            return "\(setCount) sets × \(Int(first.duration))s"
        }
        if first.weight == 0 {
            return "\(setCount) sets × \(first.reps) reps"
        }
        return "\(setCount) sets × \(units.formatWeightWithUnit(first.weight)) × \(first.reps)"
    }

    // MARK: - Private

    private static func levelUp(
        _ baseline: ExerciseBaseline,
        goal: FitnessGoal,
        increment: Double
    ) -> ExerciseBaseline {
        var result = baseline

        switch baseline.mode {
        case .timed:
            let conservative = goal == .weightLoss || goal == .maintenance
            result.durationSec = baseline.durationSec + (conservative ? 5 : 10)

        case .bodyweight:
            result.reps = baseline.reps + 1

        case .weighted:
            switch goal {
            case .strengthTraining:
                result.weightKg = roundToIncrement(baseline.weightKg + increment, increment: increment)
            case .muscleGain:
                // Double progression: build reps to 12, then add weight and reset the rep range.
                if baseline.reps >= 12 {
                    result.weightKg = roundToIncrement(baseline.weightKg + increment, increment: increment)
                    result.reps = 8
                } else {
                    result.reps = baseline.reps + 1
                }
            case .endurance, .generalFitness, .weightLoss, .maintenance:
                result.reps = baseline.reps + 1
            }
        }

        return result
    }

    private static func project(
        _ baseline: ExerciseBaseline,
        toSessionIndex index: Int,
        increment: Double
    ) -> ExerciseBaseline {
        switch baseline.mode {
        case .timed:
            return projectTimed(baseline, toSessionIndex: index)
        case .bodyweight:
            return projectBodyweight(baseline, toSessionIndex: index)
        case .weighted:
            return projectWeighted(baseline, toSessionIndex: index, increment: increment)
        }
    }

    private static func projectTimed(
        _ baseline: ExerciseBaseline,
        toSessionIndex index: Int
    ) -> ExerciseBaseline {
        var result = baseline
        let baseDuration = baseline.durationSec
        switch index {
        case 1:
            break
        case 2:
            result.durationSec = baseDuration + 5
        case 3:
            result.durationSec = baseDuration + 10
        case 4:
            result.durationSec = baseDuration + 15
        case 5:
            result.durationSec = (baseDuration * 0.65).rounded()
            result.setCount = 3
        default:
            break
        }
        return result
    }

    private static func projectBodyweight(
        _ baseline: ExerciseBaseline,
        toSessionIndex index: Int
    ) -> ExerciseBaseline {
        var result = baseline
        switch index {
        case 1:
            break
        case 2:
            result.reps = baseline.reps + 1
        case 3:
            result.reps = baseline.reps + 2
        case 4:
            result.reps = baseline.reps + 3
        case 5:
            result.reps = 6
            result.setCount = 3
        default:
            break
        }
        return result
    }

    private static func projectWeighted(
        _ baseline: ExerciseBaseline,
        toSessionIndex index: Int,
        increment: Double
    ) -> ExerciseBaseline {
        var result = baseline
        switch index {
        case 1:
            break
        case 2:
            result.reps = baseline.reps + 1
        case 3:
            result.weightKg = roundToIncrement(baseline.weightKg + increment, increment: increment)
            result.reps = baseline.reps
        case 4:
            let s3Weight = roundToIncrement(baseline.weightKg + increment, increment: increment)
            result.weightKg = s3Weight
            result.reps = baseline.reps + 1
        case 5:
            result.weightKg = roundToIncrement(baseline.weightKg * 0.65, increment: increment)
            result.reps = 6
            result.setCount = 3
        default:
            break
        }
        return result
    }
}
