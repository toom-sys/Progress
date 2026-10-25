//
//  DailyStepsCard.swift
//  Progress
//
//  Journey widget showing daily step progress, expandable to compare
//  today's cumulative steps against yesterday at the same time of day.
//

import SwiftUI
import SwiftData
import Charts

struct DailyStepsCardView: View {
    @StateObject private var progressTracker: WorkoutProgressTracker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Workout.updatedAt, order: .reverse) private var allWorkouts: [Workout]

    /// Persisted separately from layout state so UserDefaults writes
    /// don't interrupt the expand/collapse animation transaction.
    @AppStorage("journey.dailySteps.expanded") private var storedIsExpanded = false
    /// Seed from UserDefaults so the first frame matches the persisted state
    /// (avoids a collapse→expand flash on appear).
    @State private var isExpanded = UserDefaults.standard.bool(forKey: "journey.dailySteps.expanded")

    init() {
        _progressTracker = StateObject(wrappedValue: WorkoutProgressTracker(modelContext: nil))
    }

    // MARK: - Computed

    private var progress: Double {
        guard progressTracker.dailyStepGoal > 0 else { return 0 }
        return min(Double(progressTracker.currentSteps) / Double(progressTracker.dailyStepGoal), 1.0)
    }

    private var isGoalMet: Bool {
        progressTracker.currentSteps >= progressTracker.dailyStepGoal
    }

    private var stepsDelta: Int {
        progressTracker.stepsDeltaVsYesterday
    }

    private var chartPoints: [StepCumulativePoint] {
        progressTracker.yesterdayCumulativeSeries + progressTracker.todayCumulativeSeries
    }

    private var chartYDomain: ClosedRange<Double> {
        let maxSteps = chartPoints.map(\.cumulativeSteps).max() ?? 0
        let goal = progressTracker.dailyStepGoal
        let upper = max(maxSteps, goal, 1)
        return 0...Double(upper) * 1.05
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            progressBar
                .padding(.top, 8)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    comparisonStats
                    cumulativeChart
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .appCard(cornerRadius: 22, padding: 14)
        .accessibilityElement(children: .contain)
        .onAppear {
            progressTracker.setModelContext(modelContext)
            progressTracker.startObservingSteps()
            Task { await progressTracker.refresh() }
        }
        .onDisappear {
            progressTracker.stopObservingSteps()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                progressTracker.startObservingSteps()
                Task { await progressTracker.refresh() }
            } else {
                progressTracker.stopObservingSteps()
            }
        }
        .onChange(of: allWorkouts.count) { _, _ in
            Task { await progressTracker.refresh() }
        }
    }

    // MARK: - Header

    private var header: some View {
        JourneyCardHeader(emoji: "🚶", tint: .orange, title: "Daily steps") {
            HStack(spacing: 8) {
                if !isExpanded {
                    HStack(spacing: 0) {
                        Text(formatSteps(progressTracker.currentSteps))
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(AppPalette.ink)
                        Text(" / \(abbreviatedGoal)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppPalette.muted)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(formatSteps(progressTracker.currentSteps)) of \(formatSteps(progressTracker.dailyStepGoal)) steps")
                }

                ChevronToggleButton(
                    isExpanded: isExpanded,
                    size: 30,
                    accessibilityLabel: isExpanded ? "Collapse daily steps" : "Expand daily steps",
                    action: toggleExpanded
                )
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        AppProgressBar(progress: progress, height: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Daily steps progress")
            .accessibilityValue("\(formatSteps(progressTracker.currentSteps)) of \(formatSteps(progressTracker.dailyStepGoal)) steps\(isGoalMet ? ". Goal achieved!" : "")")
    }

    // MARK: - Comparison

    private var comparisonStats: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)

                Text(formatSteps(progressTracker.currentSteps))
                    .font(.numberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Yesterday · now")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)

                Text(formatSteps(progressTracker.yesterdaysStepsAtSameTime))
                    .font(.numberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("vs Yesterday")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)

                HStack(spacing: 4) {
                    Image(systemName: deltaSymbol)
                        .font(.caption.bold())
                    Text(deltaLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(deltaColor)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today \(formatSteps(progressTracker.currentSteps)) steps, yesterday \(formatSteps(progressTracker.yesterdaysStepsAtSameTime)) at this time, \(deltaAccessibilityLabel)")
    }

    private var cumulativeChart: some View {
        Chart {
            ForEach(progressTracker.yesterdayCumulativeSeries) { point in
                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("Steps", point.cumulativeSteps),
                    series: .value("Day", point.day.rawValue)
                )
                .foregroundStyle(by: .value("Day", point.day.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))
                .interpolationMethod(.monotone)
            }

            ForEach(progressTracker.todayCumulativeSeries) { point in
                AreaMark(
                    x: .value("Hour", point.hour),
                    yStart: .value("Baseline", 0),
                    yEnd: .value("Steps", point.cumulativeSteps),
                    series: .value("Day", point.day.rawValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppPalette.brandLight.opacity(0.45), Color.brand.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("Steps", point.cumulativeSteps),
                    series: .value("Day", point.day.rawValue)
                )
                .foregroundStyle(by: .value("Day", point.day.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.monotone)
            }

            if progressTracker.dailyStepGoal > 0 {
                RuleMark(y: .value("Goal", progressTracker.dailyStepGoal))
                    .foregroundStyle(Color.textTertiary.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
            }
        }
        .chartForegroundStyleScale([
            StepCumulativePoint.Day.today.rawValue: Color.brand,
            StepCumulativePoint.Day.yesterday.rawValue: AppPalette.brandLight
        ])
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .frame(height: 160)
        .chartYScale(domain: chartYDomain)
        .chartXScale(domain: 0...24)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hour = value.as(Double.self) {
                        Text(hourLabel(hour))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
        }
        .accessibilityLabel("Cumulative steps today versus yesterday")
    }

    // MARK: - Actions

    private func toggleExpanded() {
        HapticFeedback.workoutButtonTap()
        let newValue = !isExpanded
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            isExpanded = newValue
        }
        // Persist after the current turn so UserDefaults doesn't
        // publish inside the animation transaction.
        DispatchQueue.main.async {
            storedIsExpanded = newValue
        }
    }

    // MARK: - Formatting

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.locale = Locale.current
        return formatter
    }

    private func formatSteps(_ steps: Int) -> String {
        numberFormatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    /// Goals of 1,000 or more read as "10k".
    private var abbreviatedGoal: String {
        let goal = progressTracker.dailyStepGoal
        guard goal >= 1000 else { return formatSteps(goal) }
        if goal.isMultiple(of: 1000) {
            return "\(goal / 1000)k"
        }
        return String(format: "%.1fk", Double(goal) / 1000)
    }

    private var deltaSymbol: String {
        if stepsDelta > 0 { return "arrow.up.right" }
        if stepsDelta < 0 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var deltaColor: Color {
        if stepsDelta > 0 { return .green }
        if stepsDelta < 0 { return .orange }
        return .textSecondary
    }

    private var deltaLabel: String {
        let absDelta = abs(stepsDelta)
        let formatted = formatSteps(absDelta)
        if stepsDelta > 0 { return "+\(formatted)" }
        if stepsDelta < 0 { return "−\(formatted)" }
        return formatted
    }

    private var deltaAccessibilityLabel: String {
        if stepsDelta > 0 { return "\(formatSteps(stepsDelta)) ahead of yesterday" }
        if stepsDelta < 0 { return "\(formatSteps(abs(stepsDelta))) behind yesterday" }
        return "even with yesterday"
    }

    private func hourLabel(_ hour: Double) -> String {
        switch Int(hour) {
        case 0: return "12a"
        case 6: return "6a"
        case 12: return "12p"
        case 18: return "6p"
        case 24: return "12a"
        default: return "\(Int(hour))"
        }
    }
}

// MARK: - Preview

#Preview("Daily Steps") {
    ScrollView {
        VStack(spacing: 20) {
            DailyStepsCardView()
        }
        .padding(20)
    }
    .modelContainer(for: [User.self, Workout.self], inMemory: true)
}
