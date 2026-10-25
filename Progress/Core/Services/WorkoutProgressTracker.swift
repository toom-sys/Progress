//
//  WorkoutProgressTracker.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData
import Foundation

/// Service that tracks weekly workout progress and trained body groups
@MainActor
class WorkoutProgressTracker: ObservableObject {

    // MARK: - Published Properties

    @Published var completedWorkoutsThisWeek: Int = 0
    @Published var weeklyWorkoutGoal: Int = 4
    @Published var trainedBodyGroups: Set<MuscleGroup> = []

    /// Today's step count from Apple Health.
    @Published var currentSteps: Int = 0
    /// Yesterday's steps from midnight through the same clock time as now.
    @Published var yesterdaysStepsAtSameTime: Int = 0
    @Published var todayCumulativeSeries: [StepCumulativePoint] = []
    @Published var yesterdayCumulativeSeries: [StepCumulativePoint] = []

    @Published var dailyStepGoal: Int = 10000
    @Published var isHealthKitAvailable: Bool = false

    // MARK: - Private Properties

    private var modelContext: ModelContext?
    private let calendar = Calendar.current
    private let healthKitService = HealthKitService.shared

    // MARK: - Initialization

    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
        self.isHealthKitAvailable = healthKitService.isHealthDataAvailable
        Task { await refresh() }
    }

    // MARK: - Public Methods

    func refresh() async {
        loadUserGoals()
        await calculateWeeklyProgress()
        await calculateTrainedBodyGroups()
        await fetchDailySteps()
    }

    /// Begins observing Apple Health step updates while the steps UI is visible.
    func startObservingSteps() {
        guard healthKitService.isHealthDataAvailable else { return }
        Task {
            _ = await healthKitService.requestAuthorizationIfNeeded()
            healthKitService.startObservingStepUpdates { [weak self] in
                guard let self else { return }
                self.applyStepComparison(from: self.healthKitService)
            }
        }
    }

    func stopObservingSteps() {
        healthKitService.stopObservingStepUpdates()
    }

    func loadUserGoals() {
        guard let context = modelContext else {
            weeklyWorkoutGoal = 4
            dailyStepGoal = 10000
            return
        }
        let descriptor = FetchDescriptor<User>()
        if let user = try? context.fetch(descriptor).first {
            weeklyWorkoutGoal = user.weeklyWorkoutGoal
            dailyStepGoal = user.dailyStepGoal
        } else {
            weeklyWorkoutGoal = 4
            dailyStepGoal = 10000
        }
    }

    func calculateWeeklyProgress() async {
        guard let context = modelContext else {
            completedWorkoutsThisWeek = 0
            return
        }
        let now = Date()
        guard let weekStart = getStartOfWeek(for: now),
              let weekEnd = getEndOfWeek(for: now) else {
            completedWorkoutsThisWeek = 0
            return
        }

        let descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        do {
            let allWorkouts = try context.fetch(descriptor)
            completedWorkoutsThisWeek = allWorkouts.filter { workout in
                guard !workout.isDeleted,
                      workout.status == .completed,
                      let completedAt = workout.completedAt else { return false }
                return completedAt >= weekStart && completedAt <= weekEnd
            }.count
        } catch {
            completedWorkoutsThisWeek = 0
        }
    }

    func calculateTrainedBodyGroups() async {
        guard let context = modelContext else {
            trainedBodyGroups = []
            return
        }
        let now = Date()
        guard let weekStart = getStartOfWeek(for: now),
              let weekEnd = getEndOfWeek(for: now) else {
            trainedBodyGroups = []
            return
        }

        let descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
        do {
            let allWorkouts = try context.fetch(descriptor)
            let completedThisWeek = allWorkouts.filter { workout in
                guard !workout.isDeleted,
                      workout.status == .completed,
                      let completedAt = workout.completedAt else { return false }
                return completedAt >= weekStart && completedAt <= weekEnd
            }

            var muscleGroups: Set<MuscleGroup> = []
            for workout in completedThisWeek {
                for exercise in workout.exercises {
                    if let primaryMuscle = exercise.primaryMuscleGroup {
                        muscleGroups.insert(primaryMuscle)
                    }
                    for (secondaryMuscle, _) in exercise.secondaryMuscleGroupsDecoded {
                        muscleGroups.insert(secondaryMuscle)
                    }
                }
            }
            trainedBodyGroups = muscleGroups
        } catch {
            trainedBodyGroups = []
        }
    }

    func fetchDailySteps() async {
        isHealthKitAvailable = healthKitService.isHealthDataAvailable
        await healthKitService.fetchStepComparison()
        applyStepComparison(from: healthKitService)
    }

    private func applyStepComparison(from service: HealthKitService) {
        currentSteps = service.todaysSteps
        yesterdaysStepsAtSameTime = service.yesterdaysStepsAtSameTime
        todayCumulativeSeries = service.todayCumulativeSeries
        yesterdayCumulativeSeries = service.yesterdayCumulativeSeries
    }

    /// Today minus yesterday-at-same-time. Positive means ahead of yesterday.
    var stepsDeltaVsYesterday: Int {
        currentSteps - yesterdaysStepsAtSameTime
    }

    // MARK: - Private Helpers

    private func getStartOfWeek(for date: Date) -> Date? {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2
        guard let weekStart = calendar.date(from: components) else { return nil }
        return calendar.startOfDay(for: weekStart)
    }

    private func getEndOfWeek(for date: Date) -> Date? {
        guard let weekStart = getStartOfWeek(for: date),
              let nextMonday = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return nil }
        return calendar.date(byAdding: .second, value: -1, to: nextMonday)
    }

    // MARK: - Convenience

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task { await refresh() }
    }

    var weeklyProgressPercentage: Double {
        guard weeklyWorkoutGoal > 0 else { return 0 }
        return min(Double(completedWorkoutsThisWeek) / Double(weeklyWorkoutGoal), 1.0)
    }

    var dailyStepProgressPercentage: Double {
        guard dailyStepGoal > 0 else { return 0 }
        return min(Double(currentSteps) / Double(dailyStepGoal), 1.0)
    }

    var hasMetWeeklyGoal: Bool { completedWorkoutsThisWeek >= weeklyWorkoutGoal }
    var hasMetDailyStepGoal: Bool { currentSteps >= dailyStepGoal }
}
