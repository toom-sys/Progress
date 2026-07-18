//
//  WorkoutProgressBar.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutProgressBar: View {
    let exercises: [Exercise]
    let workout: Workout
    let onWorkoutCompleted: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Workout Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(completedExercisesCount)/\(visibleExercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                // Progress bar track
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage, height: 8)
                            .animation(.easeInOut(duration: 0.5), value: progressPercentage)
                    }
                }
                .frame(height: 8)
                
                // Detailed stats
                HStack(spacing: 16) {
                    // Total sets
                    VStack(spacing: 2) {
                        Text("\(completedSetsCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        Text("Sets Done")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Remaining sets
                    VStack(spacing: 2) {
                        Text("\(totalSetsCount - completedSetsCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textSecondary)
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Completion percentage
                    VStack(spacing: 2) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(progressPercentage == 1.0 ? .green : .blue)
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    
                    Spacer()
                    
                    WorkoutTimer(workoutId: workout.id.uuidString, defaultDuration: 90)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.border, lineWidth: 1)
                .opacity(0.2)
        )
        .onChange(of: progressPercentage) { _, newValue in
            // Auto-complete workout when all visible exercises are done AND there are completed sets
            if newValue == 1.0 && !workout.isCompleted && visibleExercises.count > 0 && completedSetsCount > 0 {
                print("🎯 WorkoutProgressBar: Auto-completion triggered!")
                print("   Progress: \(newValue * 100)% complete")
                print("   Visible exercises: \(visibleExercises.count)")
                print("   Completed sets: \(completedSetsCount)")
                print("   Workout status: \(workout.status)")
                print("   Calling onWorkoutCompleted callback...")
                onWorkoutCompleted?()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Exercises that are not hidden (visible for progression tracking)
    private var visibleExercises: [Exercise] {
        let visible = exercises.filter { !$0.isHidden }
        let hidden = exercises.filter { $0.isHidden }
        
        // Only log when there are hidden exercises and this is a meaningful change
        // (not just UI refresh spam)
        if !hidden.isEmpty && shouldLogFiltering {
            print("👁️ WorkoutProgressBar filtering:")
            print("   Total exercises: \(exercises.count)")
            print("   Visible exercises: \(visible.count) - \(visible.map { $0.name })")
            print("   Hidden exercises: \(hidden.count) - \(hidden.map { $0.name })")
        }
        
        return visible
    }
    
    /// Only log filtering when it's meaningful (not just UI refresh spam)
    private var shouldLogFiltering: Bool {
        // Simple throttling - only log occasionally to avoid spam
        return Int.random(in: 1...50) == 1
    }
    
    private var completedExercisesCount: Int {
        visibleExercises.filter { exercise in
            let sets = exercise.sets
            return sets.count > 0 && sets.allSatisfy { $0.isCompleted }
        }.count
    }
    
    private var completedSetsCount: Int {
        visibleExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.isCompleted }.count
        }
    }
    
    private var totalSetsCount: Int {
        visibleExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
    
    private var progressPercentage: Double {
        guard totalSetsCount > 0 else { return 0.0 }
        return Double(completedSetsCount) / Double(totalSetsCount)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Empty workout
        WorkoutProgressBar(
            exercises: [], 
            workout: Workout(name: "Empty Workout"),
            onWorkoutCompleted: nil
        )
        
        // Workout with some progress
        WorkoutProgressBar(
            exercises: {
                let exercise1 = Exercise(name: "Bench Press", type: .resistance)
                let set1 = ExerciseSet(weight: 80, reps: 10, order: 0)
                set1.isCompleted = true
                let set2 = ExerciseSet(weight: 80, reps: 10, order: 1)
                exercise1.addSet(set1)
                exercise1.addSet(set2)
                
                let exercise2 = Exercise(name: "Running", type: .cardio)
                let set3 = ExerciseSet(duration: 1800, distance: 5.0, order: 0) // 30 min, 5km
                exercise2.addSet(set3)
                
                return [exercise1, exercise2]
            }(),
            workout: Workout(name: "Sample Workout"),
            onWorkoutCompleted: nil
        )
        
        Spacer()
    }
    .padding()
    .background(Color.backgroundSecondary)
}
