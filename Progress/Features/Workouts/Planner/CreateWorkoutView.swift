//
//  CreateWorkoutView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct CreateWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var workoutName = ""
    @State private var isTemplate = false
    
    private var canCreate: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Create New Workout")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Give your workout a name to get started")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 20) {
                    // Workout Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workout Name")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        TextField("Enter workout name...", text: $workoutName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Template Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Save as Template")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Text("Templates can be reused for future workouts")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isTemplate)
                    }
                    
                    Spacer()
                    
                    // Create Button
                    Button("Create Workout") {
                        createWorkout()
                    }
                    .primaryButtonStyle()
                    .disabled(!canCreate)
                    .opacity(canCreate ? 1.0 : 0.6)
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createWorkout() {
        let newWorkout = Workout(
            name: workoutName.trimmingCharacters(in: .whitespacesAndNewlines),
            isTemplate: isTemplate
        )
        
        modelContext.insert(newWorkout)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error
            print("Failed to save workout: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateWorkoutView()
            .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
    }
}