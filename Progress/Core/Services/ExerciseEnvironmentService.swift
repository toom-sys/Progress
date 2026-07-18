//
//  ExerciseEnvironmentService.swift
//  Progress
//

import Foundation

/// Where a predefined exercise is typically performed.
enum WorkoutEnvironment: String, Codable, CaseIterable {
    case home
    case gym
    case both

    var displayName: String {
        switch self {
        case .home: return "Home"
        case .gym: return "Gym"
        case .both: return "Home & Gym"
        }
    }
}

/// Home-vs-gym classification for predefined exercises in the database.
class ExerciseEnvironmentService {

    // MARK: - Explicit Classifications

    /// Bodyweight or no-equipment exercises typically done at home.
    private static let homeExercises: Set<String> = [
        "Plank",
        "Side Plank",
        "Sit-Ups",
        "Crunches",
        "Lying Leg Raise",
        "V-Ups",
        "Mountain Climbers",
        "Flutter Kicks",
        "Bicycle Crunch",
        "Hollow Body Hold",
        "Glute Bridge",
        "Burpees",
        "Jump Squats",
        "High Knees",
        "Outdoor Walk",
        "Hamstring Stretch",
        "Quad Stretch",
        "Shoulder Stretch",
        "Triceps Stretch",
        "Calf Stretch",
        "Hip Flexor Stretch",
        "Cat-Cow Stretch",
        "Hip Circles",
        "Downward Dog",
        "Child's Pose",
        "Cobra Pose",
        "Warrior II",
        "Pigeon Pose",
        "Box Breathing",
        "4-7-8 Breathing",
        "Alternate Nostril Breathing",
        "Guided Meditation",
        "Progressive Relaxation"
    ]

    /// Exercises that work at home or in a gym (dumbbells, kettlebells, outdoor cardio, etc.).
    private static let bothExercises: Set<String> = [
        "Push-Ups",
        "Incline Push-Ups",
        "Dumbbell Bench Press",
        "Dumbbell Flyes",
        "Incline Dumbbell Flyes",
        "Dumbbell Row",
        "Dumbbell Shoulder Press",
        "Arnold Press",
        "Lateral Raises",
        "Front Raises",
        "Rear Delt Fly",
        "Dumbbell Shrugs",
        "Upright Row",
        "Bicep Curls",
        "Incline Dumbbell Curls",
        "Concentration Curls",
        "Hammer Curls",
        "Reverse Curls",
        "Wrist Curls",
        "Reverse Wrist Curls",
        "Zottman Curl",
        "Grip Trainer Squeeze",
        "Bench Dips",
        "Skull Crushers",
        "Overhead Tricep Extension",
        "Dumbbell Kickbacks",
        "Goblet Squat",
        "Bulgarian Split Squat",
        "Lunges",
        "Step-Ups",
        "Romanian Deadlift",
        "Hip Thrust",
        "Standing Calf Raises",
        "Weighted Plank",
        "Russian Twists",
        "Ab Rollout (Wheel)",
        "Stability Ball Rollout",
        "Side Bend",
        "Thrusters",
        "Kettlebell Swing",
        "Man Makers",
        "Farmer's Carry",
        "Turkish Get-Up",
        "Outdoor Run",
        "Interval Sprints",
        "Long-Distance Jog",
        "Road Cycling",
        "HIIT Cycling",
        "Freestyle Swim",
        "Breaststroke Swim",
        "Backstroke Swim",
        "Interval Laps",
        "Hiking Trail",
        "Incline Walk",
        "Jump Rope",
        "Foam Rolling Quads",
        "Foam Rolling Back",
        "Band Shoulder Dislocates"
    ]

    // MARK: - Lookup

    /// Returns the environment tag for a predefined exercise. Unknown names default to `.gym`.
    static func environment(for exerciseName: String) -> WorkoutEnvironment {
        if bothExercises.contains(exerciseName) { return .both }
        if homeExercises.contains(exerciseName) { return .home }
        return .gym
    }

    /// Returns predefined exercises usable in the given setting. Exercises tagged `.both` are always included.
    @MainActor
    static func exercises(in selectedEnvironment: WorkoutEnvironment) -> [ExerciseDatabase.PredefinedExercise] {
        ExerciseDatabase.shared.getAllExercises().filter { exercise in
            isUsable(environment(for: exercise.name), in: selectedEnvironment)
        }
    }

    /// Whether an exercise tag is usable for the selected training environment.
    static func isUsable(_ exerciseEnvironment: WorkoutEnvironment, in selected: WorkoutEnvironment) -> Bool {
        switch selected {
        case .home:
            return exerciseEnvironment == .home || exerciseEnvironment == .both
        case .gym:
            return exerciseEnvironment == .gym || exerciseEnvironment == .both
        case .both:
            return exerciseEnvironment == .both
        }
    }

    // MARK: - Debug

    #if DEBUG
    /// Logs environment tag counts for every predefined exercise in the database.
    @MainActor
    static func logEnvironmentCounts() {
        let allExercises = ExerciseDatabase.shared.getAllExercises()
        var counts: [WorkoutEnvironment: Int] = [.home: 0, .gym: 0, .both: 0]

        for exercise in allExercises {
            let tag = environment(for: exercise.name)
            counts[tag, default: 0] += 1
        }

        let homeUsable = exercises(in: .home).count
        let gymUsable = exercises(in: .gym).count

        print("🏠 Exercise environment tags (\(allExercises.count) predefined exercises):")
        print("   Home only: \(counts[.home, default: 0])")
        print("   Gym only:  \(counts[.gym, default: 0])")
        print("   Both:      \(counts[.both, default: 0])")
        print("   Usable at Home: \(homeUsable) · Usable at Gym: \(gymUsable)")
        print("   Spot-check — Bench Press: \(environment(for: "Bench Press").rawValue), Push-Ups: \(environment(for: "Push-Ups").rawValue), Dumbbell Row: \(environment(for: "Dumbbell Row").rawValue)")
    }
    #endif
}
