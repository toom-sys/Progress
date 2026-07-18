//
//  WorkoutDetailViewModel.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData
import Combine

@MainActor
final class WorkoutDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current workout being viewed/edited
    @Published var workout: Workout
    
    /// Whether the workout is being edited
    @Published var isEditing: Bool = false
    
    /// Whether we're currently saving changes
    @Published var isSaving: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String? = nil
    
    /// Whether to show the add exercise sheet
    @Published var showingAddExercise: Bool = false
    
    /// Whether to show the rest timer
    @Published var showingRestTimer: Bool = false
    
    /// Current exercise for rest timer
    @Published var currentRestExercise: Exercise? = nil
    
    /// Whether the workout has unsaved changes
    @Published var hasUnsavedChanges: Bool = false
    
    /// Current workout timer (for live tracking)
    @Published var workoutTimer: TimeInterval = 0
    
    /// Whether the workout timer is running
    @Published var isTimerRunning: Bool = false
    
    // MARK: - Private Properties
    
    private var workoutService: WorkoutService?
    private var cancellables = Set<AnyCancellable>()
    nonisolated(unsafe) private var timer: Timer?
    private var workoutStartTime: Date?
    
    // MARK: - Initialization
    
    init(workout: Workout) {
        self.workout = workout
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Configure the view model with a model context
    func configure(with modelContext: ModelContext) {
        self.workoutService = WorkoutService(modelContext: modelContext)
    }
    
    /// Start editing the workout
    func startEditing() {
        isEditing = true
    }
    
    /// Cancel editing and revert changes
    func cancelEditing() {
        isEditing = false
        hasUnsavedChanges = false
        // In a real implementation, you might want to revert changes here
    }
    
    /// Save changes to the workout
    func saveChanges() {
        guard let workoutService = workoutService else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try workoutService.saveWorkout(workout)
            hasUnsavedChanges = false
            isEditing = false
        } catch {
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    /// Start the workout
    func startWorkout() {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.startWorkout(workout)
            workoutStartTime = Date()
            startTimer()
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
        }
    }
    
    /// Complete the workout
    func completeWorkout() {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.completeWorkout(workout)
            stopTimer()
        } catch {
            errorMessage = "Failed to complete workout: \(error.localizedDescription)"
        }
    }
    
    /// Cancel the workout
    func cancelWorkout() {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.cancelWorkout(workout)
            stopTimer()
        } catch {
            errorMessage = "Failed to cancel workout: \(error.localizedDescription)"
        }
    }
    
    /// Add a new exercise to the workout
    func addExercise(name: String, type: ExerciseType, category: String? = nil, notes: String? = nil) {
        // Check exercise limit
        guard workout.exercises.count < 16 else {
            errorMessage = "You've reached the limit of 16 exercises per workout. Please remove an existing exercise to add another."
            return
        }
        
        let exercise = Exercise(
            name: name,
            type: type,
            category: category,
            notes: notes,
            order: workout.exercises.count,
            restTime: type.defaultRestTime
        )
        
        workout.addExercise(exercise)
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to add exercise: \(error.localizedDescription)"
            }
        }
    }
    
    /// Remove an exercise from the workout
    func removeExercise(_ exercise: Exercise) {
        workout.removeExercise(exercise)
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to remove exercise: \(error.localizedDescription)"
            }
        }
    }
    
    /// Reorder exercises in the workout
    func moveExercise(from source: IndexSet, to destination: Int) {
        workout.exercises.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, exercise) in workout.exercises.enumerated() {
            exercise.order = index
        }
        
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to reorder exercises: \(error.localizedDescription)"
            }
        }
    }
    
    /// Add a set to an exercise
    func addSet(to exercise: Exercise) {
        let newSet = exercise.createDefaultSet()
        exercise.addSet(newSet)
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to add set: \(error.localizedDescription)"
            }
        }
    }
    
    /// Remove a set from an exercise
    func removeSet(_ set: ExerciseSet, from exercise: Exercise) {
        exercise.removeSet(set)
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to remove set: \(error.localizedDescription)"
            }
        }
    }
    
    /// Complete a set and start rest timer if needed
    func completeSet(_ set: ExerciseSet) {
        set.complete()
        
        // Start rest timer for the exercise
        if let exercise = set.exercise, exercise.restTime > 0 {
            currentRestExercise = exercise
            showingRestTimer = true
        }
        
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to save set completion: \(error.localizedDescription)"
            }
        }
    }
    
    /// Reset a set to incomplete
    func resetSet(_ set: ExerciseSet) {
        set.reset()
        hasUnsavedChanges = true
        
        if let workoutService = workoutService {
            do {
                try workoutService.saveWorkout(workout)
            } catch {
                errorMessage = "Failed to reset set: \(error.localizedDescription)"
            }
        }
    }
    
    /// Duplicate the workout as a template
    func duplicateAsTemplate(name: String) -> Workout? {
        guard let workoutService = workoutService else { return nil }
        
        do {
            return try workoutService.duplicateAsTemplate(workout, name: name)
        } catch {
            errorMessage = "Failed to duplicate workout: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Timer Methods
    
    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let startTime = workoutStartTime else { return }
        workoutTimer = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor workout changes to detect unsaved changes
        // This is a simplified version - in a real app you might want more sophisticated change tracking
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Computed Properties

extension WorkoutDetailViewModel {
    
    /// Formatted workout timer string
    var formattedWorkoutTimer: String {
        let hours = Int(workoutTimer) / 3600
        let minutes = (Int(workoutTimer) % 3600) / 60
        let seconds = Int(workoutTimer) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Exercises that are not hidden (visible for progression tracking)
    var visibleExercises: [Exercise] {
        let visible = workout.exercises.filter { !$0.isHidden }
        let hidden = workout.exercises.filter { $0.isHidden }
        
        // Only log occasionally to avoid spam
        if !hidden.isEmpty && shouldLogFiltering {
            print("🎯 WorkoutDetailViewModel filtering:")
            print("   Workout: '\(workout.name)'")
            print("   Total exercises: \(workout.exercises.count)")
            print("   Visible exercises: \(visible.count) - \(visible.map { $0.name })")
            print("   Hidden exercises: \(hidden.count) - \(hidden.map { $0.name })")
        }
        
        return visible
    }
    
    /// Only log filtering occasionally to avoid spam
    private var shouldLogFiltering: Bool {
        return Int.random(in: 1...30) == 1
    }
    
    /// Total completed sets across visible exercises only
    var totalCompletedSets: Int {
        visibleExercises.reduce(0) { $0 + $1.completedSetsCount }
    }
    
    /// Total sets across visible exercises only
    var totalSets: Int {
        visibleExercises.reduce(0) { $0 + $1.sets.count }
    }
    
    /// Workout completion percentage (based on visible exercises only)
    var completionPercentage: Double {
        guard totalSets > 0 else { return 0 }
        return Double(totalCompletedSets) / Double(totalSets)
    }
    
    /// Whether the workout can be started
    var canStartWorkout: Bool {
        workout.status == .planned && !workout.exercises.isEmpty
    }
    
    /// Whether the workout can be completed
    var canCompleteWorkout: Bool {
        workout.status == .inProgress
    }
    
    /// Exercises grouped by type for better organization
    var exercisesByType: [ExerciseType: [Exercise]] {
        Dictionary(grouping: workout.exercises) { $0.type }
    }
}
