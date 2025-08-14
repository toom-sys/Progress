//
//  NutritionMetricsSettingsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct NutritionMetricsSettingsView: View {
    @AppStorage("primaryMetrics") private var primaryMetricsData = Data()
    @AppStorage("secondaryMetrics") private var secondaryMetricsData = Data()
    @State private var selectedPrimaryMetrics: [NutritionMetricType]
    @State private var selectedSecondaryMetrics: [NutritionMetricType]
    @State private var selectedCategory: NutritionCategory = .performance
    
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
    
    init() {
        // Initialize state with current values
        let primary: [NutritionMetricType]
        if let decoded = try? JSONDecoder().decode([String].self, from: Data()) {
            primary = decoded.compactMap { NutritionMetricType(rawValue: $0) }
        } else {
            primary = NutritionMetricType.primaryMetrics
        }
        
        let secondary: [NutritionMetricType]
        if let decoded = try? JSONDecoder().decode([String].self, from: Data()) {
            secondary = decoded.compactMap { NutritionMetricType(rawValue: $0) }
        } else {
            secondary = NutritionMetricType.secondaryMetrics
        }
        
        self._selectedPrimaryMetrics = State(initialValue: primary)
        self._selectedSecondaryMetrics = State(initialValue: secondary)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Current metrics preview
            currentMetricsSection
            
            List {
                // Primary metrics section (read-only info)
                Section("Primary Metrics (Fixed)") {
                    Text("The first page always shows Calories and your three main macros: Protein, Carbs, and Fat.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.vertical, 4)
                }
                
                // Quick presets section
                Section("Quick Presets for Second Page") {
                    ForEach(presetOptions, id: \.title) { preset in
                        Button(action: {
                            selectedSecondaryMetrics = preset.metrics
                            saveMetrics()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text(preset.description)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    ForEach(preset.metrics.prefix(4), id: \.self) { metric in
                                        Image(systemName: metric.icon)
                                            .font(.caption2)
                                            .foregroundColor(metric.color)
                                    }
                                    if preset.metrics.count > 4 {
                                        Text("+\(preset.metrics.count - 4)")
                                            .font(.caption2)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Custom selection section
                Section("Custom Selection") {
                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Array(NutritionMetricType.availableMetricsByCategory.keys), id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                    
                    // Metrics for selected category
                    if let metrics = NutritionMetricType.availableMetricsByCategory[selectedCategory] {
                        ForEach(metrics, id: \.self) { metric in
                            MetricSelectionRow(
                                metric: metric,
                                isSelected: selectedSecondaryMetrics.contains(metric),
                                onToggle: {
                                    toggleSecondaryMetric(metric)
                                }
                            )
                        }
                    }
                    
                    Text("Select up to 6 metrics for the second page")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Nutrition Metrics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Load current settings when view appears
            selectedPrimaryMetrics = primaryMetrics
            selectedSecondaryMetrics = secondaryMetrics
        }
    }
    
    private var currentMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Second Page Metrics")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(selectedSecondaryMetrics.prefix(6), id: \.self) { metric in
                    VStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .font(.title2)
                            .foregroundColor(metric.color)
                            .frame(width: 32, height: 32)
                        
                        Text(metric.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(Color.background)
    }
    
    private var presetOptions: [PresetOption] {
        [
            PresetOption(
                title: "Popular Supplements",
                description: "Most common supplements for fitness",
                metrics: Array(NutritionMetricType.popularSupplements.prefix(6))
            ),
            PresetOption(
                title: "Essential Vitamins",
                description: "Key vitamins for overall health",
                metrics: [.vitaminD, .vitaminC, .vitaminB12, .folate, .vitaminA, .vitaminE]
            ),
            PresetOption(
                title: "Key Minerals",
                description: "Important minerals for body function",
                metrics: [.iron, .calcium, .magnesium, .zinc, .potassium, .selenium]
            ),
            PresetOption(
                title: "Performance Focus",
                description: "Metrics for athletic performance",
                metrics: [.creatine, .caffeine, .betaAlanine, .citrulline, .leucine, .taurine]
            ),
            PresetOption(
                title: "Heart Health",
                description: "Nutrients important for cardiovascular health",
                metrics: [.omega3, .potassium, .magnesium, .fiber, .cholesterol, .sodium]
            ),
            PresetOption(
                title: "Bone Health",
                description: "Nutrients essential for strong bones",
                metrics: [.calcium, .vitaminD, .magnesium, .phosphorus, .vitaminK, .protein]
            )
        ]
    }
    
    private func toggleSecondaryMetric(_ metric: NutritionMetricType) {
        if let index = selectedSecondaryMetrics.firstIndex(of: metric) {
            selectedSecondaryMetrics.remove(at: index)
        } else if selectedSecondaryMetrics.count < 6 {
            selectedSecondaryMetrics.append(metric)
        }
        saveMetrics()
    }
    
    private func saveMetrics() {
        if let primaryData = try? JSONEncoder().encode(selectedPrimaryMetrics.map { $0.rawValue }) {
            primaryMetricsData = primaryData
        }
        if let secondaryData = try? JSONEncoder().encode(selectedSecondaryMetrics.map { $0.rawValue }) {
            secondaryMetricsData = secondaryData
        }
    }
}

// MARK: - Helper Types

struct PresetOption {
    let title: String
    let description: String
    let metrics: [NutritionMetricType]
}

struct MetricSelectionRow: View {
    let metric: NutritionMetricType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundColor(metric.color)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(metric.recommendedDailyValue, specifier: "%.1f") \(metric.unit)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    if metric.isSupplementFriendly {
                        Text("Supplement-friendly")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        NutritionMetricsSettingsView()
    }
}
