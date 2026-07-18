//
//  WorkoutHistoryView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.completedAt, order: .reverse) private var allWorkouts: [Workout]
    @Query private var users: [User]
    
    private var completedWorkouts: [Workout] {
        allWorkouts.filter { !$0.isDeleted && $0.status == WorkoutStatus.completed }
    }
    
    private var deletedWorkoutCount: Int {
        allWorkouts.filter { $0.isDeleted }.count
    }
    
    private var userUnitSystem: UnitSystem {
        users.first?.preferredUnits ?? .metric
    }
    
    @State private var expandedWorkouts: Set<UUID> = []
    @State private var editingWorkoutId: UUID? = nil
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingRecentlyDeleted = false
    let onDismiss: () -> Void
    
    init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Background
            AdaptiveGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation header - matching individual workout style
                HStack {
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        onDismiss()
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                // Blue indicator dot to show active section
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 10, y: -8)
                            }
                            
                            Text("Workouts")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        showingRecentlyDeleted = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 28, alignment: .trailing)
                            
                            if deletedWorkoutCount > 0 {
                                Text("\(min(deletedWorkoutCount, 99))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 4, y: -8)
                            }
                        }
                    }
                    .accessibilityLabel("Recently Deleted")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Content
                if completedWorkouts.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "chart.line.uptrend.xyaxis.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Completed Workouts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Complete your first workout to see it here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    // History list
                    List {
                        ForEach(completedWorkouts, id: \.id) { workout in
                            WorkoutHistoryRow(
                                workout: workout,
                                isExpanded: expandedWorkouts.contains(workout.id),
                                onToggleExpansion: {
                                    if expandedWorkouts.contains(workout.id) {
                                        expandedWorkouts.remove(workout.id)
                                    } else {
                                        expandedWorkouts.insert(workout.id)
                                    }
                                },
                                onEditDate: { workout in
                                    editingWorkoutId = workout.id
                                    selectedDate = workout.completedAt ?? Date()
                                    showingDatePicker = true
                                }
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", role: .destructive) {
                                    deleteWorkout(workout)
                                }
                            }
                        }
                        .onDelete(perform: deleteWorkouts)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingRecentlyDeleted) {
            RecentlyDeletedWorkoutsView(onDismiss: { showingRecentlyDeleted = false })
        }
        .onAppear {
            NotificationCenter.default.post(name: .showWorkoutHistory, object: nil)
            purgeExpiredDeletedWorkouts()
        }
        .onDisappear {
            NotificationCenter.default.post(name: .dismissWorkoutHistory, object: nil)
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }
    
    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Completion Date")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                HStack {
                    Spacer()
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDatePicker = false
                        editingWorkoutId = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUpdatedDate()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func saveUpdatedDate() {
        guard let workoutId = editingWorkoutId,
              let workout = completedWorkouts.first(where: { $0.id == workoutId }) else {
            return
        }
        
        workout.completedAt = selectedDate
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update workout date: \(error)")
        }
        
        showingDatePicker = false
        editingWorkoutId = nil
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        for index in offsets {
            let workout = completedWorkouts[index]
            deleteWorkout(workout)
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        // Soft-delete so the workout can be restored from Recently Deleted.
        // Plan rewind happens only on permanent deletion.
        workout.softDelete()
        expandedWorkouts.remove(workout.id)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete workout: \(error)")
        }
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

struct WorkoutHistoryRow: View {
    let workout: Workout
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onEditDate: (Workout) -> Void
    
    @Query private var users: [User]
    
    private var userUnitSystem: UnitSystem {
        users.first?.preferredUnits ?? .metric
    }
    
    private var exercises: [Exercise] {
        workout.exercises
    }
    
    private var completedExercises: [Exercise] {
        // For completed workouts, show exercises with ANY completed sets
        if workout.status == .completed {
            return exercises.filter { $0.completedSetsSnapshot > 0 }
        } else {
            return exercises.filter { $0.completedSetsCount > 0 }
        }
    }
    
