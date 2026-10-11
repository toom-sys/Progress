//
//  OnboardingView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData
import StoreKit

enum OnboardingProgressStore {
    static let stepKey = "onboarding_current_step"
    static let ageKey = "onboarding_age"
    static let goalKey = "onboarding_goal"
    static let levelKey = "onboarding_level"
    static let unitsKey = "onboarding_units"

    static func resetSavedProgress() {
        let defaults = UserDefaults.standard
        defaults.set("welcome", forKey: stepKey)
        defaults.set("", forKey: ageKey)
        defaults.set("generalFitness", forKey: goalKey)
        defaults.set("beginner", forKey: levelKey)
        defaults.set("metric", forKey: unitsKey)
    }
}

struct OnboardingView: View {
    
    // MARK: - Properties
    
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @Query private var users: [User]
    private var currentUser: User? { users.first }
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedAge: Int = 25
    @State private var selectedGoal: FitnessGoal = .generalFitness
    @State private var selectedLevel: FitnessLevel = .beginner
    @State private var selectedUnits: UnitSystem = .metric
    @State private var selectedSex: BiologicalSex = .unspecified
    @State private var selectedHeightCm: Double = 170
    @State private var selectedWeightKg: Double = 70
    @State private var selectedActivityLevel: ActivityLevel = .moderate
    @State private var selectedGymChallenge: GymChallenge = .notKnowingWhatToDo
    @State private var selectedMotivationBarrier: MotivationBarrier = .motivation
    @State private var selectedEnvironment: WorkoutEnvironment = .gym
    @State private var selectedWorkoutCount: Int = 2
    @State private var userSkippedPlan = false
    @State private var userChoseBuildPlan = false
    @State private var selectedPlanDecision: PlanDecisionChoice?
    @State private var planSplit: PlanSplitType = .fullBody
    @State private var planWorkouts: [GeneratedWorkout] = []
    @State private var hasSavedTrainingPlan = false
    @State private var welcomeHeroVisible = false
    @State private var presentedLegalDocument: LegalDocument?

    @AppStorage("onboarding_current_step") private var savedStep: String = "welcome"
    @AppStorage("onboarding_age") private var savedAge: String = ""
    @AppStorage("onboarding_goal") private var savedGoal: String = "generalFitness"
    @AppStorage("onboarding_level") private var savedLevel: String = "beginner"
    @AppStorage("onboarding_units") private var savedUnits: String = "metric"
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                OnboardingBackground()
                
