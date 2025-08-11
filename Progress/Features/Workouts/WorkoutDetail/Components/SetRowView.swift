//
//  SetRowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct SetRowView: View {
    let setNumber: Int
    let set: ExerciseSet
    let exerciseType: ExerciseType
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Number
            Text("Set \(setNumber)")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .frame(width: 60, alignment: .leading)
            
            // Reps
            if exerciseType == .resistance {
                Text("\(Int(set.reps)) reps")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(width: 80, alignment: .center)
                
                // Weight
                Text("\(set.weight, specifier: "%.1f") kg")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .frame(width: 80, alignment: .center)
            } else {
                // For cardio and recovery, show different fields
                Text("Duration")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(width: 80, alignment: .center)
                
                Text("Distance")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .frame(width: 80, alignment: .center)
            }
            
            Spacer()
            
            // Completion Checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if set.isCompleted {
                        set.reset()
                    } else {
                        set.complete()
                    }
                    try? modelContext.save()
                }
            }) {
                Image(systemName: set.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(set.isCompleted ? .blue : .textSecondary)
                    .font(.system(size: 24))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}