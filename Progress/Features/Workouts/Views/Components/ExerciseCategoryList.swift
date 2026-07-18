//
//  ExerciseCategoryList.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseCategoryList: View {
    let categories: [ExerciseDatabase.ExerciseCategory]
    let onCategorySelected: (ExerciseDatabase.ExerciseCategory) -> Void
    
    var body: some View {
        ForEach(categories, id: \.category) { category in
            CategoryRowView(
                category: category,
                onTap: {
                    HapticFeedback.workoutButtonTap()
                    onCategorySelected(category)
                }
            )
        }
    }
}

private struct CategoryRowView: View {
    let category: ExerciseDatabase.ExerciseCategory
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(categoryColor)
            }
            
            // Category info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.category)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("\(category.types.count) types")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var categoryColor: Color {
        switch category.category.lowercased() {
        case "resistance":
            return .blue
        case "cardio":
            return .red
        case "recovery":
            return .green
        default:
            return .gray
        }
    }
    
    private var categoryIcon: String {
        switch category.category.lowercased() {
        case "resistance":
            return "dumbbell.fill"
        case "cardio":
            return "heart.fill"
        case "recovery":
            return "leaf.fill"
        default:
            return "figure.walk"
        }
    }
}

#Preview {
    ExerciseCategoryList(
        categories: [],
        onCategorySelected: { _ in }
    )
}
