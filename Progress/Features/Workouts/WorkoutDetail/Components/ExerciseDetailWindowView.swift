//
//  ExerciseDetailWindowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct ExerciseDetailWindowView: View {
    let exercise: Exercise
    @Binding var isShowing: Bool
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 20) {
                // Exercise Header
                HStack {
                    // Exercise Icon (Large)
                    Image(systemName: exercise.type.icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 40, weight: .medium))
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 30, height: 30)
                            .background(Color.backgroundTertiary)
                            .clipShape(Circle())
                    }
                }
                
                // Exercise Name
                Text(exercise.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Sets Header
                HStack {
                    Text("Sets")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Text("\(exercise.completedSetsCount)/\(exercise.sets.count) completed")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Sets List in ScrollView
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        SetRowView(
                            setNumber: index + 1,
                            set: set,
                            exerciseType: exercise.type
                        )
                    }
                    
                    // Add Set Button
                    Button(action: {
                        addNewSet()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                            Text("Add Set")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 250) // Responsive height for sets list
            
            // Bottom Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Hide exercise functionality
                }) {
                    Text("Hide Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    // TODO: Coming soon functionality
                }) {
                    Text("Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 0) // Explicitly remove any default shadows
        .contentShape(Rectangle())
        .onTapGesture {
            // Prevent tap-through to background dismiss gesture
        }
    }
    
    // MARK: - Helper Methods
    
    private func addNewSet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let newSet: ExerciseSet
            
            switch exercise.type {
            case .resistance:
                // Use the last set as a template or create default values
                if let lastSet = exercise.sets.last {
                    newSet = ExerciseSet(
                        weight: lastSet.weight,
                        reps: lastSet.reps,
                        duration: 0,
                        distance: 0,
                        order: exercise.sets.count
                    )
                } else {
                    newSet = ExerciseSet(
                        weight: 20.0,
                        reps: 10,
                        duration: 0,
                        distance: 0,
                        order: 0
                    )
                }
            case .cardio:
                if let lastSet = exercise.sets.last {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: lastSet.duration,
                        distance: lastSet.distance,
                        order: exercise.sets.count
                    )
                } else {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: 1800, // 30 minutes default
                        distance: 5.0,
                        order: 0
                    )
                }
            case .recovery:
                if let lastSet = exercise.sets.last {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: lastSet.duration,
                        distance: 0,
                        order: exercise.sets.count
                    )
                } else {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: 1800, // 30 minutes default
                        distance: 0,
                        order: 0
                    )
                }
            }
            
            exercise.addSet(newSet)
            modelContext.insert(newSet)
            try? modelContext.save()
        }
    }
}