//
//  WorkoutRowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct WorkoutRowView: View {
    let workout: Workout
    
    private static let creationDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var creationDate: String {
        Self.creationDateFormatter.string(from: workout.createdAt)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\(workout.exercises.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    
                    Text("exercises")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            // Creation date
            VStack(alignment: .trailing, spacing: 2) {
                Text("Created")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
                
                Text(creationDate)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .whiteCardStyleWithBorder(cornerRadius: 12, padding: 16)
    }
}

#Preview {
    WorkoutRowView(workout: Workout(name: "Sample Workout"))
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
