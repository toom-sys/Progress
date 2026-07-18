//
//  WorkoutListOverlays.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutListOverlays: View {
    @Binding var showingCreateWorkout: Bool
    
    var body: some View {
        if showingCreateWorkout {
            CreateWorkoutView(
                onWorkoutCreated: { _ in
                    dismissCreateWorkout()
                },
                onDismiss: {
                    dismissCreateWorkout()
                }
            )
            .transition(
                .opacity
                    .combined(with: .scale(scale: 0.96, anchor: .center))
            )
            .zIndex(1000)
        }
    }
    
    private func dismissCreateWorkout() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showingCreateWorkout = false
        }
    }
}

#Preview {
    @Previewable @State var showingCreateWorkout = false
    
    return WorkoutListOverlays(
        showingCreateWorkout: $showingCreateWorkout
    )
}
