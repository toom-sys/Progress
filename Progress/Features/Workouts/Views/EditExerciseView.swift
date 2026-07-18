//
//  EditExerciseView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct EditExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var exerciseName: String
    @State private var selectedType: ExerciseType
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    let exercise: Exercise
    let onExerciseUpdated: () -> Void
    let onDismiss: () -> Void
    
    init(exercise: Exercise, onExerciseUpdated: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.exercise = exercise
        self.onExerciseUpdated = onExerciseUpdated
        self.onDismiss = onDismiss
        self._exerciseName = State(initialValue: exercise.name)
        self._selectedType = State(initialValue: exercise.type)
    }
    
    var body: some View {
        ZStack {
            // Transparent background for tap-to-dismiss
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Popup card
            VStack(spacing: 24) {
                // Header with close button and exercise source indicator
                VStack(spacing: 12) {
                    HStack {
                        Text("Edit Exercise")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            HapticFeedback.workoutButtonTap()
                            onDismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                    }
                    
                    // Exercise source indicator
                    HStack {
                        Image(systemName: exercise.isCustom ? "person.badge.plus" : "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(exercise.isCustom ? .orange : .green)
                        
                        Text(exercise.isCustom ? "Custom Exercise" : "Predefined Exercise")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(exercise.isCustom ? .orange : .green)
                        
                        if !exercise.isCustom {
                            Spacer()
                            
                            Text("• \(exercise.predefinedExercise?.type ?? "Unknown")")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        (exercise.isCustom ? Color.orange : Color.green).opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Exercise name input - conditional based on exercise type
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exercise Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        if !exercise.isCustom {
                            Spacer()
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    if exercise.isCustom {
                        // Editable text field for custom exercises
                        TextField("Enter exercise name", text: $exerciseName)
                            .focused($isTextFieldFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onChange(of: exerciseName) { _, newValue in
                                if newValue.count > 30 {
                                    exerciseName = String(newValue.prefix(30))
                                }
                            }
                            .onSubmit {
                                updateExercise()
                            }
                    } else {
                        // Read-only display for predefined exercises
                        HStack {
                            Text(exerciseName)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    // TODO: Show info about predefined exercises
                                }
                        }
                        
                        Text("Predefined exercise names cannot be modified")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                            .padding(.top, 4)
                    }
                }
                
                // Exercise type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach(ExerciseType.modernCases, id: \.self) { type in
                            Button(action: {
                                selectedType = type
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(selectedType == type ? .white : .blue)
                                    
                                    Text(type.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedType == type ? .white : .blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedType == type ? Color.blue : Color.blue.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                // Buttons
                HStack(spacing: 12) {
                    // Delete button
                    Button(action: {
                        HapticFeedback.itemDeleted()
                        deleteExercise()
                    }) {
                        Text("Delete")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Update button
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        updateExercise()
                    }) {
                        Text("Update")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                // Only disable if it's a custom exercise with empty name
                                (exercise.isCustom && exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    ? Color.gray 
                                    : Color.blue
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(exercise.isCustom && exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
            .onAppear {
                // Only focus text field for custom exercises
                if exercise.isCustom {
                    isTextFieldFocused = true
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateExercise() {
        // Only validate and update name for custom exercises
        if exercise.isCustom {
            let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedName.isEmpty else {
                errorMessage = "Please enter an exercise name"
                showingError = true
                return
            }
            
            exercise.name = trimmedName
        }
        
        // Always allow type changes (both custom and predefined exercises)
        exercise.type = selectedType
        
        do {
            try modelContext.save()
            onExerciseUpdated()
            onDismiss()
        } catch {
            errorMessage = "Failed to update exercise: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteExercise() {
        modelContext.delete(exercise)
        
        do {
            try modelContext.save()
            onExerciseUpdated()
            onDismiss()
        } catch {
            errorMessage = "Failed to delete exercise: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    EditExerciseView(
        exercise: Exercise(
            name: "Bench Press",
            type: .resistance
        ),
        onExerciseUpdated: { },
        onDismiss: { }
    )
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
