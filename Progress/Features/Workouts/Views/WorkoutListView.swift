//
//  WorkoutListView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Share Sheet Representable

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: ((UIActivity.ActivityType?, Bool) -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, _, _ in
            onComplete?(activityType, completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Alert Info

private struct WorkoutAlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

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
    @State private var shareItems: [Any] = []
    @State private var isShowingShareSheet = false
    @State private var alertInfo: WorkoutAlertInfo?
    @State private var workoutToOpen: Workout?

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
                    onDeleteWorkout: deleteWorkout,
                    onShareWorkout: shareWorkout,
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
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheetView(items: shareItems) { activityType, completed in
                guard completed else { return }
                alertInfo = WorkoutAlertInfo(
                    title: "Shared Successfully!",
                    message: shareSuccessMessage(for: activityType)
                )
            }
            .presentationDetents([.medium, .large])
        }
        .alert(item: $alertInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
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

    private func shareWorkout(_ workout: Workout) {
        guard WorkoutURLGenerator.canShareWorkout(workout) else {
            let message = WorkoutURLGenerator.getSharingError(for: workout) ?? "This workout cannot be shared."
            alertInfo = WorkoutAlertInfo(title: "Cannot Share Workout", message: message)
            return
        }

        do {
            let shareableURL = try WorkoutURLGenerator.generateShareableURL(for: workout)
            let appStoreURL = "https://apps.apple.com/app/progress-fitness-tracker/id123456789"
            let message = """
            Check out my "\(workout.name)" workout! 💪

            Get the Progress app to import this workout:
            \(appStoreURL)
            """
            shareItems = [message, URL(string: shareableURL) as Any].compactMap { $0 }
            isShowingShareSheet = true
        } catch {
            let message = (error as? WorkoutURLGenerator.WorkoutSharingError)?.errorDescription ?? error.localizedDescription
            alertInfo = WorkoutAlertInfo(title: "Sharing Failed", message: message)
        }
    }

    private func shareSuccessMessage(for activityType: UIActivity.ActivityType?) -> String {
        guard let activityType else {
            return "Workout shared successfully! 🎉\n\nRecipients can tap the link to get the Progress app and import your workout."
        }
        switch activityType {
        case .message:
            return "Workout shared via Messages! 📱\n\nRecipients can tap the link to get the Progress app and import your workout."
        case .mail:
            return "Workout shared via Mail! 📧\n\nRecipients can tap the link to get the Progress app and import your workout."
        case .airDrop:
            return "Workout shared via AirDrop! 📡\n\nThe recipient can tap the link to import your workout."
        case .copyToPasteboard:
            return "Workout link copied to clipboard! 📋\n\nYou can now paste it anywhere to share your workout."
        default:
            return "Workout shared successfully! 🎉\n\nRecipients can tap the link to get the Progress app and import your workout."
        }
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
