//
//  TrainingPlanService.swift
//  Progress
//

import Foundation
import SwiftData

/// Both next-block starting points for a plan workout, with a goal-aware recommendation.
struct BlockRegenerationOptions {
    /// New block starts at the achieved session-4 numbers.
    let keepBaselines: [ExerciseBaseline]
    /// New block starts one goal-driven step above session-4 performance.
    let levelUpBaselines: [ExerciseBaseline]
    /// True when the user hit all their session-4 targets, earning the level up.
    let recommendsLevelUp: Bool
}

/// Service layer for training plan persistence and progression state.
@MainActor
final class TrainingPlanService {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Plan Lifecycle

    /// Returns the user's currently active training plan, if any.
    func activePlan(for user: User) -> TrainingPlan? {
        let descriptor = FetchDescriptor<TrainingPlan>(
            predicate: #Predicate<TrainingPlan> { $0.isActive == true }
        )
        let activePlans = (try? modelContext.fetch(descriptor)) ?? []
        return activePlans.first { $0.user?.id == user.id }
    }

    /// Deactivates any existing active plan, then persists repeating workouts for the plan.
    @discardableResult
    func createPlan(
        for user: User,
        name: String,
        split: PlanSplitType,
        workouts: [GeneratedWorkout]
    ) throws -> TrainingPlan {
        try deactivateActivePlans(for: user)

        let plan = TrainingPlan(name: name, splitType: split)
        plan.user = user
        plan.isActive = true
        modelContext.insert(plan)

        for generatedWorkout in workouts {
            let sessionIndex = 1
            let phase = ProgressionEngine.phase(forSessionIndex: sessionIndex)
            let projected = ProgressionEngine.project(
                baseline: generatedWorkout.baselines,
                toSessionIndex: sessionIndex
            )

            let workout = Workout(name: generatedWorkout.name)
            workout.status = .planned
            workout.planSessionIndex = sessionIndex
            workout.planBlockNumber = 1
            workout.planPhase = phase
            workout.trainingPlanId = plan.id
            workout.user = user

            for (exerciseOrder, rawBaseline) in generatedWorkout.baselines.enumerated() {
                let projectedExercise = projected[exerciseOrder]
                let exercise = makeExercise(from: projectedExercise, order: exerciseOrder)
                storeBaselines(on: exercise, from: rawBaseline)
                addSets(to: exercise, from: projectedExercise)
                workout.addExercise(exercise)
                modelContext.insert(exercise)
            }

            plan.workouts.append(workout)
            modelContext.insert(workout)
        }

        try saveContext()
        return plan
    }

    /// Deactivates the user's active training plan without deleting workouts.
    func disableActivePlan(for user: User) throws {
        guard let plan = activePlan(for: user) else { return }
        plan.isActive = false
        try saveContext()
    }

    /// Advances a plan workout to its next session within the current block (1–5).
    /// Returns the new session index when advanced, or `nil` if already at session 5.
    @discardableResult
    func advanceSession(_ workout: Workout) throws -> Int? {
        guard let sessionIndex = workout.planSessionIndex, sessionIndex < 5 else { return nil }

        let newIndex = sessionIndex + 1
        try applySession(newIndex, to: workout)
        return newIndex
    }

    /// Rewinds live plan progress when the user deletes the history entry that caused the last advance
    /// (or block regeneration). Call this before deleting the historical workout.
    func rewindPlanProgressIfNeeded(afterDeleting historical: Workout) throws {
        guard let sourceId = historical.sourceWorkoutId,
              let deletedSession = historical.planSessionIndex,
              let deletedBlock = historical.planBlockNumber,
              let live = liveWorkout(id: sourceId) else { return }

        let liveSession = live.planSessionIndex ?? 1
        let liveBlock = live.planBlockNumber ?? 1

        // Completed session N → live advanced to N+1 on the same block.
        if liveBlock == deletedBlock, liveSession == deletedSession + 1 {
            try applySession(deletedSession, to: live)
            return
        }

        // Completed session 5 → regenerated into the next block at session 1.
        if deletedSession == 5,
           liveBlock == deletedBlock + 1,
           liveSession == 1 {
            live.planBlockNumber = deletedBlock
            try restoreSession(
                5,
                on: live,
                usingBaselinesFrom: historical
            )
        }
    }

