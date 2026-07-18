//
//  WorkoutFloatingAddButton.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Workout Floating Add Button Component

struct WorkoutFloatingAddButton: View {
    @Binding var showingCreateWorkout: Bool
    @EnvironmentObject private var keyboardObserver: KeyboardObserver
    
    var body: some View {
        VStack {
            Spacer()
            
            // Hide add button when keyboard is visible
            if !keyboardObserver.isKeyboardVisible {
                HStack {
                Spacer()
                
                Button(action: {
                    HapticFeedback.workoutButtonTap()
                    showingCreateWorkout = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.border.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
            .padding(.bottom, 120) // Position above the tab bar
            }
        }
    }
}

#Preview {
    WorkoutFloatingAddButton(showingCreateWorkout: .constant(false))
}
