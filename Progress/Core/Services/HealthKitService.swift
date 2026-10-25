//
//  HealthKitService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import HealthKit
import Charts

/// A cumulative step sample for charting progress through a day.
struct StepCumulativePoint: Identifiable, Equatable {
    enum Day: String, Plottable {
        case today = "Today"
        case yesterday = "Yesterday"
    }

    /// Hours from midnight (0…24).
    let hour: Double
    let cumulativeSteps: Int
    let day: Day

    var id: String { "\(day.rawValue)-\(hour)" }
}

/// Reads daily step count from Apple Health (HealthKit).
@MainActor
final class HealthKitService: ObservableObject {

    static let shared = HealthKitService()

    // MARK: - Published State

    @Published private(set) var todaysSteps: Int = 0
    /// Yesterday's steps from midnight through the same clock time as now.
    @Published private(set) var yesterdaysStepsAtSameTime: Int = 0
    @Published private(set) var todayCumulativeSeries: [StepCumulativePoint] = []
    @Published private(set) var yesterdayCumulativeSeries: [StepCumulativePoint] = []
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
            let steps = try await queryStepCount(
                from: Calendar.current.startOfDay(for: Date()),
                to: Date()
            )
            todaysSteps = steps
            lastErrorMessage = nil
            return steps
        } catch {
            lastErrorMessage = error.localizedDescription
            print("❌ HealthKit step query failed: \(error)")
            return todaysSteps
        }
    }

    /// Fetches today vs yesterday comparison totals and cumulative series for charting.
    func fetchStepComparison() async {
        guard isHealthDataAvailable else {
            clearComparisonData()
            return
        }

        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else {
            clearComparisonData()
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let yesterdaySameTime = calendar.date(byAdding: .day, value: -1, to: now),
              let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday) else {
            clearComparisonData()
            return
        }

        do {
            async let todayTotal = queryStepCount(from: startOfToday, to: now)
            async let yesterdaySame = queryStepCount(from: startOfYesterday, to: yesterdaySameTime)
            async let todayHourly = queryHourlySteps(from: startOfToday, to: now)
            async let yesterdayHourly = queryHourlySteps(from: startOfYesterday, to: endOfYesterday)

            let (today, yesterday, todayHours, yesterdayHours) = try await (
                todayTotal, yesterdaySame, todayHourly, yesterdayHourly
            )

            todaysSteps = today
            yesterdaysStepsAtSameTime = yesterday
            todayCumulativeSeries = Self.cumulativeSeries(
                hourlySteps: todayHours,
                day: .today,
                through: now,
                calendar: calendar
            )
            yesterdayCumulativeSeries = Self.cumulativeSeries(
                hourlySteps: yesterdayHours,
                day: .yesterday,
                through: endOfYesterday,
                calendar: calendar
            )
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            print("❌ HealthKit step comparison query failed: \(error)")
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
                await self.fetchStepComparison()
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

    private func clearComparisonData() {
        todaysSteps = 0
        yesterdaysStepsAtSameTime = 0
        todayCumulativeSeries = []
        yesterdayCumulativeSeries = []
    }

    private func queryStepCount(from start: Date, to end: Date) async throws -> Int {
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
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

    /// Hourly step buckets keyed by the hour's start date.
    private func queryHourlySteps(from start: Date, to end: Date) async throws -> [(start: Date, steps: Int)] {
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        let interval = DateComponents(hour: 1)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var buckets: [(start: Date, steps: Int)] = []
                results?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    buckets.append((statistics.startDate, Int(steps.rounded())))
                }
                continuation.resume(returning: buckets)
            }

            healthStore.execute(query)
        }
    }

    /// Builds a midnight-origin cumulative series from hourly buckets.
    private static func cumulativeSeries(
        hourlySteps: [(start: Date, steps: Int)],
        day: StepCumulativePoint.Day,
        through end: Date,
        calendar: Calendar
    ) -> [StepCumulativePoint] {
        let dayStart: Date
        if let first = hourlySteps.first {
            dayStart = calendar.startOfDay(for: first.start)
        } else {
            dayStart = calendar.startOfDay(for: end)
        }

        var points: [StepCumulativePoint] = [
            StepCumulativePoint(hour: 0, cumulativeSteps: 0, day: day)
        ]
        var running = 0
        let nowHour = max(0, min(24, end.timeIntervalSince(dayStart) / 3600))

        for bucket in hourlySteps.sorted(by: { $0.start < $1.start }) {
            running += bucket.steps
            let hourEnd = bucket.start.timeIntervalSince(dayStart) / 3600 + 1
            let clampedHour = day == .today ? min(hourEnd, nowHour) : min(hourEnd, 24)
            points.append(StepCumulativePoint(hour: clampedHour, cumulativeSteps: running, day: day))
        }

        // Ensure today's series ends exactly at the current clock time.
        if day == .today, points.last?.hour != nowHour {
            points.append(StepCumulativePoint(hour: nowHour, cumulativeSteps: running, day: day))
        }

        return points
    }
}
