//
//  WorkoutDetailView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    let workout: Workout
    
    @State private var showingWorkoutMenu = false
    @State private var showingAddExercise = false
    @State private var showingRenameWorkout = false
    @State private var showingEditExercise: Exercise? = nil
    @State private var showingExerciseDetail: Exercise? = nil
    @State private var showingCompletionPopup = false
    @State private var showingSessionAdvancement = false
    @State private var advancedSessionIndex: Int?
    @State private var showingBlockRegeneration = false
    @State private var blockRegenerationOptions: BlockRegenerationOptions?

    private var preferredUnits: UnitSystem {
        users.first?.preferredUnits ?? .metric
    }

    private var fitnessGoal: FitnessGoal {
        users.first?.fitnessGoal ?? .generalFitness
    }

    private var isPlanWorkout: Bool {
        workout.trainingPlanId != nil
    }
    
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 10) {
                    Text(workout.name)
                        .font(.appScreenTitle)
                        .tracking(-0.5)
                        .foregroundColor(AppPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    Spacer(minLength: 0)

                    CircleIconButton(
                        systemName: "ellipsis",
                        style: .plain,
                        size: 40,
                        accessibilityLabel: "Workout options",
                        action: {
                            HapticFeedback.workoutButtonTap()
                            showingWorkoutMenu = true
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if isPlanWorkout {
                    planSessionHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                WorkoutProgressBar(
                    exercises: workout.exercises,
                    workout: workout,
                    onWorkoutCompleted: {
                        markWorkoutComplete()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                if workout.exercises.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()

                        Image(systemName: "dumbbell")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(AppPalette.muted)

                        VStack(spacing: 6) {
                            Text("No Exercises Yet")
                                .font(.appSectionTitle)
                                .foregroundColor(AppPalette.ink)

                            Text("Add your first exercise to get started")
                                .font(.appSubtitle)
                                .foregroundColor(AppPalette.muted)
                                .multilineTextAlignment(.center)
                        }

                        Button("Add Exercise") {
                            showingAddExercise = true
                        }
                        .buttonStyle(AppPillButtonStyle(.ink, .large))

                        Spacer()
                    }
                    .padding(.horizontal, 32)
                } else {
                    // Exercise list with popup overlay
                    ZStack {
                        List {
                            ForEach(workout.exercises.sorted { $0.order < $1.order }, id: \.id) { exercise in
                                ExerciseRowView(
                                    exercise: exercise,
                                    onEdit: {
                                        showingEditExercise = exercise
                                    },
                                    onTap: {
                                        showingExerciseDetail = exercise
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        deleteExercise(exercise)
                                    }
                                }
                            }
                            .onMove(perform: moveExercises)
                            
                            // Add some bottom padding
                            Color.clear
                                .frame(height: 100)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        
                        // Exercise detail popup - positioned within exercise list area
                        if let exercise = showingExerciseDetail {
                            ExerciseDetailPopup(
                                exercise: exercise,
                                onDismiss: {
                                    showingExerciseDetail = nil
                                },
                                onEdit: {
                                    showingExerciseDetail = nil
                                    showingEditExercise = exercise
                                }
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            WorkoutDetailPresentation.didAppear()
        }
        .onDisappear {
            WorkoutDetailPresentation.didDisappear()
        }
        .overlay(
            Group {
                if showingWorkoutMenu {
                    WorkoutMenuView(
                        workout: workout,
                        onRenameWorkout: {
                            showingRenameWorkout = true
                        },
                        onAddExercise: {
                            showingAddExercise = true
                        },
                        onMarkComplete: {
                            markWorkoutComplete()
                        },
                        onDismiss: {
                            showingWorkoutMenu = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(1000)
                }
                
                if showingAddExercise {
                    AddExerciseView(
                        workout: workout,
                        onExerciseAdded: { _ in
                            // Exercise will be added automatically via SwiftData observation
                        },
                        onDismiss: {
                            showingAddExercise = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(1000)
                }
                
                if showingRenameWorkout {
                    RenameWorkoutView(
                        workout: workout,
                        onWorkoutRenamed: {
                            // Navigation title will update automatically
                        },
                        onDismiss: {
                            showingRenameWorkout = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(1000)
                }
                
                if let exercise = showingEditExercise {
                    EditExerciseView(
                        exercise: exercise,
                        onExerciseUpdated: {
                            // Exercise will update automatically via SwiftData observation
                        },
                        onDismiss: {
                            showingEditExercise = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(1000)
                }
                
                if showingCompletionPopup {
                    WorkoutCompletionPopup(
                        workout: workout,
                        exercises: workout.exercises,
                        onConfirm: {
                            confirmWorkoutCompletion()
                        },
                        onDismiss: {
                            showingCompletionPopup = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(2000)
                }

                if showingSessionAdvancement, let sessionIndex = advancedSessionIndex {
                    PlanSessionAdvancementPopup(
                        workout: workout,
                        sessionIndex: sessionIndex,
                        phase: workout.planPhase ?? .baseline,
                        units: preferredUnits,
                        onDismiss: {
                            showingSessionAdvancement = false
                            advancedSessionIndex = nil
                            navigateToProgressAfterCompletion()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(3000)
                }

                if showingBlockRegeneration, let regenerationOptions = blockRegenerationOptions {
                    PlanBlockRegenerationPopup(
                        workoutName: workout.name,
                        options: regenerationOptions,
                        units: preferredUnits,
                        onConfirm: { levelUp in
                            confirmBlockRegeneration(levelUp: levelUp)
                        },
                        onDecline: {
                            showingBlockRegeneration = false
                            blockRegenerationOptions = nil
                            navigateToProgressAfterCompletion()
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(3000)
                }

            }
        )
        .animation(.easeInOut(duration: 0.3), value: showingWorkoutMenu)
        .animation(.easeInOut(duration: 0.3), value: showingAddExercise)
        .animation(.easeInOut(duration: 0.3), value: showingRenameWorkout)
        .animation(.easeInOut(duration: 0.3), value: showingEditExercise != nil)
        .animation(.easeInOut(duration: 0.3), value: showingCompletionPopup)
        .animation(.easeInOut(duration: 0.3), value: showingSessionAdvancement)
        .animation(.easeInOut(duration: 0.3), value: showingBlockRegeneration)
    }

    private var planSessionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let sessionIndex = workout.planSessionIndex {
                    Text("Session \(sessionIndex) of 5 · Block \(workout.planBlockNumber ?? 1)")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                }

                if workout.planPhase == .deload {
                    Text("Recovery / Deload")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(AppPalette.carbs)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppPalette.tint(AppPalette.carbs)))
                }

                Spacer()
            }

            if workout.planPhase == .deload {
                Text("Lighter loads and fewer sets — recover before your next block.")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
            }
        }
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete exercise: \(error)")
        }
    }

    private func deleteExercises(offsets: IndexSet) {
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }
        for index in offsets {
            deleteExercise(sortedExercises[index])
        }
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sortedExercises = workout.exercises.sorted { $0.order < $1.order }
        sortedExercises.move(fromOffsets: source, toOffset: destination)
        
        for (index, exercise) in sortedExercises.enumerated() {
            exercise.order = index
        }
        
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to reorder exercises: \(error)")
            #endif
        }
    }
    
    private func markWorkoutComplete() {
        showingCompletionPopup = true
    }
    
    private func confirmWorkoutCompletion() {
        let completedSessionIndex = workout.planSessionIndex
        let historicalWorkout = createHistoricalWorkout()
        modelContext.insert(historicalWorkout)
        resetWorkoutForReuse()

        var didAdvanceSession = false
        var shouldOfferBlockRegeneration = false

        do {
            try modelContext.save()

            if isPlanWorkout {
                let service = TrainingPlanService(modelContext: modelContext)
                if completedSessionIndex == 5 {
                    blockRegenerationOptions = service.blockRegenerationOptions(
                        for: workout,
                        goal: fitnessGoal
                    )
                    shouldOfferBlockRegeneration = true
                } else if let newSessionIndex = try service.advanceSession(workout) {
                    advancedSessionIndex = newSessionIndex
                    didAdvanceSession = true
                }
            }

            Task {
                await BodyMapProgressService.shared.handleWorkoutCompletion(historicalWorkout)
            }
        } catch {
            #if DEBUG
            print("Failed to save historical workout: \(error)")
            #endif
        }

        showingCompletionPopup = false

        if shouldOfferBlockRegeneration {
            showingBlockRegeneration = true
        } else if didAdvanceSession {
            showingSessionAdvancement = true
        } else {
            navigateToProgressAfterCompletion()
        }
    }

    private func confirmBlockRegeneration(levelUp: Bool) {
        do {
            let service = TrainingPlanService(modelContext: modelContext)
            try service.regenerateBlock(workout, levelUp: levelUp, goal: fitnessGoal)
            advancedSessionIndex = 1
            showingBlockRegeneration = false
            blockRegenerationOptions = nil
            showingSessionAdvancement = true
        } catch {
            #if DEBUG
            print("Failed to regenerate block: \(error)")
            #endif
            showingBlockRegeneration = false
            blockRegenerationOptions = nil
            navigateToProgressAfterCompletion()
        }
    }

    private func navigateToProgressAfterCompletion() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: .navigateToProgress, object: nil)
        }
    }
    
    private func createHistoricalWorkout() -> Workout {
        // Create a new workout for history
        let historicalWorkout = Workout(
            name: workout.name,
            notes: workout.notes,
            isTemplate: false
        )
        
        // Set completion status and time
        historicalWorkout.status = .completed
        historicalWorkout.completedAt = Date()
        historicalWorkout.startedAt = workout.startedAt
        historicalWorkout.planSessionIndex = workout.planSessionIndex
        historicalWorkout.planBlockNumber = workout.planBlockNumber
        historicalWorkout.planPhase = workout.planPhase
        historicalWorkout.trainingPlanId = workout.trainingPlanId
        historicalWorkout.sourceWorkoutId = workout.id
        
        // Creating historical exercises
        
        // Create historical exercises for any exercise that has at least one completed set
        for originalExercise in workout.exercises {
            let completedSets = originalExercise.sets.filter { $0.isCompleted }
            
            if !completedSets.isEmpty {
                // Create historical exercise
                let historicalExercise = Exercise(
                    name: originalExercise.name,
                    type: originalExercise.type,
                    category: originalExercise.category,
                    notes: originalExercise.notes,
                    order: originalExercise.order,
                    restTime: originalExercise.restTime,
                    isHidden: originalExercise.isHidden,
                    isCustom: originalExercise.isCustom,
                    predefinedExerciseId: originalExercise.predefinedExerciseId,
                    primaryMuscleGroup: originalExercise.primaryMuscleGroup
                )
                
                // Copy muscle group classifications after creation
                historicalExercise.secondaryMuscleGroups = originalExercise.secondaryMuscleGroups
                historicalExercise.exerciseClassification = originalExercise.exerciseClassification
                historicalExercise.baselineWeightKg = originalExercise.baselineWeightKg
                historicalExercise.baselineReps = originalExercise.baselineReps
                historicalExercise.baselineDurationSec = originalExercise.baselineDurationSec
                historicalExercise.baselineSetCount = originalExercise.baselineSetCount
                
                // Set completion snapshot data
                historicalExercise.wasCompletedInLastWorkout = originalExercise.isCompleted
                historicalExercise.completedSetsSnapshot = completedSets.count
                
                // Copy ALL sets (both completed and incomplete) as actual ExerciseSet objects
                for originalSet in originalExercise.sets {
                    let historicalSet = ExerciseSet(
                        weight: originalSet.weight ?? 0,
                        reps: originalSet.reps,
                        duration: originalSet.duration,
                        distance: originalSet.distance ?? 0,
                        order: originalSet.order
                    )
                    
                    // Set additional properties after initialization
                    historicalSet.intensityLevel = originalSet.intensityLevel
                    historicalSet.isCompleted = originalSet.isCompleted
                    historicalSet.completedAt = originalSet.completedAt
                    historicalSet.notes = originalSet.notes
                    historicalSet.targetWeight = originalSet.targetWeight
                    historicalSet.targetReps = originalSet.targetReps
                    historicalSet.targetDuration = originalSet.targetDuration
                    historicalSet.exercise = historicalExercise
                    
                    historicalExercise.sets.append(historicalSet)
                    modelContext.insert(historicalSet)
                    
                    // Also create snapshots for historical tracking
                    let snapshot = ExerciseSetSnapshot(from: originalSet)
                    snapshot.exercise = historicalExercise
                    historicalExercise.setsSnapshot.append(snapshot)
                    modelContext.insert(snapshot)
                }
                
                // Add exercise to historical workout
                historicalWorkout.addExercise(historicalExercise)
                modelContext.insert(historicalExercise)
            }
        }
        
        // Historical workout created
        return historicalWorkout
    }
    
    private func resetWorkoutForReuse() {
        // Reset all exercise sets to uncompleted state for future use
        for exercise in workout.exercises {
            for set in exercise.sets {
                set.reset()
            }
            // Reset exercise completion tracking
            exercise.lastSetCompletedAt = nil
        }
        
        // Reset workout status but keep it as a template for reuse
        workout.status = .planned
        workout.startedAt = nil
        workout.completedAt = nil
    }
}

/// Tracks how many workout screens are visible so a closing screen cannot
/// tell the tab bar that every workout is gone while another is opening.
@MainActor
private enum WorkoutDetailPresentation {
    private static var visibleCount = 0

    static func didAppear() {
        visibleCount += 1
        NotificationCenter.default.post(name: .showWorkoutDetail, object: nil)
    }

    static func didDisappear() {
        visibleCount = max(0, visibleCount - 1)
        guard visibleCount == 0 else { return }
        guard !DeepLinkService.shared.isDeepLinkInProgress else { return }
        NotificationCenter.default.post(name: .dismissWorkoutDetail, object: nil)
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(name: "Sample Workout"))
    }
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
