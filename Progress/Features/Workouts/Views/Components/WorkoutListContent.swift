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
    var plan: TrainingPlan?
    var history: [Workout] = []
    let onDeleteWorkout: (Workout) -> Void
    let onShareWorkout: (Workout) -> Void
    var onStartPlanWorkout: (Workout) -> Void = { _ in }

    var body: some View {
        if workouts.isEmpty {
            emptyState
        } else {
            workoutList
        }
    }

    /// Plan card stays above the unchanged empty state when there are no custom workouts.
    /// Once custom workouts exist, the plan scrolls with them as the first list row.
    private var emptyState: some View {
        VStack(spacing: 0) {
            if let plan {
                planCard(plan)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }

            Spacer(minLength: 0)

            ContentUnavailableView(
                "No Workouts",
                systemImage: "dumbbell",
                description: Text("Create your first workout to get started")
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var workoutList: some View {
        List {
            if let plan {
                planCard(plan)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 18, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Text("YOUR WORKOUTS")
                .font(.system(size: 13, weight: .heavy))
                .tracking(0.4)
                .foregroundColor(AppPalette.muted)
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(workouts, id: \.id) { workout in
                ZStack {
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        EmptyView()
                    }
                    .opacity(0)

                    WorkoutRowView(workout: workout)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        onShareWorkout(workout)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(Color.brand)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        onDeleteWorkout(workout)
                    }
                }
            }

            Color.clear
                .frame(height: 100)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }

    private func planCard(_ plan: TrainingPlan) -> some View {
        TrainingPlanCard(
            plan: plan,
            history: history,
            onStartWorkout: onStartPlanWorkout
        )
    }
}

#Preview {
    NavigationStack {
        WorkoutListContent(
            workouts: [],
            onDeleteWorkout: { _ in },
            onShareWorkout: { _ in }
        )
    }
}
