//
//  TrainingPlanSetupFlowView.swift
//  Progress
//

import SwiftUI
import SwiftData

enum TrainingPlanSetupStep: Int, CaseIterable {
    case gymChallenge
    case motivation
    case trainingEnvironment
    case workoutCount
    case planPreview
    case confirmBaseline

    var nextButtonTitle: String {
        switch self {
        case .gymChallenge, .motivation, .trainingEnvironment, .workoutCount:
            return "Next"
        case .planPreview:
            return "Looks good — set my targets"
        case .confirmBaseline:
            return "Save plan"
        }
    }
}

struct TrainingPlanSetupFlowView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let user: User
    var onPlanCreated: () -> Void

    @State private var currentStep: TrainingPlanSetupStep = .gymChallenge
    @State private var selectedGymChallenge: GymChallenge = .notKnowingWhatToDo
    @State private var selectedMotivationBarrier: MotivationBarrier = .motivation
    @State private var selectedEnvironment: WorkoutEnvironment = .gym
    @State private var selectedWorkoutCount: Int = 2
    @State private var planSplit: PlanSplitType = .fullBody
    @State private var planWorkouts: [GeneratedWorkout] = []
    @State private var baselineWorkoutEntries: [BaselineWorkoutEntry] = []
    @State private var saveError: String?

    private var questionnaire: PlanQuestionnaire {
        PlanQuestionnaire(
            goal: user.fitnessGoal,
            experience: user.fitnessLevel,
            environment: selectedEnvironment,
            workoutCount: selectedWorkoutCount,
            focus: PlanQuestionnaireFocus.focusAreas(
                goal: user.fitnessGoal,
                workoutCount: selectedWorkoutCount,
                gymChallenge: selectedGymChallenge
            )
        )
    }

    private var generationContext: PlanGenerationContext {
        PlanGenerationContext.from(
            user: user,
            questionnaire: questionnaire,
            gymChallenge: selectedGymChallenge,
            motivationBarrier: selectedMotivationBarrier
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OnboardingBackground()

                VStack(spacing: 0) {
                    progressIndicator
                        .padding(.top, 12)
                        .padding(.horizontal, 24)

                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Start Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn't save plan", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .onChange(of: selectedEnvironment) { _, _ in resetGeneratedPlan() }
        .onChange(of: selectedWorkoutCount) { _, _ in resetGeneratedPlan() }
        .onChange(of: planWorkouts) { _, _ in baselineWorkoutEntries = [] }
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        OnboardingProgressBar(
            current: currentStepNumber,
            total: TrainingPlanSetupStep.allCases.count
        )
    }

    private var currentStepNumber: Int {
        (TrainingPlanSetupStep.allCases.firstIndex(of: currentStep) ?? 0) + 1
    }

    // MARK: - Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .gymChallenge:
            PlanGymChallengeSelectionView(selectedChallenge: $selectedGymChallenge)
        case .motivation:
            PlanMotivationSelectionView(selectedBarrier: $selectedMotivationBarrier)
        case .trainingEnvironment:
            PlanTrainingEnvironmentSelectionView(selectedEnvironment: $selectedEnvironment)
        case .workoutCount:
            PlanWorkoutCountSelectionView(selectedWorkoutCount: $selectedWorkoutCount)
        case .planPreview:
            PlanPreviewView(
                generationContext: generationContext,
                planSplit: $planSplit,
                planWorkouts: $planWorkouts
            )
        case .confirmBaseline:
            BaselineConfirmationView(
                units: user.preferredUnits,
                planWorkouts: planWorkouts,
                workoutEntries: $baselineWorkoutEntries
            )
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .gymChallenge {
                OnboardingBackButton(action: goBack)
                    .frame(width: 44, height: 44)
            }

            Button(action: goForward) {
                Text(currentStep.nextButtonTitle)
            }
            .buttonStyle(OnboardingPrimaryButtonStyle(isEnabled: canProceed))
            .disabled(!canProceed)
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .gymChallenge, .motivation, .trainingEnvironment, .workoutCount:
            return true
        case .planPreview:
            return !planWorkouts.isEmpty
        case .confirmBaseline:
            return true
        }
    }

    private func goBack() {
        guard let index = TrainingPlanSetupStep.allCases.firstIndex(of: currentStep),
              index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = TrainingPlanSetupStep.allCases[index - 1]
        }
    }

    private func goForward() {
        switch currentStep {
        case .confirmBaseline:
            savePlan()
        default:
            guard let index = TrainingPlanSetupStep.allCases.firstIndex(of: currentStep),
                  index < TrainingPlanSetupStep.allCases.count - 1 else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep = TrainingPlanSetupStep.allCases[index + 1]
            }
        }
    }

    // MARK: - Plan Actions

    private func resetGeneratedPlan() {
        planWorkouts = []
        baselineWorkoutEntries = []
    }

    private func savePlan() {
        guard let workouts = BaselineConfirmationView.buildGeneratedWorkouts(
                from: baselineWorkoutEntries,
                units: user.preferredUnits
              ) else { return }

        let service = TrainingPlanService(modelContext: modelContext)
        do {
            _ = try service.createPlan(
                for: user,
                name: "\(planSplit.displayName) Plan",
                split: planSplit,
                workouts: workouts
            )
            HapticFeedback.workoutButtonTap()
            onPlanCreated()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
