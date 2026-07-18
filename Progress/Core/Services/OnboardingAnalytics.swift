//
//  OnboardingAnalytics.swift
//  Progress
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

/// Firebase Analytics wrapper for onboarding funnel drop-off tracking.
/// Safely no-ops when Firebase has not been configured (e.g. missing GoogleService-Info.plist).
enum OnboardingAnalytics {

    // MARK: - Events

    static func logPageView(_ step: OnboardingStep) {
        log(
            "onboarding_page_view",
            parameters: ["step": step.analyticsName]
        )
    }

    static func logAdvance(from step: OnboardingStep) {
        log(
            "onboarding_advance",
            parameters: ["from_step": step.analyticsName]
        )
    }

    static func logAnswer(_ key: String, value: String) {
        log(
            "onboarding_answer",
            parameters: [
                "key": key,
                "value": value
            ]
        )
    }

    static func logSkippedPlan() {
        log("onboarding_skipped_plan")
    }

    static func logCompleted(planCreated: Bool) {
        log(
            "onboarding_completed",
            parameters: ["plan_created": planCreated ? "true" : "false"]
        )
    }

    // MARK: - Private

    private static var isEnabled: Bool {
        FirebaseApp.app() != nil
    }

    private static func log(_ event: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        let parameterSummary = parameters?
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: ", ") ?? ""
        if isEnabled {
            print("📊 [OnboardingAnalytics] \(event)\(parameterSummary.isEmpty ? "" : " (\(parameterSummary))")")
        } else {
            print("📊 [OnboardingAnalytics] (no-op) \(event)\(parameterSummary.isEmpty ? "" : " (\(parameterSummary))")")
        }
        #endif

        guard isEnabled else { return }
        Analytics.logEvent(event, parameters: parameters)
    }
}

// MARK: - Step Names

extension OnboardingStep {
    /// Stable lowercase snake_case identifier for analytics parameters.
    var analyticsName: String {
        switch self {
        case .welcome: return "welcome"
        case .featureNutrition: return "feature_nutrition"
        case .featureWorkouts: return "feature_workouts"
        case .featureRing: return "feature_ring"
        case .socialProof: return "social_proof"
        case .ringReveal: return "ring_reveal"
        case .ratingAsk: return "rating_ask"
        case .gymChallenge: return "gym_challenge"
        case .motivation: return "motivation"
        case .ageAndGoals: return "age_and_goals"
        case .fitnessLevel: return "fitness_level"
        case .unitPreferences: return "unit_preferences"
        case .bodyMetrics: return "body_metrics"
        case .activityLevel: return "activity_level"
        case .trainingEnvironment: return "training_environment"
        case .workoutCount: return "workout_count"
        case .planDecision: return "plan_decision"
        case .planPreview: return "plan_preview"
        case .subscription: return "subscription"
        case .completion: return "completion"
        }
    }
}
