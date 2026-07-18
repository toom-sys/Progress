//
//  AddExerciseView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCustomExerciseEntry: Bool = false
    @State private var exerciseName: String = ""
    @State private var selectedType: ExerciseType = .resistance
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    let workout: Workout
    let onExerciseAdded: (Exercise) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        Group {
            if showingCustomExerciseEntry {
                customExerciseEntryView
            } else {
                ExercisePickerView(
                    workout: workout,
                    onExerciseSelected: { predefinedExercise in
                        addPredefinedExercise(predefinedExercise)
                    },
                    onCustomExerciseRequested: {
                        showingCustomExerciseEntry = true
                    },
                    onDismiss: onDismiss
                )
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Custom Exercise Entry View
    
    private var customExerciseEntryView: some View {
        ZStack {
            // Transparent background for tap-to-dismiss
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Popup card
            VStack(spacing: 24) {
                // Header with close button
                HStack {
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        showingCustomExerciseEntry = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Add Custom Exercise")
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
                
                // Visual body map notice
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("Custom Exercise Notice")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    Text("Custom exercises will not appear in the visual body map progress tracking. Only predefined exercises contribute to the muscle group visualization.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Exercise name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
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
                            addCustomExercise()
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
                                HapticFeedback.workoutButtonTap()
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
                
                // Add button
                Button(action: {
                    HapticFeedback.workoutButtonTap()
                    addCustomExercise()
                }) {
                    Text("Add Custom Exercise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                ? Color.gray 
                                : Color.blue
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(24)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Methods
    
    private func addPredefinedExercise(_ predefinedExercise: ExerciseDatabase.PredefinedExercise) {
        // Check exercise limit
        if workout.exercises.count >= 16 {
            errorMessage = "You've reached the limit of 16 exercises per workout. Please remove an existing exercise to add another."
            showingError = true
            return
        }
        
        // Create new exercise from predefined exercise
        let newExercise = Exercise(
            predefinedExercise: predefinedExercise,
            order: workout.exercises.count
        )
        
        modelContext.insert(newExercise)
        newExercise.workout = workout
        workout.exercises.append(newExercise)
        
        do {
            try modelContext.save()
            onExerciseAdded(newExercise)
            onDismiss()
        } catch {
            errorMessage = "Failed to add exercise: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func addCustomExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter an exercise name"
            showingError = true
            return
        }
        
        // Check exercise limit
        if workout.exercises.count >= 16 {
            errorMessage = "You've reached the limit of 16 exercises per workout. Please remove an existing exercise to add another."
            showingError = true
            return
        }
        
        // Save custom exercise to database for future use
        let categoryName = selectedType.displayName
        let typeName = selectedType.displayName
        
        // Set up the ExerciseDatabase context if not already done
        ExerciseDatabase.shared.setModelContext(modelContext)
        
        // Add to custom exercise database (if it doesn't already exist)
        let _ = ExerciseDatabase.shared.addCustomExercise(
            name: trimmedName,
            category: categoryName,
            type: typeName
        )
        
        // Create new custom exercise
        let newExercise = Exercise(
            name: trimmedName,
            type: selectedType,
            order: workout.exercises.count,
            isCustom: true // Mark as custom exercise
        )
        
        modelContext.insert(newExercise)
        newExercise.workout = workout
        workout.exercises.append(newExercise)
        
        do {
            try modelContext.save()
            onExerciseAdded(newExercise)
            onDismiss()
        } catch {
            errorMessage = "Failed to add exercise: \(error.localizedDescription)"
            showingError = true
        }
    }
}



#Preview {
    AddExerciseView(
        workout: Workout(name: "Test Workout"),
        onExerciseAdded: { _ in },
        onDismiss: { }
    )
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
