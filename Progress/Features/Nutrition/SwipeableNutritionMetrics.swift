//
//  SwipeableNutritionMetrics.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct SwipeableNutritionMetrics: View {
    let nutritionEntries: [NutritionEntry]
    var totalWater: Double = 0
    var waterGoal: Double = 2500
    var calorieGoal: Double = NutritionMetricType.calories.recommendedDailyValue
    var proteinGoal: Double = NutritionMetricType.protein.recommendedDailyValue
    var carbGoal: Double = NutritionMetricType.carbohydrates.recommendedDailyValue
    var fatGoal: Double = NutritionMetricType.fat.recommendedDailyValue
    @State private var selectedPage = 0

    private let primaryMetrics: [NutritionMetricType] = NutritionMetricType.primaryMetrics
    private let secondaryMetrics: [NutritionMetricType] = [
        .fiber, .vitaminD, .magnesium, .zinc, .omega3, .creatine
    ]

    /// Personalised target for a primary macro, falling back to the metric's
    /// recommended daily value for any other metric.
    private func target(for metric: NutritionMetricType) -> Double {
        switch metric {
        case .calories: return calorieGoal
        case .protein: return proteinGoal
        case .carbohydrates: return carbGoal
        case .fat: return fatGoal
        default: return metric.recommendedDailyValue
        }
    }

    // Computed totals for all displayed metrics
    private var dailyTotals: [NutritionMetricType: Double] {
        var totals: [NutritionMetricType: Double] = [:]

        for entry in nutritionEntries {
            totals[.calories, default: 0] += entry.totalCalories
            totals[.protein, default: 0] += entry.totalProtein
            totals[.carbohydrates, default: 0] += entry.totalCarbohydrates
            totals[.fat, default: 0] += entry.totalFat

            for metric in secondaryMetrics {
                totals[metric, default: 0] += entry.getTotalValue(for: metric)
            }
        }

        return totals
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Swipeable TabView
            TabView(selection: $selectedPage) {
                // Page 1: Primary metrics (Calories + 3 macros)
                primaryMetricsPage
                    .tag(0)
                
                // Page 2: Secondary/customizable metrics
                secondaryMetricsPage
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            // Fixed height for consistent layout; includes the vertical padding
            // each page adds so card shadows aren't clipped by the TabView bounds.
            .frame(height: 304)
            
            // Bottom controls
            HStack {
                Spacer()
                
                // Page dots (centered)
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .fill(selectedPage == index ? Color.primary : Color.primary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: selectedPage)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var primaryMetricsPage: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            // Row 1: Calories (2/3) + Water (1/3)
            GridRow {
                CalorieCard(
                    consumed: dailyTotals[.calories] ?? 0,
                    target: calorieGoal
                )
                .gridCellColumns(2)

                WaterMiniCard(totalAmount: totalWater, goalAmount: waterGoal)
            }

            // Row 2: Protein, Carbs, Fat
            GridRow {
                ForEach(primaryMetrics.filter { $0 != .calories }.prefix(3), id: \.self) { metric in
                    NutritionMetricCard(
                        metric: metric,
                        consumed: dailyTotals[metric] ?? 0,
                        target: target(for: metric)
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    private var secondaryMetricsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(secondaryMetrics, id: \.self) { metric in
                NutritionMetricCard(
                    metric: metric,
                    consumed: dailyTotals[metric] ?? 0,
                    target: metric.recommendedDailyValue
                )
                .frame(height: 120)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - Nutrition Metric Card

struct NutritionMetricCard: View {
    let metric: NutritionMetricType
    let consumed: Double
    let target: Double
    
    private var remaining: Double {
        max(0, target - consumed)
    }
    
    private var progress: Double {
        target > 0 ? min(consumed / target, 1.0) : 0
    }
    
    private var displayValue: String {
        if metric.higherIsBetter {
            // Show remaining for "higher is better" metrics
            let value = remaining
            if metric.shortUnit.isEmpty {
                return "\(Int(value))"
            } else {
                return "\(formatValue(value))\(metric.shortUnit)"
            }
        } else {
            // Show consumed for "lower is better" metrics
            let value = consumed
            if metric.shortUnit.isEmpty {
                return "\(Int(value))"
            } else {
                return "\(formatValue(value))\(metric.shortUnit)"
            }
        }
    }
    
    private var label: String {
        if metric.higherIsBetter {
            return "\(metric.displayName) left"
        } else {
            return "\(metric.displayName) today"
        }
    }
    
    private var progressColor: Color {
        if metric.higherIsBetter {
            return metric.color
        } else {
            // For "lower is better", use red if over target, green if under
            return progress > 1.0 ? .red : .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text(displayValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
            
            // Circular progress with icon
            ZStack {
                Circle()
                    .stroke(progressColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Image(systemName: metric.icon)
                    .font(.caption)
                    .foregroundColor(progressColor)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .whiteCardStyle(cornerRadius: 16)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if value >= 100 {
            return "\(Int(value))"
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}


// MARK: - Water Mini Card

struct WaterMiniCard: View {
    /// Current intake in millilitres
    let totalAmount: Double
    /// Goal in millilitres
    let goalAmount: Double

    private var progress: Double {
        guard goalAmount > 0 else { return 0 }
        return min(totalAmount / goalAmount, 1.0)
    }

    private var displayText: String {
        let litres = totalAmount / 1000
        return litres >= 1
            ? String(format: "%.1f L", litres)
            : "\(Int(totalAmount)) mL"
    }

    private var fillColor: Color {
        if progress >= 1.0 { return .cyan }
        if progress >= 0.8 { return .teal }
        return .brand
    }

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)

            FillingCup(progress: progress, color: fillColor)
                .frame(width: 28, height: 44)

            VStack(spacing: 2) {
                Text(displayText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("Water")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .whiteCardStyle(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Water intake: \(displayText) of \(String(format: "%.1f L", goalAmount / 1000))")
    }
}

// MARK: - Filling Cup

struct FillingCup: View {
    let progress: Double
    let color: Color

    private let cornerRadius: CGFloat = 5
    private let wavePeriod: TimeInterval = 1.8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: progress <= 0)) { context in
            let phase = wavePhase(at: context.date)

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color.opacity(0.08))

                // Full-bounds water shape clipped to the cup so bottom corners
                // always match the outline; the wave only affects the free surface.
                WaterWaveFill(progress: progress, phase: phase)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.55), color.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.55), lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: progress)
    }

    private func wavePhase(at date: Date) -> CGFloat {
        let t = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: wavePeriod) / wavePeriod
        return CGFloat(t * .pi * 2)
    }
}

/// Fills from the bottom with a gentle sine wave along the waterline.
struct WaterWaveFill: Shape {
    var progress: Double
    var phase: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(progress, 0), 1)
        guard clamped > 0.001 else { return Path() }

        let fillHeight = rect.height * clamped
        let waterTop = rect.maxY - fillHeight
        // Keep the wave subtle, and taper it near empty / full so it stays inside the cup.
        let amplitude = min(1.6, fillHeight * 0.35, (rect.height - fillHeight) * 0.5 + 0.4)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: waterTop))

        let steps = max(Int(rect.width), 1)
        for i in 0...steps {
            let x = rect.minX + CGFloat(i)
            let relativeX = CGFloat(i) / CGFloat(steps)
            let y = waterTop + sin(relativeX * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SwipeableNutritionMetrics(nutritionEntries: [], totalWater: 1200, waterGoal: 2500)
}
