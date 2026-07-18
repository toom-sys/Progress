import SwiftUI
import SwiftData

struct ManualFoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Form fields
    @State private var foodName: String = ""
    @State private var servingSize: String = ""
    @State private var quantity: Double = 1.0
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbohydrates: String = ""
    @State private var fat: String = ""
    @State private var fiber: String = ""
    @State private var sugar: String = ""
    @State private var sodium: String = ""
    @State private var mealType: MealType = .other
    
    // Validation and UI state
    @State private var showingValidationErrors = false
    @State private var validationErrors: [String] = []
    @State private var isSaving = false
    
    // Unit selection
    @State private var servingSizeUnit: ServingSizeUnit = .grams
    
    enum ServingSizeUnit: String, CaseIterable {
        case grams = "g"
        case ounces = "oz"
        case cups = "cups"
        case tablespoons = "tbsp"
        case teaspoons = "tsp"
        case pieces = "pieces"
        case slices = "slices"
        case servings = "servings"
        
        var displayName: String {
            switch self {
            case .grams: return "Grams (g)"
            case .ounces: return "Ounces (oz)"
            case .cups: return "Cups"
            case .tablespoons: return "Tablespoons (tbsp)"
            case .teaspoons: return "Teaspoons (tsp)"
            case .pieces: return "Pieces"
            case .slices: return "Slices"
            case .servings: return "Servings"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                Section("Food Information") {
                    TextField("Food name", text: $foodName)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        TextField("Serving size", text: $servingSize)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $servingSizeUnit) {
                            ForEach(ServingSizeUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        
                        Button(action: {
                            if quantity > 0.25 {
                                quantity -= 0.25
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .disabled(quantity <= 0.25)
                        .buttonStyle(PlainButtonStyle())
                        
                        Text(String(format: "%.2g", quantity))
                            .frame(minWidth: 50)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                        
                        Button(action: {
                            quantity += 0.25
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Nutrition Information
                Section("Nutrition (per serving)") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Carbohydrates")
                        Spacer()
                        TextField("0", text: $carbohydrates)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Optional Nutrition Information
                Section("Additional Nutrition (Optional)") {
                    HStack {
                        Text("Fiber")
                        Spacer()
                        TextField("0", text: $fiber)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sugar")
                        Spacer()
                        TextField("0", text: $sugar)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sodium")
                        Spacer()
                        TextField("0", text: $sodium)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mg")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Meal Type
                Section("Meal Type") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Food Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveManualEntry()
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
            .alert("Validation Errors", isPresented: $showingValidationErrors) {
                Button("OK") { }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !servingSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !calories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func validateForm() -> Bool {
        validationErrors.removeAll()
        
        // Required fields
        if foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Food name is required")
        }
        
        if servingSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Serving size is required")
        } else if Double(servingSize) == nil || Double(servingSize)! <= 0 {
            validationErrors.append("Serving size must be a positive number")
        }
        
        if calories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Calories are required")
        } else if Double(calories) == nil || Double(calories)! < 0 {
            validationErrors.append("Calories must be a non-negative number")
        }
        
        // Optional fields validation (if provided)
        if !protein.isEmpty && (Double(protein) == nil || Double(protein)! < 0) {
            validationErrors.append("Protein must be a non-negative number")
        }
        
        if !carbohydrates.isEmpty && (Double(carbohydrates) == nil || Double(carbohydrates)! < 0) {
            validationErrors.append("Carbohydrates must be a non-negative number")
        }
        
        if !fat.isEmpty && (Double(fat) == nil || Double(fat)! < 0) {
            validationErrors.append("Fat must be a non-negative number")
        }
        
        if !fiber.isEmpty && (Double(fiber) == nil || Double(fiber)! < 0) {
            validationErrors.append("Fiber must be a non-negative number")
        }
        
        if !sugar.isEmpty && (Double(sugar) == nil || Double(sugar)! < 0) {
            validationErrors.append("Sugar must be a non-negative number")
        }
        
        if !sodium.isEmpty && (Double(sodium) == nil || Double(sodium)! < 0) {
            validationErrors.append("Sodium must be a non-negative number")
        }
        
        return validationErrors.isEmpty
    }
    
    // MARK: - Unit Conversions
    
    private func convertServingSizeToGrams(_ size: Double, unit: ServingSizeUnit) -> Double {
        switch unit {
        case .grams:
            return size
        case .ounces:
            return size * 28.35 // 1 oz = 28.35g
        case .cups:
            return size * 240 // Approximate for liquid/general use
        case .tablespoons:
            return size * 15 // 1 tbsp ≈ 15g
        case .teaspoons:
            return size * 5 // 1 tsp ≈ 5g
        case .pieces, .slices, .servings:
            return size // Keep as-is for count-based units
        }
    }
    
    private func formatServingSize(_ size: Double, unit: ServingSizeUnit) -> String {
        let convertedSize = convertServingSizeToGrams(size, unit: unit)
        
        switch unit {
        case .grams, .ounces:
            return String(format: "%.0f%@", size, unit.rawValue)
        case .cups, .tablespoons, .teaspoons:
            return String(format: "%.1f %@", size, unit.rawValue)
        case .pieces:
            return String(format: "%.0f piece%@", size, size == 1 ? "" : "s")
        case .slices:
            return String(format: "%.0f slice%@", size, size == 1 ? "" : "s")
        case .servings:
            return String(format: "%.1f serving%@", size, size == 1 ? "" : "s")
        }
    }
    
    // MARK: - Save Function
    
    private func saveManualEntry() {
        guard validateForm() else {
            showingValidationErrors = true
            return
        }
        
        isSaving = true
        
        // Parse numeric values
        let servingSizeValue = Double(servingSize) ?? 0
        let caloriesValue = Double(calories) ?? 0
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbohydrates) ?? 0
        let fatValue = Double(fat) ?? 0
        let fiberValue = Double(fiber) ?? 0
        let sugarValue = Double(sugar) ?? 0
        let sodiumValue = Double(sodium) ?? 0
        
        // Create nutrition entry
        let nutritionEntry = NutritionEntry(
            foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            servingSize: formatServingSize(servingSizeValue, unit: servingSizeUnit),
            quantity: quantity,
            calories: caloriesValue,
            protein: proteinValue,
            carbohydrates: carbsValue,
            fat: fatValue,
            mealType: mealType,
            logMethod: .manual
        )
        
        // Set optional nutrition data
        if fiberValue > 0 {
            nutritionEntry.fiber = fiberValue
        }
        if sugarValue > 0 {
            nutritionEntry.sugar = sugarValue
        }
        if sodiumValue > 0 {
            nutritionEntry.sodium = sodiumValue
        }
        
        nutritionEntry.loggedAt = Date()
        
        // Save to SwiftData
        modelContext.insert(nutritionEntry)
        
        do {
            try modelContext.save()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSaving = false
                dismiss()
            }
        } catch {
            isSaving = false
            validationErrors = ["Failed to save entry: \(error.localizedDescription)"]
            showingValidationErrors = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ManualFoodEntryView()
    }
    .modelContainer(for: NutritionEntry.self, inMemory: true)
}
