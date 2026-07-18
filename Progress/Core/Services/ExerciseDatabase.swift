//
//  ExerciseDatabase.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

/// Service for managing both predefined and custom exercise databases
@MainActor
class ExerciseDatabase: ObservableObject {
    
    // MARK: - Data Models
    
    /// Represents a category of exercises (Resistance, Cardio, Recovery)
    struct ExerciseCategory: Codable, Identifiable, Hashable {
        let id = UUID()
        let category: String
        let types: [ExerciseType]
        
        private enum CodingKeys: String, CodingKey {
            case category, types
        }
    }
    
    /// Represents a type within a category (e.g., Chest, Back, Running)
    struct ExerciseType: Codable, Identifiable, Hashable {
        let id = UUID()
        let type: String
        let exercises: [String]
        
        private enum CodingKeys: String, CodingKey {
            case type, exercises
        }
    }
    
    /// Represents a predefined exercise with metadata
    struct PredefinedExercise: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let category: String
        let type: String
        let imageName: String?
        
        init(name: String, category: String, type: String, imageName: String? = nil) {
            self.name = name
            self.category = category
            self.type = type
            self.imageName = imageName
        }
    }
    
    // MARK: - Static Exercise Data
    
    /// JSON data containing all predefined exercises organized by category and type
    nonisolated private static let exerciseDataJSON = """
    [
      {
        "category": "Resistance",
        "types": [
          {
            "type": "Chest",
            "exercises": [
              "Bench Press",
              "Incline Bench Press",
              "Decline Bench Press",
              "Dumbbell Bench Press",
              "Dumbbell Flyes",
              "Incline Dumbbell Flyes",
              "Chest Press Machine",
              "Cable Crossover",
              "Push-Ups",
              "Incline Push-Ups",
              "Chest Dips",
              "Smith Machine Bench Press"
            ]
          },
          {
            "type": "Back",
            "exercises": [
              "Pull-Ups",
              "Chin-Ups",
              "Wide-Grip Pull-Ups",
              "Lat Pulldown",
              "Close-Grip Pulldown",
              "Barbell Row",
              "Pendlay Row",
              "Dumbbell Row",
              "T-Bar Row",
              "Seal Row",
              "Seated Cable Row",
              "Meadows Row",
              "Face Pulls",
              "Reverse Fly Machine"
            ]
          },
          {
            "type": "Shoulders",
            "exercises": [
              "Overhead Press",
              "Seated Overhead Press",
              "Dumbbell Shoulder Press",
              "Arnold Press",
              "Military Press",
              "Lateral Raises",
              "Front Raises",
              "Rear Delt Fly",
              "Reverse Pec Deck",
              "Face Pulls",
              "Upright Row",
              "Dumbbell Shrugs",
              "Barbell Shrugs",
              "Cable Lateral Raises"
            ]
          },
          {
            "type": "Biceps",
            "exercises": [
              "Bicep Curls",
              "Barbell Curls",
              "EZ Bar Curls",
              "Incline Dumbbell Curls",
              "Concentration Curls",
              "Cable Curls",
              "Preacher Curl",
              "Spider Curl",
              "Drag Curl"
            ]
          },
          {
            "type": "Triceps",
            "exercises": [
              "Tricep Dips",
              "Bench Dips",
              "Close Grip Bench Press",
              "Skull Crushers",
              "Tricep Pushdowns",
              "Overhead Tricep Extension",
              "Dumbbell Kickbacks",
              "JM Press",
              "Rope Overhead Extensions"
            ]
          },
          {
            "type": "Forearms",
            "exercises": [
              "Wrist Curls",
              "Reverse Wrist Curls",
              "Hammer Curls",
              "Reverse Curls",
              "Behind-the-Back Wrist Curl",
              "Farmer's Carry",
              "Plate Pinch Hold",
              "Zottman Curl",
              "Grip Trainer Squeeze"
            ]
          },
          {
            "type": "Legs",
            "exercises": [
              "Back Squat",
              "Front Squat",
              "Goblet Squat",
              "Box Squat",
              "Bulgarian Split Squat",
              "Lunges",
              "Step-Ups",
              "Leg Press",
              "Hack Squat",
              "Romanian Deadlift",
              "Stiff-Leg Deadlift",
              "Glute Bridge",
              "Hip Thrust",
              "Leg Extension",
              "Leg Curl Machine",
              "Nordic Curl",
              "Standing Calf Raises",
              "Seated Calf Raises",
              "Donkey Calf Raises"
            ]
          },
          {
            "type": "Core",
            "exercises": [
              "Plank",
              "Side Plank",
              "Weighted Plank",
              "Sit-Ups",
              "Crunches",
              "Cable Crunch",
              "Russian Twists",
              "Hanging Leg Raise",
              "Lying Leg Raise",
              "V-Ups",
              "Mountain Climbers",
              "Flutter Kicks",
              "Bicycle Crunch",
              "Ab Rollout (Wheel)",
              "Stability Ball Rollout",
              "Hollow Body Hold",
              "Side Bend"
            ]
          },
          {
            "type": "Full Body / Compound",
            "exercises": [
              "Conventional Deadlift",
              "Sumo Deadlift",
              "Trap Bar Deadlift",
              "Clean and Press",
              "Power Clean",
              "Snatch",
              "Push Press",
              "Thrusters",
              "Kettlebell Swing",
              "Burpee Pull-Up",
              "Man Makers",
              "Farmer's Carry",
              "Yoke Carry",
              "Turkish Get-Up"
            ]
          }
        ]
      },
      {
        "category": "Cardio",
        "types": [
          {
            "type": "Running",
            "exercises": [
              "Treadmill Run",
              "Outdoor Run",
              "Interval Sprints",
              "Long-Distance Jog"
            ]
          },
          {
            "type": "Cycling",
            "exercises": [
              "Stationary Bike",
              "Road Cycling",
              "Spin Class",
              "HIIT Cycling"
            ]
          },
          {
            "type": "Rowing",
            "exercises": [
              "Rowing Machine (steady pace)",
              "Rowing Machine (intervals)",
              "500m Row Sprint"
            ]
          },
          {
            "type": "Swimming",
            "exercises": [
              "Freestyle Swim",
              "Breaststroke Swim",
              "Backstroke Swim",
              "Interval Laps"
            ]
          },
          {
            "type": "HIIT / Circuits",
            "exercises": [
              "Burpees",
              "Mountain Climbers",
              "Jump Squats",
              "High Knees",
              "Jump Rope"
            ]
          },
          {
            "type": "Walking / Hiking",
            "exercises": [
              "Treadmill Walk",
              "Outdoor Walk",
              "Hiking Trail",
              "Incline Walk"
            ]
          },
          {
            "type": "Machine-Based",
            "exercises": [
              "Stairmaster",
              "Elliptical Trainer",
              "Assault Bike",
              "VersaClimber"
            ]
          }
        ]
      },
      {
        "category": "Recovery",
        "types": [
          {
            "type": "Stretching",
            "exercises": [
              "Hamstring Stretch",
              "Quad Stretch",
              "Shoulder Stretch",
              "Triceps Stretch",
              "Calf Stretch",
              "Hip Flexor Stretch"
            ]
          },
          {
            "type": "Mobility",
            "exercises": [
              "Foam Rolling Quads",
              "Foam Rolling Back",
              "Band Shoulder Dislocates",
              "Cat-Cow Stretch",
              "Hip Circles"
            ]
          },
          {
            "type": "Yoga",
            "exercises": [
              "Downward Dog",
              "Child's Pose",
              "Cobra Pose",
              "Warrior II",
              "Pigeon Pose"
            ]
          },
          {
            "type": "Breathing / Mindfulness",
            "exercises": [
              "Box Breathing",
              "4-7-8 Breathing",
              "Alternate Nostril Breathing",
              "Guided Meditation",
              "Progressive Relaxation"
            ]
          }
        ]
      }
    ]
    """
    
    // MARK: - Singleton Instance
    
    static let shared = ExerciseDatabase()
    
    // MARK: - Private Properties
    
    private var categories: [ExerciseCategory] = []
    private var allExercises: [PredefinedExercise] = []
    
    /// SwiftData model context for custom exercises
    private var modelContext: ModelContext?
    
    /// Cached custom exercises
    @Published private var customExercises: [CustomExercise] = []
    
    // MARK: - Initialization
    
    private init() {
        loadExerciseData()
    }
    
    // MARK: - Warm-Up
    
    /// Pre-warms the singleton and classification data off the critical path
    static func warmUp() async {
        _ = shared.allExercises.count
        _ = ExerciseClassificationService.exerciseClassifications.count
        #if DEBUG
        ExerciseEnvironmentService.logEnvironmentCounts()
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Returns all exercise categories
    func getCategories() -> [ExerciseCategory] {
        return categories
    }
    
    /// Returns all exercise types for a given category
    func getTypes(for category: String) -> [ExerciseType] {
        return categories.first { $0.category == category }?.types ?? []
    }
    
    /// Returns all exercises for a given type within a category
    func getExercises(for type: String, in category: String) -> [PredefinedExercise] {
        return allExercises.filter { $0.type == type && $0.category == category }
    }
    
    /// Returns all exercises for a given type (across all categories)
    func getExercises(for type: String) -> [PredefinedExercise] {
        return allExercises.filter { $0.type == type }
    }
    
    /// Returns all exercises in a category
    func getAllExercises(in category: String) -> [PredefinedExercise] {
        return allExercises.filter { $0.category == category }
    }
    
    /// Returns all exercises across all categories
    func getAllExercises() -> [PredefinedExercise] {
        return allExercises
    }
    
    /// Searches for exercises by name (case-insensitive)
    func searchExercises(query: String) -> [PredefinedExercise] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allExercises
        }
        
        let lowercaseQuery = query.lowercased()
        return allExercises.filter { exercise in
            exercise.name.lowercased().contains(lowercaseQuery) ||
            exercise.category.lowercased().contains(lowercaseQuery) ||
            exercise.type.lowercased().contains(lowercaseQuery)
        }
    }
    
    /// Finds a specific exercise by name
    func findExercise(named name: String) -> PredefinedExercise? {
        return allExercises.first { $0.name.lowercased() == name.lowercased() }
    }
    

    
    /// Pre-parsed cache for nonisolated lookups (built once on first access)
    nonisolated private static let staticExerciseLookup: [String: PredefinedExercise] = {
        guard let data = exerciseDataJSON.data(using: .utf8),
              let categories = try? JSONDecoder().decode([ExerciseCategory].self, from: data) else {
            return [:]
        }
        var lookup: [String: PredefinedExercise] = [:]
        for category in categories {
            for type in category.types {
                for exerciseName in type.exercises {
                    lookup[exerciseName.lowercased()] = PredefinedExercise(
                        name: exerciseName,
                        category: category.category,
                        type: type.type
                    )
                }
            }
        }
        return lookup
    }()
    
    /// Static method to find exercise without actor isolation
    nonisolated static func findExerciseStatic(named name: String) -> PredefinedExercise? {
        return staticExerciseLookup[name.lowercased()]
    }
    
    // MARK: - Private Methods
    
    /// Loads and parses the exercise data from JSON
    private func loadExerciseData() {
        do {
            let data = ExerciseDatabase.exerciseDataJSON.data(using: .utf8)!
            let decoder = JSONDecoder()
            categories = try decoder.decode([ExerciseCategory].self, from: data)
            
            // Build flat list of all exercises for easy searching
            allExercises = []
            for category in categories {
                for type in category.types {
                    for exerciseName in type.exercises {
                        let exercise = PredefinedExercise(
                            name: exerciseName,
                            category: category.category,
                            type: type.type
                        )
                        allExercises.append(exercise)
                    }
                }
            }
            
            print("✅ Loaded \(categories.count) categories with \(allExercises.count) total exercises")
            
        } catch {
            print("❌ Failed to load exercise data: \(error.localizedDescription)")
            categories = []
            allExercises = []
        }
    }
    
    // MARK: - Custom Exercise Management
    
    /// Sets the SwiftData model context for custom exercise persistence
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            loadCustomExercises()
        }
    }
    
    /// Loads custom exercises from SwiftData
    private func loadCustomExercises() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CustomExercise>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            customExercises = try context.fetch(descriptor)
        } catch {
            print("Failed to load custom exercises: \(error)")
            customExercises = []
        }
    }
    
    /// Adds a new custom exercise
    func addCustomExercise(name: String, category: String, type: String) -> CustomExercise? {
        guard let context = modelContext else { return nil }
        
        // Check if custom exercise with same name already exists
        if customExercises.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            return nil
        }
        
        let customExercise = CustomExercise(name: name, category: category, type: type)
        context.insert(customExercise)
        
        do {
            try context.save()
            loadCustomExercises() // Refresh the cache
            return customExercise
        } catch {
            print("Failed to save custom exercise: \(error)")
            return nil
        }
    }
    
    /// Deletes a custom exercise
    func deleteCustomExercise(_ exercise: CustomExercise) {
        guard let context = modelContext else { return }
        
        context.delete(exercise)
        
        do {
            try context.save()
            loadCustomExercises() // Refresh the cache
        } catch {
            print("Failed to delete custom exercise: \(error)")
        }
    }
    
    /// Records usage of a custom exercise
    func recordCustomExerciseUsage(_ exercise: CustomExercise) {
        guard let context = modelContext else { return }
        
        exercise.incrementUsage()
        
        do {
            try context.save()
        } catch {
            print("Failed to record custom exercise usage: \(error)")
        }
    }
    
    /// Returns all custom exercises
    func getCustomExercises() -> [CustomExercise] {
        return customExercises
    }
    
    /// Returns custom exercises for a specific category and type
    func getCustomExercises(for category: String, type: String) -> [CustomExercise] {
        return customExercises.filter { 
            $0.category.lowercased() == category.lowercased() && 
            $0.type.lowercased() == type.lowercased() 
        }
    }
    
    /// Combined search across both predefined and custom exercises
    func searchAllExercises(query: String) -> (predefined: [PredefinedExercise], custom: [CustomExercise]) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (predefined: allExercises, custom: customExercises)
        }
        
        let lowercaseQuery = query.lowercased()
        
        let predefinedResults = allExercises.filter { exercise in
            exercise.name.lowercased().contains(lowercaseQuery) ||
            exercise.category.lowercased().contains(lowercaseQuery) ||
            exercise.type.lowercased().contains(lowercaseQuery)
        }
        
        let customResults = customExercises.filter { exercise in
            exercise.name.lowercased().contains(lowercaseQuery) ||
            exercise.category.lowercased().contains(lowercaseQuery) ||
            exercise.type.lowercased().contains(lowercaseQuery)
        }
        
        return (predefined: predefinedResults, custom: customResults)
    }
}

// MARK: - Computed Properties

extension ExerciseDatabase {
    
    /// Total number of exercises in the database
    var totalExerciseCount: Int {
        return allExercises.count
    }
    
    /// Total number of categories
    var categoryCount: Int {
        return categories.count
    }
    
    /// Total number of exercise types across all categories
    var typeCount: Int {
        return categories.reduce(0) { $0 + $1.types.count }
    }
}
