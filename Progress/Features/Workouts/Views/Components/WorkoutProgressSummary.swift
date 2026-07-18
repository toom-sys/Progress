//
//  WorkoutProgressSummary.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

/// Container view that displays weekly workout progress summary
struct WorkoutProgressSummary: View {
    @StateObject private var progressTracker: WorkoutProgressTracker
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query(sort: \Workout.updatedAt, order: .reverse) private var allWorkouts: [Workout]
    
    // MARK: - Loading & Error State
    
    @State private var isLoading = true
    @State private var hasError = false
    
    // MARK: - Initialization
    
    init() {
        _progressTracker = StateObject(wrappedValue: WorkoutProgressTracker(modelContext: nil))
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if hasError {
                // Error State
                errorStateView
            } else if isLoading {
                // Loading State
                loadingStateView
            } else {
                // Content State
                contentView
            }
        }
        .padding(.vertical, 16)
        .whiteCardStyle()
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onAppear {
            // Set model context and refresh when view appears
            progressTracker.setModelContext(modelContext)
            progressTracker.startObservingSteps()
            Task {
                await refreshData()
            }
        }
        .onDisappear {
            progressTracker.stopObservingSteps()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Refresh when app becomes active
            if newPhase == .active {
                progressTracker.startObservingSteps()
                Task {
                    await refreshData()
                }
            } else {
                progressTracker.stopObservingSteps()
            }
        }
        .onChange(of: allWorkouts.count) { _, _ in
            // Refresh when workouts change (completion, creation, deletion)
            Task {
                await refreshData()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout progress summary")
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        // Two circles side-by-side with even spacing
        HStack(alignment: .center, spacing: 0) {
            // Weekly Workout Circle (left)
            WeeklyWorkoutCircle(
                completedCount: progressTracker.completedWorkoutsThisWeek,
                goalCount: progressTracker.weeklyWorkoutGoal
            )
            
            Spacer()
            
            // Daily Steps Circle (right)
            DailyStepsCircle(
                currentSteps: progressTracker.currentSteps,
                goalSteps: progressTracker.dailyStepGoal
            )
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var loadingStateView: some View {
        HStack(alignment: .center, spacing: 0) {
            // Skeleton Workout Circle
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 120, height: 120)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                )
            
            Spacer()
            
            // Skeleton Steps Circle
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 120, height: 120)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var errorStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("Unable to load progress")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text("Please check your connection and try again")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        do {
            hasError = false
            await progressTracker.refresh()
            isLoading = false
        } catch {
            print("❌ WorkoutProgressSummary: Error refreshing data - \(error)")
            hasError = true
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutProgressSummary()
        .modelContainer(for: [User.self, Workout.self, Exercise.self], inMemory: true)
        .padding()
        .background(Color.gray.opacity(0.1))
}

