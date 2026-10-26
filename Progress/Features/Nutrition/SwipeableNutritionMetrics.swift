//
//  SwipeableNutritionMetrics.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

enum NutritionCardMetrics {
    /// Shared height so calories, water, and the macro cards line up.
    static let height: CGFloat = 158
}

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
            // Room around the cards so the softer shadow fades out
            // before the page view clips it.
            .frame(height: 366)
            
            // Bottom controls
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { index in
                        Capsule()
                            .fill(selectedPage == index ? AppPalette.ink : AppPalette.muted.opacity(0.4))
                            .frame(width: selectedPage == index ? 20 : 7, height: 7)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedPage)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var primaryMetricsPage: some View {
        Grid(horizontalSpacing: 20, verticalSpacing: 20) {
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
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 18)
    }
    
    private var secondaryMetricsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
            ForEach(secondaryMetrics, id: \.self) { metric in
                NutritionMetricCard(
                    metric: metric,
                    consumed: dailyTotals[metric] ?? 0,
                    target: metric.recommendedDailyValue
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 18)
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
    
    /// Primary macros use the shared palette. Other metrics keep their own colour.
    private var ringHue: Color {
        switch metric {
        case .protein: return AppPalette.protein
        case .carbohydrates: return AppPalette.carbs
        case .fat: return AppPalette.fat
        default: return metric.color
        }
    }

    private var centerEmoji: String? {
        switch metric {
        case .protein: return "🥩"
        case .carbohydrates: return "🍞"
        case .fat: return "🥑"
        default: return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(displayValue)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(AppPalette.ink)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppPalette.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            ZStack {
                Circle()
                    .stroke(ringHue.opacity(0.22), lineWidth: 5)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringHue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                if let centerEmoji {
                    Text(centerEmoji)
                        .font(.system(size: 18))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: metric.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ringHue)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .frame(height: NutritionCardMetrics.height)
        .appCard(cornerRadius: 22, padding: 0)
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

    var body: some View {
        VStack(spacing: 6) {
            FillingCup(progress: progress, color: AppPalette.brandLight)
                .frame(width: 28, height: 44)

            VStack(spacing: 2) {
                Text(displayText)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(AppPalette.ink)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("Water")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppPalette.muted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .frame(height: NutritionCardMetrics.height)
        .appCard(cornerRadius: 24, padding: 0)
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
                    .stroke(Color.brand.opacity(0.35), lineWidth: 1.5)
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
