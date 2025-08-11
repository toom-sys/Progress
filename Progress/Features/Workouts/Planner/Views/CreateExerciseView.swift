//
//  CreateExerciseView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct CreateExerciseView: View {
    let exerciseType: ExerciseType
    let onSave: (String, ExerciseType, Int, Double, Int, Double, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName = ""
    @State private var weight = ""
    @State private var sets = "3"
    @State private var reps = "10"
    @State private var distance = ""
    @State private var duration = ""
    @State private var recoveryType = RecoveryType.active
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Name")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Exercise Name", text: $exerciseName)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Type-specific fields
                VStack(alignment: .leading, spacing: 16) {
                    switch exerciseType {
                    case .resistance:
                        ResistanceFieldsView(weight: $weight, sets: $sets, reps: $reps)
                    case .cardio:
                        CardioFieldsView(distance: $distance, duration: $duration)
                    case .recovery:
                        RecoveryFieldsView(recoveryType: $recoveryType, duration: $duration)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    if !exerciseName.isEmpty {
                        let setCount = Int(sets) ?? 3
                        let weightValue = Double(weight) ?? 0.0
                        let repsValue = Int(reps) ?? 10
                        let distanceValue = Double(distance) ?? 0.0
                        
                        onSave(exerciseName, exerciseType, setCount, weightValue, repsValue, distanceValue, duration)
                        dismiss()
                    }
                }) {
                    Text("Save Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(exerciseName.isEmpty ? Color.gray : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(exerciseName.isEmpty)
            }
            .padding()
            .background(AdaptiveGradientBackground())
            .navigationTitle(exerciseType.displayName)
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
}