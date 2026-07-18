//
//  WorkoutListViewModel.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData
import Combine

@MainActor
final class WorkoutListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All workouts loaded from the database
    @Published var workouts: [Workout] = []
    
    /// Currently filtered workouts based on search and filters
    @Published var filteredWorkouts: [Workout] = []
    
    /// Current search text
    @Published var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }
    
    /// Selected workout status filter
    @Published var selectedStatusFilter: WorkoutStatus? = nil {
        didSet {
            applyFilters()
        }
    }
    
    /// Whether we're currently loading data
    @Published var isLoading: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String? = nil
    
    /// Whether to show completed workouts
    @Published var showCompleted: Bool = true {
        didSet {
            applyFilters()
        }
    }
    
    /// Whether to show template workouts
    @Published var showTemplates: Bool = false {
        didSet {
            applyFilters()
        }
    }
    
    // MARK: - Private Properties
    
    private var workoutService: WorkoutService?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Configure the view model with a model context
    func configure(with modelContext: ModelContext) {
        self.workoutService = WorkoutService(modelContext: modelContext)
        loadWorkouts()
    }
    
    /// Load all workouts from the database
    func loadWorkouts() {
        guard let workoutService = workoutService else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            workouts = try workoutService.fetchWorkouts()
            applyFilters()
        } catch {
            errorMessage = "Failed to load workouts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new workout
    func createWorkout(name: String, notes: String? = nil, isTemplate: Bool = false) -> Workout? {
        guard let workoutService = workoutService else { return nil }
        
        do {
            let workout = try workoutService.createWorkout(name: name, notes: notes, isTemplate: isTemplate)
            loadWorkouts() // Refresh the list
            return workout
        } catch {
            errorMessage = "Failed to create workout: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Delete a workout
    func deleteWorkout(_ workout: Workout) {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.deleteWorkout(workout)
            loadWorkouts() // Refresh the list
        } catch {
            errorMessage = "Failed to delete workout: \(error.localizedDescription)"
        }
    }
    
    /// Duplicate a workout as a template
    func duplicateAsTemplate(_ workout: Workout, name: String) {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.duplicateAsTemplate(workout, name: name)
            loadWorkouts() // Refresh the list
        } catch {
            errorMessage = "Failed to duplicate workout: \(error.localizedDescription)"
        }
    }
    
    /// Start a workout
    func startWorkout(_ workout: Workout) {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.startWorkout(workout)
            loadWorkouts() // Refresh the list
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
        }
    }
    
    /// Complete a workout
    func completeWorkout(_ workout: Workout) {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.completeWorkout(workout)
            loadWorkouts() // Refresh the list
        } catch {
            errorMessage = "Failed to complete workout: \(error.localizedDescription)"
        }
    }
    
    /// Cancel a workout
    func cancelWorkout(_ workout: Workout) {
        guard let workoutService = workoutService else { return }
        
        do {
            try workoutService.cancelWorkout(workout)
            loadWorkouts() // Refresh the list
        } catch {
            errorMessage = "Failed to cancel workout: \(error.localizedDescription)"
        }
    }
    
    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedStatusFilter = nil
        showCompleted = true
        showTemplates = false
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Any additional reactive bindings can be set up here
    }
    
    private func applyFilters() {
        var filtered = workouts
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { workout in
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply status filter
        if let statusFilter = selectedStatusFilter {
            filtered = filtered.filter { $0.status == statusFilter }
        }
        
        // Apply completed filter
        if !showCompleted {
            filtered = filtered.filter { $0.status != .completed }
        }
        
        // Apply template filter
        filtered = filtered.filter { workout in
            showTemplates ? true : !workout.isTemplate
        }
        
        filteredWorkouts = filtered
    }
    

}

// MARK: - Computed Properties

extension WorkoutListViewModel {
    
    /// Statistics about the workouts
    var workoutStats: WorkoutStats {
        guard let workoutService = workoutService else {
            return WorkoutStats(total: 0, completed: 0, inProgress: 0, planned: 0, templates: 0)
        }
        
        do {
            return try workoutService.getWorkoutStats()
        } catch {
            return WorkoutStats(
                total: workouts.count,
                completed: workouts.filter { $0.status == .completed }.count,
                inProgress: workouts.filter { $0.status == .inProgress }.count,
                planned: workouts.filter { $0.status == .planned }.count,
                templates: workouts.filter { $0.isTemplate }.count
            )
        }
    }
    
    /// Recent workouts (last 7 days)
    var recentWorkouts: [Workout] {
        guard let workoutService = workoutService else {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return workouts.filter { $0.updatedAt >= sevenDaysAgo }
        }
        
        do {
            return try workoutService.fetchRecentWorkouts(days: 7)
        } catch {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return workouts.filter { $0.updatedAt >= sevenDaysAgo }
        }
    }
}


