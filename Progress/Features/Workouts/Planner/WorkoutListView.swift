//
//  WorkoutListView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

enum WorkoutSortOption: String, CaseIterable {
    case off = "off"
    case alphabeticalAZ = "a_to_z"
    case alphabeticalZA = "z_to_a"
    case oldest = "oldest"
    case newest = "newest"
    case lastUsed = "last_used"
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .alphabeticalAZ: return "A → Z"
        case .alphabeticalZA: return "Z → A"
        case .oldest: return "Oldest"
        case .newest: return "Newest"
        case .lastUsed: return "Last Used"
        }
    }
}

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var selectedSortOption: WorkoutSortOption
    @State private var showingSortMenu = false
    
    init() {
        // Load saved sort option from UserDefaults
        let savedSort = UserDefaults.standard.string(forKey: "workout_sort_option") ?? WorkoutSortOption.off.rawValue
        _selectedSortOption = State(initialValue: WorkoutSortOption(rawValue: savedSort) ?? .off)
    }
    
    private var filteredWorkouts: [Workout] {
        let filtered = searchText.isEmpty ? workouts : workouts.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) 
        }
        
        return sortWorkouts(filtered)
    }
    
    private func sortWorkouts(_ workouts: [Workout]) -> [Workout] {
        switch selectedSortOption {
        case .off:
            return workouts
        case .alphabeticalAZ:
            return workouts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .alphabeticalZA:
            return workouts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .oldest:
            return workouts.sorted { $0.createdAt < $1.createdAt }
        case .newest:
            return workouts.sorted { $0.createdAt > $1.createdAt }
        case .lastUsed:
            return workouts.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar with Sort Button
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.textSecondary)
                            
                            TextField("Search workouts...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Sort Button
                        Menu {
                            ForEach(WorkoutSortOption.allCases, id: \.self) { option in
                                Button {
                                    selectedSortOption = option
                                    UserDefaults.standard.set(option.rawValue, forKey: "workout_sort_option")
                                } label: {
                                    HStack {
                                        Text(option.displayName)
                                        if selectedSortOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(Color.backgroundTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Workout List - Full Height
                if filteredWorkouts.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Text("💪")
                            .font(.system(size: 60))
                        
                        VStack(spacing: 12) {
                            Text(searchText.isEmpty ? "No Workouts Yet" : "No Results Found")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text(searchText.isEmpty ? 
                                "Create your first workout to get started!" : 
                                "Try adjusting your search terms.")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        if searchText.isEmpty {
                            Button("Create First Workout") {
                                showingCreateSheet = true
                            }
                            .primaryButtonStyle()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Workout List
                    List {
                        ForEach(filteredWorkouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(workout.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text(workout.updatedAt, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    workoutToDelete = workout
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .safeAreaInset(edge: .bottom) {
                        // Add bottom padding to ensure content isn't hidden behind floating navigation bar
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 100) // Height of floating nav bar + safe margin
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateWorkoutView()
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                }
                workoutToDelete = nil
            }
        } message: {
            if let workout = workoutToDelete {
                Text("Are you sure you want to delete '\(workout.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteWorkout(_ workout: Workout) {
        withAnimation {
            modelContext.delete(workout)
            try? modelContext.save()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutListView()
            .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
    }
}