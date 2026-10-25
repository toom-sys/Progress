//
//  WeightTrendCard.swift
//  Progress
//
//  Journey widget showing body weight progression over time,
//  with a quick-add button for logging new measurements.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Chart Range

enum WeightChartRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case all = "All"

    var id: String { rawValue }

    /// Earliest date included in this range, or nil for no limit.
    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
        case .all: return nil
        }
    }
}

// MARK: - Weight Trend Card

struct WeightTrendCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.loggedAt) private var allEntries: [BodyWeightEntry]
    @Query private var users: [User]

    /// Persisted separately from layout state so UserDefaults writes
    /// don't interrupt the expand/collapse animation transaction.
    @AppStorage("journey.weightTrend.expanded") private var storedIsExpanded = false
    /// Seed from UserDefaults so the first frame matches the persisted state
    /// (avoids a collapse→expand flash on appear).
    @State private var isExpanded = UserDefaults.standard.bool(forKey: "journey.weightTrend.expanded")
    @State private var selectedRange: WeightChartRange = .threeMonths
    @State private var showingLogSheet = false

    private var currentUser: User? { users.first }
    private var units: UnitSystem { currentUser?.preferredUnits ?? .metric }

    /// Entries within the selected range, oldest first.
    private var visibleEntries: [BodyWeightEntry] {
        guard let start = selectedRange.startDate else { return allEntries }
        return allEntries.filter { $0.loggedAt >= start }
    }

    private func displayWeight(_ entry: BodyWeightEntry) -> Double {
        units.convertWeight(from: entry.weightKg)
    }

    /// Zooms the y-axis to the data range with padding so the line
    /// never sits flat on the axis.
    private var chartYDomain: ClosedRange<Double> {
        let values = visibleEntries.map(displayWeight)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        guard minValue < maxValue else {
            let padding = max(minValue * 0.05, 1)
            return max(0, minValue - padding)...(maxValue + padding)
        }
        let padding = max((maxValue - minValue) * 0.15, 0.5)
        return max(0, minValue - padding)...(maxValue + padding)
    }

    /// Weight change across the visible range, in display units.
    private var rangeChange: Double? {
        guard let first = visibleEntries.first, let last = visibleEntries.last,
              visibleEntries.count >= 2 else { return nil }
        return displayWeight(last) - displayWeight(first)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if allEntries.isEmpty {
                        emptyState
                    } else {
                        rangePicker
                        statsRow
                        chart
                    }
                }
                .padding(.top, 12)
            }
        }
        .whiteCardStyle(cornerRadius: 14, padding: 14)
        .sheet(isPresented: $showingLogSheet) {
            WeightLogSheet()
        }
        .onAppear {
            seedInitialEntryFromProfileIfNeeded()
        }
    }

    /// If the profile already has a weight (e.g. from onboarding before
    /// history seeding existed) but no logged entries yet, create one so
    /// the widget isn't empty on first visit.
    private func seedInitialEntryFromProfileIfNeeded() {
        guard allEntries.isEmpty,
              let user = currentUser,
              user.weightKg > 0 else { return }

        let entry = BodyWeightEntry(weightKg: user.weightKg, loggedAt: Date())
        entry.user = user
        modelContext.insert(entry)
        try? modelContext.save()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: toggleExpanded) {
                HStack(spacing: 8) {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.purple)
                        .frame(width: 24, height: 24)
                        .background(Color.purple.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    Text("Body Weight")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    Spacer(minLength: 8)

                    if !isExpanded {
                        compactSummary
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: {
                HapticFeedback.workoutButtonTap()
                showingLogSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.brand)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Log weight")

            Button(action: toggleExpanded) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse body weight" : "Expand body weight")
        }
    }

    private var compactSummary: some View {
        Group {
            if let latest = allEntries.last {
                HStack(spacing: 4) {
                    Text(units.formatWeight(latest.weightKg))
                        .fontWeight(.semibold)
                    Text(units.weightUnit)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)

                    if let change = rangeChange {
                        Image(systemName: change < 0 ? "arrow.down.right" : (change > 0 ? "arrow.up.right" : "arrow.right"))
                            .font(.caption2.bold())
                            .foregroundColor(changeColor(for: change))
                    }
                }
                .font(.caption)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.backgroundSecondary)
                .clipShape(Capsule())
            } else {
                Text("Tap to log")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textTertiary)
            }
        }
    }

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

    // MARK: - Range Picker

    private var rangePicker: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(WeightChartRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 16) {
            if let latest = allEntries.last {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)

                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(units.formatWeight(latest.weightKg))
                            .font(.numberMedium)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        Text(units.weightUnit)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            if let change = rangeChange {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Change (\(selectedRange.rawValue))")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)

                    HStack(spacing: 4) {
                        Image(systemName: change < 0 ? "arrow.down.right" : (change > 0 ? "arrow.up.right" : "arrow.right"))
                            .font(.caption.bold())
                        Text(String(format: "%+.1f %@", change, units.weightUnit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(changeColor(for: change))
                }
            }

            Spacer()
        }
    }

    /// Colours the change toward the user's goal: losing reads green for a
    /// weight-loss goal, gaining reads green for a muscle-gain goal.
    private func changeColor(for change: Double) -> Color {
        guard change != 0 else { return .textSecondary }
        switch currentUser?.fitnessGoal {
        case .weightLoss:
            return change < 0 ? .green : .orange
        case .muscleGain:
            return change > 0 ? .green : .orange
        default:
            return .brand
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(visibleEntries) { entry in
            AreaMark(
                x: .value("Date", entry.loggedAt),
                yStart: .value("Baseline", chartYDomain.lowerBound),
                yEnd: .value("Weight", displayWeight(entry))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.brand.opacity(0.25), Color.brand.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", entry.loggedAt),
                y: .value("Weight", displayWeight(entry))
            )
            .foregroundStyle(Color.brand)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Date", entry.loggedAt),
                y: .value("Weight", displayWeight(entry))
            )
            .foregroundStyle(Color.brand)
            .symbolSize(visibleEntries.count > 20 ? 20 : 45)
        }
        .frame(height: 140)
        .chartYScale(domain: chartYDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .overlay {
            if visibleEntries.isEmpty {
                Text("No entries in this period")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .accessibilityLabel("Body weight chart for the selected period")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.12))
                .clipShape(Circle())

            Text("Log your weight to start tracking your progression over time.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                HapticFeedback.workoutButtonTap()
                showingLogSheet = true
            }) {
                Label("Log Weight", systemImage: "plus")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Weight Trend") {
    ScrollView {
        WeightTrendCard()
            .padding(20)
    }
    .modelContainer(for: [User.self, BodyWeightEntry.self], inMemory: true)
}
