import SwiftUI
import SwiftData

struct FoodRecognitionResultsView: View {
    let result: FoodRecognitionResult
    let capturedImage: UIImage?
    let onDismiss: () -> Void
    
    @State private var selectedFoods: Set<Int> = []
    @State private var editedFoods: [RecognizedFood] = []
    @State private var isAddingFoods = false
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Captured image
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    
                    // Confidence indicator
                    ConfidenceIndicatorView(confidence: result.confidence)
                    
                    // Recognized foods
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recognized Foods")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(selectedFoods.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(Array(editedFoods.enumerated()), id: \.offset) { index, food in
                            FoodRecognitionRow(
                                food: food,
                                isSelected: selectedFoods.contains(index),
                                onToggle: {
                                    if selectedFoods.contains(index) {
                                        selectedFoods.remove(index)
                                    } else {
                                        selectedFoods.insert(index)
                                    }
                                },
                                onEdit: { editedFood in
                                    editedFoods[index] = editedFood
                                }
                            )
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: addSelectedFoods) {
                            HStack {
                                if isAddingFoods {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text(isAddingFoods ? "Adding Foods..." : "Add \(selectedFoods.count) Foods")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedFoods.isEmpty || isAddingFoods ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedFoods.isEmpty || isAddingFoods)
                        
                        Button("Retake Photo") {
                            onDismiss()
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Food Recognition")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select All") {
                        if selectedFoods.count == editedFoods.count {
                            selectedFoods.removeAll()
                        } else {
                            selectedFoods = Set(0..<editedFoods.count)
                        }
                    }
                }
            }
        }
        .onAppear {
            editedFoods = result.foods
            // Auto-select high confidence foods
            selectedFoods = Set(result.foods.enumerated().compactMap { index, food in
                food.confidence > 0.7 ? index : nil
            })
        }
    }
    
    private func addSelectedFoods() {
        guard !selectedFoods.isEmpty else { return }
        
        isAddingFoods = true
        
        // Create nutrition entries for selected foods
        let selectedFoodItems = selectedFoods.compactMap { index in
            index < editedFoods.count ? editedFoods[index] : nil
        }
        
        for food in selectedFoodItems {
            let nutritionEntry = NutritionEntry(
                foodName: food.name,
                servingSize: food.quantity,
                quantity: 1.0, // Since quantity is already included in the serving size
                calories: food.calories ?? 0,
                protein: food.protein ?? 0,
                carbohydrates: food.carbs ?? 0,
                fat: food.fat ?? 0,
                mealType: .other, // Default meal type
                logMethod: .aiCamera
            )
            
            // Set AI-specific properties
            nutritionEntry.setAIData(confidence: food.confidence, capturedImage: capturedImage)
            nutritionEntry.loggedAt = Date()
            
            // Add extended nutrition data (supplements, vitamins, minerals)
            if let extendedNutrition = food.extendedNutrition {
                nutritionEntry.extendedNutrition = extendedNutrition
            }
            
            // Insert into the model context
            modelContext.insert(nutritionEntry)
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("✅ Successfully added \(selectedFoodItems.count) foods to nutrition log")
            
            // Add a small delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAddingFoods = false
                onDismiss()
            }
        } catch {
            print("❌ Failed to save nutrition entries: \(error)")
            isAddingFoods = false
            // TODO: Show error alert to user
        }
    }
}

