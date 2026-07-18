//
//  HealthKitService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import HealthKit

/// Reads daily step count from Apple Health (HealthKit).
@MainActor
final class HealthKitService: ObservableObject {

    static let shared = HealthKitService()

    // MARK: - Published State

    @Published private(set) var todaysSteps: Int = 0
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var lastErrorMessage: String?

    // MARK: - Private

    private let healthStore = HKHealthStore()
    private let permissionRequestedKey = "com.progress.healthkit.steps.permissionRequested"
    private var observerQuery: HKObserverQuery?
    private var stepUpdateHandler: (() -> Void)?

    private var stepType: HKQuantityType {
        HKQuantityType(.stepCount)
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var hasRequestedPermission: Bool {
        get { UserDefaults.standard.bool(forKey: permissionRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: permissionRequestedKey) }
    }

    private init() {}

    // MARK: - Authorization

    /// Requests read access for step count if HealthKit is available and we haven't asked yet.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        guard isHealthDataAvailable else {
            isAuthorized = false
            return false
        }

        if hasRequestedPermission {
            isAuthorized = true
            return true
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            hasRequestedPermission = true
            // HealthKit does not reveal whether read access was granted; treat a successful
            // request as authorized and rely on query results for the actual count.
            isAuthorized = true
            lastErrorMessage = nil
            return true
        } catch {
            isAuthorized = false
            lastErrorMessage = error.localizedDescription
            print("❌ HealthKit authorization failed: \(error)")
            return false
        }
    }

    // MARK: - Step Queries

    /// Fetches today's cumulative step count from Apple Health.
    func fetchTodaysStepCount() async -> Int {
        guard isHealthDataAvailable else {
            todaysSteps = 0
            return 0
        }

        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else {
            todaysSteps = 0
            return 0
        }

        do {
            let steps = try await queryTodaysSteps()
            todaysSteps = steps
            lastErrorMessage = nil
            return steps
        } catch {
            lastErrorMessage = error.localizedDescription
            print("❌ HealthKit step query failed: \(error)")
            return todaysSteps
        }
    }

    /// Starts observing HealthKit step updates while the app is active.
    func startObservingStepUpdates(onUpdate: @escaping () -> Void) {
        guard isHealthDataAvailable else { return }

        stepUpdateHandler = onUpdate
        stopObservingStepUpdates()

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }

            if let error {
                print("❌ HealthKit observer error: \(error)")
                return
            }

            Task { @MainActor in
                guard let self else { return }
                _ = await self.fetchTodaysStepCount()
                self.stepUpdateHandler?()
            }
        }

        observerQuery = query
        healthStore.execute(query)
    }

    func stopObservingStepUpdates() {
        if let observerQuery {
            healthStore.stop(observerQuery)
            self.observerQuery = nil
        }
    }

    // MARK: - Private Helpers

    private func queryTodaysSteps() async throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps.rounded()))
            }

            healthStore.execute(query)
        }
    }
}
