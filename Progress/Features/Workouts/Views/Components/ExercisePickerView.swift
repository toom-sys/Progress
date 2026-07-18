//
//  ExercisePickerView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var exerciseDatabase = ExerciseDatabase.shared
    
    @State private var searchText: String = ""
    @State private var selectedCategory: ExerciseDatabase.ExerciseCategory?
    @State private var selectedType: ExerciseDatabase.ExerciseType?
    @State private var showingCustomExerciseForm = false
    
    let workout: Workout
    let onExerciseSelected: (ExerciseDatabase.PredefinedExercise) -> Void
    let onCustomExerciseRequested: (() -> Void)?
    let onDismiss: () -> Void
    
    init(
        workout: Workout,
        onExerciseSelected: @escaping (ExerciseDatabase.PredefinedExercise) -> Void,
        onCustomExerciseRequested: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.workout = workout
        self.onExerciseSelected = onExerciseSelected
        self.onCustomExerciseRequested = onCustomExerciseRequested
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Transparent background for tap-to-dismiss
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Main picker card
            VStack(spacing: 0) {
                // Header
                ExercisePickerHeader(
                    selectedCategory: selectedCategory,
                    selectedType: selectedType,
                    onBackToCategories: {
                        selectedCategory = nil
                    },
                    onBackToTypes: {
                        selectedType = nil
                    },
                    onDismiss: onDismiss
                )
                
                // Search bar
                ExerciseSearchBar(
                    searchText: $searchText,
                    onSearchChanged: {
                        // Reset navigation when searching
                        if !searchText.isEmpty {
                            selectedCategory = nil
                            selectedType = nil
                        }
                    }
                )
                
                // Content based on navigation state
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if searchText.isEmpty {
                            // Hierarchical navigation when not searching
                            if let selectedType = selectedType {
                                ExerciseList(
                                    exercises: exerciseDatabase.getExercises(for: selectedType.type),
                                    onExerciseSelected: { exercise in
                                        selectPredefinedExercise(exercise)
                                    }
                                )
                            } else if let selectedCategory = selectedCategory {
                                ExerciseTypeList(
                                    types: exerciseDatabase.getTypes(for: selectedCategory.category),
                                    onTypeSelected: { type in
                                        self.selectedType = type
                                    }
                                )
                            } else {
                                ExerciseCategoryList(
                                    categories: exerciseDatabase.getCategories(),
                                    onCategorySelected: { category in
                                        selectedCategory = category
                                    }
                                )
                            }
                        } else {
                            // Search results
                            ExerciseList(
                                exercises: searchResults,
                                showCategory: true,
                                onExerciseSelected: { exercise in
                                    selectPredefinedExercise(exercise)
                                }
                            )
                        }
                        
                        // Add Custom Exercise button (only at exercise selection level)
                        if onCustomExerciseRequested != nil && selectedType != nil {
                            addCustomExerciseButton
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.top, 80) // Start lower on screen
            .padding(.bottom, 120) // Add more bottom padding to limit height
        }
        .onAppear {
            exerciseDatabase.setModelContext(modelContext)
        }
        .fullScreenCover(isPresented: $showingCustomExerciseForm) {
            CustomExerciseForm(
                workout: workout,
                onExerciseAdded: { exercise in
                    showingCustomExerciseForm = false
                    onDismiss()
                },
                onDismiss: {
                    showingCustomExerciseForm = false
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private var searchResults: [ExerciseDatabase.PredefinedExercise] {
        guard !searchText.isEmpty else { return [] }
        
        return exerciseDatabase.getAllExercises().filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            exercise.category.localizedCaseInsensitiveContains(searchText) ||
            exercise.type.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var addCustomExerciseButton: some View {
        Button(action: {
            HapticFeedback.workoutButtonTap()
            if let onCustomExerciseRequested = onCustomExerciseRequested {
                onCustomExerciseRequested()
            } else {
                showingCustomExerciseForm = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Add Custom Exercise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func selectPredefinedExercise(_ exercise: ExerciseDatabase.PredefinedExercise) {
        onExerciseSelected(exercise)
    }
}

#Preview {
    ExercisePickerView(
        workout: Workout(name: "Sample Workout"),
        onExerciseSelected: { _ in },
        onDismiss: {}
    )
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}