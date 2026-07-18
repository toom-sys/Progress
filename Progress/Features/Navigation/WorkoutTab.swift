//
//  WorkoutTab.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Workout Tab View

struct WorkoutTab: View {
    @StateObject private var deepLinkService = DeepLinkService.shared
    
    var body: some View {
        NavigationStack {
            WorkoutListView()
                .navigationDestination(item: $deepLinkService.workoutToOpen) { workout in
                    WorkoutDetailView(workout: workout)
                        .onAppear {
                            NotificationCenter.default.post(name: .showWorkoutDetail, object: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                deepLinkService.setDeepLinkInProgress(false)
                            }
                        }
                        .onDisappear {
                            if deepLinkService.workoutToOpen != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    deepLinkService.workoutToOpen = nil
                                    deepLinkService.shouldNavigateToWorkouts = false
                                }
                            }
                        }
                }
        }
    }
}
