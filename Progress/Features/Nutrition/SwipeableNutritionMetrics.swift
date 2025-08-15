//
//  SwipeableNutritionMetrics.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct SwipeableNutritionMetrics: View {
    let nutritionEntries: [NutritionEntry]
    @State private var selectedPage = 0
    @AppStorage("primaryMetrics") private var primaryMetricsData = Data()
    @AppStorage("secondaryMetrics") private var secondaryMetricsData = Data()
    
    // Computed totals for all metrics
    private var dailyTotals: [NutritionMetricType: Double] {
        var totals: [NutritionMetricType: Double] = [:]
        
        for entry in nutritionEntries {
            // Primary macros
            totals[.calories, default: 0] += entry.totalCalories
            totals[.protein, default: 0] += entry.totalProtein
            totals[.carbohydrates, default: 0] += entry.totalCarbohydrates
            totals[.fat, default: 0] += entry.totalFat
            
            // Extended metrics
            for metric in NutritionMetricType.allCases {
                if metric != .calories && metric != .protein && metric != .carbohydrates && metric != .fat {
                    totals[metric, default: 0] += entry.getTotalValue(for: metric)
                }
            }
        }
        
        return totals
    }
    
    // Load saved metrics or use defaults
    private var primaryMetrics: [NutritionMetricType] {
        if let decoded = try? JSONDecoder().decode([String].self, from: primaryMetricsData) {
            return decoded.compactMap { NutritionMetricType(rawValue: $0) }
        }
        return NutritionMetricType.primaryMetrics
    }
    
    private var secondaryMetrics: [NutritionMetricType] {
        if let decoded = try? JSONDecoder().decode([String].self, from: secondaryMetricsData) {
            return decoded.compactMap { NutritionMetricType(rawValue: $0) }
        }
        return NutritionMetricType.secondaryMetrics
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
            .frame(height: 280) // Fixed height for consistent layout
            
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
        VStack(spacing: 12) {
            // Calories card - full width
            if primaryMetrics.contains(.calories) {
                CalorieCard(
                    consumed: dailyTotals[.calories] ?? 0,
                    target: NutritionMetricType.calories.recommendedDailyValue
                )
            }
            
            // Macro cards row
            HStack(spacing: 12) {
                ForEach(primaryMetrics.filter { $0 != .calories }.prefix(3), id: \.self) { metric in
                    NutritionMetricCard(
                        metric: metric,
                        consumed: dailyTotals[metric] ?? 0,
                        target: metric.recommendedDailyValue
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var secondaryMetricsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(Array(secondaryMetrics.prefix(6)), id: \.self) { metric in
                CompactNutritionMetricCard(
                    metric: metric,
                    consumed: dailyTotals[metric] ?? 0,
                    target: metric.recommendedDailyValue
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func saveMetrics(primary: [NutritionMetricType], secondary: [NutritionMetricType]) {
        if let primaryData = try? JSONEncoder().encode(primary.map { $0.rawValue }) {
            primaryMetricsData = primaryData
        }
        if let secondaryData = try? JSONEncoder().encode(secondary.map { $0.rawValue }) {
            secondaryMetricsData = secondaryData
        }
    }
}

// MARK: - Nutrition Metric Card

struct CompactNutritionMetricCard: View {
    let metric: NutritionMetricType
    let consumed: Double
    let target: Double
    
    private var remaining: Double {
        if metric.higherIsBetter {
            return max(0, target - consumed)
        } else {
            // For "lower is better" metrics, show how much under target
            return max(0, target - consumed)
        }
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
        VStack(spacing: 8) {
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
                    .lineLimit(2)
            }
            
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
        }
        .frame(maxWidth: .infinity)
        .whiteCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
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

struct NutritionMetricCard: View {
    let metric: NutritionMetricType
    let consumed: Double
    let target: Double
    
    private var remaining: Double {
        if metric.higherIsBetter {
            return max(0, target - consumed)
        } else {
            // For "lower is better" metrics, show how much under target
            return max(0, target - consumed)
        }
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
        VStack(spacing: 8) {
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
                    .lineLimit(2)
            }
            
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
        }
        .frame(maxWidth: .infinity)
        .whiteCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
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



#Preview {
    SwipeableNutritionMetrics(nutritionEntries: [])
}
