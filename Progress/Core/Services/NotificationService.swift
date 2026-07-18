//
//  NotificationService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import UserNotifications
import UIKit

/// Service for managing local notifications and permissions
/// Step 5B: Basic timer notifications implementation
final class NotificationService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let permissionRequestedKey = "com.progress.notification.permissionRequested"
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationDelegate()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from the user
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            userDefaults.set(true, forKey: permissionRequestedKey)
            return granted
            
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
            return false
        }
    }
    
    /// Check if we've already requested permissions
    var hasRequestedPermissions: Bool {
        return userDefaults.bool(forKey: permissionRequestedKey)
    }
    
    /// Check current notification authorization status
    func getCurrentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Timer Notifications
    
    /// Schedule a rest timer completion notification
    func scheduleRestTimerNotification(for exerciseName: String, duration: TimeInterval, workoutId: UUID? = nil) async {
        print("📱 NOTIFICATION: scheduleRestTimerNotification called")
        print("📱 NOTIFICATION: Exercise: \(exerciseName)")
        print("📱 NOTIFICATION: Duration: \(duration)s")
        print("📱 NOTIFICATION: Workout ID: \(workoutId?.uuidString ?? "nil")")
        
        // Check if we have permission
        let status = await getCurrentAuthorizationStatus()
        print("📱 NOTIFICATION: Authorization status: \(status.rawValue)")
        guard status == .authorized else {
            print("❌ NOTIFICATION: Not authorized - status: \(status)")
            return
        }
        
        // Validate duration - must be at least 1 second for UNTimeIntervalNotificationTrigger
        guard duration >= 1.0 else {
            print("⚠️ Timer duration too short for notification: \(duration)s")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete"
        content.body = "Time to get back to \(exerciseName)!"
        content.sound = .default
        // Don't set badge for timer notifications
        
        // Add workout ID to user info for deep linking (Step 5C)
        if let workoutId = workoutId {
            content.userInfo = [
                "workoutId": workoutId.uuidString,
                "action": "openWorkout"
            ]
        }
        
        // Create trigger for the specified duration
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: duration,
            repeats: false
        )
        
        // Create unique identifier
        let identifier = "rest_timer_\(exerciseName)_\(Date().timeIntervalSince1970)"
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        print("📱 NOTIFICATION: About to schedule notification with ID: \(identifier)")
        
        do {
            try await notificationCenter.add(request)
            print("✅ NOTIFICATION: Successfully scheduled notification for \(duration)s")
        } catch {
            print("❌ NOTIFICATION: Failed to schedule timer notification: \(error)")
        }
    }
    
    /// Cancel all pending timer notifications
    func cancelAllTimerNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Cancel timer notifications for specific exercise
    func cancelTimerNotifications(for exerciseName: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains("rest_timer_\(exerciseName)") }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationDelegate() {
        notificationCenter.delegate = NotificationDelegate.shared
    }
}

// MARK: - Notification Delegate

private class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        
        print("📱 NOTIFICATION: Timer notification tapped: \(identifier)")
        print("📱 NOTIFICATION: UserInfo: \(userInfo)")
        #if targetEnvironment(simulator)
        print("📱 NOTIFICATION: Running on simulator")
        #else
        print("📱 NOTIFICATION: Running on physical device")
        #endif
        
        // Handle deep linking for workout notifications (Step 5C)
        if let workoutIdString = userInfo["workoutId"] as? String,
           let workoutId = UUID(uuidString: workoutIdString),
           let action = userInfo["action"] as? String,
           action == "openWorkout" {
            
            print("🔗 NOTIFICATION: Opening workout via deep link: \(workoutId)")
            
            DispatchQueue.main.async {
                // Set deep link flag immediately to prevent dismissal
                DeepLinkService.shared.setDeepLinkInProgress(true)
                DeepLinkService.shared.handleDirectWorkoutLink(workoutId: workoutId)
            }
        } else {
            print("⚠️ NOTIFICATION: No valid workout ID found in notification")
            print("   workoutIdString: \(userInfo["workoutId"] as? String ?? "nil")")
            print("   action: \(userInfo["action"] as? String ?? "nil")")
        }
        
        completionHandler()
    }
}
