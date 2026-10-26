//
//  WorkoutListContent.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData
import UIKit

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

    private let revealWidth: CGFloat = 88
    private let cardCornerRadius: CGFloat = 22

    var body: some View {
        ZStack(alignment: .trailing) {
            // Same shape as the card, so the rounded corners reveal red instead of the page.
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color.red)
                .opacity(offset < 0 ? 1 : 0)
                .allowsHitTesting(false)

            WorkoutRowView(workout: workout)
                .overlay {
                    WorkoutRowSwipeLayer(
                        offset: $offset,
                        revealWidth: revealWidth,
                        onTap: handleTap
                    )
                }
                .offset(x: offset)

            deleteButton
                .frame(width: revealWidth)
                .frame(maxHeight: .infinity)
                .opacity(offset < 0 ? 1 : 0)
                .allowsHitTesting(offset < 0)
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete")
    }

    private func handleTap() {
        if offset != 0 {
            settle(to: 0)
        } else {
            onOpen()
        }
    }

    private func settle(to target: CGFloat) {
        withAnimation(.smooth(duration: 0.2)) {
            offset = target
        }
    }
}

/// Horizontal reveal that stays with the finger. A SwiftUI drag inside the
/// scroll view was being cancelled and restarted, which snapped the card back and forth.
private struct WorkoutRowSwipeLayer: UIViewRepresentable {
    @Binding var offset: CGFloat
    var revealWidth: CGFloat
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset, revealWidth: revealWidth, onTap: onTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        pan.cancelsTouchesInView = true
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.offset = $offset
        context.coordinator.revealWidth = revealWidth
        context.coordinator.onTap = onTap
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var offset: Binding<CGFloat>
        var revealWidth: CGFloat
        var onTap: () -> Void
        private var dragStart: CGFloat = 0

        init(offset: Binding<CGFloat>, revealWidth: CGFloat, onTap: @escaping () -> Void) {
            self.offset = offset
            self.revealWidth = revealWidth
            self.onTap = onTap
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer.view is UIScrollView
        }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            switch pan.state {
            case .began:
                dragStart = offset.wrappedValue
                pan.setTranslation(.zero, in: pan.view)
            case .changed:
                let next = dragStart + pan.translation(in: pan.view).x
                let clamped = min(max(next, -revealWidth), 0)
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    offset.wrappedValue = clamped
                }
            case .ended, .cancelled, .failed:
                let next = dragStart + pan.translation(in: pan.view).x
                let target: CGFloat = next < -revealWidth * 0.45 ? -revealWidth : 0
                withAnimation(.smooth(duration: 0.2)) {
                    offset.wrappedValue = target
                }
            default:
                break
            }
        }

        @objc func handleTap(_ tap: UITapGestureRecognizer) {
            guard tap.state == .ended else { return }
            onTap()
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