// MARK: - Confidence Indicator
struct ConfidenceIndicatorView: View {
    let confidence: Double
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var confidenceText: String {
        switch confidence {
        case 0.8...:
            return "High Confidence"
        case 0.6..<0.8:
            return "Medium Confidence"
        default:
            return "Low Confidence"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(confidenceColor)
            
            Text("AI Analysis: \(confidenceText)")
                .font(.subheadline)
                .foregroundColor(confidenceColor)
            
            Spacer()
            
            Text("\(Int(confidence * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(confidenceColor)
        }
        .padding()
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Food Recognition Row
struct FoodRecognitionRow: View {
    let food: RecognizedFood
    let isSelected: Bool
    let onToggle: () -> Void
    let onEdit: (RecognizedFood) -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            // Selection checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Confidence badge
                    Text("\(Int(food.confidence * 100))%")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(confidenceColor.opacity(0.2))
                        .foregroundColor(confidenceColor)
                        .cornerRadius(4)
                }
                
                Text(food.quantity)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let calories = food.calories {
                    HStack(spacing: 16) {
                        NutrientView(label: "Cal", value: Int(calories))
                        
                        if let protein = food.protein {
                            NutrientView(label: "P", value: Int(protein), unit: "g")
                        }
                        
                        if let carbs = food.carbs {
                            NutrientView(label: "C", value: Int(carbs), unit: "g")
                        }
                        
                        if let fat = food.fat {
                            NutrientView(label: "F", value: Int(fat), unit: "g")
                        }
                    }
                    .font(.caption)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: { showingEditSheet = true }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditFoodView(food: food, onSave: onEdit)
        }
    }
    
    private var confidenceColor: Color {
        switch food.confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Nutrient View
struct NutrientView: View {
    let label: String
    let value: Int
    let unit: String
    
    init(label: String, value: Int, unit: String = "") {
        self.label = label
        self.value = value
        self.unit = unit
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(value)\(unit)")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Edit Food View
struct EditFoodView: View {
    let food: RecognizedFood
    let onSave: (RecognizedFood) -> Void
    
    @State private var editedFood: RecognizedFood
    @Environment(\.dismiss) private var dismiss
    
    init(food: RecognizedFood, onSave: @escaping (RecognizedFood) -> Void) {
        self.food = food
        self.onSave = onSave
        self._editedFood = State(initialValue: food)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: Binding(
                        get: { editedFood.name },
                        set: { editedFood = RecognizedFood(
                            name: $0,
                            quantity: editedFood.quantity,
                            calories: editedFood.calories,
                            protein: editedFood.protein,
                            carbs: editedFood.carbs,
                            fat: editedFood.fat,
                            confidence: editedFood.confidence
                        )}
                    ))
                    
                    TextField("Quantity", text: Binding(
                        get: { editedFood.quantity },
                        set: { editedFood = RecognizedFood(
                            name: editedFood.name,
                            quantity: $0,
                            calories: editedFood.calories,
                            protein: editedFood.protein,
                            carbs: editedFood.carbs,
                            fat: editedFood.fat,
                            confidence: editedFood.confidence
                        )}
                    ))
                }
                
                Section("Nutrition (Optional)") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { editedFood.calories ?? 0 },
                            set: { editedFood = RecognizedFood(
                                name: editedFood.name,
                                quantity: editedFood.quantity,
                                calories: $0,
                                protein: editedFood.protein,
                                carbs: editedFood.carbs,
                                fat: editedFood.fat,
                                confidence: editedFood.confidence
                            )}
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { editedFood.protein ?? 0 },
                            set: { editedFood = RecognizedFood(
                                name: editedFood.name,
                                quantity: editedFood.quantity,
                                calories: editedFood.calories,
                                protein: $0,
                                carbs: editedFood.carbs,
                                fat: editedFood.fat,
                                confidence: editedFood.confidence
                            )}
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { editedFood.carbs ?? 0 },
                            set: { editedFood = RecognizedFood(
                                name: editedFood.name,
                                quantity: editedFood.quantity,
                                calories: editedFood.calories,
                                protein: editedFood.protein,
                                carbs: $0,
                                fat: editedFood.fat,
                                confidence: editedFood.confidence
                            )}
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { editedFood.fat ?? 0 },
                            set: { editedFood = RecognizedFood(
                                name: editedFood.name,
                                quantity: editedFood.quantity,
                                calories: editedFood.calories,
                                protein: editedFood.protein,
                                carbs: editedFood.carbs,
                                fat: $0,
                                confidence: editedFood.confidence
                            )}
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(editedFood)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleResult = FoodRecognitionResult(
        foods: [
            RecognizedFood(
                name: "Grilled Chicken Breast",
                quantity: "150g",
                calories: 231,
                protein: 43.5,
                carbs: 0,
                fat: 5.0,
                confidence: 0.9
            ),
            RecognizedFood(
                name: "Brown Rice",
                quantity: "1 cup cooked",
                calories: 216,
                protein: 5.0,
                carbs: 45,
                fat: 1.8,
                confidence: 0.8
            )
        ],
        confidence: 0.85,
        rawResponse: ""
    )
    
    FoodRecognitionResultsView(
        result: sampleResult,
        capturedImage: nil,
        onDismiss: {}
    )
}
