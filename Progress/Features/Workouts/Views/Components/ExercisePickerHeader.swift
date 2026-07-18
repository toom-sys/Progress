//
//  ExercisePickerHeader.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExercisePickerHeader: View {
    let selectedCategory: ExerciseDatabase.ExerciseCategory?
    let selectedType: ExerciseDatabase.ExerciseType?
    let onBackToCategories: () -> Void
    let onBackToTypes: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Title and close button
            HStack {
                // Navigation back button or title
                if selectedType != nil {
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        onBackToTypes()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text(selectedCategory?.category ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                    }
                } else if selectedCategory != nil {
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        onBackToCategories()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Categories")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                    }
                } else {
                    Text("Choose Exercise")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    HapticFeedback.workoutButtonTap()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 32, height: 32)
                .background(Color.red)
                .clipShape(Circle())
            }
            
            // Breadcrumb navigation
            if selectedType != nil {
                HStack(spacing: 8) {
                    Text(selectedCategory?.category ?? "")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Text(selectedType?.type ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    ExercisePickerHeader(
        selectedCategory: nil,
        selectedType: nil,
        onBackToCategories: {},
        onBackToTypes: {},
        onDismiss: {}
    )
}