                VStack(spacing: 0) {
                    // Top bar: back (when applicable) + progress
                    if currentStep != .welcome && currentStep != .completion {
                        onboardingTopBar
                            .padding(.top, 12)
                            .padding(.horizontal, 24)
                    }
                    
                    // Current step content
                    currentStepView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Forward navigation only
                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 34)
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await subscriptionService.loadOfferings()
            await subscriptionService.checkSubscriptionStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await subscriptionService.checkSubscriptionStatus() }
        }
        .onAppear {
            restoreOnboardingState()
            OnboardingAnalytics.logPageView(currentStep)
        }
        .onChange(of: currentStep) { _, newStep in
            saveOnboardingProgress()
            OnboardingAnalytics.logPageView(newStep)
            if newStep == .planDecision {
                selectedPlanDecision = nil
            }
            if newStep == .planPreview {
                refreshTrainingPlanSavedState()
            }
        }
        .onChange(of: selectedAge) { _, _ in
            saveOnboardingProgress()
        }
        .onChange(of: selectedGoal) { _, _ in
            saveOnboardingProgress()
            resetPlanState()
        }
        .onChange(of: selectedLevel) { _, _ in
            saveOnboardingProgress()
            resetPlanState()
        }
        .onChange(of: selectedUnits) { _, _ in
            saveOnboardingProgress()
        }
        .onChange(of: selectedEnvironment) { _, _ in
            resetPlanState()
        }
        .onChange(of: selectedWorkoutCount) { _, _ in
            resetPlanState()
        }
        .sheet(item: $presentedLegalDocument) { document in
            NavigationStack {
                document.destination
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                presentedLegalDocument = nil
                            }
                        }
                    }
            }
        }
    }

    private func resetPlanState() {
        planWorkouts = []
        hasSavedTrainingPlan = false
    }

    private var planQuestionnaire: PlanQuestionnaire {
        PlanQuestionnaire(
            goal: selectedGoal,
            experience: selectedLevel,
            environment: selectedEnvironment,
            workoutCount: selectedWorkoutCount,
            focus: focusAreasForQuestionnaire()
        )
    }

    /// Full onboarding profile used for AI plan generation — built from local
    /// state because the answers aren't saved to the `User` until completion.
    private var planGenerationContext: PlanGenerationContext {
        PlanGenerationContext(
            questionnaire: planQuestionnaire,
            age: selectedAge,
            biologicalSex: selectedSex,
            heightCm: selectedHeightCm,
            weightKg: selectedWeightKg,
            activityLevel: selectedActivityLevel,
            gymChallenge: selectedGymChallenge,
            motivationBarrier: selectedMotivationBarrier,
            preferredUnits: selectedUnits
        )
    }

    private var previewNutritionGoals: NutritionGoals {
        NutritionGoalCalculator.goals(
            weightKg: selectedWeightKg,
            heightCm: selectedHeightCm,
            age: selectedAge,
            sex: selectedSex,
            activity: selectedActivityLevel,
            goal: selectedGoal
        )
    }

    private func focusAreasForQuestionnaire() -> [FocusArea] {
        PlanQuestionnaireFocus.focusAreas(
            goal: selectedGoal,
            workoutCount: selectedWorkoutCount,
            gymChallenge: selectedGymChallenge
        )
    }
    
    // MARK: - Top Bar
    
    @ViewBuilder
    private var onboardingTopBar: some View {
        if currentStep.isFeaturePage {
            // Feature carousel: back button + page dots
            HStack(spacing: 12) {
                OnboardingBackButton(action: goToPreviousStep)
                Spacer()
                OnboardingPageDots(
                    total: OnboardingStep.featurePages.count,
                    index: OnboardingStep.featurePages.firstIndex(of: currentStep) ?? 0
                )
                Spacer()
                // Balance the back button so the dots stay centred
                Color.clear.frame(width: 36, height: 36)
            }
        } else if currentStep.usesPlainChrome {
            HStack {
                OnboardingBackButton(action: goToPreviousStep)
                Spacer()
            }
        } else {
            HStack(spacing: 12) {
                OnboardingBackButton(action: goToPreviousStep)

                OnboardingProgressBar(
                    current: currentStepNumber,
                    total: totalSteps
                )
            }
        }
    }
    
    // MARK: - Progress
    
    private var trackedSteps: [OnboardingStep] {
        let base: [OnboardingStep] = [
            .gymChallenge,
            .motivation,
            .ageAndGoals,
            .fitnessLevel,
            .unitPreferences,
            .bodyMetrics,
            .activityLevel,
            .trainingEnvironment,
            .workoutCount,
            .planDecision
        ]
        if userChoseBuildPlan {
            return base + [.planPreview, .subscription]
        }
        return base + [.subscription]
    }

    private var currentStepNumber: Int {
        guard let index = trackedSteps.firstIndex(of: currentStep) else { return 0 }
        return index + 1
    }

    private var totalSteps: Int { trackedSteps.count }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcome:
            welcomeView
        case .featureNutrition:
            featureNutritionView
        case .featureWorkouts:
            featureWorkoutsView
        case .featureRing:
            featureRingView
        case .socialProof:
            socialProofView
        case .ringReveal:
            ringRevealView
        case .ratingAsk:
            ratingAskView
        case .gymChallenge:
            gymChallengeView
        case .motivation:
            motivationView
        case .ageAndGoals:
            ageAndGoalsView
        case .fitnessLevel:
            fitnessLevelView
        case .unitPreferences:
            unitPreferencesView
        case .bodyMetrics:
            bodyMetricsView
        case .activityLevel:
            activityLevelView
        case .trainingEnvironment:
            trainingEnvironmentView
        case .workoutCount:
            workoutCountView
        case .planDecision:
            planDecisionView
        case .planPreview:
            PlanPreviewView(
                generationContext: planGenerationContext,
                planSplit: $planSplit,
                planWorkouts: $planWorkouts
            )
        case .subscription:
            subscriptionStepView
        case .completion:
            completionView
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // Hero collage of floating app cards
            welcomeHeroCollage
                .frame(height: 240)
                .padding(.horizontal, 24)
                .opacity(welcomeHeroVisible ? 1 : 0)
                .offset(y: welcomeHeroVisible ? 0 : 20)
                .accessibilityHidden(true)

            // Headline
            VStack(alignment: .leading, spacing: 10) {
                Text("All your progress.\nOne place.")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(OnboardingPalette.ink)
                    .lineSpacing(1)
                    .accessibilityAddTraits(.isHeader)

                Text("Workouts and nutrition, tracked together — so you can finally see the full picture.")
                    .font(.system(size: 15.5))
                    .foregroundColor(OnboardingPalette.muted)
                    .lineSpacing(3)
            }
            .padding(.top, 28)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(welcomeHeroVisible ? 1 : 0)
            .offset(y: welcomeHeroVisible ? 0 : 14)

            Spacer()
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                welcomeHeroVisible = true
            }
        }
    }

    private var welcomeHeroCollage: some View {
        ZStack {
            // Push Day card — top left
            VStack(alignment: .leading, spacing: 8) {
                Text("Push Day")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(OnboardingPalette.muted)

                HStack(spacing: 8) {
                    Text("🏋️")
                        .font(.system(size: 15))
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(OnboardingPalette.accentSoft)
                        )
                    Text("5 exercises")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(OnboardingPalette.ink)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(OnboardingPalette.line)
                        Capsule()
                            .fill(Color.brand)
                            .frame(width: geo.size.width * 0.7)
                    }
                }
                .frame(height: 6)
            }
            .padding(14)
            .frame(width: 156)
            .onboardingSurfaceCard()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Lunch card — top right
            VStack(alignment: .leading, spacing: 3) {
                Text("Lunch")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(OnboardingPalette.muted)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("612")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingPalette.ink)
                    Text("kcal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OnboardingPalette.muted)
                }

                Text("📸 Logged from photo")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(14)
            .frame(width: 140, alignment: .leading)
            .onboardingSurfaceCard()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 56)

            // Body map card — bottom left
            HStack(spacing: 10) {
                OnboardingSilhouetteThumb(size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Body map")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(OnboardingPalette.muted)
                    Text("Chest lighting up")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(OnboardingPalette.ink)
                }
            }
            .padding(14)
            .onboardingSurfaceCard()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 30)
        }
    }
    
    // MARK: - Feature Carousel

    /// Feature page 1 — AI photo nutrition logging.
    private var featureNutritionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // Meal visual: plate on a blue gradient with floating stat chips
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [OnboardingPalette.brandLight, Color.brand],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Plate with food
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white, Color(hex: "EDEDED")],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 5,
                                endRadius: 90
                            )
                        )
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)

                    Circle().fill(Color(hex: "6FBF73")).frame(width: 34, height: 34).offset(x: -22, y: -18)
                    Circle().fill(Color(hex: "E7B65A")).frame(width: 26, height: 26).offset(x: 22, y: -22)
                    Circle().fill(Color(hex: "D9694A")).frame(width: 38, height: 38).offset(x: -6, y: 20)
                    Circle().fill(Color(hex: "7FA65A")).frame(width: 22, height: 22).offset(x: 30, y: 14)
                }
                .offset(y: 12)

                OnboardingStatChip(value: "165 kcal", label: "Chicken breast")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
                OnboardingStatChip(value: "200 kcal", label: "Rice")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
                    .padding(.top, 30)
                OnboardingStatChip(value: "40 kcal", label: "Broccoli")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(12)
            }
            .frame(height: 210)
            .accessibilityHidden(true)

            featureHeadline(
                title: "Snap it. Log it. Done.",
                subtitle: "Point your camera at any meal — Progress detects the food and logs calories & macros instantly."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    /// Feature page 2 — workout logging.
    private var featureWorkoutsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                OnboardingWorkoutRow(emoji: "🏋️", title: "Bench Press", detail: "4 sets · 8 reps · 62.5kg", isDone: true)
                OnboardingWorkoutRow(emoji: "🦵", title: "Leg Press", detail: "3 sets · 10 reps", isDone: true)
                OnboardingWorkoutRow(emoji: "💪", title: "Cable Row", detail: "3 sets · 12 reps", isDone: false)
            }
            .padding(16)
            .onboardingGroupCard()
            .accessibilityHidden(true)

            featureHeadline(
                title: "Train your way",
                subtitle: "Follow expert-built plans, or log your own lifts and cardio. Either way, every session counts."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    /// Feature page 3 — the body-map silhouette.
    private var featureRingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            ZStack {
                OnboardingSilhouette(height: 200)

                OnboardingStatChip(value: "Chest", label: "lighting up")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                OnboardingStatChip(value: "Quads", label: "on fire")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .frame(height: 215)
            .accessibilityHidden(true)

            featureHeadline(
                title: "Watch your body light up",
                subtitle: "Every workout paints your silhouette — see exactly which muscles you're building, week after week."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func featureHeadline(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 29, weight: .heavy, design: .rounded))
                .foregroundColor(OnboardingPalette.ink)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(OnboardingPalette.muted)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    // MARK: - Social Proof View

    private var socialProofView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Progress plays\nthe long game")
                    .font(.system(size: 29, weight: .heavy, design: .rounded))
                    .foregroundColor(OnboardingPalette.ink)
                    .lineSpacing(1)
                    .accessibilityAddTraits(.isHeader)

                Text("Random workouts fade. A plan that adapts to you compounds — week after week.")
                    .font(.system(size: 15))
                    .foregroundColor(OnboardingPalette.muted)
                    .lineSpacing(3)
            }
            .padding(.top, 12)

            OnboardingMomentumChart()
                .frame(height: 190)
                .padding(16)
                .onboardingSurfaceCard(cornerRadius: 22)
                .accessibilityLabel("Chart comparing steady Progress momentum against random workouts that fade over time")

            OnboardingNotePill(
                emoji: "📈",
                text: "are still hitting their goals after 6 months.",
                boldText: "82% of Progress users"
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Ring Reveal View

    private var ringRevealView: some View {
        VStack(spacing: 0) {
            Spacer()

            OnboardingStepHeader(
                title: "Meet your\nBody Map",
                subtitle: "It lights up every time you train. Watch each muscle group grow with you, week after week.",
                alignment: .center
            )

            ZStack {
                Text("✦").font(.system(size: 16)).foregroundColor(Color.brand.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 24)
                Text("✦").font(.system(size: 12)).foregroundColor(Color.brand.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 34)
                    .padding(.top, 24)
                Text("✦").font(.system(size: 12)).foregroundColor(Color.brand.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 44)

                OnboardingSilhouette(height: 240, lit: false, variant: selectedSex.bodyMapVariant)
            }
            .frame(height: 260)
            .accessibilityHidden(true)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Rating Ask View

    private var ratingAskView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    // Star row
                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "FFB800"))
                        }
                    }
                    .accessibilityLabel("Five star rating")

                    Text("Real people.\nReal Progress.")
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingPalette.ink)
                        .lineSpacing(1)
                        .accessibilityAddTraits(.isHeader)

                    Text("Join the people already turning consistent logging into real results.")
                        .font(.system(size: 15))
                        .foregroundColor(OnboardingPalette.muted)
                        .lineSpacing(3)
                }
                .padding(.top, 12)

                // Laurels
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("4.8")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(OnboardingPalette.ink)
                        Text("avg. rating")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OnboardingPalette.muted)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("500K+")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(OnboardingPalette.ink)
                        Text("users worldwide")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(OnboardingPalette.muted)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .onboardingGroupCard(cornerRadius: 20)

                OnboardingTestimonialCard(
                    initial: "J",
                    name: "Jordan 🇺🇸",
                    stat: "89kg → 81kg · Bench +20kg in 3 months",
                    quote: "First app where my lifts and my meals actually talk to each other. I finally see the whole picture."
                )

                OnboardingTestimonialCard(
                    initial: "S",
                    name: "Sophie 🇬🇧",
                    stat: "−6kg · 4 workouts a week since January",
                    quote: "The body map keeps me honest. Six months in and I've never trained this consistently."
                )

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Ask for a rating while motivation is at its peak, just before the paywall.
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                requestReview()
            }
        }
    }

    // MARK: - Age and Goals View
    
    private var ageAndGoalsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingChatBubble(question: "How old are you, and what's your main goal?")
                    .padding(.top, 8)
                
                // Age Input Section
                VStack(spacing: 8) {
                    Text("AGE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OnboardingPalette.muted)
                        .tracking(1)

                    Text("\(selectedAge)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingPalette.ink)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.15), value: selectedAge)

                    OnboardingRulerSlider(
                        value: Binding(
                            get: { Double(selectedAge) },
                            set: { selectedAge = Int($0.rounded()) }
                        ),
                        range: 18...100
                    )
                    .accessibilityLabel("Age")
                    .accessibilityHint("Swipe up or down to adjust your age between 18 and 100 years")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .onboardingGroupCard()
                
                // Fitness Goals Section
                VStack(spacing: 12) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        OnboardingOptionRow(
                            emoji: goal.onboardingEmoji,
                            title: goal.displayName,
                            subtitle: goal.description,
                            isSelected: selectedGoal == goal
                        ) {
                            selectedGoal = goal
                        }
                    }
                }
                
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Fitness Level View
    
    private var fitnessLevelView: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingChatBubble(question: "How experienced are you?")
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    OnboardingOptionRow(
                        emoji: level.onboardingEmoji,
                        title: level.displayName,
                        subtitle: level.description,
                        isSelected: selectedLevel == level
                    ) {
                        selectedLevel = level
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Unit Preferences View
    
    private var unitPreferencesView: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingChatBubble(question: "Which units do you prefer?")
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                ForEach(UnitSystem.allCases, id: \.self) { unitSystem in
                    OnboardingOptionRow(
                        emoji: unitSystem.onboardingEmoji,
                        title: unitSystem.displayName,
                        subtitle: unitSystemDescription(for: unitSystem),
                        isSelected: selectedUnits == unitSystem
                    ) {
                        selectedUnits = unitSystem
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func unitSystemDescription(for unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            return "Weight in kilograms (kg), height in centimeters (cm)"
        case .imperial:
            return "Weight in pounds (lbs), height in feet and inches (ft/in)"
        }
    }

    // MARK: - Body Metrics View

    private var bodyMetricsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingChatBubble(question: "Tell us a bit about your body so we can tailor your daily nutrition targets.")
                    .padding(.top, 8)

                // Biological sex
                VStack(alignment: .leading, spacing: 12) {
                    Text("BIOLOGICAL SEX")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OnboardingPalette.muted)
                        .tracking(1)

                    ForEach(BiologicalSex.allCases, id: \.self) { sex in
                        OnboardingOptionRow(
                            emoji: sex.onboardingEmoji,
                            title: sex.displayName,
                            isSelected: selectedSex == sex
                        ) {
                            selectedSex = sex
                        }
                    }
                }

                // Height
                VStack(spacing: 12) {
                    HStack {
                        Text("HEIGHT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(OnboardingPalette.muted)
                            .tracking(1)
                        Spacer()
                        Text(selectedUnits.formatHeight(selectedHeightCm))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(OnboardingPalette.ink)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.15), value: selectedHeightCm)
                    }

                    OnboardingRulerSlider(
                        value: heightSliderValue,
                        range: heightSliderRange,
                        majorTickInterval: selectedUnits == .metric ? 5 : 6,
                        labelInterval: selectedUnits == .metric ? 10 : 12,
                        label: heightTickLabel
                    )
                    .accessibilityLabel("Height")
                    .accessibilityValue(selectedUnits.formatHeight(selectedHeightCm))
                }
                .padding(16)
                .onboardingGroupCard()

                // Weight
                VStack(spacing: 12) {
                    HStack {
                        Text("WEIGHT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(OnboardingPalette.muted)
                            .tracking(1)
                        Spacer()
                        Text(selectedUnits.formatWeightWithUnit(selectedWeightKg, precision: 0))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(OnboardingPalette.ink)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.15), value: selectedWeightKg)
                    }

                    OnboardingRulerSlider(
                        value: weightSliderValue,
                        range: weightSliderRange,
                        majorTickInterval: 5,
                        labelInterval: selectedUnits == .metric ? 10 : 25
                    )
                    .accessibilityLabel("Weight")
                    .accessibilityValue(selectedUnits.formatWeightWithUnit(selectedWeightKg, precision: 0))
                }
                .padding(16)
                .onboardingGroupCard()

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Body Metric Sliders

    /// Height slider works in the user's display unit (cm or total inches)
    /// so each tick is one natural step in that system.
    private var heightSliderValue: Binding<Double> {
        switch selectedUnits {
        case .metric:
            return Binding(
                get: { selectedHeightCm.rounded() },
                set: { selectedHeightCm = $0 }
            )
        case .imperial:
            return Binding(
                get: { (selectedHeightCm / 2.54).rounded() },
                set: { selectedHeightCm = $0 * 2.54 }
            )
        }
    }

    private var heightSliderRange: ClosedRange<Double> {
        switch selectedUnits {
        case .metric: return 120...220     // cm
        case .imperial: return 48...86     // total inches (4'0" – 7'2")
        }
    }

    private func heightTickLabel(_ value: Double) -> String {
        switch selectedUnits {
        case .metric:
            return "\(Int(value))"
        case .imperial:
            return "\(Int(value) / 12)'"
        }
    }

    /// Weight slider works in the user's display unit (kg or lbs).
    private var weightSliderValue: Binding<Double> {
        switch selectedUnits {
        case .metric:
            return Binding(
                get: { selectedWeightKg.rounded() },
                set: { selectedWeightKg = $0 }
            )
        case .imperial:
            return Binding(
                get: { (selectedWeightKg * 2.20462).rounded() },
                set: { selectedWeightKg = $0 / 2.20462 }
            )
        }
    }

    private var weightSliderRange: ClosedRange<Double> {
        switch selectedUnits {
        case .metric: return 30...250      // kg
        case .imperial: return 66...550    // lbs
        }
    }

    // MARK: - Activity Level View

    private var activityLevelView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingChatBubble(question: "How active are you on a typical day?")
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        OnboardingOptionRow(
                            emoji: level.onboardingEmoji,
                            title: level.displayName,
                            subtitle: level.description,
                            isSelected: selectedActivityLevel == level
                        ) {
                            selectedActivityLevel = level
                        }
                    }
                }

                OnboardingNotePill(
                    emoji: "🍎",
                    text: "uses this to calculate your personalised calorie and macro goals.",
                    boldText: "Progress"
                )

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Gym Challenge View

    private var gymChallengeView: some View {
        PlanGymChallengeSelectionView(selectedChallenge: $selectedGymChallenge)
    }

    // MARK: - Motivation View

    private var motivationView: some View {
        PlanMotivationSelectionView(selectedBarrier: $selectedMotivationBarrier)
    }

    // MARK: - Training Environment View

    private var trainingEnvironmentView: some View {
        PlanTrainingEnvironmentSelectionView(selectedEnvironment: $selectedEnvironment)
    }

    // MARK: - Workout Count View

    private var workoutCountView: some View {
        PlanWorkoutCountSelectionView(selectedWorkoutCount: $selectedWorkoutCount)
    }

    // MARK: - Plan Decision View (placeholder removed duplicate views below)

    private var planDecisionView: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingChatBubble(question: "How do you want to train?")
                .padding(.top, 8)

            VStack(spacing: 12) {
                OnboardingOptionRow(
                    emoji: "🗓️",
                    title: "Build my plan",
                    subtitle: "\(selectedWorkoutCount) \(selectedEnvironment.displayName.lowercased()) workouts with progressive sessions",
                    isSelected: selectedPlanDecision == .build
                ) {
                    selectedPlanDecision = .build
                }

                OnboardingOptionRow(
                    emoji: "✍️",
                    title: "Skip for now — I'll create my own",
                    subtitle: "Jump straight in with manual workouts. You can start a plan later in Settings.",
                    isSelected: selectedPlanDecision == .skip
                ) {
                    selectedPlanDecision = .skip
                }
            }

            OnboardingNotePill(
                emoji: "💡",
                text: "is the only app where your plan and your own logs live side by side.",
                boldText: "Progress"
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Subscription Step View

    private var subscriptionStepView: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Pro badge + headline
                VStack(spacing: 14) {
                    Text("ONE MEMBERSHIP")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(OnboardingPalette.onInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(OnboardingPalette.ink))
                        .padding(.top, 20)

                    (Text("Start free.\nKeep the ")
                        .foregroundColor(OnboardingPalette.ink)
                     + Text("momentum")
                        .foregroundColor(Color.brand)
                     + Text(".")
                        .foregroundColor(OnboardingPalette.ink))
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity)

                Text("Yearly, monthly, or weekly. Same access on each.")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(OnboardingPalette.muted)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    ForEach(SubscriptionService.Plan.allCases) { plan in
                        if let offering = subscriptionService.offerings[plan] {
                            onboardingPlanCard(offering)
                        }
                    }
                }
                .padding(.top, 4)

                Button("Redeem an annual code") {
                    subscriptionService.redeemAnnualCode()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(OnboardingPalette.ink)

                // Feature list
                VStack(alignment: .leading, spacing: 0) {
                    Text("WHAT YOU GET")
                        .font(.system(size: 11.5, weight: .heavy))
                        .tracking(0.4)
                        .foregroundColor(OnboardingPalette.muted)
                        .padding(.bottom, 8)

                    ForEach(SubscriptionService.ServiceTier.pro.features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color.brand)
                            Text(feature)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(OnboardingPalette.ink)
                            Spacer()
                        }
                        .padding(.vertical, 9)
                        .overlay(Rectangle().fill(OnboardingPalette.line).frame(height: 1), alignment: .top)
                    }
                }

                if let error = subscriptionService.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button("Maybe later") {
                    trackForwardNavigation(from: .subscription)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .completion
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(OnboardingPalette.muted)

                Text("Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Cancel anytime in Settings → Subscriptions.")
                    .font(.system(size: 11.5))
                    .foregroundColor(OnboardingPalette.muted)
                    .multilineTextAlignment(.center)

                HStack(spacing: 20) {
                    Button("Terms of Service") {
                        presentedLegalDocument = .terms
                    }
                    Button("Privacy Policy") {
                        presentedLegalDocument = .privacy
                    }
                }
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(OnboardingPalette.ink)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }

    private func onboardingPlanCard(_ offering: SubscriptionService.SubscriptionOffering) -> some View {
        let isSelected = subscriptionService.selectedPlan == offering.plan

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                subscriptionService.selectedPlan = offering.plan
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? Color.brand : OnboardingPalette.muted)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(offering.plan.title)
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundColor(OnboardingPalette.ink)

                        if offering.plan == .annual {
                            Text("BEST VALUE")
                                .font(.system(size: 9.5, weight: .heavy))
                                .tracking(0.4)
                                .foregroundColor(OnboardingPalette.onInk)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.brand))
                        }
                    }

                    Text(offering.plan.detailLine(pricePerMonth: offering.pricePerMonth))
                        .font(.system(size: 11.5))
                        .foregroundColor(OnboardingPalette.muted)

                    if offering.hasTrial {
                        Text("\(offering.trialDays)-day free trial")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.brand)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(offering.price)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingPalette.ink)
                    Text(offering.plan.billingPeriodText)
                        .font(.system(size: 11))
                        .foregroundColor(OnboardingPalette.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? OnboardingPalette.ink : OnboardingPalette.line,
                                  lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success animation
            VStack(spacing: 28) {
                // Fresh body-map silhouette
                OnboardingSilhouette(height: 170, lit: false, variant: selectedSex.bodyMapVariant)
                .accessibilityLabel("Setup complete")
                
                OnboardingStepHeader(
                    title: "You're all set!",
                    subtitle: "Every workout you log lights up your silhouette. Watch it grow with you, week after week.",
                    alignment: .center
                )
            }
            
            Spacer()
            
            // Profile summary
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR PROFILE")
                    .font(.system(size: 11.5, weight: .heavy))
                    .tracking(0.4)
                    .foregroundColor(OnboardingPalette.muted)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 10) {
                    ProfileSummaryRow(label: "Age", value: "\(selectedAge) years old")
                    ProfileSummaryRow(label: "Goal", value: selectedGoal.displayName)
                    ProfileSummaryRow(label: "Level", value: selectedLevel.displayName)
                    ProfileSummaryRow(label: "Units", value: selectedUnits.displayName)
                    ProfileSummaryRow(label: "Daily calories", value: "\(Int(previewNutritionGoals.calories)) kcal")
                    ProfileSummaryRow(label: "Daily protein", value: "\(Int(previewNutritionGoals.protein)) g")
                    ProfileSummaryRow(label: "Training", value: selectedEnvironment.displayName)
                    if !userSkippedPlan {
                        ProfileSummaryRow(label: "Plan", value: "\(selectedWorkoutCount) repeating workouts")
                    }
                }
                .padding(18)
                .onboardingGroupCard()
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        Group {
            if currentStep == .completion {
                Button("Get Started") {
                    completeOnboarding()
                    onComplete()
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .accessibilityLabel("Get Started")
                .accessibilityHint("Complete onboarding and start using the app")
            } else if currentStep == .planDecision {
                Button(action: confirmPlanDecision) {
                    Text(planDecisionConfirmTitle)
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(isEnabled: canProceed))
                .disabled(!canProceed)
                .accessibilityLabel(planDecisionConfirmTitle)
                .accessibilityHint(nextButtonAccessibilityHint)
            } else {
                Button(action: handleNextAction) {
                    HStack(spacing: 8) {
                        Text(nextButtonTitle)
                        if currentStep != .subscription && currentStep != .planPreview {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(isEnabled: canProceed))
                .disabled(!canProceed)
                .accessibilityLabel(nextButtonTitle)
                .accessibilityHint(nextButtonAccessibilityHint)
            }
        }
    }
    
    private var nextButtonAccessibilityHint: String {
        switch currentStep {
        case .welcome:
            return "Start the onboarding process"
        case .featureNutrition, .featureWorkouts:
            return "Continue to the next feature"
        case .featureRing:
            return "Continue to the questionnaire"
        case .socialProof:
            return "Continue to plan decision"
        case .ringReveal:
            return "Continue to ratings and reviews"
        case .ratingAsk:
            return "Continue to subscription"
        case .gymChallenge:
            return "Continue to motivation question"
        case .motivation:
            return "Continue to profile setup"
        case .ageAndGoals:
            return "Continue to fitness level selection"
        case .fitnessLevel:
            return "Continue to unit preferences"
        case .unitPreferences:
            return "Continue to body measurements"
        case .bodyMetrics:
            return "Continue to activity level"
        case .activityLevel:
            return "Continue to training environment"
        case .trainingEnvironment:
            return "Continue to workout count"
        case .workoutCount:
            return "Continue to plan decision"
        case .planDecision:
            return "Confirm your choice to continue"
        case .planPreview:
            return "Save your plan and continue"
        case .subscription:
            return "Start your free trial and continue"
        case .completion:
            return "Start using the app"
        }
    }
    
    // MARK: - Computed Properties

    private var nextButtonTitle: String {
        switch currentStep {
        case .welcome: return "Get Started"
        case .featureNutrition: return "Next"
        case .featureWorkouts: return "Next"
        case .featureRing: return "Next"
        case .socialProof: return "Next"
        case .ringReveal: return "Let's go"
        case .ratingAsk: return "Continue"
        case .gymChallenge: return "Next"
        case .motivation: return "Next"
        case .ageAndGoals: return "Next"
        case .fitnessLevel: return "Next"
        case .unitPreferences: return "Next"
        case .bodyMetrics: return "Next"
        case .activityLevel: return "Next"
        case .trainingEnvironment: return "Next"
        case .workoutCount: return "Next"
        case .planDecision: return planDecisionConfirmTitle
        case .planPreview: return "Looks good — save my plan"
        case .subscription:
            if subscriptionService.isLoading { return "Processing..." }
            if let offering = subscriptionService.currentOffering, offering.hasTrial {
                return "Start \(offering.trialDays)-Day Free Trial"
            }
            return "Subscribe"
        case .completion: return "Get Started"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .welcome: return true
        case .featureNutrition, .featureWorkouts, .featureRing: return true
        case .socialProof, .ringReveal, .ratingAsk: return true
        case .gymChallenge: return true
        case .motivation: return true
        case .ageAndGoals: return true
        case .fitnessLevel: return true
        case .unitPreferences: return true
        case .bodyMetrics: return true
        case .activityLevel: return true
        case .trainingEnvironment: return true
        case .workoutCount: return true
        case .planDecision: return selectedPlanDecision != nil
        case .planPreview: return !planWorkouts.isEmpty
        case .subscription: return !subscriptionService.isLoading
        case .completion: return true
        }
    }
    
    private var planDecisionConfirmTitle: String {
        switch selectedPlanDecision {
        case .build: return "Build my plan"
        case .skip: return "Skip for now"
        case nil: return "Continue"
        }
    }

    private func confirmPlanDecision() {
        guard let choice = selectedPlanDecision else { return }
        switch choice {
        case .build:
            buildPlanAndContinue()
        case .skip:
            skipPlanAndContinue()
        }
    }

    // MARK: - Analytics

    private func trackForwardNavigation(from step: OnboardingStep) {
        logAnswersForStep(step)
        OnboardingAnalytics.logAdvance(from: step)
    }

    private func logAnswersForStep(_ step: OnboardingStep) {
        switch step {
        case .gymChallenge:
            OnboardingAnalytics.logAnswer("gym_challenge", value: selectedGymChallenge.rawValue)
        case .motivation:
            OnboardingAnalytics.logAnswer("motivation_barrier", value: selectedMotivationBarrier.rawValue)
        case .trainingEnvironment:
            OnboardingAnalytics.logAnswer("training_environment", value: selectedEnvironment.rawValue)
        case .workoutCount:
            OnboardingAnalytics.logAnswer("workout_count", value: String(selectedWorkoutCount))
        default:
            break
        }
    }

    // MARK: - Actions
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break
            case .featureNutrition:
                currentStep = .welcome
            case .featureWorkouts:
                currentStep = .featureNutrition
            case .featureRing:
                currentStep = .featureWorkouts
            case .gymChallenge:
                currentStep = .featureRing
            case .motivation:
                currentStep = .gymChallenge
            case .ageAndGoals:
                currentStep = .motivation
            case .fitnessLevel:
                currentStep = .ageAndGoals
            case .unitPreferences:
                currentStep = .fitnessLevel
            case .bodyMetrics:
                currentStep = .unitPreferences
            case .activityLevel:
                currentStep = .bodyMetrics
            case .trainingEnvironment:
                currentStep = .activityLevel
            case .workoutCount:
                currentStep = .trainingEnvironment
            case .socialProof:
                currentStep = .workoutCount
            case .planDecision:
                currentStep = .socialProof
            case .planPreview:
                currentStep = .planDecision
            case .ringReveal:
                currentStep = userSkippedPlan ? .planDecision : .planPreview
            case .ratingAsk:
                currentStep = .ringReveal
            case .subscription:
                currentStep = .ratingAsk
            case .completion:
                currentStep = .subscription
            }
        }
    }
    
    private func handleNextAction() {
        let fromStep = currentStep
        switch currentStep {
        case .welcome:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .featureNutrition
            }
        case .featureNutrition:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .featureWorkouts
            }
        case .featureWorkouts:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .featureRing
            }
        case .featureRing:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .gymChallenge
            }
        case .socialProof:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .planDecision
            }
        case .ringReveal:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .ratingAsk
            }
        case .ratingAsk:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .subscription
            }
        case .gymChallenge:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .motivation
            }
        case .motivation:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .ageAndGoals
            }
        case .ageAndGoals:
            guard canProceed else { return }
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .fitnessLevel
            }
        case .fitnessLevel:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .unitPreferences
            }
        case .unitPreferences:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .bodyMetrics
            }
        case .bodyMetrics:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .activityLevel
            }
        case .activityLevel:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .trainingEnvironment
            }
        case .trainingEnvironment:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .workoutCount
            }
        case .workoutCount:
            trackForwardNavigation(from: fromStep)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .socialProof
            }
        case .planDecision:
            break
        case .planPreview:
            savePlanAndContinue()
        case .subscription:
            Task {
                if subscriptionService.isSubscribed {
                    trackForwardNavigation(from: fromStep)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .completion
                    }
                    return
                }
                await subscriptionService.purchase()
                if subscriptionService.isSubscribed {
                    trackForwardNavigation(from: fromStep)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .completion
                    }
                }
            }
        case .completion:
            break
        }
    }
    
    private func buildPlanAndContinue() {
        OnboardingAnalytics.logAnswer("plan_decision", value: "build")
        trackForwardNavigation(from: .planDecision)
        userSkippedPlan = false
        userChoseBuildPlan = true
        resetPlanState()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .planPreview
        }
    }

    private func skipPlanAndContinue() {
        OnboardingAnalytics.logAnswer("plan_decision", value: "skip")
        OnboardingAnalytics.logSkippedPlan()
        trackForwardNavigation(from: .planDecision)
        userSkippedPlan = true
        userChoseBuildPlan = false
        resetPlanState()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .ringReveal
        }
    }

    private func refreshTrainingPlanSavedState() {
        guard let user = currentUser else { return }
        let service = TrainingPlanService(modelContext: modelContext)
        hasSavedTrainingPlan = service.activePlan(for: user) != nil
    }

    private func savePlanAndContinue() {
        guard canProceed, let user = currentUser, !planWorkouts.isEmpty else { return }

        let service = TrainingPlanService(modelContext: modelContext)
        if !hasSavedTrainingPlan && service.activePlan(for: user) == nil {
            do {
                _ = try service.createPlan(
                    for: user,
                    name: "\(planSplit.displayName) Plan",
                    split: planSplit,
                    workouts: planWorkouts
                )
                hasSavedTrainingPlan = true
            } catch {
                #if DEBUG
                print("❌ Failed to create training plan: \(error)")
                #endif
                return
            }
        } else {
            hasSavedTrainingPlan = true
        }

        trackForwardNavigation(from: .planPreview)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .ringReveal
        }
    }

    private func completeOnboarding() {
        OnboardingAnalytics.logCompleted(planCreated: hasSavedTrainingPlan)
        guard let user = currentUser else { return }
        
        // Update user profile with all collected data
        user.age = selectedAge
        user.fitnessGoal = selectedGoal
        user.fitnessLevel = selectedLevel
        user.preferredUnits = selectedUnits
        user.biologicalSex = selectedSex
        user.heightCm = selectedHeightCm
        user.weightKg = selectedWeightKg
        user.activityLevel = selectedActivityLevel
        user.hasCompletedOnboarding = true
        user.updatedAt = Date()

        // Derive personalised nutrition targets from the collected profile.
        user.recalculateNutritionGoals(force: true)
        
        // Save to SwiftData
        do {
            try modelContext.save()
            print("✅ Onboarding completed - User profile updated")
            print("📊 Profile: Age \(selectedAge), Goal: \(selectedGoal.displayName), Level: \(selectedLevel.displayName), Units: \(selectedUnits.displayName)")
            print("🍎 Nutrition targets: \(Int(user.dailyCalorieGoal)) kcal, P\(Int(user.dailyProteinGoal))/C\(Int(user.dailyCarbGoal))/F\(Int(user.dailyFatGoal))")
        } catch {
            print("❌ Failed to save onboarding data: \(error.localizedDescription)")
        }
        
        // Clear saved onboarding state after successful completion
        clearOnboardingProgress()
    }
    
    // MARK: - State Management
    
    private func saveOnboardingProgress() {
        savedStep = currentStep.rawValue
        savedAge = String(selectedAge)
        savedGoal = selectedGoal.rawValue
        savedLevel = selectedLevel.rawValue
        savedUnits = selectedUnits.rawValue
    }
    
    private func restoreOnboardingState() {
        // Restore step
        if let step = OnboardingStep(rawValue: savedStep) {
            currentStep = step
        }
        
        // Restore age
        if !savedAge.isEmpty, let age = Int(savedAge), age >= 18 && age <= 100 {
            selectedAge = age
        }
        
        // Restore goal
        if let goal = FitnessGoal(rawValue: savedGoal) {
            selectedGoal = goal
        }
        
        // Restore level
        if let level = FitnessLevel(rawValue: savedLevel) {
            selectedLevel = level
        }
        
        // Restore units
        if let units = UnitSystem(rawValue: savedUnits) {
            selectedUnits = units
        }
    }
    
    private func clearOnboardingProgress() {
        OnboardingProgressStore.resetSavedProgress()
    }
}

