//
//  ExerciseRowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct ExerciseRowView: View {
    let exercise: Exercise
    let onEdit: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise image or type icon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                if !exercise.isCustom && ExerciseImageService.shared.hasSpecificImage(for: exercise.name) {
                    // Show exercise image for predefined exercises with images
                    ExerciseImageService.shared.getSwiftUIImage(for: exercise.name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(typeColor.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    // Show type icon for custom exercises or predefined without images
                    ZStack {
                        Image(systemName: exercise.type.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(typeColor)
                        
                        // Add small badge to indicate exercise source
                        if exercise.isCustom {
                            VStack {
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Image(systemName: "person.badge.plus")
                                                .font(.system(size: 6, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                Spacer()
                            }
                            .frame(width: 40, height: 40)
                        } else {
                            VStack {
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 6, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                Spacer()
                            }
                            .frame(width: 40, height: 40)
                        }
                    }
                }
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(exercise.isHidden ? .textSecondary : .textPrimary)
                        .lineLimit(1)
                    
                    if exercise.isHidden {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    if isExerciseCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .scaleEffect(1.1)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(exercise.type.displayName)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    if exercise.sets.count > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Text("\(completedSetsCount)/\(exercise.sets.count) sets")
                            .font(.caption)
                            .foregroundColor(isExerciseCompleted ? .green : .textSecondary)
                            .fontWeight(isExerciseCompleted ? .semibold : .regular)
                    }
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColorForExercise)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColorForExercise, lineWidth: 1)
                .opacity(borderOpacityForExercise)
        )
        .animation(.easeInOut(duration: 0.3), value: isExerciseCompleted)
        .animation(.easeInOut(duration: 0.3), value: exercise.isHidden)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.workoutButtonTap()
            onTap()
        }
    }
    
    // MARK: - Computed Properties
    
    private var typeColor: Color {
        switch exercise.type {
        case .resistance, .strength:
            return .blue
        case .cardio:
            return .red
        case .recovery, .flexibility:
            return .green
        }
    }
    
    private var completedSetsCount: Int {
        exercise.sets.filter { $0.isCompleted }.count
    }
    
    private var isExerciseCompleted: Bool {
        exercise.sets.count > 0 && completedSetsCount == exercise.sets.count
    }
    
    private var backgroundColorForExercise: Color {
        if exercise.isHidden {
            return Color.gray.opacity(0.1)
        } else if isExerciseCompleted {
            return Color.green.opacity(0.05)
        } else {
            return Color.surfaceWhite
        }
    }
    
    private var borderColorForExercise: Color {
        if exercise.isHidden {
            return Color.orange.opacity(0.3)
        } else if isExerciseCompleted {
            return Color.green.opacity(0.3)
        } else {
            return Color.border
        }
    }
    
    private var borderOpacityForExercise: Double {
        if exercise.isHidden || isExerciseCompleted {
            return 1.0
        } else {
            return 0.2
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ExerciseRowView(
            exercise: Exercise(
                name: "Bench Press",
                type: .resistance
            ),
            onEdit: { },
            onTap: { }
        )
        
        ExerciseRowView(
            exercise: Exercise(
                name: "Running",
                type: .cardio
            ),
            onEdit: { },
            onTap: { }
        )
        
        ExerciseRowView(
            exercise: Exercise(
                name: "Stretching",
                type: .recovery
            ),
            onEdit: { },
            onTap: { }
        )
    }
    .padding()
    .background(Color.backgroundSecondary)
}
