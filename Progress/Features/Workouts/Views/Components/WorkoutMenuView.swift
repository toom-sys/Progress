//
//  WorkoutMenuView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutMenuView: View {
    let workout: Workout
    let onRenameWorkout: () -> Void
    let onAddExercise: () -> Void
    let onMarkComplete: () -> Void
    let onDismiss: () -> Void
    
    // Check if there are any completed sets in the workout
    private var hasCompletedSets: Bool {
        workout.exercises.contains { exercise in
            exercise.sets.contains { $0.isCompleted }
        }
    }
    
    var body: some View {
        ZStack {
            // Transparent background for tap-to-dismiss
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Menu card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Workout Options")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.backgroundSecondary)
                
                // Menu options
                VStack(spacing: 0) {
                    MenuOptionView(
                        icon: "pencil",
                        title: "Rename Workout",
                        subtitle: "Change the workout name",
                        action: {
                            HapticFeedback.workoutButtonTap()
                            onRenameWorkout()
                            onDismiss()
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    MenuOptionView(
                        icon: "plus.circle",
                        title: "Add Exercise",
                        subtitle: "Add a new exercise to this workout",
                        action: {
                            HapticFeedback.workoutButtonTap()
                            onAddExercise()
                            onDismiss()
                        }
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    MenuOptionView(
                        icon: "checkmark.circle",
                        title: "Mark Complete",
                        subtitle: hasCompletedSets ? "Mark this workout as completed" : "Complete at least one set first",
                        isEnabled: hasCompletedSets,
                        action: {
                            HapticFeedback.workoutCompleted()
                            onMarkComplete()
                            onDismiss()
                        }
                    )
                }
                .background(Color.surfaceWhite)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
}

private struct MenuOptionView: View {
    let icon: String
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: isEnabled ? action : {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isEnabled ? .blue : .gray)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? .textPrimary : .gray)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isEnabled ? .textSecondary : .gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isEnabled ? .textTertiary : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

#Preview {
    WorkoutMenuView(
        workout: Workout(name: "Test Workout"),
        onRenameWorkout: { },
        onAddExercise: { },
        onMarkComplete: { },
        onDismiss: { }
    )
}