    /// Builds both next-block options (keep vs level up) from the workout's best session-4 history.
    func blockRegenerationOptions(for workout: Workout, goal: FitnessGoal) -> BlockRegenerationOptions {
        let currentBlock = workout.planBlockNumber ?? 1
        let achievedS4 = bestSession4Performance(for: workout, blockNumber: currentBlock)
            ?? buildBaselines(from: workout)

        return BlockRegenerationOptions(
            keepBaselines: ProgressionEngine.nextBlockBaseline(from: achievedS4),
            levelUpBaselines: ProgressionEngine.levelUpBaseline(from: achievedS4, goal: goal),
            recommendsLevelUp: didHitSession4Targets(for: workout, blockNumber: currentBlock)
        )
    }

    /// Starts a new block for one repeating plan workout from its best session-4 history.
    /// When `levelUp` is true, baselines are bumped one goal-driven step above achieved S4.
    func regenerateBlock(_ workout: Workout, levelUp: Bool, goal: FitnessGoal) throws {
        let currentBlock = workout.planBlockNumber ?? 1
        let achievedS4 = bestSession4Performance(for: workout, blockNumber: currentBlock)
            ?? buildBaselines(from: workout)
        let newBaselines = levelUp
            ? ProgressionEngine.levelUpBaseline(from: achievedS4, goal: goal)
            : ProgressionEngine.nextBlockBaseline(from: achievedS4)

        workout.planBlockNumber = currentBlock + 1
        workout.planSessionIndex = 1
        workout.planPhase = .baseline

        let projected = ProgressionEngine.project(baseline: newBaselines, toSessionIndex: 1)
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }

        for index in sortedExercises.indices {
            let exercise = sortedExercises[index]
            storeBaselines(on: exercise, from: newBaselines[index])
            updateSets(for: exercise, from: projected[index])
        }