    private var formattedDate: String {
        guard let completedAt = workout.completedAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
    
    private var totalSets: Int {
        if workout.status == .completed {
            return completedExercises.reduce(0) { $0 + $1.completedSetsSnapshot }
        } else {
            return completedExercises.reduce(0) { $0 + $1.sets.count }
        }
    }
    
    private var totalVolume: Double {
        if workout.status == .completed {
            return completedExercises.reduce(0.0) { total, exercise in
                total + exercise.setsSnapshot.reduce(0.0) { setTotal, snapshot in
                    guard snapshot.isCompleted else { return setTotal }
                    return setTotal + (snapshot.weight * Double(snapshot.reps))
                }
            }
        } else {
            return completedExercises.reduce(0.0) { total, exercise in
                total + exercise.sets.reduce(0.0) { setTotal, set in
                    guard set.isCompleted else { return setTotal }
                    return setTotal + (set.weight * Double(set.reps))
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainRowContent
            
            if isExpanded {
                expandedContent
            }
        }
        .whiteCardStyleWithBorder(cornerRadius: 12, padding: 0)
    }
    
    private var mainRowContent: some View {
        Button(action: onToggleExpansion) {
            HStack(spacing: 16) {
                workoutInfo
                Spacer()
                editButton
                expansionIndicator
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var workoutInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            workoutStats
        }
    }
    
    private var workoutStats: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "dumbbell")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("\(completedExercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("\(totalSets) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var editButton: some View {
        Button(action: {
            onEditDate(workout)
        }) {
            Image(systemName: "pencil")
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var expansionIndicator: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 16)
            
            exerciseDetails
            
            Spacer()
                .frame(height: 8)
        }
    }
    
    private var summaryStats: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(totalSets)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("Total Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text(String(format: "%.0f kg", totalVolume))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Text("Total Volume")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var exerciseDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Exercises Completed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ForEach(completedExercises, id: \.id) { exercise in
                exerciseSection(exercise)
            }
        }
    }
    
    private func exerciseSection(_ exercise: Exercise) -> some View {
        VStack(spacing: 8) {
            // Exercise header
            HStack(spacing: 12) {
                Image(systemName: exercise.type.icon)
                    .font(.subheadline)
                    .foregroundColor(colorFromString(exercise.type.color))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(workout.status == .completed ? 
                         "\(exercise.completedSetsSnapshot)/\(exercise.setsSnapshot.count) sets completed" :
                         "\(exercise.completedSetsCount)/\(exercise.sets.count) sets completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Individual sets
            VStack(spacing: 4) {
                if workout.status == .completed {
                    ForEach(Array(exercise.setsSnapshot.enumerated()), id: \.element.id) { index, snapshot in
                        if snapshot.isCompleted {
                            snapshotSetRow(snapshot: snapshot, setNumber: index + 1)
                        }
                    }
                } else {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        if set.isCompleted {
                            setRow(set: set, setNumber: index + 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.surface.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    private func setRow(set: ExerciseSet, setNumber: Int) -> some View {
        HStack {
            Text("Set \(setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text(self.userUnitSystem.formatWeight(set.weight))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    Text(self.userUnitSystem.weightUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    Text("reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if set.duration > 0 {
                    HStack(spacing: 4) {
                        Text("\(Int(set.duration))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        Text("sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if set.distance > 0 {
                    HStack(spacing: 4) {
                        Text("\(String(format: "%.1f", set.distance))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        Text("km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color.surface)
        .cornerRadius(8)
    }
    
    private func snapshotSetRow(snapshot: ExerciseSetSnapshot, setNumber: Int) -> some View {
        HStack {
            Text("Set \(setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text(self.userUnitSystem.formatWeight(snapshot.weight))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    Text(self.userUnitSystem.weightUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text("\(snapshot.reps)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    Text("reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if snapshot.duration > 0 {
                    HStack(spacing: 4) {
                        Text("\(Int(snapshot.duration))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        Text("sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if snapshot.distance > 0 {
                    HStack(spacing: 4) {
                        Text(self.userUnitSystem.formatDistance(snapshot.distance))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        Text(self.userUnitSystem.distanceUnit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color.surface)
        .cornerRadius(8)
    }
}



// Helper function to convert string colors to SwiftUI Colors
private func colorFromString(_ colorString: String) -> Color {
    switch colorString {
    case "blue":
        return .blue
    case "red":
        return .red
    case "green":
        return .green
    default:
        return .primary
    }
}

#Preview {
    WorkoutHistoryView()
}
