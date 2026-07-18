//
//  PlanSessionAdvancementPopup.swift
//  Progress
//

import SwiftUI
import SwiftData

struct PlanSessionAdvancementPopup: View {
    let workout: Workout
    let sessionIndex: Int
    let phase: PlanWorkoutPhase
    let units: UnitSystem
    let onDismiss: () -> Void

    private var sortedExercises: [Exercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: phase == .deload ? "leaf.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(phase == .deload ? .orange : .brand)

                    Text("Session \(sessionIndex) ready")
                        .font(.title2)
                        .fontWeight(.bold)

                    if phase == .deload {
                        Text("Recovery / Deload")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())

                        Text("Lighter loads and fewer sets to recover before your next block.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Your next session targets are set for \(workout.name).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(sortedExercises, id: \.id) { exercise in
                            HStack(alignment: .top, spacing: 12) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(ProgressionEngine.formattedTargetLine(for: exercise, units: units))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: 220)

                Button("Got it") {
                    HapticFeedback.workoutButtonTap()
                    onDismiss()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.brand)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 28)
        }
    }
}