        try saveContext()
    }

    // MARK: - Private Methods

    /// Sets session index/phase and re-projects set targets from baselines.
    private func applySession(
        _ sessionIndex: Int,
        to workout: Workout
    ) throws {
        workout.planSessionIndex = sessionIndex
        workout.planPhase = ProgressionEngine.phase(forSessionIndex: sessionIndex)

        let baselines = buildBaselines(from: workout)
        let projected = ProgressionEngine.project(baseline: baselines, toSessionIndex: sessionIndex)
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }

        for (exercise, projectedBaseline) in zip(sortedExercises, projected) {
            updateSets(for: exercise, from: projectedBaseline)
        }

        try saveContext()
    }

    /// Restores session targets after undoing a block regeneration, using baselines
    /// captured on the historical clone before regen overwrote the live workout.
    private func restoreSession(
        _ sessionIndex: Int,
        on live: Workout,
        usingBaselinesFrom historical: Workout
    ) throws {
        live.planSessionIndex = sessionIndex
        live.planPhase = ProgressionEngine.phase(forSessionIndex: sessionIndex)

        let sortedLive = live.exercises.sorted { $0.order < $1.order }
        let baselines: [ExerciseBaseline] = sortedLive.map { liveExercise in
            if let historicalExercise = matchingExercise(liveExercise, in: historical.exercises) {
                let baseline = baselineFromStoredFields(historicalExercise)
                storeBaselines(on: liveExercise, from: baseline)
                return baseline
            }
            return baselineFromStoredFields(liveExercise)
        }

        let projected = ProgressionEngine.project(baseline: baselines, toSessionIndex: sessionIndex)
        for (exercise, projectedBaseline) in zip(sortedLive, projected) {
            updateSets(for: exercise, from: projectedBaseline)
        }

        try saveContext()
    }

    private func liveWorkout(id: UUID) -> Workout? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func deactivateActivePlans(for user: User) throws {
        let descriptor = FetchDescriptor<TrainingPlan>(
            predicate: #Predicate<TrainingPlan> { $0.isActive == true }
        )
        let activePlans = try modelContext.fetch(descriptor)
        for plan in activePlans where plan.user?.id == user.id {
            plan.isActive = false
        }
    }

    private func buildBaselines(from workout: Workout) -> [ExerciseBaseline] {
        workout.exercises
            .sorted { $0.order < $1.order }
            .map { baselineFromStoredFields($0) }
    }

    private func baselineFromStoredFields(_ exercise: Exercise) -> ExerciseBaseline {
        if let durationSec = exercise.baselineDurationSec, durationSec > 0 {
            return ExerciseBaseline(
                exerciseName: exercise.name,
                predefinedExerciseId: exercise.predefinedExerciseId,
                mode: .timed,
                weightKg: 0,
                reps: 0,
                durationSec: durationSec,
                setCount: exercise.baselineSetCount ?? exercise.sets.count
            )
        }

        let weightKg = exercise.baselineWeightKg ?? 0
        if weightKg == 0 {
            return ExerciseBaseline(
                exerciseName: exercise.name,
                predefinedExerciseId: exercise.predefinedExerciseId,
                mode: .bodyweight,
                weightKg: 0,
                reps: exercise.baselineReps ?? 8,
                setCount: exercise.baselineSetCount ?? exercise.sets.count
            )
        }

        return ExerciseBaseline(
            exerciseName: exercise.name,
            predefinedExerciseId: exercise.predefinedExerciseId,
            mode: .weighted,
            weightKg: weightKg,
            reps: exercise.baselineReps ?? 8,
            setCount: exercise.baselineSetCount ?? exercise.sets.count
        )
    }

    private func session4Candidates(for workout: Workout, blockNumber: Int) -> [Workout] {
        let sourceId = workout.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { historical in
                historical.sourceWorkoutId == sourceId
                    && historical.planSessionIndex == 4
                    && historical.planBlockNumber == blockNumber
            }
        )
        return ((try? modelContext.fetch(descriptor)) ?? []).filter { !$0.isDeleted && $0.status == .completed }
    }

    /// True when the most recent completed session-4 clone hit every set's targets.
    private func didHitSession4Targets(for workout: Workout, blockNumber: Int) -> Bool {
        let candidates = session4Candidates(for: workout, blockNumber: blockNumber)
        guard let latest = candidates.max(by: {
            ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast)
        }) else { return false }

        // Historical clones only include exercises with at least one completed set,
        // so a shorter exercise list means something was skipped entirely.
        guard latest.exercises.count >= workout.exercises.count else { return false }

        for exercise in latest.exercises {
            for set in exercise.sets {
                guard set.isCompleted else { return false }
                if let targetDuration = set.targetDuration, set.duration < targetDuration {
                    return false
                }
                if let targetReps = set.targetReps, set.reps < targetReps {
                    return false
                }
                if let targetWeight = set.targetWeight, set.weight < targetWeight {
                    return false
                }
            }
        }

        return true
    }

    private func bestSession4Performance(for workout: Workout, blockNumber: Int) -> [ExerciseBaseline]? {
        let candidates = session4Candidates(for: workout, blockNumber: blockNumber)
        guard !candidates.isEmpty else { return nil }

        let liveExercises = workout.exercises.sorted { $0.order < $1.order }
        return liveExercises.map { liveExercise in
            var best: ExerciseBaseline?

            for historicalWorkout in candidates {
                guard let historicalExercise = matchingExercise(liveExercise, in: historicalWorkout.exercises) else {
                    continue
                }

                let candidate = performanceBaseline(from: historicalExercise, template: liveExercise)
                if let existing = best {
                    best = preferredBaseline(candidate, over: existing)
                } else {
                    best = candidate
                }
            }

            return best ?? baselineFromStoredFields(liveExercise)
        }
    }

    private func matchingExercise(_ liveExercise: Exercise, in exercises: [Exercise]) -> Exercise? {
        exercises.first { $0.order == liveExercise.order && $0.name == liveExercise.name }
            ?? exercises.first { $0.order == liveExercise.order }
            ?? exercises.first { $0.name == liveExercise.name }
    }

    private func performanceBaseline(from exercise: Exercise, template: Exercise) -> ExerciseBaseline {
        let completedSets = exercise.sets.filter(\.isCompleted).sorted { $0.order < $1.order }
        let setCount = template.baselineSetCount ?? max(completedSets.count, exercise.sets.count)

        if let durationSec = template.baselineDurationSec, durationSec > 0 {
            let bestDuration = completedSets.map(\.duration).max() ?? durationSec
            return ExerciseBaseline(
                exerciseName: template.name,
                predefinedExerciseId: template.predefinedExerciseId,
                mode: .timed,
                weightKg: 0,
                reps: 0,
                durationSec: bestDuration,
                setCount: setCount
            )
        }

        let templateWeight = template.baselineWeightKg ?? 0
        if templateWeight == 0 {
            let bestReps = completedSets.map(\.reps).max() ?? (template.baselineReps ?? 8)
            return ExerciseBaseline(
                exerciseName: template.name,
                predefinedExerciseId: template.predefinedExerciseId,
                mode: .bodyweight,
                weightKg: 0,
                reps: bestReps,
                setCount: setCount
            )
        }

        let bestSet = completedSets.max { lhs, rhs in
            if lhs.weight != rhs.weight { return lhs.weight < rhs.weight }
            return lhs.reps < rhs.reps
        }

        return ExerciseBaseline(
            exerciseName: template.name,
            predefinedExerciseId: template.predefinedExerciseId,
            mode: .weighted,
            weightKg: bestSet?.weight ?? templateWeight,
            reps: bestSet?.reps ?? (template.baselineReps ?? 8),
            setCount: setCount
        )
    }

    private func preferredBaseline(_ candidate: ExerciseBaseline, over existing: ExerciseBaseline) -> ExerciseBaseline {
        switch candidate.mode {
        case .timed:
            return candidate.durationSec >= existing.durationSec ? candidate : existing
        case .bodyweight:
            return candidate.reps >= existing.reps ? candidate : existing
        case .weighted:
            if candidate.weightKg != existing.weightKg {
                return candidate.weightKg > existing.weightKg ? candidate : existing
            }
            return candidate.reps >= existing.reps ? candidate : existing
        }
    }

    private func storeBaselines(on exercise: Exercise, from rawBaseline: ExerciseBaseline) {
        exercise.baselineWeightKg = rawBaseline.mode == .weighted ? rawBaseline.weightKg : nil
        exercise.baselineReps = rawBaseline.mode == .timed ? nil : rawBaseline.reps
        exercise.baselineDurationSec = rawBaseline.mode == .timed ? rawBaseline.durationSec : nil
        exercise.baselineSetCount = rawBaseline.setCount
    }

    private func makeExercise(from baseline: ExerciseBaseline, order: Int) -> Exercise {
        let exercise: Exercise

        if baseline.mode == .timed {
            if let id = baseline.predefinedExerciseId,
               let predefined = ExerciseDatabase.findExerciseStatic(named: id) {
                exercise = Exercise(predefinedExercise: predefined, order: order)
            } else {
                exercise = Exercise(
                    name: baseline.exerciseName,
                    type: .recovery,
                    order: order,
                    isCustom: false,
                    predefinedExerciseId: baseline.predefinedExerciseId
                )
            }
            exercise.type = .recovery
        } else if let id = baseline.predefinedExerciseId,
                  let predefined = ExerciseDatabase.findExerciseStatic(named: id) {
            exercise = Exercise(predefinedExercise: predefined, order: order)
        } else {
            exercise = Exercise(
                name: baseline.exerciseName,
                type: .resistance,
                order: order,
                isCustom: false,
                predefinedExerciseId: baseline.predefinedExerciseId
            )
        }

        return exercise
    }

    private func addSets(to exercise: Exercise, from projected: ExerciseBaseline) {
        for setOrder in 0..<projected.setCount {
            let set: ExerciseSet
            if projected.mode == .timed {
                set = ExerciseSet(duration: projected.durationSec, order: setOrder)
                set.targetDuration = projected.durationSec
            } else {
                set = ExerciseSet(
                    weight: projected.weightKg,
                    reps: projected.reps,
                    order: setOrder
                )
                set.targetWeight = projected.weightKg
                set.targetReps = projected.reps
            }
            set.exercise = exercise
            exercise.sets.append(set)
            modelContext.insert(set)
        }
    }

    private func updateSets(for exercise: Exercise, from projected: ExerciseBaseline) {
        let sortedSets = exercise.sets.sorted { $0.order < $1.order }

        if sortedSets.count < projected.setCount {
            for setOrder in sortedSets.count..<projected.setCount {
                let set: ExerciseSet
                if projected.mode == .timed {
                    set = ExerciseSet(duration: projected.durationSec, order: setOrder)
                    set.targetDuration = projected.durationSec
                } else {
                    set = ExerciseSet(
                        weight: projected.weightKg,
                        reps: projected.reps,
                        order: setOrder
                    )
                    set.targetWeight = projected.weightKg
                    set.targetReps = projected.reps
                }
                set.exercise = exercise
                exercise.sets.append(set)
                modelContext.insert(set)
            }
        } else if sortedSets.count > projected.setCount {
            for set in sortedSets.dropFirst(projected.setCount) {
                exercise.sets.removeAll { $0.id == set.id }
                modelContext.delete(set)
            }
            for (order, set) in exercise.sets.sorted(by: { $0.order < $1.order }).enumerated() {
                set.order = order
            }
        }

        for set in exercise.sets.sorted(by: { $0.order < $1.order }) {
            if projected.mode == .timed {
                set.duration = projected.durationSec
                set.targetDuration = projected.durationSec
                set.weight = 0
                set.reps = 0
                set.targetWeight = nil
                set.targetReps = nil
            } else {
                set.weight = projected.weightKg
                set.reps = projected.reps
                set.targetWeight = projected.weightKg
                set.targetReps = projected.reps
                set.duration = 0
            }
        }
    }

    private func saveContext() throws {
        try modelContext.save()
    }
}
