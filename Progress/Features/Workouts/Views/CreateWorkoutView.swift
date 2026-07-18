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
    
    @State private var workoutName: String = ""
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingAICreation: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    let onWorkoutCreated: (Workout) -> Void
    let onDismiss: () -> Void
    
    private var trimmedName: String {
        workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canCreate: Bool {
        !trimmedName.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture {
                    isTextFieldFocused = false
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                HStack {
                    Text("New Workout")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        isTextFieldFocused = false
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .background(Color.red)
                    .clipShape(Circle())
                    .accessibilityLabel("Close")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g. Upper body strength training", text: $workoutName)
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
                            createWorkout()
                        }
                    
                    Text("Also used as your AI prompt — describe what you want to train")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        isTextFieldFocused = false
                        showingAICreation = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                            Text("AI Generate")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        createWorkout()
                    }) {
                        Text("Create")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(canCreate ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!canCreate)
                }
            }
            .elevatedCardStyle(cornerRadius: 16, padding: 24)
            .padding(.horizontal, 32)
            .compositingGroup()
        }
        .task {
            // Defer keyboard until after the entrance animation to avoid layout thrash.
            try? await Task.sleep(for: .milliseconds(180))
            isTextFieldFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingAICreation) {
            AIWorkoutCreationView(initialRequest: workoutName, onWorkoutCreated: onWorkoutCreated)
        }
    }
    
    private func createWorkout() {
        guard canCreate else {
            errorMessage = "Please enter a workout name"
            showingError = true
            return
        }
        
        do {
            // Count only — avoid fetching every Workout model into memory.
            // Exclude soft-deleted workouts from the active limit.
            let descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate { $0.deletedAt == nil }
            )
            let existingCount = try modelContext.fetchCount(descriptor)
            if existingCount >= 10 {
                errorMessage = "You've reached the limit of 10 workouts. Please delete an existing workout to add another."
                showingError = true
                return
            }
        } catch {
            errorMessage = "Failed to check existing workouts: \(error.localizedDescription)"
            showingError = true
            return
        }
        
        let newWorkout = Workout(
            name: trimmedName,
            notes: nil
        )
        
        modelContext.insert(newWorkout)
        
        do {
            try modelContext.save()
            isTextFieldFocused = false
            onWorkoutCreated(newWorkout)
            onDismiss()
        } catch {
            errorMessage = "Failed to create workout: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    CreateWorkoutView(onWorkoutCreated: { _ in }, onDismiss: { })
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
