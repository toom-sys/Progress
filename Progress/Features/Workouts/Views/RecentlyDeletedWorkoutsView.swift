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
            AdaptiveGradientBackground()
                .ignoresSafeArea()
            
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
        HStack {
            Button(action: {
                HapticFeedback.workoutButtonTap()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("History")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Text("Recently Deleted")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Balance the back button width
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("History")
                    .font(.headline)
            }
            .opacity(0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "trash.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Recently Deleted Workouts")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Deleted workouts stay here for \(Workout.softDeleteRetentionDays) days so you can restore them.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - List
    
    private var deletedList: some View {
        VStack(spacing: 0) {
            Text("Workouts stay here for \(Workout.softDeleteRetentionDays) days, then are permanently deleted.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            List {
                ForEach(deletedWorkouts, id: \.id) { workout in
                    RecentlyDeletedWorkoutRow(
                        workout: workout,
                        onRestore: { restore(workout) }
                    )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                restore(workout)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
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
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text("Deleted \(deletedDateText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Text(workout.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text(retentionText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onRestore) {
                Text("Restore")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .whiteCardStyleWithBorder(cornerRadius: 12, padding: 0)
    }
}

#Preview {
    RecentlyDeletedWorkoutsView()
}
