//
//  PlanPreviewView.swift
//  Progress
//

import SwiftUI
import SwiftData

struct PlanPreviewView: View {

    @Environment(\.modelContext) private var modelContext

    let generationContext: PlanGenerationContext

    @Binding var planSplit: PlanSplitType
    @Binding var planWorkouts: [GeneratedWorkout]

    @State private var isGenerating = false
    @State private var showingExercisePicker = false
    @State private var swappingContext: (workoutIndex: Int, exerciseIndex: Int)?

    private let pickerWorkout = Workout(name: "Plan Preview")

    private var questionnaire: PlanQuestionnaire { generationContext.questionnaire }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingStepHeader(
                    title: isGenerating ? "Building your plan" : "Your plan, ready to go",
                    subtitle: isGenerating
                        ? "Your coach is designing workouts around your goal, experience and setup."
                        : "We've picked the exercises for your first block. Swap any you don't like.",
                    alignment: .center
                )
                .padding(.top, 12)

                if isGenerating {
                    PlanGenerationLoadingView()
                        .padding(.top, 24)
                } else {
                    Text(planSplit.displayName)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(OnboardingPalette.onInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(OnboardingPalette.ink))

                    Text("\(questionnaire.clampedWorkoutCount) repeating workouts · \(questionnaire.environment.displayName)")
                        .font(.subheadline)
                        .foregroundColor(OnboardingPalette.muted)

                    LazyVStack(spacing: 20) {
                        ForEach(Array(planWorkouts.enumerated()), id: \.offset) { workoutIndex, workout in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(workout.name)
                                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                                    .foregroundColor(OnboardingPalette.ink)

                                ForEach(Array(workout.baselines.enumerated()), id: \.offset) { exerciseIndex, exercise in
                                    PlanExerciseCard(
                                        exerciseName: exercise.exerciseName,
                                        detailLine: "\(exercise.setCount) sets",
                                        onSwap: {
                                            swappingContext = (workoutIndex, exerciseIndex)
                                            showingExercisePicker = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 100)
            }
        }
        .task {
            await generatePlanIfNeeded()
        }
        .overlay {
            if showingExercisePicker {
                ExercisePickerView(
                    workout: pickerWorkout,
                    onExerciseSelected: { predefined in
                        applySwap(with: predefined)
                        showingExercisePicker = false
                        swappingContext = nil
                    },
                    onDismiss: {
                        showingExercisePicker = false
                        swappingContext = nil
                    }
                )
            }
        }
    }

    // MARK: - Private

    /// Generates the plan with AI using the full onboarding profile, falling
    /// back to the rule-based generator if the request or parsing fails.
    private func generatePlanIfNeeded() async {
        guard planWorkouts.isEmpty, !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }

        do {
            let generator = AITrainingPlanGenerator()
            let generated = try await generator.generatePlan(from: generationContext)
            planSplit = generated.split
            planWorkouts = generated.workouts
        } catch {
            #if DEBUG
            print("⚠️ PlanPreviewView: AI generation failed (\(error.localizedDescription)) — using rule-based fallback")
            #endif
            let generated = TrainingPlanGenerator.generate(from: questionnaire)
            planSplit = generated.split
            planWorkouts = generated.workouts
        }
    }

    private func applySwap(with predefined: ExerciseDatabase.PredefinedExercise) {
        guard let context = swappingContext,
              planWorkouts.indices.contains(context.workoutIndex) else { return }

        let workout = planWorkouts[context.workoutIndex]
        guard workout.baselines.indices.contains(context.exerciseIndex) else { return }

        let existing = workout.baselines[context.exerciseIndex]
        let mode = TrainingPlanGenerator.progressionMode(for: predefined.name)
        var updatedBaselines = workout.baselines

        switch mode {
        case .timed:
            updatedBaselines[context.exerciseIndex] = ExerciseBaseline(
                exerciseName: predefined.name,
                predefinedExerciseId: predefined.name,
                mode: .timed,
                weightKg: 0,
                reps: 0,
                durationSec: existing.mode == .timed ? existing.durationSec : 30,
                setCount: existing.setCount
            )
        case .bodyweight:
            updatedBaselines[context.exerciseIndex] = ExerciseBaseline(
                exerciseName: predefined.name,
                predefinedExerciseId: predefined.name,
                mode: .bodyweight,
                weightKg: 0,
                reps: existing.mode == .bodyweight ? existing.reps : 8,
                setCount: existing.setCount
            )
        case .weighted:
            updatedBaselines[context.exerciseIndex] = ExerciseBaseline(
                exerciseName: predefined.name,
                predefinedExerciseId: predefined.name,
                mode: .weighted,
                weightKg: existing.mode == .weighted ? existing.weightKg : 20,
                reps: existing.reps,
                setCount: existing.setCount
            )
        }

        planWorkouts[context.workoutIndex] = GeneratedWorkout(
            name: workout.name,
            baselines: updatedBaselines
        )
    }
}

// MARK: - Generation Loading View

/// Spinner with rotating status lines shown while the AI plan request runs.
private struct PlanGenerationLoadingView: View {
    @State private var messageIndex = 0

    private let messages = [
        "Analyzing your profile…",
        "Choosing your split…",
        "Picking exercises for your setup…",
        "Setting your starting targets…"
    ]

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.brand)

            Text(messages[messageIndex])
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(OnboardingPalette.muted)
                .transition(.opacity)
                .id(messageIndex)
                .animation(.easeInOut(duration: 0.3), value: messageIndex)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
    }
}

// MARK: - Plan Exercise Card

private struct PlanExerciseCard: View {
    let exerciseName: String
    let detailLine: String
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(OnboardingPalette.ink)

                Text(detailLine)
                    .font(.system(size: 12.5))
                    .foregroundColor(OnboardingPalette.muted)
            }

            Spacer()

            Button("Swap", action: onSwap)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.brand)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onboardingSurfaceCard(cornerRadius: 16)
    }
}

#Preview {
    PlanPreviewView(
        generationContext: PlanGenerationContext(
            questionnaire: PlanQuestionnaire(
                goal: .muscleGain,
                experience: .beginner,
                environment: .gym,
                workoutCount: 2,
                focus: [.upperBody, .lowerBody]
            ),
            age: 28,
            biologicalSex: .male,
            heightCm: 180,
            weightKg: 78,
            activityLevel: .moderate,
            gymChallenge: .notKnowingWhatToDo,
            motivationBarrier: .motivation,
            preferredUnits: .metric
        ),
        planSplit: .constant(.fullBody),
        planWorkouts: .constant([])
    )
    .modelContainer(for: User.self, inMemory: true)
}
