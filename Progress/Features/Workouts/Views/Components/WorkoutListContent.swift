//
//  WorkoutListContent.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct WorkoutListContent: View {
    let workouts: [Workout]
    let onDeleteWorkout: (Workout) -> Void
    let onShareWorkout: (Workout) -> Void

    var body: some View {
        if workouts.isEmpty {
            Spacer()
            ContentUnavailableView(
                "No Workouts",
                systemImage: "dumbbell",
                description: Text("Create your first workout to get started")
            )
            Spacer()
        } else {
            List {
                ForEach(workouts, id: \.id) { workout in
                    ZStack {
                        // Hidden NavigationLink
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        // Visible content
                        WorkoutRowView(workout: workout)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            onShareWorkout(workout)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            onDeleteWorkout(workout)
                        }
                    }
                }
                
                // Add some bottom padding for the floating button
                Color.clear
                    .frame(height: 100)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    NavigationView {
        WorkoutListContent(
            workouts: [],
            onDeleteWorkout: { _ in },
            onShareWorkout: { _ in }
        )
    }
}
