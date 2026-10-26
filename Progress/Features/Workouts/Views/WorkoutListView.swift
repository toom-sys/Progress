//
//  WorkoutListView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - WorkoutListView

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.updatedAt, order: .reverse) private var allWorkouts: [Workout]
    @Query(filter: #Predicate<TrainingPlan> { $0.isActive == true }) private var activePlans: [TrainingPlan]
    @Query private var users: [User]

    private var activePlan: TrainingPlan? {
        guard let userId = users.first?.id else { return nil }
        return activePlans.first { $0.user?.id == userId }
    }

    private var workouts: [Workout] {
        allWorkouts.filter { !$0.isDeleted && $0.status != .completed && $0.trainingPlanId == nil }
    }

    @State private var showingCreateWorkout = false
    @AppStorage("workoutSortOption") private var sortOption: WorkoutSortOption = .dateCreated
    @State private var showingWorkoutHistory = false
    @State private var workoutToOpen: Workout?
    @State private var workoutPendingDelete: Workout?

    /// Latest started workout that is still in progress, plan or custom.
    private var activeWorkout: Workout? {
        allWorkouts
            .filter { $0.isInProgress && !$0.isDeleted }
            .max { lhs, rhs in
                (lhs.startedAt ?? .distantPast) < (rhs.startedAt ?? .distantPast)
            }
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                WorkoutListHeader(
                    sortOption: $sortOption,
                    onHistoryTapped: { showingWorkoutHistory = true },
                    onAddTapped: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            showingCreateWorkout = true
                        }
                    }
                )

                WorkoutListContent(
                    workouts: sortedWorkouts,
                    plan: activePlan,
                    history: allWorkouts,
                    activeWorkout: activeWorkout,
                    onDeleteWorkout: { workoutPendingDelete = $0 },
                    onOpenWorkout: { workout in
                        workoutToOpen = workout
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $workoutToOpen) { workout in
            WorkoutDetailView(workout: workout)
        }
        .navigationDestination(isPresented: $showingWorkoutHistory) {
            WorkoutHistoryView(onDismiss: { showingWorkoutHistory = false })
        }
        .overlay {
            // Animation is applied only via withAnimation above — do not
            // attach `.animation(_:value:)` here or the whole list re-animates.
            WorkoutListOverlays(showingCreateWorkout: $showingCreateWorkout)
                .environment(\.modelContext, modelContext)
        }
        .alert(
            "Delete Workout?",
            isPresented: Binding(
                get: { workoutPendingDelete != nil },
                set: { if !$0 { workoutPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                workoutPendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutPendingDelete {
                    deleteWorkout(workout)
                }
                workoutPendingDelete = nil
            }
        } message: {
            Text("\(workoutPendingDelete?.name ?? "This workout") will move to Recently Deleted.")
        }
    }

    // MARK: - Sorted Workouts

    private var sortedWorkouts: [Workout] {
        switch sortOption {
        case .dateCreated:
            return workouts.sorted { $0.createdAt > $1.createdAt }
        case .dateCreatedOldest:
            return workouts.sorted { $0.createdAt < $1.createdAt }
        case .nameAscending:
            return workouts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return workouts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .exerciseCount:
            return workouts.sorted { $0.exercises.count > $1.exercises.count }
        }
    }

    // MARK: - Actions

    private func deleteWorkout(_ workout: Workout) {
        workout.softDelete()
        try? modelContext.save()
    }
}

// MARK: - Workout Sort Options

enum WorkoutSortOption: String, CaseIterable, Codable {
    case dateCreated = "dateCreated"
    case dateCreatedOldest = "dateCreatedOldest"
    case nameAscending = "nameAscending"
    case nameDescending = "nameDescending"
    case exerciseCount = "exerciseCount"
    
    var displayName: String {
        switch self {
        case .dateCreated:
            return "Date Created (Newest)"
        case .dateCreatedOldest:
            return "Date Created (Oldest)"
        case .nameAscending:
            return "Name (A-Z)"
        case .nameDescending:
            return "Name (Z-A)"
        case .exerciseCount:
            return "Exercise Count"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutListView()
    }
    .modelContainer(for: [User.self, Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self, TrainingPlan.self])
}
