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
    var activeWorkout: Workout?
    let onDeleteWorkout: (Workout) -> Void
    var onOpenWorkout: (Workout) -> Void = { _ in }

    var body: some View {
        if workouts.isEmpty && activeWorkout == nil {
            emptyState
        } else {
            workoutList
        }
    }

    /// Plan card stays above the unchanged empty state when there are no custom workouts
    /// and nothing is in progress.
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

    /// Cards sit in a normal stack, not list rows. A list cell under the live card
    /// cannot animate its height without fighting the cell above it.
    private var workoutList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let activeWorkout {
                    ActiveWorkoutCard(workout: activeWorkout, onResume: onOpenWorkout)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }

                if let plan {
                    planCard(plan)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }

                if !workouts.isEmpty {
                    Text("YOUR WORKOUTS")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(0.4)
                        .foregroundColor(AppPalette.muted)
                        .padding(.leading, 24)
                        .padding(.trailing, 20)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(workouts, id: \.id) { workout in
                        WorkoutSwipeRow(
                            workout: workout,
                            onOpen: { onOpenWorkout(workout) },
                            onDelete: { onDeleteWorkout(workout) }
                        )
                    }
                }

                Color.clear
                    .frame(height: 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func planCard(_ plan: TrainingPlan) -> some View {
        TrainingPlanCard(
            plan: plan,
            history: history,
            activeWorkoutId: activeWorkout?.id,
            onStartWorkout: onOpenWorkout
        )
    }
}

/// Trailing delete sits behind the row and is uncovered by a left swipe.
private struct WorkoutSwipeRow: View {
    let workout: Workout
    let onOpen: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragAxis: Axis?
    @State private var dragStart: CGFloat = 0

    private let revealWidth: CGFloat = 88

    var body: some View {
        ZStack(alignment: .trailing) {
            if offset < 0 {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { settle(to: 0) }
            }

            deleteButton
                .frame(width: revealWidth)
                .frame(maxHeight: .infinity)
                .opacity(offset < 0 ? 1 : 0)
                .allowsHitTesting(offset < 0)

            WorkoutRowView(workout: workout)
                .contentShape(Rectangle())
                .simultaneousGesture(swipeGesture)
                .offset(x: offset)
                .allowsHitTesting(offset == 0)
        }
        // Height comes from the card, so the delete control can't grow past it.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .accessibilityAction(.default, onOpen)
        .accessibilityAction(named: Text("Delete"), onDelete)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                Text("Delete")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 22,
                    topTrailingRadius: 22,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete")
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation
                let distance = hypot(translation.width, translation.height)
                if dragAxis == nil {
                    guard distance >= 12 else { return }
                    let isHorizontal = abs(translation.width) > abs(translation.height)
                    dragAxis = isHorizontal ? .horizontal : .vertical
                    dragStart = offset
                }
                guard dragAxis == .horizontal else { return }
                let next = dragStart + translation.width
                offset = min(max(next, -revealWidth), 0)
            }
            .onEnded { value in
                let translation = value.translation
                let distance = hypot(translation.width, translation.height)
                let wasHorizontal = dragAxis == .horizontal
                dragAxis = nil
                if !wasHorizontal && distance < 12 {
                    if offset != 0 {
                        settle(to: 0)
                    } else {
                        onOpen()
                    }
                    return
                }
                guard wasHorizontal else { return }
                let next = dragStart + translation.width
                let target: CGFloat = next < -revealWidth * 0.45 ? -revealWidth : 0
                settle(to: target)
            }
    }

    private func settle(to target: CGFloat) {
        withAnimation(.smooth(duration: 0.2)) {
            offset = target
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutListContent(
            workouts: [],
            onDeleteWorkout: { _ in }
        )
    }
}
