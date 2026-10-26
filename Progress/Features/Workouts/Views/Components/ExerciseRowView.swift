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
                                        .fill(AppPalette.carbs)
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
                                        .fill(AppPalette.live)
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
                        .font(.appCardTitle)
                        .foregroundColor(exercise.isHidden ? AppPalette.muted : AppPalette.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if exercise.isHidden {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppPalette.carbs)
                    }
                    
                    if isExerciseCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppPalette.live)
                            .scaleEffect(1.1)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(exercise.type.displayName)
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)

                    if exercise.sets.count > 0 {
                        Text("·")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.muted)

                        Text("\(completedSetsCount)/\(exercise.sets.count) sets")
                            .font(.appSubtitle)
                            .foregroundColor(isExerciseCompleted ? AppPalette.liveText : AppPalette.muted)
                    }
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppPalette.muted.opacity(0.7))
                .accessibilityHidden(true)
        }
        .appCard(cornerRadius: 22, padding: 14)
        .overlay {
            if isExerciseCompleted {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppPalette.live.opacity(0.45), lineWidth: 1.5)
            } else if exercise.isHidden {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppPalette.carbs.opacity(0.45), lineWidth: 1.5)
            }
        }
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
            return Color.brand
        case .cardio:
            return AppPalette.protein
        case .recovery, .flexibility:
            return AppPalette.live
        }
    }
    
    private var completedSetsCount: Int {
        exercise.sets.filter { $0.isCompleted }.count
    }
    
    private var isExerciseCompleted: Bool {
        exercise.sets.count > 0 && completedSetsCount == exercise.sets.count
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
    .background(AppBackground())
}
