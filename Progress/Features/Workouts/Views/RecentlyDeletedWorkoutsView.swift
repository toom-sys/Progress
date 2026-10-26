//
//  RecentlyDeletedWorkoutsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct RecentlyDeletedWorkoutsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.deletedAt, order: .reverse) private var allWorkouts: [Workout]
    
    let onDismiss: () -> Void
    
    @State private var workoutPendingPermanentDelete: Workout?
    
    private var deletedWorkouts: [Workout] {
        allWorkouts.filter { $0.isDeleted }
    }
    
    init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header
                
                if deletedWorkouts.isEmpty {
                    emptyState
                } else {
                    deletedList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            purgeExpiredDeletedWorkouts()
        }
        .alert(
            "Delete Forever?",
            isPresented: Binding(
                get: { workoutPendingPermanentDelete != nil },
                set: { if !$0 { workoutPendingPermanentDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {
                workoutPendingPermanentDelete = nil
            }
            Button("Delete Forever", role: .destructive) {
                if let workout = workoutPendingPermanentDelete {
                    permanentlyDelete(workout)
                }
                workoutPendingPermanentDelete = nil
            }
        } message: {
            Text("This workout will be permanently removed and cannot be restored.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            CircleIconButton(
                systemName: "chevron.left",
                style: .plain,
                size: 40,
                accessibilityLabel: "History",
                action: {
                    HapticFeedback.workoutButtonTap()
                    onDismiss()
                }
            )

            Text("Recently Deleted")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundColor(AppPalette.ink)
                .lineLimit(2)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Recently Deleted Workouts",
            systemImage: "trash.slash",
            description: Text("Deleted workouts stay here for \(Workout.softDeleteRetentionDays) days so you can restore them.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - List
    
    private var deletedList: some View {
        VStack(spacing: 0) {
            Text("Workouts stay here for \(Workout.softDeleteRetentionDays) days, then are permanently deleted.")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            List {
                ForEach(deletedWorkouts, id: \.id) { workout in
                    RecentlyDeletedWorkoutRow(
                        workout: workout,
                        onRestore: { restore(workout) }
                    )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                restore(workout)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Color.brand)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                workoutPendingPermanentDelete = workout
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Actions
    
    private func restore(_ workout: Workout) {
        HapticFeedback.workoutButtonTap()
        workout.restoreFromDeletion()
        try? modelContext.save()
    }
    
    private func permanentlyDelete(_ workout: Workout) {
        do {
            let planService = TrainingPlanService(modelContext: modelContext)
            try planService.rewindPlanProgressIfNeeded(afterDeleting: workout)
        } catch {
            print("Failed to rewind plan progress: \(error)")
        }
        modelContext.delete(workout)
        try? modelContext.save()
    }
    
    private func purgeExpiredDeletedWorkouts() {
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -Workout.softDeleteRetentionDays,
            to: Date()
        ) ?? Date()
        
        let expired = allWorkouts.filter { workout in
            guard let deletedAt = workout.deletedAt else { return false }
            return deletedAt < cutoff
        }
        
        guard !expired.isEmpty else { return }
        
        let planService = TrainingPlanService(modelContext: modelContext)
        for workout in expired {
            do {
                try planService.rewindPlanProgressIfNeeded(afterDeleting: workout)
            } catch {
                print("Failed to rewind plan progress: \(error)")
            }
            modelContext.delete(workout)
        }
        try? modelContext.save()
    }
}

// MARK: - Row

private struct RecentlyDeletedWorkoutRow: View {
    let workout: Workout
    let onRestore: () -> Void
    
    private var deletedDateText: String {
        guard let deletedAt = workout.deletedAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: deletedAt)
    }
    
    private var retentionText: String {
        let days = workout.daysUntilPermanentDeletion
        if days == 0 {
            return "Expires today"
        } else if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Deleted \(deletedDateText)")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)

                HStack(spacing: 8) {
                    Text(workout.status.displayName)
                    Text("·")
                    Text(retentionText)
                }
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
            }
            
            Spacer()
            
            Button("Restore", action: onRestore)
                .buttonStyle(AppPillButtonStyle(.outline, .compact))
        }
        .appCard(cornerRadius: 22, padding: 14)
    }
}

#Preview {
    RecentlyDeletedWorkoutsView()
}
