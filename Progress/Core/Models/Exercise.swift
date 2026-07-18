//
//  Exercise.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import SwiftData

// MARK: - ExerciseSetSnapshot

@Model
final class ExerciseSetSnapshot {
    var id: UUID
    var order: Int
    var weight: Double
    var reps: Int
    var duration: TimeInterval
    var distance: Double
    var isCompleted: Bool
    var completedAt: Date?
    var notes: String?
    
    /// The exercise this snapshot belongs to
    var exercise: Exercise?
    
    init(from set: ExerciseSet) {
        self.id = UUID()
        self.order = set.order
        self.weight = set.weight
        self.reps = set.reps
        self.duration = set.duration
        self.distance = set.distance
        self.isCompleted = set.isCompleted
        self.completedAt = set.completedAt
        self.notes = set.notes
    }
}

@Model
final class Exercise {
    
    // MARK: - Properties
    
    /// Unique identifier for the exercise
    var id: UUID
    
    /// Name of the exercise (e.g., "Bench Press", "Running")
    var name: String
    
    /// Type of exercise (resistance, cardio, recovery)
    var type: ExerciseType
    
    /// Category for organization (e.g., "Chest", "Legs")
    var category: String?
    
    /// Optional notes about the exercise
    var notes: String?
    
    /// Order of this exercise in the workout
    var order: Int
    
    /// When this exercise was created
    var createdAt: Date
    
    // MARK: - Rest Timer Properties
    
    /// Recommended rest time between sets (in seconds)
    var restTime: TimeInterval
    
    /// When the last set was completed (for rest timer)
    var lastSetCompletedAt: Date?
    
    /// Whether this exercise is hidden from workout summary progression
    var isHidden: Bool
    
    // MARK: - Completion Snapshot Properties
    
    /// Snapshot of completion state when workout was completed (persists after reset)
    var wasCompletedInLastWorkout: Bool
    
    /// Snapshot of completed sets count when workout was completed
    var completedSetsSnapshot: Int
    
    // MARK: - Database Integration Properties
    
    /// Whether this is a custom exercise (true) or predefined exercise (false)
    var isCustom: Bool
    
    /// ID linking to predefined exercise in ExerciseDatabase (nil for custom exercises)
    var predefinedExerciseId: String?
    
    // MARK: - Muscle Group Classification Properties
    
    /// Primary muscle group targeted by this exercise
    var primaryMuscleGroup: MuscleGroup?
    
    /// Secondary muscle groups with intensity percentages (0.0 to 1.0)
    var secondaryMuscleGroups: Data?
    
    /// Exercise classification type (strength, cardio, flexibility)
    var exerciseClassification: ExerciseType?
    
    // MARK: - Training Plan Baseline Properties
    
    /// Baseline weight in kg for plan progression (nil if not part of a plan)
    var baselineWeightKg: Double?
    
    /// Baseline reps for plan progression
    var baselineReps: Int?
    
    /// Baseline duration in seconds for timed plan exercises
    var baselineDurationSec: Double?
    
    /// Baseline set count for plan progression (session 1 set count)
    var baselineSetCount: Int?
    
    // MARK: - Relationships
    
    /// The workout this exercise belongs to
    var workout: Workout?
    
