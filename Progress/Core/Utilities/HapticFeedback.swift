//
//  HapticFeedback.swift
//  Progress
//
//  Created by Progress Team
//

import UIKit

/// Centralized haptic feedback utility for consistent user experience
/// Provides subtle, appropriate feedback for different interaction types
struct HapticFeedback {
    
    // MARK: - Feedback Types
    
    /// Light haptic feedback for subtle interactions like button taps
    @MainActor
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Medium haptic feedback for standard interactions like confirmations
    @MainActor
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Heavy haptic feedback for significant interactions like completions
    @MainActor
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    /// Success haptic feedback for positive outcomes
    @MainActor
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Warning haptic feedback for cautionary actions
    @MainActor
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Error haptic feedback for failed actions
    @MainActor
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Workout-Specific Feedback
    
    /// Subtle feedback for workout button presses
    static func workoutButtonTap() {
        Task { @MainActor in
            light()
        }
    }
    
    /// Feedback for completing a set
    static func setCompleted() {
        Task { @MainActor in
            medium()
        }
    }
    
    /// Feedback for completing an entire exercise
    static func exerciseCompleted() {
        Task { @MainActor in
            success()
        }
    }
    
    /// Feedback for completing a workout
    static func workoutCompleted() {
        Task { @MainActor in
            heavy()
        }
    }
    
    /// Feedback for timer actions (start/pause/reset)
    static func timerAction() {
        Task { @MainActor in
            light()
        }
    }
    
    /// Intense feedback for timer completion — three-pulse pattern
    static func timerFinished() {
        Task { @MainActor in
            success()
            try? await Task.sleep(nanoseconds: 200_000_000)
            heavy()
            try? await Task.sleep(nanoseconds: 150_000_000)
            heavy()
        }
    }
    
    /// Feedback for deleting items
    static func itemDeleted() {
        Task { @MainActor in
            warning()
        }
    }
    
    /// Feedback for creating a workout
    static func workoutCreated() {
        Task { @MainActor in
            success()
        }
    }
    
    /// Feedback for selection changes
    static func selectionChanged() {
        Task { @MainActor in
            light()
        }
    }
}
