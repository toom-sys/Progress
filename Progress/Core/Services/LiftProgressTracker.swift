//
//  LiftProgressTracker.swift
//  Progress
//

import Foundation
import SwiftData

/// One completed session's top-set performance for a tracked lift.
struct LiftSessionRecord: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let metricKind: ExerciseProgressionMode
    /// Weight (kg), reps, or duration (seconds) depending on `metricKind`.
    let primaryMetric: Double
    /// Epley estimated 1RM in kg; only set for weighted lifts.
    let estimatedOneRMKg: Double?
    let isDeload: Bool
    let planSessionIndex: Int?
    let planBlockNumber: Int?
    let workoutName: String?

    var sessionLabel: String {
        if let block = planBlockNumber, let session = planSessionIndex {
            return "B\(block) · S\(session)"
        }
        return workoutName ?? "Session"
    }
}

/// Reads per-exercise lift history from completed workout clones.
@MainActor
enum LiftProgressTracker {

    // MARK: - Public API

    static func history(forExerciseNamed name: String, in context: ModelContext) -> [LiftSessionRecord] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .forward)]
        )
        let workouts = ((try? context.fetch(descriptor)) ?? [])
            .filter { !$0.isDeleted && $0.status == .completed && $0.completedAt != nil }

        var records: [LiftSessionRecord] = []

        for workout in workouts {
            guard let exercise = matchingExercise(named: trimmed, in: workout.exercises) else { continue }
            guard let record = sessionRecord(from: exercise, workout: workout) else { continue }
            records.append(record)
        }

        return records.sorted { $0.date < $1.date }
    }

    /// Unique exercise names from the user's active plan workouts, in stable order.
    static func planExerciseNames(for user: User, in context: ModelContext) -> [String] {
        guard let plan = activePlan(for: user, in: context) else { return [] }

        var seen = Set<String>()
        var names: [String] = []

        for workout in plan.workouts.sorted(by: { $0.name < $1.name }) {
            guard workout.sourceWorkoutId == nil else { continue }
            for exercise in workout.exercises.sorted(by: { $0.order < $1.order }) {
                let trimmed = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                let key = trimmed.lowercased()
                if seen.insert(key).inserted {
                    names.append(trimmed)
                }
            }
        }

        return names
    }

    static func metricKind(for exercise: Exercise) -> ExerciseProgressionMode {
        if let durationSec = exercise.baselineDurationSec, durationSec > 0 { return .timed }
        if let weightKg = exercise.baselineWeightKg, weightKg > 0 { return .weighted }

        let completedSets = exercise.sets.filter(\.isCompleted)
        if completedSets.contains(where: { $0.weight > 0 }) { return .weighted }
        if completedSets.contains(where: { $0.duration > 0 }),
           exercise.type == .recovery || exercise.type == .cardio || exercise.type == .flexibility {
            return .timed
        }
        return .bodyweight
    }

    /// Epley formula: 1RM = weight × (1 + reps / 30)
    static func estimatedOneRM(weightKg: Double, reps: Int) -> Double {
        guard weightKg > 0, reps > 0 else { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }

    static func formattedPrimaryMetric(
        _ record: LiftSessionRecord,
        units: UnitSystem
    ) -> String {
        switch record.metricKind {
        case .weighted:
            return units.formatWeightWithUnit(record.primaryMetric)
        case .bodyweight:
            return "\(Int(record.primaryMetric.rounded())) reps"
        case .timed:
            return "\(Int(record.primaryMetric.rounded()))s"
        }
    }

    static func formattedOneRM(_ kg: Double, units: UnitSystem) -> String {
        units.formatWeightWithUnit(kg)
    }

    static func chartAxisLabel(for kind: ExerciseProgressionMode, units: UnitSystem) -> String {
        switch kind {
        case .weighted: return "Top set (\(units.weightUnit))"
        case .bodyweight: return "Top set (reps)"
        case .timed: return "Top set (sec)"
        }
    }

    // MARK: - Private

    private static func activePlan(for user: User, in context: ModelContext) -> TrainingPlan? {
        let descriptor = FetchDescriptor<TrainingPlan>(
            predicate: #Predicate<TrainingPlan> { $0.isActive == true }
        )
        return ((try? context.fetch(descriptor)) ?? []).first { $0.user?.id == user.id }
    }

    private static func matchingExercise(named name: String, in exercises: [Exercise]) -> Exercise? {
        exercises.first {
            $0.name.compare(name, options: .caseInsensitive) == .orderedSame
        }
    }

    private static func sessionRecord(from exercise: Exercise, workout: Workout) -> LiftSessionRecord? {
        let completedSets = exercise.sets.filter(\.isCompleted)
        guard !completedSets.isEmpty, let date = workout.completedAt else { return nil }

        let kind = metricKind(for: exercise)

        switch kind {
        case .weighted:
            guard let topSet = completedSets.max(by: { lhs, rhs in
                if lhs.weight != rhs.weight { return lhs.weight < rhs.weight }
                return lhs.reps < rhs.reps
            }), topSet.weight > 0 else { return nil }

            return LiftSessionRecord(
                id: UUID(),
                date: date,
                metricKind: .weighted,
                primaryMetric: topSet.weight,
                estimatedOneRMKg: estimatedOneRM(weightKg: topSet.weight, reps: topSet.reps),
                isDeload: workout.planPhase == .deload,
                planSessionIndex: workout.planSessionIndex,
                planBlockNumber: workout.planBlockNumber,
                workoutName: workout.name
            )

        case .bodyweight:
            guard let bestReps = completedSets.map(\.reps).max(), bestReps > 0 else { return nil }

            return LiftSessionRecord(
                id: UUID(),
                date: date,
                metricKind: .bodyweight,
                primaryMetric: Double(bestReps),
                estimatedOneRMKg: nil,
                isDeload: workout.planPhase == .deload,
                planSessionIndex: workout.planSessionIndex,
                planBlockNumber: workout.planBlockNumber,
                workoutName: workout.name
            )

        case .timed:
            guard let bestDuration = completedSets.map(\.duration).max(), bestDuration > 0 else { return nil }

            return LiftSessionRecord(
                id: UUID(),
                date: date,
                metricKind: .timed,
                primaryMetric: bestDuration,
                estimatedOneRMKg: nil,
                isDeload: workout.planPhase == .deload,
                planSessionIndex: workout.planSessionIndex,
                planBlockNumber: workout.planBlockNumber,
                workoutName: workout.name
            )
        }
    }
}
