//
//  SetEntryView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct SetEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var keyboardObserver: KeyboardObserver
    @Query private var users: [User]
    
    let exercise: Exercise
    let set: ExerciseSet?
    let onSetSaved: (ExerciseSet) -> Void
    let onDismiss: () -> Void
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var duration: String = ""
    @State private var distance: String = ""
    @State private var intensityLevel: Int = 5
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    private var userUnitSystem: UnitSystem {
        users.first?.preferredUnits ?? .metric
    }
    
    private enum Field {
        case weight, reps, duration, distance, notes
    }
    
    private var isEditing: Bool {
        self.set != nil
    }
    
    private var title: String {
        isEditing ? "Edit Set" : "Add Set"
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Two spacers + card = centered, but the bottom spacer shrinks when the
            // keyboard is up, pushing the card into the visible area above the keyboard.
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Main card - sized to fit content
                VStack(spacing: 0) {
                // Header
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .background(Color.red)
                    .clipShape(Circle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.backgroundSecondary)
                
                // Form content - no ScrollView, just VStack
                VStack(spacing: 20) {
                    // Exercise type indicator
                    HStack {
                        Image(systemName: exercise.type.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(typeColor)
                        
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Text(exercise.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(typeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(typeColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Type-specific form fields
                    VStack(spacing: 16) {
                        switch exercise.type {
                        case .resistance, .strength:
                            resistanceFields
                        case .cardio:
                            cardioFields
                        case .recovery, .flexibility:
                            recoveryFields
                        }
                        

                    }
                    .padding(.horizontal, 24)
                    
                    // Save button
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        saveSet()
                    }) {
                        Text(isEditing ? "Update Set" : "Add Set")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(Color.surfaceWhite)
            }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 32)

                Spacer(minLength: 0)
            }
            .padding(.bottom, keyboardObserver.isKeyboardVisible ? keyboardObserver.keyboardHeight : 0)
            .animation(.easeInOut(duration: 0.25), value: keyboardObserver.keyboardHeight)
        }
        .onAppear {
            loadSetData()
            focusFirstField()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Type-specific form sections
    
    @ViewBuilder
    private var resistanceFields: some View {
        VStack(spacing: 16) {
            // Weight field
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight (\(userUnitSystem.weightUnit))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("0", text: $weight)
                    .focused($focusedField, equals: .weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Reps field
            VStack(alignment: .leading, spacing: 8) {
                Text("Reps")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("0", text: $reps)
                    .focused($focusedField, equals: .reps)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    @ViewBuilder
    private var cardioFields: some View {
        VStack(spacing: 16) {
            // Duration field
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration (minutes)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("0", text: $duration)
                    .focused($focusedField, equals: .duration)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Distance field
            VStack(alignment: .leading, spacing: 8) {
                Text("Distance (km)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("0", text: $distance)
                    .focused($focusedField, equals: .distance)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    @ViewBuilder
    private var recoveryFields: some View {
        VStack(spacing: 16) {
            // Duration field
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration (minutes)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("0", text: $duration)
                    .focused($focusedField, equals: .duration)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Intensity level
            VStack(alignment: .leading, spacing: 8) {
                Text("Intensity Level (1-10)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Slider(value: Binding(
                        get: { Double(intensityLevel) },
                        set: { intensityLevel = Int($0) }
                    ), in: 1...10, step: 1)
                    
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Text("\(intensityLevel)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .frame(width: 30)
                }
            }
        }
    }
    
    @ViewBuilder
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            TextField("Add notes about this set...", text: $notes, axis: .vertical)
                .focused($focusedField, equals: .notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Computed Properties
    
    private var typeColor: Color {
        switch exercise.type {
        case .resistance, .strength: return .blue
        case .cardio: return .red
        case .recovery, .flexibility: return .green
        }
    }
    
    private var canSave: Bool {
        switch exercise.type {
        case .resistance, .strength:
            return !weight.isEmpty && !reps.isEmpty &&
                   Double(weight) != nil && Int(reps) != nil
        case .cardio:
            return !duration.isEmpty && Double(duration) != nil
        case .recovery, .flexibility:
            return !duration.isEmpty && Double(duration) != nil
        }
    }
    
    // MARK: - Methods
    
    private func loadSetData() {
        guard let set = self.set else { return }
        
        switch exercise.type {
        case .resistance, .strength:
            // Convert weight from kg (stored) to user's preferred unit for display
            if set.weight > 0 {
                let displayWeight = userUnitSystem.convertWeight(from: set.weight)
                weight = String(format: "%.1f", displayWeight)
            } else {
                weight = ""
            }
            reps = set.reps > 0 ? String(set.reps) : ""
        case .cardio:
            duration = set.duration > 0 ? String(set.duration / 60) : "" // Convert to minutes
            distance = set.distance > 0 ? String(set.distance) : ""
        case .recovery, .flexibility:
            duration = set.duration > 0 ? String(set.duration / 60) : "" // Convert to minutes
            intensityLevel = set.intensityLevel ?? 5
        }
        
        notes = set.notes ?? ""
    }
    
    private func focusFirstField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch exercise.type {
            case .resistance, .strength:
                focusedField = .weight
            case .cardio, .recovery, .flexibility:
                focusedField = .duration
            }
        }
    }
    
    private func saveSet() {
        let setToSave: ExerciseSet
        
        if let existingSet = self.set {
            setToSave = existingSet
        } else {
            setToSave = ExerciseSet(order: exercise.sets.count)
            modelContext.insert(setToSave)
            exercise.addSet(setToSave)
        }
        
        // Update set data based on exercise type
        switch exercise.type {
        case .resistance, .strength:
            guard let weightValue = Double(weight),
                  let repsValue = Int(reps) else {
                errorMessage = "Please enter valid weight and reps"
                showingError = true
                return
            }
            // Convert weight from user's preferred unit back to kg for storage
            let weightInKg = userUnitSystem.convertWeightToKg(from: weightValue)
            setToSave.weight = weightInKg
            setToSave.reps = repsValue
            
        case .cardio:
            guard let durationValue = Double(duration) else {
                errorMessage = "Please enter valid duration"
                showingError = true
                return
            }
            setToSave.duration = durationValue * 60 // Convert to seconds
            setToSave.distance = Double(distance) ?? 0
            
        case .recovery, .flexibility:
            guard let durationValue = Double(duration) else {
                errorMessage = "Please enter valid duration"
                showingError = true
                return
            }
            setToSave.duration = durationValue * 60 // Convert to seconds
            setToSave.intensityLevel = intensityLevel
        }
        
        // Set notes
        setToSave.notes = notes.isEmpty ? nil : notes
        
        // Save to model context
        do {
            try modelContext.save()
            onSetSaved(setToSave)
            onDismiss()
        } catch {
            errorMessage = "Failed to save set: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    SetEntryView(
        exercise: Exercise(name: "Bench Press", type: .resistance),
        set: nil,
        onSetSaved: { _ in },
        onDismiss: { }
    )
    .modelContainer(for: [Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