// MARK: - Onboarding Step Enum

enum PlanDecisionChoice {
    case build
    case skip
}

enum OnboardingStep: String, CaseIterable {
    case welcome = "welcome"
    case featureNutrition = "featureNutrition"
    case featureWorkouts = "featureWorkouts"
    case featureRing = "featureRing"
    case gymChallenge = "gymChallenge"
    case motivation = "motivation"
    case ageAndGoals = "ageAndGoals"
    case fitnessLevel = "fitnessLevel"
    case unitPreferences = "unitPreferences"
    case bodyMetrics = "bodyMetrics"
    case activityLevel = "activityLevel"
    case trainingEnvironment = "trainingEnvironment"
    case workoutCount = "workoutCount"
    case socialProof = "socialProof"
    case planDecision = "planDecision"
    case planPreview = "planPreview"
    case ringReveal = "ringReveal"
    case ratingAsk = "ratingAsk"
    case subscription = "subscription"
    case completion = "completion"

    /// Feature carousel pages shown between welcome and the questionnaire.
    static let featurePages: [OnboardingStep] = [.featureNutrition, .featureWorkouts, .featureRing]

    var isFeaturePage: Bool { Self.featurePages.contains(self) }

    /// "Sale" pages that show only a back button — no progress bar.
    var usesPlainChrome: Bool {
        self == .socialProof || self == .ringReveal || self == .ratingAsk
    }
}

