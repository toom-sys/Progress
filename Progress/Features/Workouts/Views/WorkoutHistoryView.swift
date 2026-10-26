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
    private var completedWorkouts: [Workout] {
        allWorkouts.filter { !$0.isDeleted && $0.status == WorkoutStatus.completed }
    }
    
    private var deletedWorkoutCount: Int {
        allWorkouts.filter { $0.isDeleted }.count
    }
    
    @State private var expandedWorkouts: Set<UUID> = []
    @State private var editingWorkoutId: UUID? = nil
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingRecentlyDeleted = false
    @State private var workoutPendingDelete: Workout?
    let onDismiss: () -> Void
    
    init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header

                if completedWorkouts.isEmpty {
                    ContentUnavailableView(
                        "No Completed Workouts",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete your first workout to see it here")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    workoutPendingDelete = workout
                                }
                            }
                        }

                        Color.clear
                            .frame(height: 100)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
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

    private var header: some View {
        HStack(spacing: 10) {
            CircleIconButton(
                systemName: "chevron.left",
                style: .plain,
                size: 40,
                accessibilityLabel: "Workouts",
                action: {
                    HapticFeedback.workoutButtonTap()
                    onDismiss()
                }
            )

            Text("History")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundColor(AppPalette.ink)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            ZStack(alignment: .topTrailing) {
                CircleIconButton(
                    systemName: "trash",
                    style: .plain,
                    size: 40,
                    accessibilityLabel: "Recently deleted",
                    action: {
                        HapticFeedback.workoutButtonTap()
                        showingRecentlyDeleted = true
                    }
                )

                if deletedWorkoutCount > 0 {
                    Text("\(min(deletedWorkoutCount, 99))")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(AppPalette.onInk)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppPalette.ink))
                        .offset(x: 4, y: -4)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Completion Date")
                    .font(.appSectionTitle)
                    .foregroundColor(AppPalette.ink)
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
            .background(AppBackground())
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
        .appCard(cornerRadius: 22, padding: 0)
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
        .buttonStyle(.plain)
        .accessibilityLabel(workout.name)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }
    
    private var workoutInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.appCardTitle)
                .foregroundColor(AppPalette.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(formattedDate)
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)

            workoutStats
        }
    }
    
    private var workoutStats: some View {
        HStack(spacing: 12) {
            Text("\(completedExercises.count) exercises")
            Text("·")
            Text("\(totalSets) sets")
        }
        .font(.appSubtitle)
        .foregroundColor(AppPalette.muted)
    }
    
    private var editButton: some View {
        Button(action: {
            onEditDate(workout)
        }) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppPalette.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppPalette.optionFill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit completion date")
    }

    private var expansionIndicator: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppPalette.ink)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .frame(width: 32, height: 32)
            .background(Circle().fill(AppPalette.optionFill))
            .accessibilityHidden(true)
    }
    
    private var expandedContent: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(AppPalette.line)
                .frame(height: 1)
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
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                Text("Total Sets")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
            }

            VStack(spacing: 4) {
                Text(String(format: "%.0f kg", totalVolume))
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                Text("Total Volume")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var exerciseDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Exercises Completed")
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colorFromString(exercise.type.color))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.appCardTitle)
                        .foregroundColor(AppPalette.ink)

                    Text(workout.status == .completed ?
                         "\(exercise.completedSetsSnapshot)/\(exercise.setsSnapshot.count) sets completed" :
                         "\(exercise.completedSetsCount)/\(exercise.sets.count) sets completed")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppPalette.optionFill)
        )
        .padding(.horizontal, 16)
    }
    
    private func setRow(set: ExerciseSet, setNumber: Int) -> some View {
        HStack {
            Text("Set \(setNumber)")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
                .frame(width: 50, alignment: .leading)

            Spacer()

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text(self.userUnitSystem.formatWeight(set.weight))
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.ink)
                    Text(self.userUnitSystem.weightUnit)
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                }

                HStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.ink)
                    Text("reps")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                }

                if set.duration > 0 {
                    HStack(spacing: 4) {
                        Text("\(Int(set.duration))")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.ink)
                        Text("sec")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.muted)
                    }
                }

                if set.distance > 0 {
                    HStack(spacing: 4) {
                        Text("\(String(format: "%.1f", set.distance))")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.ink)
                        Text("km")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.muted)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppPalette.surface)
        )
    }
    
    private func snapshotSetRow(snapshot: ExerciseSetSnapshot, setNumber: Int) -> some View {
        HStack {
            Text("Set \(setNumber)")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
                .frame(width: 50, alignment: .leading)

            Spacer()

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text(self.userUnitSystem.formatWeight(snapshot.weight))
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.ink)
                    Text(self.userUnitSystem.weightUnit)
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                }

                HStack(spacing: 4) {
                    Text("\(snapshot.reps)")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.ink)
                    Text("reps")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                }

                if snapshot.duration > 0 {
                    HStack(spacing: 4) {
                        Text("\(Int(snapshot.duration))")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.ink)
                        Text("sec")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.muted)
                    }
                }

                if snapshot.distance > 0 {
                    HStack(spacing: 4) {
                        Text(self.userUnitSystem.formatDistance(snapshot.distance))
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.ink)
                        Text(self.userUnitSystem.distanceUnit)
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.muted)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppPalette.surface)
        )
    }
}



// Helper function to convert string colors to SwiftUI Colors
private func colorFromString(_ colorString: String) -> Color {
    switch colorString {
    case "blue":
        return Color.brand
    case "red":
        return AppPalette.protein
    case "green":
        return AppPalette.live
    default:
        return AppPalette.ink
    }
}

#Preview {
    WorkoutHistoryView()
}
