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
    
    /// Cache for loaded primary/thumbnail images
    private var imageCache: [String: UIImage] = [:]
    
    /// Cache for ordered pose-frame sequences used by the detail carousel
    private var poseFramesCache: [String: [UIImage]] = [:]
    
    /// Default fallback icon for exercises without specific images
    private let defaultExerciseIcon = "figure.strengthtraining.traditional"
    
    /// Mapping of exercise names to ordered pose-frame asset names (typically 2).
    /// The first frame is also used as the list/thumbnail image.
    private let exercisePoseMap: [String: [String]] = [
        // Chest exercises
        "Bench Press": [
            "exercise_bench_press_1",
            "exercise_bench_press_2"
        ],
        "Incline Bench Press": [
            "exercise_incline_bench_press_1",
            "exercise_incline_bench_press_2"
        ],
        "Decline Bench Press": [
            "exercise_decline_bench_press_1",
            "exercise_decline_bench_press_2"
        ],
        "Dumbbell Bench Press": [
            "exercise_dumbbell_bench_press_1",
            "exercise_dumbbell_bench_press_2"
        ],
        "Dumbbell Flyes": [
            "exercise_dumbbell_flyes_1",
            "exercise_dumbbell_flyes_2"
        ],
        "Incline Dumbbell Flyes": [
            "exercise_incline_dumbbell_flyes_1",
            "exercise_incline_dumbbell_flyes_2"
        ],
        "Chest Press Machine": [
            "exercise_chest_press_machine_1",
            "exercise_chest_press_machine_2"
        ],
        "Cable Crossover": [
            "exercise_cable_crossover_1",
            "exercise_cable_crossover_2"
        ],
        "Push-Ups": [
            "exercise_push_ups_1",
            "exercise_push_ups_2"
        ],
        "Incline Push-Ups": [
            "exercise_incline_push_ups_1",
            "exercise_incline_push_ups_2"
        ],
        "Chest Dips": [
            "exercise_chest_dips_1",
            "exercise_chest_dips_2"
        ],
        "Smith Machine Bench Press": [
            "exercise_smith_machine_bench_press_1",
            "exercise_smith_machine_bench_press_2"
        ],
        
        // Back exercises
        "Pull-Ups": [
            "exercise_pull_ups_1",
            "exercise_pull_ups_2"
        ],
        "Chin-Ups": [
            "exercise_chin_ups_1",
            "exercise_chin_ups_2"
        ],
        "Wide-Grip Pull-Ups": [
            "exercise_wide_grip_pull_ups_1",
            "exercise_wide_grip_pull_ups_2"
        ],
        "Lat Pulldown": [
            "exercise_lat_pulldown_1",
            "exercise_lat_pulldown_2"
        ],
        "Close-Grip Pulldown": [
            "exercise_close_grip_pulldown_1",
            "exercise_close_grip_pulldown_2"
        ],
        "Barbell Row": [
            "exercise_barbell_row_1",
            "exercise_barbell_row_2"
        ],
        "Pendlay Row": [
            "exercise_pendlay_row_1",
            "exercise_pendlay_row_2"
        ],
        "Dumbbell Row": [
            "exercise_dumbbell_row_1",
            "exercise_dumbbell_row_2"
        ],
        "T-Bar Row": [
            "exercise_t_bar_row_1",
            "exercise_t_bar_row_2"
        ],
        "Seal Row": [
            "exercise_seal_row_1",
            "exercise_seal_row_2"
        ],
        "Seated Cable Row": [
            "exercise_seated_cable_row_1",
            "exercise_seated_cable_row_2"
        ],
        "Meadows Row": [
            "exercise_meadows_row_1",
            "exercise_meadows_row_2"
        ],
        "Reverse Fly Machine": [
            "exercise_reverse_fly_machine_1",
            "exercise_reverse_fly_machine_2"
        ],
        "Face Pulls": [
            "exercise_face_pulls_1",
            "exercise_face_pulls_2"
        ],
        
        // Legs exercises
        "Squats": ["exercise_squats"],
        "Deadlifts": ["exercise_deadlifts"],
        "Conventional Deadlift": [
            "exercise_conventional_deadlift"
        ],
        "Sumo Deadlift": [
            "exercise_sumo_deadlift"
        ],
        "Trap Bar Deadlift": [
            "exercise_trap_bar_deadlift"
        ],
        "Clean and Press": [
            "exercise_clean_and_press"
        ],
        "Power Clean": [
            "exercise_power_clean"
        ],
        "Snatch": [
            "exercise_snatch"
        ],
        "Push Press": [
            "exercise_push_press"
        ],
        "Thrusters": [
            "exercise_thrusters"
        ],
        "Kettlebell Swing": [
            "exercise_kettlebell_swing"
        ],
        "Burpee Pull-Up": [
            "exercise_burpee_pull_up"
        ],
        "Man Makers": [
            "exercise_man_makers"
        ],
        "Yoke Carry": [
            "exercise_yoke_carry"
        ],
        "Turkish Get-Up": [
            "exercise_turkish_get_up"
        ],
        "Back Squat": [
            "exercise_back_squat_1",
            "exercise_back_squat_2"
        ],
        "Front Squat": [
            "exercise_front_squat_1",
            "exercise_front_squat_2"
        ],
        "Goblet Squat": [
            "exercise_goblet_squat_1",
            "exercise_goblet_squat_2"
        ],
        "Box Squat": [
            "exercise_box_squat_1",
            "exercise_box_squat_2"
        ],
        "Bulgarian Split Squat": [
            "exercise_bulgarian_split_squat_1",
            "exercise_bulgarian_split_squat_2"
        ],
        "Lunges": [
            "exercise_lunges_1",
            "exercise_lunges_2"
        ],
        "Step-Ups": [
            "exercise_step_ups_1",
            "exercise_step_ups_2"
        ],
        "Leg Press": [
            "exercise_leg_press_1",
            "exercise_leg_press_2"
        ],
        "Hack Squat": [
            "exercise_hack_squat_1",
            "exercise_hack_squat_2"
        ],
        "Romanian Deadlift": [
            "exercise_romanian_deadlift_1",
            "exercise_romanian_deadlift_2"
        ],
        "Stiff-Leg Deadlift": [
            "exercise_stiff_leg_deadlift_1",
            "exercise_stiff_leg_deadlift_2"
        ],
        "Glute Bridge": [
            "exercise_glute_bridge_1",
            "exercise_glute_bridge_2"
        ],
        "Hip Thrust": [
            "exercise_hip_thrust_1",
            "exercise_hip_thrust_2"
        ],
        "Leg Extension": [
            "exercise_leg_extension_1",
            "exercise_leg_extension_2"
        ],
        "Leg Curl Machine": [
            "exercise_leg_curl_machine_1",
            "exercise_leg_curl_machine_2"
        ],
        "Leg Curls": ["exercise_leg_curls"],
        "Nordic Curl": [
            "exercise_nordic_curl_1",
            "exercise_nordic_curl_2"
        ],
        "Standing Calf Raises": [
            "exercise_standing_calf_raises_1",
            "exercise_standing_calf_raises_2"
        ],
        "Seated Calf Raises": [
            "exercise_seated_calf_raises_1",
            "exercise_seated_calf_raises_2"
        ],
        "Donkey Calf Raises": [
            "exercise_donkey_calf_raises_1",
            "exercise_donkey_calf_raises_2"
        ],
        
        // Shoulders exercises
        "Overhead Press": [
            "exercise_overhead_press_1",
            "exercise_overhead_press_2"
        ],
        "Seated Overhead Press": [
            "exercise_seated_overhead_press_1",
            "exercise_seated_overhead_press_2"
        ],
        "Dumbbell Shoulder Press": [
            "exercise_dumbbell_shoulder_press_1",
            "exercise_dumbbell_shoulder_press_2"
        ],
        "Arnold Press": [
            "exercise_arnold_press_1",
            "exercise_arnold_press_2"
        ],
        "Military Press": [
            "exercise_military_press_1",
            "exercise_military_press_2"
        ],
        "Lateral Raises": [
            "exercise_lateral_raises_1",
            "exercise_lateral_raises_2"
        ],
        "Front Raises": [
            "exercise_front_raises_1",
            "exercise_front_raises_2"
        ],
        "Rear Delt Fly": [
            "exercise_rear_delt_fly_1",
            "exercise_rear_delt_fly_2"
        ],
        "Reverse Pec Deck": [
            "exercise_reverse_pec_deck_1",
            "exercise_reverse_pec_deck_2"
        ],
        "Upright Row": [
            "exercise_upright_row_1",
            "exercise_upright_row_2"
        ],
        "Dumbbell Shrugs": [
            "exercise_dumbbell_shrugs_1",
            "exercise_dumbbell_shrugs_2"
        ],
        "Barbell Shrugs": [
            "exercise_barbell_shrugs_1",
            "exercise_barbell_shrugs_2"
        ],
        "Cable Lateral Raises": [
            "exercise_cable_lateral_raises_1",
            "exercise_cable_lateral_raises_2"
        ],
        
        // Arms exercises
        "Bicep Curls": [
            "exercise_bicep_curls_1",
            "exercise_bicep_curls_2"
        ],
        "Barbell Curls": [
            "exercise_barbell_curls_1",
            "exercise_barbell_curls_2"
        ],
        "EZ Bar Curls": [
            "exercise_ez_bar_curls_1",
            "exercise_ez_bar_curls_2"
        ],
        "Incline Dumbbell Curls": [
            "exercise_incline_dumbbell_curls_1",
            "exercise_incline_dumbbell_curls_2"
        ],
        "Concentration Curls": [
            "exercise_concentration_curls_1",
            "exercise_concentration_curls_2"
        ],
        "Cable Curls": [
            "exercise_cable_curls_1",
            "exercise_cable_curls_2"
        ],
        "Preacher Curl": [
            "exercise_preacher_curl_1",
            "exercise_preacher_curl_2"
        ],
        "Spider Curl": [
            "exercise_spider_curl_1",
            "exercise_spider_curl_2"
        ],
        "Drag Curl": [
            "exercise_drag_curl_1",
            "exercise_drag_curl_2"
        ],
        "Tricep Dips": [
            "exercise_tricep_dips_1",
            "exercise_tricep_dips_2"
        ],
        "Bench Dips": [
            "exercise_bench_dips_1",
            "exercise_bench_dips_2"
        ],
        "Close Grip Bench Press": [
            "exercise_close_grip_bench_press_1",
            "exercise_close_grip_bench_press_2"
        ],
        "Skull Crushers": [
            "exercise_skull_crushers_1",
            "exercise_skull_crushers_2"
        ],
        "Tricep Pushdowns": [
            "exercise_tricep_pushdowns_1",
            "exercise_tricep_pushdowns_2"
        ],
        "Overhead Tricep Extension": [
            "exercise_overhead_tricep_extension_1",
            "exercise_overhead_tricep_extension_2"
        ],
        "Dumbbell Kickbacks": [
            "exercise_dumbbell_kickbacks_1",
            "exercise_dumbbell_kickbacks_2"
        ],
        "JM Press": [
            "exercise_jm_press_1",
            "exercise_jm_press_2"
        ],
        "Rope Overhead Extensions": [
            "exercise_rope_overhead_extensions_1",
            "exercise_rope_overhead_extensions_2"
        ],
        
        // Forearms / grip exercises
        "Wrist Curls": [
            "exercise_wrist_curls_1",
            "exercise_wrist_curls_2"
        ],
        "Reverse Wrist Curls": [
            "exercise_reverse_wrist_curls_1",
            "exercise_reverse_wrist_curls_2"
        ],
        "Hammer Curls": [
            "exercise_hammer_curls_1",
            "exercise_hammer_curls_2"
        ],
        "Reverse Curls": [
            "exercise_reverse_curls_1",
            "exercise_reverse_curls_2"
        ],
        "Behind-the-Back Wrist Curl": [
            "exercise_behind_the_back_wrist_curl_1",
            "exercise_behind_the_back_wrist_curl_2"
        ],
        "Farmer's Carry": [
            "exercise_farmers_carry_1",
            "exercise_farmers_carry_2"
        ],
        "Plate Pinch Hold": [
            "exercise_plate_pinch_hold_1",
            "exercise_plate_pinch_hold_2"
        ],
        "Zottman Curl": [
            "exercise_zottman_curl_1",
            "exercise_zottman_curl_2"
        ],
        "Grip Trainer Squeeze": [
            "exercise_grip_trainer_squeeze_1",
            "exercise_grip_trainer_squeeze_2"
        ],
        
        // Core exercises
        "Plank": [
            "exercise_plank_1",
            "exercise_plank_2"
        ],
        "Side Plank": [
            "exercise_side_plank_1",
            "exercise_side_plank_2"
        ],
        "Weighted Plank": [
            "exercise_weighted_plank_1",
            "exercise_weighted_plank_2"
        ],
        "Sit-Ups": [
            "exercise_sit_ups_1",
            "exercise_sit_ups_2"
        ],
        "Crunches": [
            "exercise_crunches_1",
            "exercise_crunches_2"
        ],
        "Cable Crunch": [
            "exercise_cable_crunch_1",
            "exercise_cable_crunch_2"
        ],
        "Russian Twists": [
            "exercise_russian_twists_1",
            "exercise_russian_twists_2"
        ],
        "Hanging Leg Raise": [
            "exercise_hanging_leg_raise_1",
            "exercise_hanging_leg_raise_2"
        ],
        "Lying Leg Raise": [
            "exercise_lying_leg_raise_1",
            "exercise_lying_leg_raise_2"
        ],
        "V-Ups": [
            "exercise_v_ups_1",
            "exercise_v_ups_2"
        ],
        "Mountain Climbers": [
            "exercise_mountain_climbers_1",
            "exercise_mountain_climbers_2"
        ],
        "Flutter Kicks": [
            "exercise_flutter_kicks_1",
            "exercise_flutter_kicks_2"
        ],
        "Bicycle Crunch": [
            "exercise_bicycle_crunch_1",
            "exercise_bicycle_crunch_2"
        ],
        "Ab Rollout (Wheel)": [
            "exercise_ab_rollout_wheel_1",
            "exercise_ab_rollout_wheel_2"
        ],
        "Stability Ball Rollout": [
            "exercise_stability_ball_rollout_1",
            "exercise_stability_ball_rollout_2"
        ],
        "Hollow Body Hold": [
            "exercise_hollow_body_hold_1",
            "exercise_hollow_body_hold_2"
        ],
        "Side Bend": [
            "exercise_side_bend_1",
            "exercise_side_bend_2"
        ],
        
        // Cardio exercises
        "Running": ["exercise_running"],
        "Cycling": ["exercise_cycling"],
        "Rowing": ["exercise_rowing"],
        
        // Recovery exercises
        "Stretching": ["exercise_stretching"],
        "Foam Rolling": ["exercise_foam_rolling"]
    ]
    
    /// Primary (thumbnail) asset name per exercise — first pose frame.
    private var exerciseImageMap: [String: String] {
        Dictionary(uniqueKeysWithValues: exercisePoseMap.compactMap { name, frames in
            guard let first = frames.first else { return nil }
            return (name, first)
        })
    }
    
    // MARK: - Initialization
    
    private init() {
        preloadCommonImages()
    }
    
    // MARK: - Public Methods
    
    /// Gets the primary (thumbnail) image for a given exercise name
    /// - Parameter exerciseName: The name of the exercise
    /// - Returns: UIImage if found, nil if not available
    func getImage(for exerciseName: String) -> UIImage? {
        if let cachedImage = imageCache[exerciseName] {
            return cachedImage
        }
        
        if let assetName = exerciseImageMap[exerciseName],
           let image = UIImage(named: assetName) {
            imageCache[exerciseName] = image
            return image
        }
        
        return nil
    }
    
    /// Ordered pose frames for the detail preview carousel (crossfade + arrows).
    func getPoseFrames(for exerciseName: String) -> [UIImage] {
        if let cachedFrames = poseFramesCache[exerciseName] {
            return cachedFrames
        }
        
        let assetNames = exercisePoseMap[exerciseName] ?? []
        let frames = assetNames.compactMap { UIImage(named: $0) }
        if !frames.isEmpty {
            poseFramesCache[exerciseName] = frames
        }
        return frames
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
        !getPoseFrames(for: exerciseName).isEmpty
    }
    
    /// Gets the primary asset name for an exercise (for debugging/testing)
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
        poseFramesCache.removeAll()
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