    /// All sets for this exercise
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]
    
    /// Snapshot of sets from last workout completion
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSetSnapshot.exercise)
    var setsSnapshot: [ExerciseSetSnapshot]
    
    // MARK: - Computed Properties
    
    /// Whether this exercise is currently in rest period
    var isInRestPeriod: Bool {
        guard let lastCompleted = lastSetCompletedAt else { return false }
        return Date().timeIntervalSince(lastCompleted) < restTime
    }
    
    /// Remaining rest time in seconds
    var remainingRestTime: TimeInterval {
        guard let lastCompleted = lastSetCompletedAt else { return 0 }
        let elapsed = Date().timeIntervalSince(lastCompleted)
        return max(0, restTime - elapsed)
    }
    
    /// Total volume for resistance exercises (weight × reps × sets)
    var totalVolume: Double {
        guard type == .resistance else { return 0 }
        return sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    /// Total duration for cardio exercises
    var totalDuration: TimeInterval {
        guard type == .cardio else { return 0 }
        return sets.reduce(0.0) { $0 + $1.duration }
    }
    
    /// Number of completed sets
    var completedSetsCount: Int {
        sets.filter { $0.isCompleted }.count
    }
    
    /// Whether all sets are completed
    var isCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
    }
    
    /// Get the predefined exercise from the database if this is a predefined exercise
    /// Note: This is a synchronous lookup that searches the static data
    var predefinedExercise: ExerciseDatabase.PredefinedExercise? {
        guard !isCustom, let exerciseId = predefinedExerciseId else { return nil }
        // Use direct static method to avoid actor isolation issues
        return ExerciseDatabase.findExerciseStatic(named: exerciseId)
    }
    
    /// Whether this exercise has an associated image (for future image support)
    var hasImage: Bool {
        predefinedExercise?.imageName != nil
    }
    
    // MARK: - Muscle Group Computed Properties
    
    /// Decoded secondary muscle groups with intensity percentages
    var secondaryMuscleGroupsDecoded: MuscleGroupIntensity {
        get {
            guard let data = secondaryMuscleGroups else { return [:] }
            do {
                return try JSONDecoder().decode(MuscleGroupIntensity.self, from: data)
            } catch {
                print("Failed to decode secondary muscle groups: \(error)")
                return [:]
            }
        }
        set {
            do {
                secondaryMuscleGroups = try JSONEncoder().encode(newValue)
            } catch {
                print("Failed to encode secondary muscle groups: \(error)")
                secondaryMuscleGroups = nil
            }
        }
    }
    
    /// All muscle groups involved in this exercise (primary + secondary)
    var allMuscleGroups: [MuscleGroup] {
        var groups: [MuscleGroup] = []
        if let primary = primaryMuscleGroup {
            groups.append(primary)
        }
        groups.append(contentsOf: secondaryMuscleGroupsDecoded.keys)
        return Array(Set(groups)) // Remove duplicates
    }
    
    /// Whether this exercise has muscle group classifications
    var hasMuscleGroupClassification: Bool {
        return primaryMuscleGroup != nil || !secondaryMuscleGroupsDecoded.isEmpty
    }
    
    /// The effective exercise type for muscle group calculations
    var effectiveExerciseType: ExerciseType {
        return exerciseClassification ?? type
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        type: ExerciseType,
        category: String? = nil,
        notes: String? = nil,
        order: Int = 0,
        restTime: TimeInterval = 60, // Default 60 seconds rest
        isHidden: Bool = false, // Default to visible
        isCustom: Bool = true, // Default to custom for backward compatibility
        predefinedExerciseId: String? = nil, // Default to nil for custom exercises
        primaryMuscleGroup: MuscleGroup? = nil,
        secondaryMuscleGroups: MuscleGroupIntensity? = nil,
        exerciseClassification: ExerciseType? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.category = category
        self.notes = notes
        self.order = order
        self.restTime = restTime
        self.isHidden = isHidden
        self.isCustom = isCustom
        self.predefinedExerciseId = predefinedExerciseId
        self.primaryMuscleGroup = primaryMuscleGroup
        self.exerciseClassification = exerciseClassification
        self.createdAt = Date()
        self.sets = []
        self.wasCompletedInLastWorkout = false
        self.completedSetsSnapshot = 0
        self.setsSnapshot = []
        
        // Encode secondary muscle groups
        if let secondaryMuscleGroups = secondaryMuscleGroups {
            do {
                self.secondaryMuscleGroups = try JSONEncoder().encode(secondaryMuscleGroups)
            } catch {
                print("Failed to encode secondary muscle groups: \(error)")
                self.secondaryMuscleGroups = nil
            }
        } else {
            self.secondaryMuscleGroups = nil
        }
    }
    
    /// Convenience initializer for predefined exercises from ExerciseDatabase
    convenience init(
        predefinedExercise: ExerciseDatabase.PredefinedExercise,
        order: Int = 0,
        notes: String? = nil,
        restTime: TimeInterval? = nil,
        isHidden: Bool = false
    ) {
        // Map predefined exercise category to ExerciseType
        let exerciseType: ExerciseType
        switch predefinedExercise.category.lowercased() {
        case "resistance":
            exerciseType = .resistance
        case "cardio":
            exerciseType = .cardio
        case "recovery":
            exerciseType = .recovery
        default:
            exerciseType = .resistance // Default fallback
        }
        
        self.init(
            name: predefinedExercise.name,
            type: exerciseType,
            category: predefinedExercise.type, // Use the specific type (e.g., "Chest", "Running")
            notes: notes,
            order: order,
            restTime: restTime ?? exerciseType.defaultRestTime,
            isHidden: isHidden,
            isCustom: false, // This is a predefined exercise
            predefinedExerciseId: predefinedExercise.name // Use name as ID for now
        )
    }
    
    // MARK: - Methods
    
    /// Add a new set to this exercise
    func addSet(_ set: ExerciseSet) {
        set.order = sets.count
        sets.append(set)
        set.exercise = self
    }
    
    /// Remove a set from this exercise
    func removeSet(_ set: ExerciseSet) {
        if let index = sets.firstIndex(of: set) {
            sets.remove(at: index)
            // Reorder remaining sets
            for (newIndex, remainingSet) in sets.enumerated() {
                remainingSet.order = newIndex
            }
        }
    }
    
    /// Mark the current set as completed and start rest timer
    func completeSet() {
        lastSetCompletedAt = Date()
    }
    
    // MARK: - Muscle Group Methods
    
    /// Updates the muscle group classification for this exercise
    func updateMuscleGroupClassification(
        primary: MuscleGroup?,
        secondary: MuscleGroupIntensity? = nil,
        classification: ExerciseType? = nil
    ) {
        self.primaryMuscleGroup = primary
        self.exerciseClassification = classification
        
        if let secondary = secondary {
            self.secondaryMuscleGroupsDecoded = secondary
        }
    }
    
    /// Gets the intensity for a specific muscle group (1.0 for primary, percentage for secondary)
    func intensityForMuscleGroup(_ muscleGroup: MuscleGroup) -> Double {
        if primaryMuscleGroup == muscleGroup {
            return 1.0
        }
        return secondaryMuscleGroupsDecoded[muscleGroup] ?? 0.0
    }
    
    /// Calculates the total volume contribution for a specific muscle group
    func volumeContributionForMuscleGroup(_ muscleGroup: MuscleGroup) -> Double {
        let intensity = intensityForMuscleGroup(muscleGroup)
        guard intensity > 0 else { return 0.0 }
        
        switch effectiveExerciseType {
        case .strength, .resistance:
            return totalVolume * intensity
        case .cardio:
            // For cardio, use duration as "volume"
            return totalDuration * intensity
        case .flexibility, .recovery:
            // Flexibility doesn't contribute to muscle group progress
            return 0.0
        }
    }
    
    /// Toggle the hidden state of this exercise
    func toggleHidden() {
        let wasHidden = isHidden
        isHidden.toggle()
        print("🔄 Exercise '\(name)' toggled: \(wasHidden ? "hidden" : "visible") → \(isHidden ? "hidden" : "visible")")
        print("   SwiftData will persist this change on next save")
    }
    
    /// Set the hidden state of this exercise
    func setHidden(_ hidden: Bool) {
        let wasHidden = isHidden
        isHidden = hidden
        if wasHidden != hidden {
            print("🔄 Exercise '\(name)' set to: \(hidden ? "hidden" : "visible") (was \(wasHidden ? "hidden" : "visible"))")
            print("   SwiftData will persist this change on next save")
        }
    }
    
    /// Create a snapshot of the current completion state before reset
    func createCompletionSnapshot() {
        print("📸 Creating completion snapshot for exercise '\(name)'")
        
        // Save current completion state
        wasCompletedInLastWorkout = isCompleted
        completedSetsSnapshot = completedSetsCount
        
        // Clear existing snapshots
        setsSnapshot.removeAll()
        
        // Create snapshots of all sets
        for set in sets {
            let snapshot = ExerciseSetSnapshot(from: set)
            snapshot.exercise = self
            setsSnapshot.append(snapshot)
        }
        
        print("   Completion state: \(wasCompletedInLastWorkout)")
        print("   Completed sets: \(completedSetsSnapshot)/\(sets.count)")
        print("   Snapshots created: \(setsSnapshot.count)")
    }
    
    /// Get the default set based on exercise type
    func createDefaultSet() -> ExerciseSet {
        switch type {
        case .resistance, .strength:
            return ExerciseSet(weight: 0, reps: 8, order: sets.count)
        case .cardio:
            return ExerciseSet(duration: 300, distance: 0, order: sets.count) // 5 minutes default
        case .recovery, .flexibility:
            return ExerciseSet(duration: 60, order: sets.count) // 1 minute default
        }
    }
    
    /// Duplicate this exercise for templates
    func duplicate() -> Exercise {
        let newExercise = Exercise(
            name: name,
            type: type,
            category: category,
            notes: notes,
            order: order,
            restTime: restTime,
            isHidden: isHidden,
            isCustom: isCustom,
            predefinedExerciseId: predefinedExerciseId
        )
        
        newExercise.baselineWeightKg = baselineWeightKg
        newExercise.baselineReps = baselineReps
        newExercise.baselineDurationSec = baselineDurationSec
        newExercise.baselineSetCount = baselineSetCount
        
        // Copy sets but mark them as not completed
        for set in sets {
            let newSet = set.duplicate()
            newExercise.addSet(newSet)
        }
        
        return newExercise
    }
}

