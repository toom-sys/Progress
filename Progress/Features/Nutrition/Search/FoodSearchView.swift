//
//  FoodSearchView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var foodSearchService = FoodSearchService()
    @State private var searchText = ""
    @State private var selectedFood: FoodSearchResult?
    @State private var showingAddFood = false

    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                

                
                // Search Results
                searchResultsList
            }
            .background(AdaptiveGradientBackground())
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFood) { food in
                AddFoodSheet(
                    food: food,
                    modelContext: modelContext
                ) {
                    dismiss() // Close search view after adding food
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)
                
                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        Task {
                            await foodSearchService.searchFoods(query: searchText)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        foodSearchService.searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .cardStyle()
            
            // Search suggestion buttons
            if searchText.isEmpty {
                searchSuggestions
            }
                }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.backgroundSecondary)
    }
    
    private var searchSuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["Chicken breast", "Banana", "Oats", "Salmon", "Broccoli", "Eggs"], id: \.self) { suggestion in
                    Button(suggestion) {
                        searchText = suggestion
                        Task {
                            await foodSearchService.searchFoods(query: suggestion)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.1))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .font(.caption)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    

    
    // MARK: - Search Results
    
    private var searchResultsList: some View {
        Group {
            if foodSearchService.isLoading {
                loadingView
            } else if let errorMessage = foodSearchService.errorMessage {
                errorView(errorMessage)
            } else if foodSearchService.searchResults.isEmpty && !searchText.isEmpty {
                emptyStateView
            } else {
                resultsList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching foods...")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Search Error")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await foodSearchService.searchFoods(query: searchText)
                }
            }
            .primaryButtonStyle()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.background)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.textTertiary)
            
            Text("No foods found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text("Try searching for a different food or check your spelling")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.background)
    }
    
    private var resultsList: some View {
        List(foodSearchService.searchResults) { food in
            FoodSearchRowView(food: food) {
                selectedFood = food
            }
                            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
                .listStyle(PlainListStyle())
        .background(Color.background)
    }
}

// MARK: - Food Search Row

struct FoodSearchRowView: View {
    let food: FoodSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Food Icon
                Image(systemName: food.isVerified ? "checkmark.seal.fill" : "leaf.fill")
                    .font(.title2)
                    .foregroundColor(food.isVerified ? .green : .orange)
                    .frame(width: 40, height: 40)
                    .background(Color.surface)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.border, lineWidth: 1)
                    )
                
                // Food Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    if let brand = food.displayBrand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 16) {
                        if let calories = food.calories {
                            NutrientLabel(value: calories, unit: "cal", color: .orange)
                        }
                        
                        if let protein = food.protein {
                            NutrientLabel(value: protein, unit: "g protein", color: .blue)
                        }
                    }
                }
                
                Spacer()
                
                // Serving Size
                VStack(alignment: .trailing) {
                    Text(food.servingText)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    if food.isVerified {
                        Text("Verified")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutrientLabel: View {
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(Int(value))")
                .font(.caption)
                .fontWeight(.medium)
            Text(unit)
                .font(.caption2)
        }
        .foregroundColor(color)
    }
}

// MARK: - Add Food Sheet

struct AddFoodSheet: View {
    let food: FoodSearchResult
    let modelContext: ModelContext
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double = 1.0
    @State private var notes: String = ""
    @State private var isLoading = false
    
    private var totalCalories: Double {
        (food.calories ?? 0) * quantity
    }
    
    private var totalProtein: Double {
        (food.protein ?? 0) * quantity
    }
    
    private var totalCarbs: Double {
        (food.carbohydrates ?? 0) * quantity
    }
    
    private var totalFat: Double {
        (food.fat ?? 0) * quantity
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Food Header
                    foodHeader
                    
                    // Quantity Selector
                    quantitySelector
                    
                    // Nutrition Summary
                    nutritionSummary
                    
                    // Notes
                    notesSection
                    
                    // Add Button
                    addButton
                }
                .padding()
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var foodHeader: some View {
        VStack(spacing: 8) {
            Text(food.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if let brand = food.displayBrand {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Text("per \(food.servingText)")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
    }
    
    private var quantitySelector: some View {
        VStack(spacing: 12) {
            Text("Quantity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button(action: {
                    if quantity > 0.25 {
                        quantity -= 0.25
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .disabled(quantity <= 0.25)
                
                Spacer()
                
                Text(String(format: "%.2g", quantity))
                    .font(.title)
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                Spacer()
                
                Button(action: {
                    quantity += 0.25
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
    }
    
    private var nutritionSummary: some View {
        VStack(spacing: 16) {
            Text("Nutrition Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                NutritionRow(label: "Calories", value: totalCalories, unit: "cal", color: .orange)
                NutritionRow(label: "Protein", value: totalProtein, unit: "g", color: .blue)
                NutritionRow(label: "Carbs", value: totalCarbs, unit: "g", color: .green)
                NutritionRow(label: "Fat", value: totalFat, unit: "g", color: .purple)
            }
            .padding()
            .background(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
    }
    
    private var notesSection: some View {
        VStack(spacing: 12) {
            Text("Notes (optional)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Add any notes about this food...", text: $notes, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
                .lineLimit(3...6)
        }
    }
    
    private var addButton: some View {
        Button(action: addFood) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                }
                
                Text("Add Food")
                    .fontWeight(.semibold)
            }
        }
        .primaryButtonStyle()
        .disabled(isLoading)
    }
    
    private func addFood() {
        isLoading = true
        
        let nutritionEntry = NutritionEntry(
            foodName: food.displayName,
            servingSize: food.servingText,
            quantity: quantity,
            calories: food.calories ?? 0,
            protein: food.protein ?? 0,
            carbohydrates: food.carbohydrates ?? 0,
            fat: food.fat ?? 0,
            mealType: .breakfast, // Default value since we're not using meal types
            logMethod: .search
        )
        
        // Set additional properties
        nutritionEntry.brandName = food.displayBrand
        nutritionEntry.fiber = food.fiber
        nutritionEntry.foodDatabaseId = String(food.fdcId)
        nutritionEntry.isVerified = food.isVerified
        nutritionEntry.isFavorite = false
        nutritionEntry.notes = notes.isEmpty ? nil : notes
        
        modelContext.insert(nutritionEntry)
        
        // Simulate a small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            onComplete()
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(String(format: "%.1f", value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                
                Text(unit)
                    .font(.caption)
            }
            .foregroundColor(color)
        }
    }
}

#Preview {
    FoodSearchView()
}