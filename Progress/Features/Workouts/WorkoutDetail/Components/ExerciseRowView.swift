//
//  ExerciseRowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise
    let onDelete: () -> Void
    let onTap: (CGRect) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                // Exercise Type Icon
                Image(systemName: exercise.type.icon)
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        Text(exercise.type.displayName)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        if !exercise.sets.isEmpty {
                            Text("• \(exercise.sets.count) sets")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Progress indicator
                if !exercise.sets.isEmpty {
                    Text("\(exercise.completedSetsCount)/\(exercise.sets.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.backgroundTertiary)
                        .clipShape(Capsule())
                }
            }
            .whiteCardStyle()
            .onTapGesture {
                let globalFrame = geometry.frame(in: .global)
                onTap(globalFrame)
            }
        }
        .frame(height: 80) // Fixed height for consistent layout
    }
}