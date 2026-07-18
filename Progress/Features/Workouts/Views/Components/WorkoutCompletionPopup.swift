//
//  WorkoutCompletionPopup.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutCompletionPopup: View {
    let workout: Workout
    let exercises: [Exercise]
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    @State private var isExerciseListExpanded = false
    
    // Calculate workout summary data (excluding hidden exercises)
    private var visibleExercises: [Exercise] {
        let visible = exercises.filter { !$0.isHidden }
        let hidden = exercises.filter { $0.isHidden }
        
        // Only log once when popup is first shown (not on every UI refresh)
        if shouldLogSummary {
            // Summary calculation
            print("   Total exercises: \(exercises.count)")
            print("   Visible exercises: \(visible.count) - \(visible.map { $0.name })")
            if !hidden.isEmpty {
                print("   Hidden exercises (excluded): \(hidden.count) - \(hidden.map { $0.name })")
            }
        }
        
        return visible
    }
    
    /// Only log summary calculation occasionally to avoid spam
    private var shouldLogSummary: Bool {
        // Simple throttling - only log occasionally
        return Int.random(in: 1...20) == 1
    }
    
    private var totalSets: Int {
        visibleExercises.reduce(0) { $0 + $1.sets.count }
    }
    
    private var completedSets: Int {
        visibleExercises.reduce(0) { $0 + $1.completedSetsCount }
    }
    
    private var totalTime: String {
        guard let startTime = workout.startedAt else { return "Not started" }
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var totalVolume: Double {
        visibleExercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                guard set.isCompleted else { return setTotal }
                return setTotal + (set.weight * Double(set.reps))
            }
        }
    }
    
    private var completedExercises: [Exercise] {
        visibleExercises.filter { $0.isCompleted }
    }
    
    var body: some View {
        ZStack {
            // Completion popup
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Complete Workout?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                // Workout Summary
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        Text("Workout Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Summary stats
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("\(completedSets)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Sets Done")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if totalVolume > 0 {
                                VStack(spacing: 4) {
                                    Text("\(Int(totalVolume))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    Text("Total kg")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Exercise breakdown
                        if !completedExercises.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Exercises Completed")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                ForEach(isExerciseListExpanded ? completedExercises : Array(completedExercises.prefix(3)), id: \.id) { exercise in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 16))
                                        
                                        Text(exercise.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(exercise.completedSetsCount)/\(exercise.sets.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if completedExercises.count > 3 {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isExerciseListExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(isExerciseListExpanded ? 
                                                 "Show less" : 
                                                 "+ \(completedExercises.count - 3) more exercises")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            
                                            Image(systemName: isExerciseListExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.top, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 20)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        print("🎯 WorkoutCompletionPopup: User cancelled workout completion")
                        onDismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Complete Workout") {
                        print("🎯 WorkoutCompletionPopup: User confirmed workout completion")
                        print("   Calling onConfirm callback...")
                        onConfirm()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    let workout = Workout(name: "Push Day")
    workout.startedAt = Date().addingTimeInterval(-3600) // Started 1 hour ago
    
    let exercise1 = Exercise(name: "Bench Press", type: .resistance)
    let set1 = ExerciseSet(weight: 80, reps: 10)
    set1.complete()
    exercise1.addSet(set1)
    
    let exercise2 = Exercise(name: "Push-ups", type: .resistance)
    let set2 = ExerciseSet(weight: 0, reps: 15)
    exercise2.addSet(set2)
    
    return WorkoutCompletionPopup(
        workout: workout,
        exercises: [exercise1, exercise2],
        onConfirm: {},
        onDismiss: {}
    )
}
