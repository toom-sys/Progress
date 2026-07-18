//
//  ExerciseList.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseList: View {
    let exercises: [ExerciseDatabase.PredefinedExercise]
    let showCategory: Bool
    let onExerciseSelected: (ExerciseDatabase.PredefinedExercise) -> Void
    
    init(exercises: [ExerciseDatabase.PredefinedExercise], showCategory: Bool = false, onExerciseSelected: @escaping (ExerciseDatabase.PredefinedExercise) -> Void) {
        self.exercises = exercises
        self.showCategory = showCategory
        self.onExerciseSelected = onExerciseSelected
    }
    
    var body: some View {
        ForEach(exercises, id: \.name) { exercise in
            ExerciseOptionRowView(
                exercise: exercise,
                showCategory: showCategory,
                onTap: {
                    HapticFeedback.workoutButtonTap()
                    onExerciseSelected(exercise)
                }
            )
        }
    }
}

private struct ExerciseOptionRowView: View {
    let exercise: ExerciseDatabase.PredefinedExercise
    let showCategory: Bool
    let onTap: () -> Void
    
    init(exercise: ExerciseDatabase.PredefinedExercise, showCategory: Bool = false, onTap: @escaping () -> Void) {
        self.exercise = exercise
        self.showCategory = showCategory
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise image or icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                if ExerciseImageService.shared.hasSpecificImage(for: exercise.name) {
                    ExerciseImageService.shared.getSwiftUIImage(for: exercise.name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Image(systemName: fallbackIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(categoryColor)
                }
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                if showCategory {
                    HStack(spacing: 4) {
                        Text(exercise.category)
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        
                        Text(exercise.type)
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Add button
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var categoryColor: Color {
        switch exercise.category.lowercased() {
        case "resistance":
            return .blue
        case "cardio":
            return .red
        case "recovery":
            return .green
        default:
            return .blue
        }
    }
    
    private var fallbackIcon: String {
        switch exercise.category.lowercased() {
        case "resistance":
            return "dumbbell.fill"
        case "cardio":
            return "heart.fill"
        case "recovery":
            return "leaf.fill"
        default:
            return "dumbbell.fill"
        }
    }
}

#Preview {
    ExerciseList(
        exercises: [],
        onExerciseSelected: { _ in }
    )
}
