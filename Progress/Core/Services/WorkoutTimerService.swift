//
//  WorkoutTimerService.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import Combine
import UIKit

@MainActor
class WorkoutTimerService: ObservableObject {
    static private var timers: [String: WorkoutTimerService] = [:]
    
    static func forWorkout(_ workoutId: String) -> WorkoutTimerService {
        if let existingTimer = timers[workoutId] {
            return existingTimer
        } else {
            let newTimer = WorkoutTimerService(workoutId: workoutId)
            timers[workoutId] = newTimer
            return newTimer
        }
    }
    
    @Published var timeRemaining: TimeInterval = 90
    @Published var isRunning = false
    @Published var defaultDuration: TimeInterval = 90
    @Published var isFinished = false
    
    private var timer: Timer?
    private let workoutId: String
    private var timerEndDate: Date?
    
    private static func userDefaultsKey(for workoutId: String) -> String {
        "timerDuration.\(workoutId)"
    }
    
    private init(workoutId: String) {
        self.workoutId = workoutId
        // Load persisted duration for this specific workout
        let key = WorkoutTimerService.userDefaultsKey(for: workoutId)
        let saved = UserDefaults.standard.double(forKey: key)
        let duration = saved > 0 ? saved : 90
        self.defaultDuration = duration
        self.timeRemaining = duration
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reconcileBackgroundTime() }
        }
    }
    
    func startTimer() {
        guard timeRemaining > 0 else { return }
        
        isRunning = true
        
        if timeRemaining >= 2.0 {
            Task {
                let workoutUUID = UUID(uuidString: workoutId)
                await NotificationService.shared.scheduleRestTimerNotification(
                    for: "Rest Timer",
                    duration: timeRemaining,
                    workoutId: workoutUUID
                )
            }
        }
        
        // Start immediately by decrementing first, then record the absolute end date
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        timerEndDate = Date().addingTimeInterval(timeRemaining)
        
        // Then start the repeating timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    // Timer finished
                    self.timerFinished()
                }
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        timerEndDate = nil
        
        // Cancel pending notifications when timer is paused (Step 5B)
        Task {
            await NotificationService.shared.cancelTimerNotifications(for: "Rest Timer")
        }
    }
    
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = defaultDuration
        
        // Cancel any pending notifications when timer is reset (Step 5B)
        Task {
            await NotificationService.shared.cancelTimerNotifications(for: "Rest Timer")
        }
    }
    
    func setDefaultDuration(_ duration: TimeInterval, fromUser: Bool = false) {
        guard duration > 0 else { return }
        if fromUser {
            defaultDuration = duration
            timeRemaining = duration
            // Persist per-workout timer duration
            let key = WorkoutTimerService.userDefaultsKey(for: workoutId)
            UserDefaults.standard.set(duration, forKey: key)
        } else {
            // Only apply the programmatic default if no persisted value exists for this workout
            let key = WorkoutTimerService.userDefaultsKey(for: workoutId)
            let hasSaved = UserDefaults.standard.object(forKey: key) != nil
            if !hasSaved {
                if !isRunning { timeRemaining = duration }
                defaultDuration = duration
            }
        }
    }
    
    /// Called when the app returns to foreground — corrects timeRemaining using the
    /// stored end date so the countdown reflects time that passed while backgrounded.
    private func reconcileBackgroundTime() {
        guard isRunning, let endDate = timerEndDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            timerFinished()
        } else {
            timeRemaining = remaining
        }
    }
    
    private func timerFinished() {
        pauseTimer()
        isFinished = true
        HapticFeedback.timerFinished()
        timeRemaining = defaultDuration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            isFinished = false
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
