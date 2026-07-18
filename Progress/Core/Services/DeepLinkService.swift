//
//  DeepLinkService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Workout Import Errors

/// Errors that can occur during workout import
enum WorkoutImportError: LocalizedError {
    case exerciseNotFound(String)
    case invalidExerciseType(String)
    case duplicateWorkout
    case invalidWorkoutData
    
    var errorDescription: String? {
        switch self {
        case .exerciseNotFound(let exerciseName):
            return "Exercise '\(exerciseName)' is not available in your app. The shared workout contains exercises that aren't in the default library."
        case .invalidExerciseType(let type):
            return "Invalid exercise type '\(type)' found in shared workout."
        case .duplicateWorkout:
            return "This workout has already been imported."
        case .invalidWorkoutData:
            return "The shared workout data is corrupted or invalid."
        }
    }
}

/// Service for handling deep links and navigation from notifications
/// Step 5C: Deep linking support for timer notifications
/// Step 7C: Workout import from shared URLs
@MainActor
final class DeepLinkService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DeepLinkService()
    
    // MARK: - Published Properties
    
    /// The workout to navigate to from deep link
    @Published var workoutToOpen: Workout?
    
    /// Whether we should navigate to workouts tab
    @Published var shouldNavigateToWorkouts = false
    
    /// Whether a deep link is currently in progress
    @Published var isDeepLinkInProgress = false
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    /// Workout ID buffered from a notification tap that arrived before the model context was ready (cold start)
    private var pendingWorkoutId: UUID?
    
    // MARK: - Initialization
    
    private init() {
        print("🔗 DeepLinkService initialized")
    }
    
    // MARK: - Configuration
    
    /// Configure the service with SwiftData model context
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        print("🔗 DeepLinkService configured with model context")
        // Drain any notification tap that arrived before the model context was ready (cold start)
        if let pending = pendingWorkoutId {
            pendingWorkoutId = nil
            print("🔗 DeepLinkService: processing buffered pending workout ID: \(pending)")
            handleDirectWorkoutLink(workoutId: pending)
        }
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle incoming URL from deep link
    func handleURL(_ url: URL) {
        print("🔗 Handling deep link URL: \(url)")
        
        guard url.scheme == "progress" else {
            print("❌ Invalid URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to parse URL components")
            return
        }
        
        switch components.host {
        case "workout":
            handleWorkoutDeepLink(components: components)
        default:
            print("❌ Unknown deep link host: \(components.host ?? "nil")")
        }
    }
    
    /// Handle workout-specific deep link
    private func handleWorkoutDeepLink(components: URLComponents) {
        // Check if this is a shared workout URL (has 'data' parameter)
        if let dataParameter = components.queryItems?.first(where: { $0.name == "data" })?.value {
            handleSharedWorkoutImport(components: components, encodedData: dataParameter)
            return
        }
        
        // Otherwise, handle as existing workout ID deep link
        guard let workoutIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let workoutId = UUID(uuidString: workoutIdString) else {
            print("❌ DEEPLINK: Invalid or missing workout ID in deep link")
            return
        }
        
        print("🔗 DEEPLINK: Looking for workout with ID: \(workoutId)")
        
        guard let modelContext = modelContext else {
            print("⏳ DEEPLINK: Model context not configured yet — buffering workout ID for cold start")
            pendingWorkoutId = workoutId
            return
        }
        
        // Find the workout by ID
        do {
            let descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { workout in
                    workout.id == workoutId
                }
            )
            
            let workouts = try modelContext.fetch(descriptor)
            
            if let workout = workouts.first {
                print("✅ DEEPLINK: Found workout: \(workout.name)")
                print("🔗 DEEPLINK: Current workoutToOpen: \(workoutToOpen?.name ?? "nil")")
                print("🔗 DEEPLINK: Current shouldNavigateToWorkouts: \(shouldNavigateToWorkouts)")
                
                // Prevent duplicate navigation - clear any existing workout first
                if workoutToOpen != nil {
                    print("⚠️ DEEPLINK: Clearing existing workout navigation to prevent duplicates")
                    clearWorkoutToOpen()
                }
                
                print("📡 DEEPLINK: Posting navigateToWorkouts notification")
                // Post notification to navigate to workouts tab first
                NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
                
                // Set the workout to open after a small delay to ensure tab navigation completes
                print("⏰ DEEPLINK: Setting 0.2s delay before setting workout")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("🎯 DEEPLINK: Setting workoutToOpen to: \(workout.name)")
                    self.workoutToOpen = workout
                    self.shouldNavigateToWorkouts = true
                    print("🔗 DEEPLINK: workoutToOpen set, shouldNavigateToWorkouts = true")
                }
                
            } else {
                print("❌ DEEPLINK: Workout not found with ID: \(workoutId)")
            }
            
        } catch {
            print("❌ DEEPLINK: Error fetching workout: \(error)")
        }
    }
    
    /// Set deep link in progress flag
    func setDeepLinkInProgress(_ inProgress: Bool) {
        print("🚩 DEEPLINK: Setting isDeepLinkInProgress to: \(inProgress)")
        isDeepLinkInProgress = inProgress
    }
    
    /// Handle direct workout link (more reliable on physical devices)
    func handleDirectWorkoutLink(workoutId: UUID) {
        print("🔗 DEEPLINK: Direct workout link for ID: \(workoutId)")
        
        guard let modelContext = modelContext else {
            print("⏳ DEEPLINK: Model context not configured yet — buffering workout ID for cold start")
            pendingWorkoutId = workoutId
            return
        }
        
        // Find the workout by ID
        do {
            let descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { workout in
                    workout.id == workoutId
                }
            )
            
            let workouts = try modelContext.fetch(descriptor)
            
            if let workout = workouts.first {
                print("✅ DEEPLINK: Direct link found workout: \(workout.name)")
                
                // Prevent duplicate navigation - clear any existing workout first
                if workoutToOpen != nil {
                    print("⚠️ DEEPLINK: Clearing existing workout navigation to prevent duplicates")
                    workoutToOpen = nil
                    shouldNavigateToWorkouts = false
                }
                
                // Post notification to navigate to workouts tab first
                NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
                
                // Set the workout to open after a small delay to ensure tab navigation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("🎯 DEEPLINK: Direct link setting workoutToOpen to: \(workout.name)")
                    self.workoutToOpen = workout
                    self.shouldNavigateToWorkouts = true
                }
                
            } else {
                print("❌ DEEPLINK: Direct link workout not found with ID: \(workoutId)")
            }
            
        } catch {
            print("❌ DEEPLINK: Direct link error fetching workout: \(error)")
        }
    }
    
    /// Clear the workout to open after navigation
    func clearWorkoutToOpen() {
        print("🧹 DEEPLINK: Clearing shouldNavigateToWorkouts and isDeepLinkInProgress")
        // Don't clear workoutToOpen immediately - let navigation handle it
        shouldNavigateToWorkouts = false
        isDeepLinkInProgress = false
    }
    
    // MARK: - Workout Import (Step 7C)
    
    /// Handle shared workout import from URL
    private func handleSharedWorkoutImport(components: URLComponents, encodedData: String) {
        print("🔗 IMPORT: Handling shared workout import")
        
        guard let modelContext = modelContext else {
            print("❌ IMPORT: Model context not configured")
            showImportError("App not ready for workout import. Please try again.")
            return
        }
        
        do {
            // Parse the workout URL using WorkoutURLGenerator
            let shareableWorkout = try WorkoutURLGenerator.parseWorkoutURL(components.url?.absoluteString ?? "")
            print("✅ IMPORT: Successfully parsed workout: \(shareableWorkout.name)")
            
            // Check for duplicate workout
            if try isDuplicateWorkout(shareableWorkout, in: modelContext) {
                print("⚠️ IMPORT: Duplicate workout detected, skipping import")
                showImportError("This workout has already been imported.")
                return
            }
            
            // Validate all exercises exist in the default library
            try validateExercisesExist(shareableWorkout.exercises)
            
            // Convert to SwiftData models and import
            let importedWorkout = try createWorkoutFromSharedData(shareableWorkout, in: modelContext)
            
            // Save to database
            modelContext.insert(importedWorkout)
            try modelContext.save()
            
            print("✅ IMPORT: Successfully imported workout: \(importedWorkout.name)")
            showImportSuccess(workoutName: importedWorkout.name)
            
        } catch let error as WorkoutURLGenerator.WorkoutSharingError {
            print("❌ IMPORT: Workout sharing error: \(error.localizedDescription)")
            showImportError(error.localizedDescription)
        } catch {
            print("❌ IMPORT: Unexpected error: \(error)")
            showImportError("Failed to import workout. The shared link may be corrupted.")
        }
    }
    
    /// Check if a workout with the same name and exercises already exists
    private func isDuplicateWorkout(_ shareableWorkout: WorkoutURLGenerator.ShareableWorkout, in modelContext: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.name == shareableWorkout.name
            }
        )
        
        let existingWorkouts = try modelContext.fetch(descriptor)
        
        // Check if any existing workout has the same name and exercise structure
        for existingWorkout in existingWorkouts {
            if workoutsHaveSameStructure(existing: existingWorkout, shared: shareableWorkout) {
                return true
            }
        }
        
        return false
    }
    
    /// Compare workout structures to detect duplicates
    private func workoutsHaveSameStructure(existing: Workout, shared: WorkoutURLGenerator.ShareableWorkout) -> Bool {
        // Compare exercise count
        guard existing.exercises.count == shared.exercises.count else { return false }
        
        // Sort both by order and compare
        let existingExercises = existing.exercises.sorted { $0.order < $1.order }
        let sharedExercises = shared.exercises.sorted { $0.order < $1.order }
        
        for (existingEx, sharedEx) in zip(existingExercises, sharedExercises) {
            // Compare exercise names and set counts
            if existingEx.name != sharedEx.name || existingEx.sets.count != sharedEx.sets.count {
                return false
            }
        }
        
        return true
    }
    
    /// Validate that all exercises in the shared workout exist in the default library
    private func validateExercisesExist(_ exercises: [WorkoutURLGenerator.ShareableExercise]) throws {
        for exercise in exercises {
            // Check if exercise exists in the predefined exercise database
            if ExerciseDatabase.findExerciseStatic(named: exercise.name) == nil {
                throw WorkoutImportError.exerciseNotFound(exercise.name)
            }
        }
    }
    
    /// Create a full Workout object from shared workout data
    private func createWorkoutFromSharedData(_ shareableWorkout: WorkoutURLGenerator.ShareableWorkout, in modelContext: ModelContext) throws -> Workout {
        // Create the workout
        let workout = Workout(
            name: shareableWorkout.name,
            notes: nil,
            isTemplate: false
        )
        
        // Create exercises
        for shareableExercise in shareableWorkout.exercises.sorted(by: { $0.order < $1.order }) {
            // Get the predefined exercise info
            guard let predefinedExercise = ExerciseDatabase.findExerciseStatic(named: shareableExercise.name) else {
                throw WorkoutImportError.exerciseNotFound(shareableExercise.name)
            }
            
            // Convert exercise type
            guard let exerciseType = ExerciseType(rawValue: shareableExercise.type) else {
                throw WorkoutImportError.invalidExerciseType(shareableExercise.type)
            }
            
            // Create the exercise
            let exercise = Exercise(
                name: shareableExercise.name,
                type: exerciseType,
                category: shareableExercise.category,
                notes: nil,
                order: shareableExercise.order,
                restTime: TimeInterval(shareableExercise.restTime),
                isHidden: false,
                isCustom: false,
                predefinedExerciseId: predefinedExercise.name // Use name as ID for predefined exercises
            )
            
            // Create sets
            for shareableSet in shareableExercise.sets.sorted(by: { $0.order < $1.order }) {
                let exerciseSet = ExerciseSet(
                    weight: shareableSet.weight ?? 0.0,
                    reps: shareableSet.reps ?? 0,
                    duration: TimeInterval(shareableSet.duration ?? 0),
                    distance: shareableSet.distance ?? 0.0,
                    order: shareableSet.order
                )
                
                // Set notes after initialization
                exerciseSet.notes = shareableSet.notes
                
                exercise.addSet(exerciseSet)
            }
            
            workout.addExercise(exercise)
        }
        
        return workout
    }
    
    /// Show import success message to user
    private func showImportSuccess(workoutName: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Workout Imported",
                message: "'\(workoutName)' has been added to your workout list.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
    
    /// Show import error message to user
    private func showImportError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Import Failed",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
}
