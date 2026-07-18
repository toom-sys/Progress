//
//  FoodFixIssueView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct FoodFixIssueView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entry: NutritionEntry
    @State private var issueDescription: String = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    
                    Text("Fix result")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }
                .padding(.top, 32)
                
                // Description input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Describe what needs to be fixed", text: $issueDescription, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .padding(16)
                        .background(Color.surfaceWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .lineLimit(3...6)
                    
                    // Example text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                        
                        Text("The sandwich is missing the turkey and lettuce.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 4)
                }
                
                Spacer()
                
                // Update button
                Button(action: updateFood) {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isUpdating ? "Updating..." : "Update")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(issueDescription.isEmpty ? Color.gray : Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(issueDescription.isEmpty || isUpdating)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
        }
    }
    
    private func updateFood() {
        guard !issueDescription.isEmpty else { return }
        
        isUpdating = true
        
        // Simulate API call to update food information
        Task {
            do {
                // Here you would typically call an AI service to re-analyze the food
                // based on the user's feedback and update the nutrition entry
                
                // For now, we'll simulate a delay and then dismiss
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    // You could update the entry here based on AI response
                    // entry.updateNutrition(...)
                    
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    // Handle error
                }
            }
        }
    }
}

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
    
    return FoodFixIssueView(entry: entry)
}
