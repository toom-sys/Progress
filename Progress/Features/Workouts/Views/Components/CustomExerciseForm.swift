//
//  CustomExerciseForm.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct CustomExerciseForm: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var exerciseName: String = ""
    @State private var selectedType: ExerciseType = .resistance
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    let workout: Workout
    let onExerciseAdded: (Exercise) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
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
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedType == type ? typeColor : Color.gray.opacity(0.1))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: type.icon)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedType == type ? .white : .gray)
                                    }
                                    
                                    Text(type.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedType == type ? typeColor : .textSecondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedType == type ? typeColor.opacity(0.1) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedType == type ? typeColor : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Error message
                if showingError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Add button
                Button(action: addCustomExercise) {
                    Text("Add Exercise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : typeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .navigationTitle("Add Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private var typeColor: Color {
        switch selectedType {
        case .resistance, .strength:
            return .blue
        case .cardio:
            return .red
        case .recovery, .flexibility:
            return .green
        }
    }
    
    private func addCustomExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Please enter an exercise name")
            return
        }
        
        // Check if exercise already exists in workout
        if workout.exercises.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            showError("This exercise is already in your workout")
            return
        }
        
        // Create the custom exercise
        let exercise = Exercise(
            name: trimmedName,
            type: selectedType,
            category: selectedType.displayName,
            notes: nil,
            order: workout.exercises.count,
            restTime: selectedType.defaultRestTime,
            isCustom: true
        )
        
        // Add to workout and model context
        workout.addExercise(exercise)
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            onExerciseAdded(exercise)
        } catch {
            showError("Failed to add exercise: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showingError = false
        }
    }
}

#Preview {
    CustomExerciseForm(
        workout: Workout(name: "Sample Workout"),
        onExerciseAdded: { _ in },
        onDismiss: {}
    )
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
