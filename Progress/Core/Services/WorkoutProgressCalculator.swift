import SwiftUI
import SwiftData
import Foundation

/// Comprehensive workout progress calculation service that transforms workout data
/// into personalized muscle group progress scores and visual feedback
@MainActor
class WorkoutProgressCalculator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var muscleGroupProgress: [MuscleGroup: ProgressTier] = [:]
    @Published var muscleGroupOpacity: [MuscleGroup: Double] = [:]
    @Published var isCalculating: Bool = false
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private var personalBaselines: [MuscleGroup: PersonalBaseline] = [:]
    private let calendar = Calendar.current
    
    // MARK: - Configuration Constants
    
    private struct Config {
        // Time decay rates (days until significant fade)
        static let strengthDecayDays: Double = 10.0
        static let cardioDecayDays: Double = 5.0
        
        // Progress tier thresholds (more realistic progression)
        // These represent consistency and improvement over time, not single workout spikes
        static let beginnerSparkThreshold: Double = 1.0    // First few workouts
        static let gettingTractionThreshold: Double = 3.0  // Building consistency (3-5 workouts)
        static let solidIntermediateThreshold: Double = 8.0 // Regular training (8-12 workouts)
        static let advancedThreshold: Double = 15.0        // Consistent improvement (15+ workouts)
        static let athleteTierThreshold: Double = 25.0     // Elite consistency (25+ workouts)
        
        // Volume calculation weights
        static let volumeWeight: Double = 0.7
        static let strengthWeight: Double = 0.3
        
        // Proxy load for bodyweight sets (push-ups, pull-ups, etc.) so weight-0 sets still score
        static let bodyweightProxyLoad: Double = 30.0
        
        // Impact per minute for duration-based sets (cardio, planks, wall sits)
        static let impactPerMinute: Double = 50.0
        
        // Minimum opacity for faded muscle groups
        static let minimumOpacity: Double = 0.3
        
        // Minimum workouts needed before advancing tiers
        static let minWorkoutsForTraction: Int = 3
        static let minWorkoutsForIntermediate: Int = 6
        static let minWorkoutsForAdvanced: Int = 12
        static let minWorkoutsForAthlete: Int = 20
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        Task {
            await initializeProgress()
        }
    }
    
    // MARK: - Public Methods
    
    /// Updates progress after workout completion
    func updateProgressAfterWorkout(_ workout: Workout) async {
        guard let modelContext = modelContext else { return }
        
        isCalculating = true
        defer { isCalculating = false }
        
        // Calculate impact scores for this workout
        let workoutImpact = calculateWorkoutImpact(workout)
        
        // Process workout impact silently
        
        // Update personal baselines with new data
        await updatePersonalBaselines(with: workoutImpact)
        
        // Recalculate all progress tiers
        await recalculateAllProgress()
        
        // Trigger satisfying reveal animation
        let affectedMuscleGroups = workoutImpact.keys.map { $0 }
        if !affectedMuscleGroups.isEmpty {
            await triggerRevealAnimation(for: affectedMuscleGroups)
        }
        
        // Progress update completed
    }
    
    /// Forces a complete recalculation of all progress
    func recalculateAllProgress() async {
        guard let context = modelContext else { return }
        
        isCalculating = true
        defer { isCalculating = false }
        
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        guard let allWorkouts = try? context.fetch(descriptor) else { return }
        let completedWorkouts = allWorkouts.filter { !$0.isDeleted && $0.status == .completed }
        
        calculatePersonalBaselines(from: completedWorkouts)
        
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentWorkouts = completedWorkouts.filter {
            ($0.completedAt ?? Date.distantPast) >= sevenDaysAgo
        }
        
        for muscleGroup in MuscleGroup.allCases {
            let recentImpact = calculateRecentImpact(for: muscleGroup, from: recentWorkouts)
            let progressTier = calculateProgressTier(impact: recentImpact, muscleGroup: muscleGroup)
            let opacity = calculateOpacity(for: muscleGroup, from: completedWorkouts)
            
            muscleGroupProgress[muscleGroup] = progressTier
            muscleGroupOpacity[muscleGroup] = opacity
        }
    }
    
    /// Gets current progress for a specific muscle group
    func getProgress(for muscleGroup: MuscleGroup) -> (tier: ProgressTier, opacity: Double) {
        let tier = muscleGroupProgress[muscleGroup] ?? .dormant
        let opacity = muscleGroupOpacity[muscleGroup] ?? Config.minimumOpacity
        return (tier, opacity)
    }
    
    // MARK: - Private Calculation Methods
    
    private func initializeProgress() async {
        // Initialize all muscle groups to dormant with minimum opacity
        for muscleGroup in MuscleGroup.allCases {
            muscleGroupProgress[muscleGroup] = .dormant
            muscleGroupOpacity[muscleGroup] = Config.minimumOpacity
        }
        
        // Calculate actual progress if we have data
        await recalculateAllProgress()
    }
    
    private func calculateWorkoutImpact(_ workout: Workout) -> [MuscleGroup: Double] {
        var muscleGroupImpacts: [MuscleGroup: Double] = [:]
        
        // Process each exercise in the workout
        for exercise in workout.exercises {
            // Try to classify the exercise if it doesn't have classifications
            if !exercise.hasMuscleGroupClassification {
                tryToClassifyExercise(exercise)
            }
            
            guard exercise.hasMuscleGroupClassification else { continue }
            
            let exerciseImpact = calculateExerciseImpact(exercise)
            if exerciseImpact == 0 { continue }
            
            // Distribute impact to muscle groups based on classification
            if let primaryMuscleGroup = exercise.primaryMuscleGroup {
                muscleGroupImpacts[primaryMuscleGroup, default: 0] += exerciseImpact
            }
            
            // Add secondary muscle group impacts
            for (secondaryGroup, intensity) in exercise.secondaryMuscleGroupsDecoded {
                let secondaryImpact = exerciseImpact * intensity
                muscleGroupImpacts[secondaryGroup, default: 0] += secondaryImpact
            }
        }
        
        // Workout impact calculated silently
        
        return muscleGroupImpacts
    }
    
    private func calculateExerciseImpact(_ exercise: Exercise) -> Double {
        let completedSets = exercise.sets.filter { $0.isCompleted }
        guard !completedSets.isEmpty else { return 0 }
        
        // Flexibility/recovery work doesn't contribute to body map progress
        guard exercise.effectiveExerciseType.contributesToMuscleGroups else { return 0 }
        
        var totalVolume: Double = 0
        var totalStrengthScore: Double = 0
        
        for set in completedSets {
            if set.reps > 0 {
                // Weighted or bodyweight strength set: use proxy load when no weight is logged
                let effectiveWeight = set.weight > 0 ? set.weight : Config.bodyweightProxyLoad
                let volume = Double(set.reps) * effectiveWeight
                totalVolume += volume
                totalStrengthScore += volume * 0.1
            } else if set.duration > 0 {
                // Duration-based set (cardio, planks, wall sits): score by minutes
                totalVolume += (set.duration / 60.0) * Config.impactPerMinute
            }
        }
        
        // Blend volume and strength with configurable weights
        let volumeComponent = totalVolume * Config.volumeWeight
        let strengthComponent = totalStrengthScore * Config.strengthWeight
        let totalImpact = volumeComponent + strengthComponent
        
        return totalImpact
    }
    
    private func calculatePersonalBaselines(from completedWorkouts: [Workout]) {
        for muscleGroup in MuscleGroup.allCases {
            let impacts = completedWorkouts.compactMap { workout -> Double? in
                let workoutImpact = calculateWorkoutImpact(workout)
                return workoutImpact[muscleGroup]
            }.filter { $0 > 0 }
            
            if !impacts.isEmpty {
                let averageImpact = impacts.reduce(0, +) / Double(impacts.count)
                let maxImpact = impacts.max() ?? 0
                
                personalBaselines[muscleGroup] = PersonalBaseline(
                    averageImpact: averageImpact,
                    maxImpact: maxImpact,
                    workoutCount: impacts.count,
                    lastUpdated: Date()
                )
            } else {
                personalBaselines[muscleGroup] = PersonalBaseline(
                    averageImpact: 0,
                    maxImpact: 0,
                    workoutCount: 0,
                    lastUpdated: Date()
                )
            }
        }
    }
    
    private func updatePersonalBaselines(with newImpacts: [MuscleGroup: Double]) async {
        // Update baselines with new workout data
        for (muscleGroup, impact) in newImpacts {
            if var baseline = personalBaselines[muscleGroup] {
                // Update rolling average
                let totalImpact = baseline.averageImpact * Double(baseline.workoutCount) + impact
                baseline.workoutCount += 1
                baseline.averageImpact = totalImpact / Double(baseline.workoutCount)
                baseline.maxImpact = max(baseline.maxImpact, impact)
                baseline.lastUpdated = Date()
                
                personalBaselines[muscleGroup] = baseline
            } else {
                // First workout for this muscle group
                personalBaselines[muscleGroup] = PersonalBaseline(
                    averageImpact: impact,
                    maxImpact: impact,
                    workoutCount: 1,
                    lastUpdated: Date()
                )
            }
        }
    }
    
    private func calculateRecentImpact(for muscleGroup: MuscleGroup, from recentWorkouts: [Workout]) -> Double {
        let impacts = recentWorkouts.compactMap { workout -> Double? in
            let workoutImpact = calculateWorkoutImpact(workout)
            let impact = workoutImpact[muscleGroup] ?? 0
            return impact > 0 ? impact : nil
        }
        
        return impacts.isEmpty ? 0 : impacts.reduce(0, +) / Double(impacts.count)
    }
    
    private func calculateProgressTier(impact: Double, muscleGroup: MuscleGroup) -> ProgressTier {
        // No recent activity = dormant
        guard impact > 0 else { return .dormant }
        
        // Get workout count and consistency for this muscle group
        let baseline = personalBaselines[muscleGroup]
        let workoutCount = baseline?.workoutCount ?? 0
        
        // Calculate consistency score (recent impact vs baseline, capped at reasonable levels)
        let consistencyMultiplier: Double
        if let baseline = baseline, baseline.averageImpact > 0 {
            let rawRatio = impact / baseline.averageImpact
            // Cap the multiplier to prevent single-workout spikes from dominating
            consistencyMultiplier = min(rawRatio, 2.0) // Max 2x baseline impact
        } else {
            consistencyMultiplier = 1.0 // First workout
        }
        
        // Calculate progress score based on workout count and consistency
        let progressScore = Double(workoutCount) * consistencyMultiplier
        
        // Determine tier based on progress score AND minimum workout requirements
        let tier: ProgressTier
        switch progressScore {
        case 0:
            tier = .dormant
        case 0..<Config.beginnerSparkThreshold:
            tier = .beginnerSpark
        case Config.beginnerSparkThreshold..<Config.gettingTractionThreshold:
            // Require minimum workouts for traction
            tier = workoutCount >= Config.minWorkoutsForTraction ? .gettingTraction : .beginnerSpark
        case Config.gettingTractionThreshold..<Config.solidIntermediateThreshold:
            // Require minimum workouts for intermediate
            tier = workoutCount >= Config.minWorkoutsForIntermediate ? .solidIntermediate : .gettingTraction
        case Config.solidIntermediateThreshold..<Config.advancedThreshold:
            // Require minimum workouts for advanced
            tier = workoutCount >= Config.minWorkoutsForAdvanced ? .advanced : .solidIntermediate
        default:
            // Require minimum workouts for athlete tier
            tier = workoutCount >= Config.minWorkoutsForAthlete ? .athleteTier : .advanced
        }
        
        return tier
    }
    
    private func calculateOpacity(for muscleGroup: MuscleGroup, from completedWorkouts: [Workout]) -> Double {
        for workout in completedWorkouts {
            let workoutImpact = calculateWorkoutImpact(workout)
            if (workoutImpact[muscleGroup] ?? 0) > 0 {
                let workoutDate = workout.completedAt ?? workout.createdAt
                let daysSinceWorkout = calendar.dateComponents([.day], from: workoutDate, to: Date()).day ?? 0
                let decayRate = muscleGroup.isStrengthTraining ? Config.strengthDecayDays : Config.cardioDecayDays
                
                return max(Config.minimumOpacity, 1.0 - (Double(daysSinceWorkout) / decayRate))
            }
        }
        
        return Config.minimumOpacity
    }
    
    private func triggerRevealAnimation(for muscleGroups: [MuscleGroup]) async {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        let completedWorkouts = (try? context.fetch(descriptor).filter { !$0.isDeleted && $0.status == .completed }) ?? []
        
        for muscleGroup in muscleGroups {
            muscleGroupOpacity[muscleGroup] = 0.1
            
            withAnimation(.easeOut(duration: 0.8).delay(Double.random(in: 0...0.3))) {
                muscleGroupOpacity[muscleGroup] = calculateOpacity(for: muscleGroup, from: completedWorkouts)
            }
        }
    }
}

