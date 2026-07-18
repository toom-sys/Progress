//
//  RenameWorkoutView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct RenameWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var workoutName: String
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    let workout: Workout
    let onWorkoutRenamed: () -> Void
    let onDismiss: () -> Void
    
    init(workout: Workout, onWorkoutRenamed: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.workout = workout
        self.onWorkoutRenamed = onWorkoutRenamed
        self.onDismiss = onDismiss
        self._workoutName = State(initialValue: workout.name)
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
                // Header with close button
                HStack {
                    Text("Rename Workout")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
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
                
                // Workout name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Enter workout name", text: $workoutName)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onChange(of: workoutName) { _, newValue in
                            if newValue.count > 32 {
                                workoutName = String(newValue.prefix(32))
                            }
                        }
                        .onSubmit {
                            renameWorkout()
                        }
                }
                
                // Save button
                Button(action: {
                    renameWorkout()
                }) {
                    Text("Save Changes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                ? Color.gray 
                                : Color.blue
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func renameWorkout() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a workout name"
            showingError = true
            return
        }
        
        workout.name = trimmedName
        workout.updateTimestamp()
        
        do {
            try modelContext.save()
            onWorkoutRenamed()
            onDismiss()
        } catch {
            errorMessage = "Failed to rename workout: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    RenameWorkoutView(
        workout: Workout(name: "Test Workout"),
        onWorkoutRenamed: { },
        onDismiss: { }
    )
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