// MARK: - Engagement Enums

enum GymChallenge: String, CaseIterable, Codable {
    case notKnowingWhatToDo = "not_knowing_what_to_do"
    case stayingConsistent = "staying_consistent"
    case hittingPlateaus = "hitting_plateaus"
    case lackOfConfidence = "lack_of_confidence"
    case findingTime = "finding_time"

    var displayName: String {
        switch self {
        case .notKnowingWhatToDo: return "Not knowing what to do"
        case .stayingConsistent: return "Staying consistent"
        case .hittingPlateaus: return "Hitting plateaus"
        case .lackOfConfidence: return "Lack of confidence"
        case .findingTime: return "Finding time"
        }
    }

    var description: String {
        switch self {
        case .notKnowingWhatToDo: return "I walk in but don't have a clear plan"
        case .stayingConsistent: return "I start strong but struggle to keep going"
        case .hittingPlateaus: return "My progress has stalled"
        case .lackOfConfidence: return "I'm unsure about form and exercise choice"
        case .findingTime: return "Busy schedule makes training hard to stick to"
        }
    }
}

enum MotivationBarrier: String, CaseIterable, Codable {
    case motivation = "motivation"
    case knowledge = "knowledge"
    case time = "time"
    case equipment = "equipment"
    case accountability = "accountability"