// MARK: - Supporting Types

/// Personal baseline data for a specific muscle group
private struct PersonalBaseline {
    var averageImpact: Double
    var maxImpact: Double
    var workoutCount: Int
    var lastUpdated: Date
}

// MARK: - Extensions

extension WorkoutProgressCalculator {
    /// Convenience method to set model context
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await recalculateAllProgress()
        }
    }
    
    /// Gets summary statistics for debugging
    func getProgressSummary() -> String {
        var summary = "=== Workout Progress Summary ===\n"
        
        for muscleGroup in MuscleGroup.allCases {
            let progress = getProgress(for: muscleGroup)
            let baseline = personalBaselines[muscleGroup]
            
            summary += "\(muscleGroup.displayName):\n"
            summary += "  Tier: \(progress.tier.displayName)\n"
            summary += "  Opacity: \(String(format: "%.2f", progress.opacity))\n"
            
            if let baseline = baseline {
                summary += "  Baseline: \(String(format: "%.1f", baseline.averageImpact)) (avg), \(String(format: "%.1f", baseline.maxImpact)) (max)\n"
                summary += "  Workouts: \(baseline.workoutCount)\n"
            }
            summary += "\n"
        }
        
        return summary
    }
    
    /// Debug method to check exercise classifications (disabled for clean logs)
    func debugExerciseClassifications(_ workout: Workout) {
        // Debug logging disabled for cleaner console output
    }
    
    /// Attempts to classify an exercise using the ExerciseClassificationService
    private func tryToClassifyExercise(_ exercise: Exercise) {
        guard let classification = ExerciseClassificationService.exerciseClassifications[exercise.name] else {
            return
        }
        
        // Apply the classification
        exercise.updateMuscleGroupClassification(
            primary: classification.primaryMuscleGroup,
            secondary: classification.secondaryMuscleGroups,
            classification: classification.exerciseType
        )
    }
}