// MARK: - Enums

enum ExerciseType: String, CaseIterable, Codable {
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"
    
    // Legacy support for existing data
    case resistance = "resistance"
    case recovery = "recovery"
    
    var displayName: String {
        switch self {
        case .strength, .resistance: return "Strength"
        case .cardio: return "Cardio"
        case .flexibility, .recovery: return "Flexibility"
        }
    }
    
    var icon: String {
        switch self {
        case .strength, .resistance: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility, .recovery: return "figure.flexibility"
        }
    }
    
    var color: String {
        switch self {
        case .strength, .resistance: return "blue"
        case .cardio: return "red"
        case .flexibility, .recovery: return "green"
        }
    }
    
    /// Default rest time for this exercise type
    var defaultRestTime: TimeInterval {
        switch self {
        case .strength, .resistance: return 90  // 90 seconds
        case .cardio: return 120     // 2 minutes
        case .flexibility, .recovery: return 30    // 30 seconds
        }
    }
    
    /// Modern cases only (excludes legacy cases to avoid duplicates in UI)
    static var modernCases: [ExerciseType] {
        return [.strength, .cardio, .flexibility]
    }
    
    /// Whether this exercise type contributes to muscle group progress
    var contributesToMuscleGroups: Bool {
        switch self {
        case .strength, .resistance: return true
        case .cardio: return true // Cardio contributes to cardio muscle group
        case .flexibility, .recovery: return false // Flexibility doesn't show on body map
        }
    }
    
    /// The primary muscle group category for this exercise type
    var primaryMuscleGroupCategory: MuscleGroup? {
        switch self {
        case .cardio: return .cardio
        case .strength, .resistance, .flexibility, .recovery: return nil // Determined by specific exercise
        }
    }
}