    var displayName: String {
        switch self {
        case .motivation: return "Motivation"
        case .knowledge: return "Knowledge"
        case .time: return "Time"
        case .equipment: return "Equipment"
        case .accountability: return "Accountability"
        }
    }

    var description: String {
        switch self {
        case .motivation: return "I struggle to stay motivated long-term"
        case .knowledge: return "I'm not sure what exercises or loads to use"
        case .time: return "Life gets in the way of training"
        case .equipment: return "I don't have the right setup"
        case .accountability: return "No one keeps me accountable"
        }
    }
}

// MARK: - Onboarding Emojis

extension FitnessGoal {
    var onboardingEmoji: String {
        switch self {
        case .weightLoss: return "🔥"
        case .muscleGain: return "💪"
        case .strengthTraining: return "🏋️"
        case .endurance: return "🏃"
        case .generalFitness: return "⚡"
        case .maintenance: return "🌱"
        }
    }
}

extension FitnessLevel {
    var onboardingEmoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "💪"
        case .advanced: return "🏆"
        }
    }
}

extension UnitSystem {
    var onboardingEmoji: String {
        switch self {
        case .metric: return "📏"
        case .imperial: return "⚖️"
        }
    }
}

extension GymChallenge {
    var onboardingEmoji: String {
        switch self {
        case .notKnowingWhatToDo: return "🤷"
        case .stayingConsistent: return "📆"
        case .hittingPlateaus: return "🧱"
        case .lackOfConfidence: return "😬"
        case .findingTime: return "⏰"
        }
    }
}

extension MotivationBarrier {
    var onboardingEmoji: String {
        switch self {
        case .motivation: return "🔥"
        case .knowledge: return "🧠"
        case .time: return "⏰"
        case .equipment: return "🏋️"
        case .accountability: return "🤝"
        }
    }
}

// MARK: - Profile Summary Row Component

struct ProfileSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(OnboardingPalette.muted)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(OnboardingPalette.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(SubscriptionService())
        .modelContainer(for: User.self, inMemory: true)
}
