//
//  ExerciseClassificationService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

/// Service for managing exercise muscle group classifications and mappings
class ExerciseClassificationService {
    
    // MARK: - Exercise Classification Data Structure
    
    struct ExerciseClassification {
        let primaryMuscleGroup: MuscleGroup
        let secondaryMuscleGroups: MuscleGroupIntensity
        let exerciseType: ExerciseType
        
        init(primary: MuscleGroup, secondary: MuscleGroupIntensity = [:], type: ExerciseType = .strength) {
            self.primaryMuscleGroup = primary
            self.secondaryMuscleGroups = secondary
            self.exerciseType = type
        }
    }
    
    // MARK: - Static Exercise Classifications
    
    /// Comprehensive mapping of all default exercises to their muscle group classifications
    static let exerciseClassifications: [String: ExerciseClassification] = [
        
        // MARK: - Chest Exercises
        "Bench Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.3, .arms: 0.2]
        ),
        "Incline Bench Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.4, .arms: 0.2]
        ),
        "Decline Bench Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.2, .arms: 0.2]
        ),
        "Dumbbell Bench Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.3, .arms: 0.2]
        ),
        "Incline Dumbbell Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.4, .arms: 0.2]
        ),
        "Decline Dumbbell Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.2, .arms: 0.2]
        ),
        "Push-Ups": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.3, .arms: 0.2, .core: 0.1]
        ),
        "Incline Push-Ups": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.4, .arms: 0.2, .core: 0.1]
        ),
        "Decline Push-Ups": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.2, .arms: 0.2, .core: 0.1]
        ),
        "Diamond Push-Ups": ExerciseClassification(
            primary: .arms,
            secondary: [.chest: 0.4, .shoulders: 0.2]
        ),
        "Dumbbell Flyes": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.2]
        ),
        "Incline Dumbbell Flyes": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.3]
        ),
        "Cable Fly": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.2]
        ),
        "Pec Deck": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.1]
        ),
        "Chest Dips": ExerciseClassification(
            primary: .chest,
            secondary: [.arms: 0.4, .shoulders: 0.2]
        ),
        "Dumbbell Pullover": ExerciseClassification(
            primary: .chest,
            secondary: [.back: 0.3, .arms: 0.2]
        ),
        "Chest Press Machine": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.3, .arms: 0.2]
        ),
        "Cable Crossover": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.2]
        ),
        "Smith Machine Bench Press": ExerciseClassification(
            primary: .chest,
            secondary: [.shoulders: 0.3, .arms: 0.2]
        ),
        
        // MARK: - Back Exercises
        "Pull-Ups": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.4, .shoulders: 0.2]
        ),
        "Chin-Ups": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.5, .shoulders: 0.2]
        ),
        "Wide-Grip Pull-Ups": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.2]
        ),
        "Assisted Pull-Ups": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.4, .shoulders: 0.2]
        ),
        "Lat Pulldown": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.2]
        ),
        "Wide-Grip Lat Pulldown": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.2, .shoulders: 0.2]
        ),
        "Close-Grip Lat Pulldown": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.4, .shoulders: 0.2]
        ),
        "Seated Cable Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3]
        ),
        "Bent-Over Barbell Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .posteriorChain: 0.2]
        ),
        "Bent-Over Dumbbell Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .posteriorChain: 0.2]
        ),
        "Single-Arm Dumbbell Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .core: 0.2]
        ),
        "T-Bar Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .posteriorChain: 0.2]
        ),
        "Inverted Rows": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .core: 0.1]
        ),
        "Barbell Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .posteriorChain: 0.2]
        ),
        "Pendlay Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .posteriorChain: 0.2]
        ),
        "Dumbbell Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .core: 0.2]
        ),
        "Seal Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3]
        ),
        "Meadows Row": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.3, .shoulders: 0.3, .core: 0.2]
        ),
        "Close-Grip Pulldown": ExerciseClassification(
            primary: .back,
            secondary: [.arms: 0.4, .shoulders: 0.2]
        ),
        "Face Pulls": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.4, .arms: 0.2]
        ),
        
        // MARK: - Shoulder Exercises
        "Overhead Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3, .core: 0.2]
        ),
        "Military Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3, .core: 0.3]
        ),
        "Seated Shoulder Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3]
        ),
        "Dumbbell Shoulder Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3, .core: 0.1]
        ),
        "Arnold Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3, .core: 0.1]
        ),
        "Lateral Raises": ExerciseClassification(
            primary: .shoulders,
            secondary: [.core: 0.1]
        ),
        "Front Raises": ExerciseClassification(
            primary: .shoulders,
            secondary: [.core: 0.1]
        ),
        "Rear Delt Fly": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.3]
        ),
        "Upright Row": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3, .back: 0.2]
        ),
        "Shrugs": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.2]
        ),
        "Cable Lateral Raises": ExerciseClassification(
            primary: .shoulders
        ),
        "Machine Shoulder Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3]
        ),
        "Pike Push-Ups": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3, .core: 0.2]
        ),
        "Seated Overhead Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.arms: 0.3]
        ),
        "Reverse Pec Deck": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.3]
        ),
        "Reverse Fly Machine": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.3]
        ),
        "Dumbbell Shrugs": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.2]
        ),
        "Barbell Shrugs": ExerciseClassification(
            primary: .shoulders,
            secondary: [.back: 0.2]
        ),
        
        // MARK: - Arm Exercises
        "Bicep Curls": ExerciseClassification(
            primary: .arms
        ),
        "Hammer Curls": ExerciseClassification(
            primary: .arms
        ),
        "Preacher Curls": ExerciseClassification(
            primary: .arms
        ),
        "Cable Curls": ExerciseClassification(
            primary: .arms
        ),
        "Concentration Curls": ExerciseClassification(
            primary: .arms
        ),
        "21s (Bicep Curls)": ExerciseClassification(
            primary: .arms
        ),
        "Barbell Curls": ExerciseClassification(
            primary: .arms
        ),
        "EZ Bar Curls": ExerciseClassification(
            primary: .arms
        ),
        "Incline Dumbbell Curls": ExerciseClassification(
            primary: .arms
        ),
        "Preacher Curl": ExerciseClassification(
            primary: .arms
        ),
        "Spider Curl": ExerciseClassification(
            primary: .arms
        ),
        "Drag Curl": ExerciseClassification(
            primary: .arms
        ),
        "Tricep Dips": ExerciseClassification(
            primary: .arms,
            secondary: [.chest: 0.3, .shoulders: 0.2]
        ),
        "Tricep Pushdowns": ExerciseClassification(
            primary: .arms
        ),
        "Overhead Tricep Extension": ExerciseClassification(
            primary: .arms,
            secondary: [.shoulders: 0.2]
        ),
        "Close-Grip Bench Press": ExerciseClassification(
            primary: .arms,
            secondary: [.chest: 0.4, .shoulders: 0.2]
        ),
        "Close Grip Bench Press": ExerciseClassification(
            primary: .arms,
            secondary: [.chest: 0.4, .shoulders: 0.2]
        ),
        "Skull Crushers": ExerciseClassification(
            primary: .arms,
            secondary: [.shoulders: 0.1]
        ),
        "Bench Dips": ExerciseClassification(
            primary: .arms,
            secondary: [.chest: 0.3, .shoulders: 0.2]
        ),
        "Dumbbell Kickbacks": ExerciseClassification(
            primary: .arms
        ),
        "JM Press": ExerciseClassification(
            primary: .arms,
            secondary: [.chest: 0.3, .shoulders: 0.2]
        ),
        "Rope Overhead Extensions": ExerciseClassification(
            primary: .arms,
            secondary: [.shoulders: 0.2]
        ),
        "Reverse Curls": ExerciseClassification(
            primary: .arms
        ),
        "Behind-the-Back Wrist Curl": ExerciseClassification(
            primary: .arms
        ),
        "Plate Pinch Hold": ExerciseClassification(
            primary: .arms
        ),
        "Zottman Curl": ExerciseClassification(
            primary: .arms
        ),
        "Grip Trainer Squeeze": ExerciseClassification(
            primary: .arms
        ),
        "Wrist Curls": ExerciseClassification(
            primary: .arms
        ),
        "Reverse Wrist Curls": ExerciseClassification(
            primary: .arms
        ),
        
        // MARK: - Leg Exercises (Quads)
        "Squats": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.4, .core: 0.2]
        ),
        "Front Squat": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3, .core: 0.3]
        ),
        "Goblet Squats": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3, .core: 0.2]
        ),
        "Bulgarian Split Squats": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3, .core: 0.2]
        ),
        "Lunges": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.4, .core: 0.2]
        ),
        "Walking Lunges": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.4, .core: 0.2]
        ),
        "Reverse Lunges": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.4, .core: 0.2]
        ),
        "Leg Press": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3]
        ),
        "Leg Extensions": ExerciseClassification(
            primary: .quads
        ),
        "Wall Sits": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.2, .core: 0.2]
        ),
        "Step-Ups": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3, .core: 0.2]
        ),
        "Back Squat": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.4, .core: 0.2]
        ),
        "Box Squat": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.4, .core: 0.2]
        ),
        "Hack Squat": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3]
        ),
        "Goblet Squat": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3, .core: 0.2]
        ),
        "Bulgarian Split Squat": ExerciseClassification(
            primary: .quads,
            secondary: [.posteriorChain: 0.3, .core: 0.2]
        ),
        "Leg Extension": ExerciseClassification(
            primary: .quads
        ),
        
        // MARK: - Posterior Chain Exercises
        "Conventional Deadlift": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.4, .quads: 0.3, .core: 0.3]
        ),
        "Sumo Deadlift": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.4, .quads: 0.2, .core: 0.3]
        ),
        "Trap Bar Deadlift": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.3, .quads: 0.4, .core: 0.3]
        ),
        "Romanian Deadlift": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.3, .core: 0.2]
        ),
        "Stiff-Leg Deadlift": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.3, .core: 0.2]
        ),
        "Hip Thrusts": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.core: 0.2]
        ),
        "Glute Bridges": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.core: 0.2]
        ),
        "Good Mornings": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.3, .core: 0.3]
        ),
        "Leg Curls": ExerciseClassification(
            primary: .posteriorChain
        ),
        "Leg Curl Machine": ExerciseClassification(
            primary: .posteriorChain
        ),
        "Standing Calf Raises": ExerciseClassification(
            primary: .posteriorChain
        ),
        "Nordic Curls": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.core: 0.3]
        ),
        "Single-Leg Deadlift": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.3, .core: 0.4]
        ),
        "Calf Raises": ExerciseClassification(
            primary: .posteriorChain
        ),
        "Seated Calf Raises": ExerciseClassification(
            primary: .posteriorChain
        ),
        "Donkey Calf Raises": ExerciseClassification(
            primary: .posteriorChain
        ),
        "Hip Thrust": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.core: 0.2]
        ),
        "Glute Bridge": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.core: 0.2]
        ),
        "Nordic Curl": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.core: 0.3]
        ),
        
        // MARK: - Core Exercises
        "Plank": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.2]
        ),
        "Side Plank": ExerciseClassification(
            primary: .core
        ),
        "Weighted Plank": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.2]
        ),
        "Sit-Ups": ExerciseClassification(
            primary: .core
        ),
        "Crunches": ExerciseClassification(
            primary: .core
        ),
        "Cable Crunch": ExerciseClassification(
            primary: .core
        ),
        "Russian Twists": ExerciseClassification(
            primary: .core
        ),
        "Hanging Leg Raise": ExerciseClassification(
            primary: .core,
            secondary: [.arms: 0.2]
        ),
        "Lying Leg Raise": ExerciseClassification(
            primary: .core
        ),
        "V-Ups": ExerciseClassification(
            primary: .core
        ),
        "Mountain Climbers": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.3, .cardio: 0.2]
        ),
        "Flutter Kicks": ExerciseClassification(
            primary: .core
        ),
        "Bicycle Crunch": ExerciseClassification(
            primary: .core
        ),
        "Ab Rollout (Wheel)": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.3]
        ),
        "Stability Ball Rollout": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.3]
        ),
        "Hollow Body Hold": ExerciseClassification(
            primary: .core
        ),
        "Side Bend": ExerciseClassification(
            primary: .core
        ),
        
        // MARK: - Full Body / Compound Exercises
        "Clean and Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.posteriorChain: 0.4, .back: 0.3, .quads: 0.3, .core: 0.3, .arms: 0.2]
        ),
        "Power Clean": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.back: 0.4, .shoulders: 0.3, .quads: 0.3, .core: 0.3]
        ),
        "Snatch": ExerciseClassification(
            primary: .shoulders,
            secondary: [.posteriorChain: 0.4, .back: 0.4, .quads: 0.3, .core: 0.4]
        ),
        "Push Press": ExerciseClassification(
            primary: .shoulders,
            secondary: [.quads: 0.3, .core: 0.3, .arms: 0.2]
        ),
        "Thrusters": ExerciseClassification(
            primary: .shoulders,
            secondary: [.quads: 0.4, .posteriorChain: 0.3, .core: 0.3, .arms: 0.2]
        ),
        "Kettlebell Swing": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.shoulders: 0.3, .core: 0.3, .cardio: 0.2]
        ),
        "Burpee Pull-Up": ExerciseClassification(
            primary: .cardio,
            secondary: [.chest: 0.3, .back: 0.3, .shoulders: 0.3, .core: 0.3, .quads: 0.2]
        ),
        "Man Makers": ExerciseClassification(
            primary: .cardio,
            secondary: [.chest: 0.3, .shoulders: 0.4, .core: 0.3, .quads: 0.2]
        ),
        "Farmer's Carry": ExerciseClassification(
            primary: .core,
            secondary: [.arms: 0.4, .shoulders: 0.3, .posteriorChain: 0.2]
        ),
        "Yoke Carry": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.4, .posteriorChain: 0.3, .quads: 0.2]
        ),
        "Turkish Get-Up": ExerciseClassification(
            primary: .core,
            secondary: [.shoulders: 0.4, .posteriorChain: 0.3, .quads: 0.2]
        ),
        
        // MARK: - Cardio Exercises
        "Treadmill Run": ExerciseClassification(
            primary: .cardio,
            type: .cardio
        ),
        "Outdoor Run": ExerciseClassification(
            primary: .cardio,
            type: .cardio
        ),
        "Interval Sprints": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.3, .posteriorChain: 0.2],
            type: .cardio
        ),
        "Long-Distance Jog": ExerciseClassification(
            primary: .cardio,
            type: .cardio
        ),
        "Stationary Bike": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.2],
            type: .cardio
        ),
        "Road Cycling": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.2],
            type: .cardio
        ),
        "Spin Class": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.3],
            type: .cardio
        ),
        "HIIT Cycling": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.3],
            type: .cardio
        ),
        "Rowing Machine (steady pace)": ExerciseClassification(
            primary: .cardio,
            secondary: [.back: 0.3, .arms: 0.2, .core: 0.2],
            type: .cardio
        ),
        "Rowing Machine (intervals)": ExerciseClassification(
            primary: .cardio,
            secondary: [.back: 0.4, .arms: 0.3, .core: 0.3],
            type: .cardio
        ),
        "500m Row Sprint": ExerciseClassification(
            primary: .cardio,
            secondary: [.back: 0.4, .arms: 0.3, .core: 0.3],
            type: .cardio
        ),
        "Freestyle Swim": ExerciseClassification(
            primary: .cardio,
            secondary: [.shoulders: 0.3, .back: 0.3, .arms: 0.2, .core: 0.2],
            type: .cardio
        ),
        "Breaststroke Swim": ExerciseClassification(
            primary: .cardio,
            secondary: [.chest: 0.3, .shoulders: 0.2, .arms: 0.2],
            type: .cardio
        ),
        "Backstroke Swim": ExerciseClassification(
            primary: .cardio,
            secondary: [.back: 0.3, .shoulders: 0.2, .arms: 0.2],
            type: .cardio
        ),
        "Interval Laps": ExerciseClassification(
            primary: .cardio,
            secondary: [.shoulders: 0.3, .back: 0.3, .arms: 0.2, .core: 0.2],
            type: .cardio
        ),
        "Burpees": ExerciseClassification(
            primary: .cardio,
            secondary: [.chest: 0.3, .shoulders: 0.3, .core: 0.3, .quads: 0.2],
            type: .cardio
        ),
        "Jump Squats": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.4, .posteriorChain: 0.3],
            type: .cardio
        ),
        "High Knees": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.3, .core: 0.2],
            type: .cardio
        ),
        "Jump Rope": ExerciseClassification(
            primary: .cardio,
            secondary: [.arms: 0.2, .core: 0.2],
            type: .cardio
        ),
        "Treadmill Walk": ExerciseClassification(
            primary: .cardio,
            type: .cardio
        ),
        "Outdoor Walk": ExerciseClassification(
            primary: .cardio,
            type: .cardio
        ),
        "Hiking Trail": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.2, .posteriorChain: 0.2],
            type: .cardio
        ),
        "Incline Walk": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.2, .posteriorChain: 0.2],
            type: .cardio
        ),
        "Stairmaster": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.3, .posteriorChain: 0.2],
            type: .cardio
        ),
        "Elliptical Trainer": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.2, .arms: 0.1],
            type: .cardio
        ),
        "Assault Bike": ExerciseClassification(
            primary: .cardio,
            secondary: [.quads: 0.3, .arms: 0.2],
            type: .cardio
        ),
        "VersaClimber": ExerciseClassification(
            primary: .cardio,
            secondary: [.shoulders: 0.3, .arms: 0.3, .core: 0.3, .quads: 0.2],
            type: .cardio
        ),
        
        // MARK: - Flexibility/Recovery Exercises
        "Hamstring Stretch": ExerciseClassification(
            primary: .posteriorChain,
            type: .flexibility
        ),
        "Quad Stretch": ExerciseClassification(
            primary: .quads,
            type: .flexibility
        ),
        "Shoulder Stretch": ExerciseClassification(
            primary: .shoulders,
            type: .flexibility
        ),
        "Triceps Stretch": ExerciseClassification(
            primary: .arms,
            type: .flexibility
        ),
        "Calf Stretch": ExerciseClassification(
            primary: .posteriorChain,
            type: .flexibility
        ),
        "Hip Flexor Stretch": ExerciseClassification(
            primary: .quads,
            type: .flexibility
        ),
        "Foam Rolling Quads": ExerciseClassification(
            primary: .quads,
            type: .flexibility
        ),
        "Foam Rolling Back": ExerciseClassification(
            primary: .back,
            type: .flexibility
        ),
        "Band Shoulder Dislocates": ExerciseClassification(
            primary: .shoulders,
            type: .flexibility
        ),
        "Cat-Cow Stretch": ExerciseClassification(
            primary: .core,
            secondary: [.back: 0.3],
            type: .flexibility
        ),
        "Hip Circles": ExerciseClassification(
            primary: .core,
            type: .flexibility
        ),
        "Downward Dog": ExerciseClassification(
            primary: .shoulders,
            secondary: [.posteriorChain: 0.3, .core: 0.2],
            type: .flexibility
        ),
        "Child's Pose": ExerciseClassification(
            primary: .back,
            secondary: [.shoulders: 0.2],
            type: .flexibility
        ),
        "Cobra Pose": ExerciseClassification(
            primary: .core,
            secondary: [.back: 0.3],
            type: .flexibility
        ),
        "Warrior II": ExerciseClassification(
            primary: .quads,
            secondary: [.core: 0.3, .shoulders: 0.2],
            type: .flexibility
        ),
        "Pigeon Pose": ExerciseClassification(
            primary: .posteriorChain,
            secondary: [.quads: 0.3],
            type: .flexibility
        ),
        "Box Breathing": ExerciseClassification(
            primary: .core,
            type: .flexibility
        ),
        "4-7-8 Breathing": ExerciseClassification(
            primary: .core,
            type: .flexibility
        ),
        "Alternate Nostril Breathing": ExerciseClassification(
            primary: .core,
            type: .flexibility
        ),
        "Guided Meditation": ExerciseClassification(
            primary: .core,
            type: .flexibility
        ),
        "Progressive Relaxation": ExerciseClassification(
            primary: .core,
            type: .flexibility
        )
    ]
    
    // MARK: - Public Methods
    
    /// Gets the muscle group classification for a given exercise name
    static func getClassification(for exerciseName: String) -> ExerciseClassification? {
        return exerciseClassifications[exerciseName]
    }
    
    /// Gets all available exercise names that have classifications
    static func getAllClassifiedExerciseNames() -> [String] {
        return Array(exerciseClassifications.keys).sorted()
    }
    
    /// Validates that all exercises in the database have classifications
    @MainActor
    static func validateExerciseClassifications() -> [String] {
        let allExercises = ExerciseDatabase.shared.getAllExercises()
        var missingClassifications: [String] = []
        
        for exercise in allExercises {
            if exerciseClassifications[exercise.name] == nil {
                missingClassifications.append(exercise.name)
            }
        }
        
        return missingClassifications
    }
    
    /// Gets exercises by primary muscle group
    static func getExercises(for primaryMuscleGroup: MuscleGroup) -> [String] {
        return exerciseClassifications.compactMap { (name, classification) in
            classification.primaryMuscleGroup == primaryMuscleGroup ? name : nil
        }.sorted()
    }
    
    /// Gets exercises by exercise type
    static func getExercises(for exerciseType: ExerciseType) -> [String] {
        return exerciseClassifications.compactMap { (name, classification) in
            classification.exerciseType == exerciseType ? name : nil
        }.sorted()
    }
    
    /// Updates an exercise with its muscle group classification
    static func applyClassification(to exercise: Exercise) {
        guard let classification = getClassification(for: exercise.name) else {
            print("⚠️ No classification found for exercise: \(exercise.name)")
            return
        }
        
        exercise.updateMuscleGroupClassification(
            primary: classification.primaryMuscleGroup,
            secondary: classification.secondaryMuscleGroups,
            classification: classification.exerciseType
        )
        
        print("✅ Applied classification to \(exercise.name): \(classification.primaryMuscleGroup.displayName)")
    }
    
    /// Applies classifications to all exercises in a workout
    static func applyClassifications(to workout: Workout) {
        for exercise in workout.exercises {
            applyClassification(to: exercise)
        }
    }
    
    /// Gets muscle group coverage statistics
    static func getMuscleGroupCoverage() -> [MuscleGroup: Int] {
        var coverage: [MuscleGroup: Int] = [:]
        
        for classification in exerciseClassifications.values {
            coverage[classification.primaryMuscleGroup, default: 0] += 1
        }
        
        return coverage
    }
}
