//
//  TrainingPlanCard.swift
//  Progress
//

import SwiftUI
import SwiftData

struct TrainingPlanCard: View {
    let plan: TrainingPlan
    let onStartWorkout: (Workout) -> Void

    private var sortedWorkouts: [Workout] {
        plan.workouts
            .filter { !$0.isDeleted }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR PLAN")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(plan.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text(plan.splitType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }

            VStack(spacing: 10) {
                ForEach(sortedWorkouts, id: \.id) { workout in
                    PlanWorkoutRow(
                        workout: workout,
                        onStart: {
                            HapticFeedback.workoutButtonTap()
                            onStartWorkout(workout)
                        }
                    )
                }
            }
        }
        .whiteCardStyle(cornerRadius: 16, padding: 20)
    }
}

// MARK: - Plan Workout Row

private struct PlanWorkoutRow: View {
    let workout: Workout
    let onStart: () -> Void

    private var sessionIndex: Int {
        workout.planSessionIndex ?? 1
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("Session \(sessionIndex) of 5")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)

                    PlanSessionDotStrip(currentSession: sessionIndex)
                }
            }

            Spacer(minLength: 0)

            Button(action: onStart) {
                Text("Start")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Session Dot Strip

private struct PlanSessionDotStrip: View {
    let currentSession: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...5, id: \.self) { index in
                PlanSessionDot(
                    isFilled: index <= currentSession,
                    isDeload: index == 5
                )
                .accessibilityLabel(dotAccessibilityLabel(for: index))
            }
        }
    }

    private func dotAccessibilityLabel(for index: Int) -> String {
        let phase = ProgressionEngine.phase(forSessionIndex: index).displayName
        if index <= currentSession {
            return "Session \(index), \(phase), completed or current"
        }
        return "Session \(index), \(phase), upcoming"
    }
}

private struct PlanSessionDot: View {
    let isFilled: Bool
    let isDeload: Bool

    private var strokeColor: Color {
        if isDeload { return .orange }
        if isFilled { return .blue }
        return .blue.opacity(0.35)
    }

    private var fillColor: Color {
        if isFilled {
            return isDeload ? .orange : .blue
        }
        return .clear
    }

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: isDeload ? 1.5 : 1)
            )
    }
}

#Preview {
    TrainingPlanCard(
        plan: TrainingPlan(name: "Upper/Lower Plan", splitType: .upperLower),
        onStartWorkout: { _ in }
    )
    .padding()
    .background(Color.backgroundSecondary)
}
