//
//  ExerciseImageService.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import Combine

/// Service for managing exercise images with caching and fallback support
@MainActor
class ExerciseImageService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ExerciseImageService()
    
    // MARK: - Properties
    
    /// Cache for loaded images to avoid repeated loading
    private var imageCache: [String: UIImage] = [:]
    
    /// Default fallback icon for exercises without specific images
    private let defaultExerciseIcon = "figure.strengthtraining.traditional"
    
    /// Mapping of exercise names to their corresponding asset names
    private let exerciseImageMap: [String: String] = [
        // Chest exercises
        "Bench Press": "exercise_bench_press",
        "Incline Bench Press": "exercise_incline_bench_press",
        "Dumbbell Bench Press": "exercise_dumbbell_bench_press",
        "Push-Ups": "exercise_push_ups",
        "Chest Dips": "exercise_chest_dips",
        
        // Back exercises
        "Pull-Ups": "exercise_pull_ups",
        "Chin-Ups": "exercise_chin_ups",
        "Lat Pulldown": "exercise_lat_pulldown",
        "Barbell Row": "exercise_barbell_row",
        "Dumbbell Row": "exercise_dumbbell_row",
        
        // Legs exercises
        "Squats": "exercise_squats",
        "Deadlifts": "exercise_deadlifts",
        "Leg Press": "exercise_leg_press",
        "Lunges": "exercise_lunges",
        "Leg Curls": "exercise_leg_curls",
        
        // Shoulders exercises
        "Overhead Press": "exercise_overhead_press",
        "Lateral Raises": "exercise_lateral_raises",
        "Front Raises": "exercise_front_raises",
        
        // Arms exercises
        "Bicep Curls": "exercise_bicep_curls",
        "Tricep Dips": "exercise_tricep_dips",
        
        // Cardio exercises
        "Running": "exercise_running",
        "Cycling": "exercise_cycling",
        "Rowing": "exercise_rowing",
        
        // Recovery exercises
        "Stretching": "exercise_stretching",
        "Foam Rolling": "exercise_foam_rolling"
    ]
    
    // MARK: - Initialization
    
    private init() {
        preloadCommonImages()
    }
    
    // MARK: - Public Methods
    
    /// Gets the image for a given exercise name
    /// - Parameter exerciseName: The name of the exercise
    /// - Returns: UIImage if found, nil if not available
    func getImage(for exerciseName: String) -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache[exerciseName] {
            return cachedImage
        }
        
        // Try to load from assets
        if let assetName = exerciseImageMap[exerciseName],
           let image = UIImage(named: assetName) {
            // Cache the loaded image
            imageCache[exerciseName] = image
            return image
        }
        
        return nil
    }
    
    /// Gets the SwiftUI Image for a given exercise name with fallback
    /// - Parameter exerciseName: The name of the exercise
    /// - Returns: SwiftUI Image (either exercise-specific or default icon)
    func getSwiftUIImage(for exerciseName: String) -> Image {
        if let uiImage = getImage(for: exerciseName) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: defaultExerciseIcon)
        }
    }
    
    /// Checks if an exercise has a specific image available
    /// - Parameter exerciseName: The name of the exercise
    /// - Returns: True if a specific image exists, false if it would use the default
    func hasSpecificImage(for exerciseName: String) -> Bool {
        return exerciseImageMap[exerciseName] != nil && 
               UIImage(named: exerciseImageMap[exerciseName]!) != nil
    }
    
    /// Gets the asset name for an exercise (for debugging/testing)
    /// - Parameter exerciseName: The name of the exercise
    /// - Returns: The asset name if mapped, nil otherwise
    func getAssetName(for exerciseName: String) -> String? {
        return exerciseImageMap[exerciseName]
    }
    
    /// Preloads images for common exercises to improve performance
    private func preloadCommonImages() {
        let commonExercises = [
            "Bench Press", "Squats", "Deadlifts", "Pull-Ups", 
            "Overhead Press", "Bicep Curls", "Running"
        ]
        
        for exercise in commonExercises {
            _ = getImage(for: exercise) // This will cache the image if available
        }
    }
    
    /// Clears the image cache (useful for memory management)
    func clearCache() {
        imageCache.removeAll()
    }
    
    /// Gets cache statistics for debugging
    var cacheInfo: (count: Int, exercises: [String]) {
        return (count: imageCache.count, exercises: Array(imageCache.keys))
    }
}

// MARK: - Exercise Extensions

extension Exercise {
    /// Convenience property to get the exercise image
    @MainActor var image: Image {
        ExerciseImageService.shared.getSwiftUIImage(for: name)
    }
    
    /// Convenience property to check if exercise has a specific image
    @MainActor var hasSpecificImage: Bool {
        ExerciseImageService.shared.hasSpecificImage(for: name)
    }
}

// MARK: - ExerciseDatabase Extensions

extension ExerciseDatabase.PredefinedExercise {
    /// Convenience property to get the exercise image
    @MainActor var image: Image {
        ExerciseImageService.shared.getSwiftUIImage(for: name)
    }
    
    /// Convenience property to check if exercise has a specific image
    @MainActor var hasSpecificImage: Bool {
        ExerciseImageService.shared.hasSpecificImage(for: name)
    }
}
