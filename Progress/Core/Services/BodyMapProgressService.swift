import SwiftUI
import SwiftData
import Foundation

/// Service that manages body map progress updates and real-time integration
/// with workout completion flow
@MainActor
class BodyMapProgressService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentProgress: [MuscleGroup: ProgressTier] = [:]
    @Published var currentOpacity: [MuscleGroup: Double] = [:]
    @Published var isUpdating: Bool = false
    @Published var lastUpdateDate: Date = Date()
    
    // MARK: - Private Properties
    
    private var progressCalculator: WorkoutProgressCalculator
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        self.progressCalculator = WorkoutProgressCalculator(modelContext: modelContext)
        
        // Subscribe to calculator updates
        setupCalculatorBinding()
        
        // Initialize progress
        Task {
            await loadInitialProgress()
        }
    }
    
    // MARK: - Public Methods
    
    /// Updates progress after a workout is completed
    func handleWorkoutCompletion(_ workout: Workout) async {
        isUpdating = true
        defer { isUpdating = false }
        
        // Update progress through calculator
        await progressCalculator.updateProgressAfterWorkout(workout)
        
        // Update last update timestamp
        lastUpdateDate = Date()
    }
    
    /// Forces a refresh of all progress data
    func refreshProgress() async {
        isUpdating = true
        defer { isUpdating = false }
        
        await progressCalculator.recalculateAllProgress()
        lastUpdateDate = Date()
    }
    
    /// Gets current progress for a specific muscle group
    func getProgress(for muscleGroup: MuscleGroup) -> (tier: ProgressTier, opacity: Double) {
        return progressCalculator.getProgress(for: muscleGroup)
    }
    
    /// Sets the model context for data access
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        progressCalculator.setModelContext(context)
    }
    
    /// Gets progress data formatted for BodyMapView
    func getBodyMapProgress() -> [MuscleGroup: ProgressTier] {
        return currentProgress
    }
    
    /// Gets opacity data for time-based fading
    func getBodyMapOpacity() -> [MuscleGroup: Double] {
        return currentOpacity
    }
    
    // MARK: - Private Methods
    
    private func setupCalculatorBinding() {
        // Observe calculator changes and update our published properties
        progressCalculator.$muscleGroupProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentProgress)
        
        progressCalculator.$muscleGroupOpacity
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentOpacity)
    }
    
    private func loadInitialProgress() async {
        // Load initial progress state
        await progressCalculator.recalculateAllProgress()
    }
}

// MARK: - Singleton Access

extension BodyMapProgressService {
    /// Shared instance for app-wide access
    static let shared = BodyMapProgressService()
    
    /// Configure the shared instance with model context
    static func configure(with modelContext: ModelContext) {
        shared.setModelContext(modelContext)
    }
}
