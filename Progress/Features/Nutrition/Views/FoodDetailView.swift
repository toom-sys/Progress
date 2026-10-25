//
//  FoodDetailView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entry: NutritionEntry
    @State private var selectedNutritionPage = 0
    @State private var showingFixIssue = false
    @State private var quantity: Double
    
    init(entry: NutritionEntry) {
        self.entry = entry
        self._quantity = State(initialValue: entry.quantity)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero image section
                    heroImageSection
                    
                    // Content section
                    VStack(spacing: 32) {
                        // Food info header
                        foodInfoHeader
                        
                        // Main nutrition metrics
                        mainNutritionSection
                        
                        // Additional nutrition (swipeable)
                        additionalNutritionSection
                        
                        // Ingredients section
                        ingredientsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 120) // Space for bottom buttons
                }
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { /* Share functionality */ }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundColor(.textPrimary)
                        }
                        
                        Button(action: { /* More options */ }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionButtons
            }
        }
        .sheet(isPresented: $showingFixIssue) {
            FoodFixIssueView(entry: entry)
        }
    }
    
    // MARK: - Hero Image Section
    
    private var heroImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image or placeholder
            if let capturedImage = entry.capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
            } else {
                // Placeholder with food icon
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 300)
                    .overlay {
                        VStack {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("No Image")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
            }
            
            // Gradient overlay for better text readability
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Time stamp overlay
            HStack {
                Spacer()
                VStack {
                    Text(timeFormatter.string(from: entry.loggedAt))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    Spacer()
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Food Info Header
    
    private var foodInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.foodName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    if let brandName = entry.brandName {
                        Text(brandName)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                // Quantity editor
                quantityEditor
            }
            
            // Serving size and indicators
            HStack {
                Text(entry.servingSize)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                if entry.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if entry.logMethod == .aiCamera {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                } else if entry.logMethod == .aiPrompt {
                    Image(systemName: "text.bubble.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                Spacer()
            }
        }
    }
    
    private var quantityEditor: some View {
        HStack(spacing: 8) {
            Button(action: { adjustQuantity(-0.5) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.textSecondary)
            }
            .disabled(quantity <= 0.5)
            
            Text("\(String(format: "%.1g", quantity))")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .frame(minWidth: 40)
            
            Button(action: { adjustQuantity(0.5) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Main Nutrition Section
    
    private var mainNutritionSection: some View {
        VStack(spacing: 20) {
            // Calories (large display)
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("\(Int(entry.calories * quantity))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Calories")
                            .font(.headline)
                            .foregroundColor(.textSecondary)
                        
                        Text("+\(Int(entry.calories * quantity))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(24)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
            
            // Macros row
            HStack(spacing: 12) {
                MacroDetailCard(
                    value: entry.protein * quantity,
                    label: "Protein",
                    unit: "g",
                    color: .red,
                    icon: "fish.fill"
                )
                
                MacroDetailCard(
                    value: entry.carbohydrates * quantity,
                    label: "Carbs",
                    unit: "g",
                    color: .orange,
                    icon: "leaf.fill"
                )
                
                MacroDetailCard(
                    value: entry.fat * quantity,
                    label: "Fats",
                    unit: "g",
                    color: .blue,
                    icon: "drop.fill"
                )
            }
        }
    }
    
    // MARK: - Additional Nutrition Section
    
    private var additionalNutritionSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Nutrition Details")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Page indicator dots
            HStack {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(selectedNutritionPage == index ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: selectedNutritionPage)
                }
            }
            
            TabView(selection: $selectedNutritionPage) {
                // Page 1: Basic nutrients + fiber
                basicNutrientsPage
                    .tag(0)
                
                // Page 2: Essential vitamins
                essentialVitaminsPage
                    .tag(1)
                
                // Page 3: Essential minerals
                essentialMineralsPage
                    .tag(2)
                
                // Page 4: Performance supplements
                performanceSupplementsPage
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 220)
        }
    }
    
    private var basicNutrientsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            NutrientMiniCard(
                name: "Fiber",
                value: getValueForMetric(.fiber),
                unit: "g",
                color: .green
            )
            
            NutrientMiniCard(
                name: "Sugar",
                value: (entry.sugar ?? 0) * quantity,
                unit: "g",
                color: .pink
            )
            
            NutrientMiniCard(
                name: "Sodium",
                value: (entry.sodium ?? 0) * quantity,
                unit: "mg",
                color: .purple
            )
            
            NutrientMiniCard(
                name: "Choline",
                value: getValueForMetric(.choline),
                unit: "mg",
                color: .indigo
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var essentialVitaminsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            NutrientMiniCard(
                name: "Vitamin D",
                value: getValueForMetric(.vitaminD),
                unit: "μg",
                color: .yellow
            )
            
            NutrientMiniCard(
                name: "Vitamin B12",
                value: getValueForMetric(.vitaminB12),
                unit: "μg",
                color: .blue
            )
            
            NutrientMiniCard(
                name: "Vitamin C",
                value: getValueForMetric(.vitaminC),
                unit: "mg",
                color: .orange
            )
            
            NutrientMiniCard(
                name: "Folate",
                value: getValueForMetric(.folate),
                unit: "μg",
                color: .green
            )
            
            NutrientMiniCard(
                name: "Vitamin B6",
                value: getValueForMetric(.vitaminB6),
                unit: "mg",
                color: .purple
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var essentialMineralsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            NutrientMiniCard(
                name: "Magnesium",
                value: getValueForMetric(.magnesium),
                unit: "mg",
                color: .green
            )
            
            NutrientMiniCard(
                name: "Zinc",
                value: getValueForMetric(.zinc),
                unit: "mg",
                color: .orange
            )
            
            NutrientMiniCard(
                name: "Iron",
                value: getValueForMetric(.iron),
                unit: "mg",
                color: .red
            )
            
            NutrientMiniCard(
                name: "Calcium",
                value: getValueForMetric(.calcium),
                unit: "mg",
                color: .gray
            )
            
            NutrientMiniCard(
                name: "Potassium",
                value: getValueForMetric(.potassium),
                unit: "mg",
                color: .mint
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var performanceSupplementsPage: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            NutrientMiniCard(
                name: "Creatine",
                value: getValueForMetric(.creatine),
                unit: "g",
                color: .red
            )
            
            NutrientMiniCard(
                name: "Caffeine",
                value: getValueForMetric(.caffeine),
                unit: "mg",
                color: .brown
            )
            
            NutrientMiniCard(
                name: "Omega-3",
                value: getValueForMetric(.omega3),
                unit: "g",
                color: .teal
            )
            
            NutrientMiniCard(
                name: "Beta-Alanine",
                value: getValueForMetric(.betaAlanine),
                unit: "g",
                color: .pink
            )
            
            NutrientMiniCard(
                name: "Citrulline",
                value: getValueForMetric(.citrulline),
                unit: "g",
                color: .cyan
            )
            
            NutrientMiniCard(
                name: "Leucine",
                value: getValueForMetric(.leucine),
                unit: "g",
                color: .indigo
            )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Add More") {
                    // Add more ingredients functionality
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            // Individual ingredient items
            VStack(spacing: 12) {
                IngredientRow(
                    name: entry.foodName,
                    calories: Int(entry.calories * quantity),
                    serving: entry.servingSize
                )
                
                // Show additional ingredients if this is a composite food
                if entry.logMethod == .aiCamera && entry.foodName.lowercased().contains("and") {
                    let components = entry.foodName.components(separatedBy: " and ")
                    ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                        if index > 0 {
                            IngredientRow(
                                name: component.capitalized,
                                calories: Int(entry.calories * quantity / Double(components.count)),
                                serving: "1 portion"
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Action Buttons
    
    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { showingFixIssue = true }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.headline)
                        Text("Fix Issue")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Button(action: { 
                    updateQuantityAndDismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Safe area padding
        .background(
            Color.background
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Helper Methods
    
    private func adjustQuantity(_ delta: Double) {
        let newQuantity = max(0.5, quantity + delta)
        quantity = newQuantity
    }
    
    private func updateQuantityAndDismiss() {
        entry.updateQuantity(quantity)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to update quantity: \(error)")
            dismiss()
        }
    }
    
    private func getValueForMetric(_ metric: NutritionMetricType) -> Double {
        return entry.getTotalValue(for: metric)
    }
}

// MARK: - Supporting Views

struct MacroDetailCard: View {
    let value: Double
    let label: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(height: 24)
            
            // Value
            VStack(spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NutrientMiniCard: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    private var formattedValue: String {
        if value == 0 {
            return "0"
        } else if value < 1 {
            return String(format: "%.2f", value)
        } else if value < 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    private var displayColor: Color {
        value > 0 ? color : .textTertiary
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Value with unit
            VStack(spacing: 2) {
                Text(formattedValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(displayColor)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            // Name
            Text(name)
                .font(.caption)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(value > 0 ? color.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct IngredientRow: View {
    let name: String
    let calories: Int
    let serving: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(calories) cal")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(serving)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    let entry = NutritionEntry(
        foodName: "Coffee and Cake",
        servingSize: "1 serving",
        quantity: 1.0,
        calories: 450,
        protein: 6,
        carbohydrates: 70,
        fat: 15
    )
    
    return FoodDetailView(entry: entry)
}
