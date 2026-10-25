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
    let onShareWorkout: (Workout) -> Void
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
                            onShare: { onShareWorkout(workout) },
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

/// Leading share and trailing delete, without putting the row in a list cell.
private struct WorkoutSwipeRow: View {
    let workout: Workout
    let onOpen: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragAxis: Axis?
    @State private var dragStart: CGFloat = 0

    private let revealWidth: CGFloat = 88

    var body: some View {
        ZStack {
            actions

            row
                .offset(x: offset)
                .contentShape(Rectangle())
                .simultaneousGesture(swipeGesture)
        }
        .accessibilityAction(.default, onOpen)
        .accessibilityAction(named: Text("Share"), onShare)
        .accessibilityAction(named: Text("Delete"), onDelete)
    }

    private var row: some View {
        WorkoutRowView(workout: workout)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 0) {
            if offset > 0 {
                swipeButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    tint: Color.brand,
                    action: {
                        settle(to: 0)
                        onShare()
                    }
                )
                .frame(width: revealWidth)
                Spacer(minLength: 0)
            }
            if offset < 0 {
                Spacer(minLength: 0)
                swipeButton(
                    title: "Delete",
                    systemImage: "trash",
                    tint: .red,
                    action: {
                        settle(to: 0)
                        onDelete()
                    }
                )
                .frame(width: revealWidth)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func swipeButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
                offset = min(max(next, -revealWidth), revealWidth)
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
                let target: CGFloat
                if next > revealWidth * 0.45 {
                    target = revealWidth
                } else if next < -revealWidth * 0.45 {
                    target = -revealWidth
                } else {
                    target = 0
                }
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
            onDeleteWorkout: { _ in },
            onShareWorkout: { _ in }
        )
    }
}
