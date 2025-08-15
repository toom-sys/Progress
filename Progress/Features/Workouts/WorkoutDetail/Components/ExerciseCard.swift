//
//  ExerciseCard.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text(exercise.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            if !exercise.sets.isEmpty {
                Text("\(exercise.sets.count) sets")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .whiteCardStyle(cornerRadius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}