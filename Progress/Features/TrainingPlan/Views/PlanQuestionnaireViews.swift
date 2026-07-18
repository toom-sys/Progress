//
//  PlanQuestionnaireViews.swift
//  Progress
//

import SwiftUI

// MARK: - Focus Helper

enum PlanQuestionnaireFocus {

    static func focusAreas(
        goal: FitnessGoal,
        workoutCount: Int,
        gymChallenge: GymChallenge
    ) -> [FocusArea] {
        var focus = TrainingPlanGenerator.defaultFocus(for: goal)
        if workoutCount >= 3, !focus.contains(.core) {
            focus.append(.core)
        }
        if gymChallenge == .hittingPlateaus, !focus.contains(.fullBody) {
            focus.append(.fullBody)
        }
        return focus
    }
}

// MARK: - Gym Challenge

struct PlanGymChallengeSelectionView: View {
    @Binding var selectedChallenge: GymChallenge

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingChatBubble(question: "What's your biggest challenge in the gym?")
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(GymChallenge.allCases, id: \.self) { challenge in
                        OnboardingOptionRow(
                            emoji: challenge.onboardingEmoji,
                            title: challenge.displayName,
                            subtitle: challenge.description,
                            isSelected: selectedChallenge == challenge
                        ) {
                            selectedChallenge = challenge
                        }
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Motivation

struct PlanMotivationSelectionView: View {
    @Binding var selectedBarrier: MotivationBarrier

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingChatBubble(question: "What's stopping you reaching the body you want?")
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(MotivationBarrier.allCases, id: \.self) { barrier in
                        OnboardingOptionRow(
                            emoji: barrier.onboardingEmoji,
                            title: barrier.displayName,
                            subtitle: barrier.description,
                            isSelected: selectedBarrier == barrier
                        ) {
                            selectedBarrier = barrier
                        }
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Training Environment

struct PlanTrainingEnvironmentSelectionView: View {
    @Binding var selectedEnvironment: WorkoutEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingChatBubble(question: "Where do you train?")
                .padding(.top, 8)

            VStack(spacing: 12) {
                OnboardingOptionRow(
                    emoji: "🏠",
                    title: "Home",
                    subtitle: "Bodyweight, dumbbells and minimal equipment",
                    isSelected: selectedEnvironment == .home
                ) {
                    selectedEnvironment = .home
                }

                OnboardingOptionRow(
                    emoji: "🏋️",
                    title: "Gym",
                    subtitle: "Full gym access with barbells and machines",
                    isSelected: selectedEnvironment == .gym
                ) {
                    selectedEnvironment = .gym
                }
            }

            OnboardingNotePill(
                emoji: "💡",
                text: "We'll only pick exercises you can actually do in your setup."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Workout Count

struct PlanWorkoutCountSelectionView: View {
    @Binding var selectedWorkoutCount: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingChatBubble(question: "How many different workouts do you want?")
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(1...4, id: \.self) { count in
                        OnboardingOptionRow(
                            emoji: PlanWorkoutCountLabels.emoji(for: count),
                            title: PlanWorkoutCountLabels.title(for: count),
                            subtitle: PlanWorkoutCountLabels.subtitle(for: count),
                            isSelected: selectedWorkoutCount == count
                        ) {
                            selectedWorkoutCount = count
                        }
                    }
                }

                OnboardingNotePill(
                    emoji: "🔁",
                    text: "Each workout repeats on its own schedule — rotate through them at your pace across a 5-session block."
                )

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }
}

enum PlanWorkoutCountLabels {
    static func emoji(for count: Int) -> String {
        switch count {
        case 1: return "1️⃣"
        case 2: return "2️⃣"
        case 3: return "3️⃣"
        default: return "4️⃣"
        }
    }

    static func title(for count: Int) -> String {
        switch count {
        case 1: return "1 workout"
        case 2: return "2 workouts"
        case 3: return "3 workouts"
        default: return "4 workouts"
        }
    }

    static func subtitle(for count: Int) -> String {
        switch count {
        case 1: return "One full-body session to repeat"
        case 2: return "e.g. Upper & Lower — rotate between them"
        case 3: return "e.g. Upper, Lower & Abs"
        default: return "e.g. Push, Pull, Legs & Core"
        }
    }
}
