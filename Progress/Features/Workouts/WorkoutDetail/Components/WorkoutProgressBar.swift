//
//  WorkoutProgressBar.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutProgressBar: View {
    let workout: Workout
    
    private var completionProgress: Double {
        guard !workout.exercises.isEmpty else { return 0.0 }
        
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        guard totalSets > 0 else { return 0.0 }
        
        let completedSets = workout.exercises.reduce(0) { result, exercise in
            result + exercise.sets.filter { $0.isCompleted }.count
        }
        
        return Double(completedSets) / Double(totalSets)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(Int(completionProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.primary, .accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * completionProgress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: completionProgress)
                }
            }
            .frame(height: 8)
        }
    }
}