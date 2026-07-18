//
//  NavigationNotifications.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation

// MARK: - NotificationCenter Extension

extension Notification.Name {
    static let dismissWorkoutDetail = Notification.Name("dismissWorkoutDetail")
    static let showWorkoutDetail = Notification.Name("showWorkoutDetail")
    static let showWorkoutHistory = Notification.Name("showWorkoutHistory")
    static let dismissWorkoutHistory = Notification.Name("dismissWorkoutHistory")
    static let navigateToProgress = Notification.Name("navigateToProgress")
    static let navigateToWorkouts = Notification.Name("navigateToWorkouts")
    static let navigateToNutrition = Notification.Name("navigateToNutrition")
}
