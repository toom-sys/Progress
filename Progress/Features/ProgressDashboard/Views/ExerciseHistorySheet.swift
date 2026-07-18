//
//  ExerciseHistorySheet.swift
//  Progress
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseHistorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let exerciseName: String
    let units: UnitSystem

    private var history: [LiftSessionRecord] {
        LiftProgressTracker.history(forExerciseNamed: exerciseName, in: modelContext)
    }

    private var metricKind: ExerciseProgressionMode {
        history.last?.metricKind ?? .weighted
    }

    private var chartDisplayValue: (LiftSessionRecord) -> Double {
        { record in
            if record.metricKind == .weighted, let oneRM = record.estimatedOneRMKg {
                return units.convertWeight(from: oneRM)
            }
            switch record.metricKind {
            case .weighted:
                return units.convertWeight(from: record.primaryMetric)
            case .bodyweight, .timed:
                return record.primaryMetric
            }
        }
    }

    /// Zooms the y-axis to the data range with padding so points never sit on or below the axis.
    private var chartYDomain: ClosedRange<Double> {
        let values = history.map(chartDisplayValue)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }

        guard minValue < maxValue else {
            let padding = max(minValue * 0.1, 1)
            let lower = max(0, minValue - padding)
            return lower...(maxValue + padding)
        }

        let range = maxValue - minValue
        let padding = max(range * 0.12, minValue * 0.025)
        let lower = max(0, minValue - padding)
        return lower...(maxValue + padding)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if history.isEmpty {
                        emptyState
                    } else {
                        chartSection
                        historyList
                    }
                }
                .padding(20)
            }
            .background(AdaptiveGradientBackground())
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            Text("No history yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Complete a workout with \(exerciseName) and your progress will show up here.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 12)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(chartTitle)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                if metricKind == .weighted {
                    HStack(spacing: 12) {
                        legendDot(color: .brand, label: "1RM est.")
                        legendDot(color: .orange, label: "Deload", dashed: true)
                    }
                } else {
                    HStack(spacing: 12) {
                        legendDot(color: .brand, label: "Top set")
                        legendDot(color: .orange, label: "Deload", dashed: true)
                    }
                }
            }

            Chart(history) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Value", chartDisplayValue(record))
                )
                .foregroundStyle(Color.brand)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Value", chartDisplayValue(record))
                )
                .foregroundStyle(record.isDeload ? Color.orange : Color.brand)
                .symbol(record.isDeload ? .triangle : .circle)
                .symbolSize(record.isDeload ? 70 : 50)
            }
            .frame(height: 220)
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
        }
        .padding(16)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartTitle: String {
        switch metricKind {
        case .weighted:
            return "Estimated 1RM over time"
        case .bodyweight:
            return "Best set reps over time"
        case .timed:
            return "Best set duration over time"
        }
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sessions")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(history.reversed()) { record in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.sessionLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        Text(record.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(LiftProgressTracker.formattedPrimaryMetric(record, units: units))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(record.isDeload ? .orange : .textPrimary)

                        if let oneRM = record.estimatedOneRMKg {
                            Text("Est. 1RM \(LiftProgressTracker.formattedOneRM(oneRM, units: units))")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }

                        if record.isDeload {
                            Text("Deload")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(12)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func legendDot(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 4) {
            if dashed {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 7))
                    .foregroundColor(color)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
    }
}
