//
//  WorkoutGoalsSettingsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Workout Goals Settings View

struct WorkoutGoalsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    private var currentUser: User? { users.first }
    
    // MARK: - Edit State
    @State private var isEditing = false
    @State private var showingSaveConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var saveError: String?
    
    // MARK: - Form Fields
    @State private var editedWeeklyWorkoutGoal = 4
    @State private var editedDailyStepGoal = 10000
    @State private var editedDailyWaterGoal: Double = 2500
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = currentUser {
                    // Header Section
                    headerSection
                    
                    // Goals Section
                    goalsSection(user: user)
                } else {
                    // No User State
                    noUserSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Workout & Activity Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if currentUser != nil {
                    editButton
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
            }
        }
        .alert("Save Changes", isPresented: $showingSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveChanges()
            }
        } message: {
            Text("Are you sure you want to save these changes to your workout and activity goals?")
        }
        .alert("Discard Changes", isPresented: $showingCancelConfirmation) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) {
                cancelEditing()
            }
        } message: {
            Text("Are you sure you want to discard your changes?")
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") {
                saveError = nil
            }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout and activity goals management")
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accent)
                .accessibilityLabel("Workout goals icon")
            
            VStack(spacing: 8) {
                Text("Set Your Goals")
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text("Configure your weekly workout targets and daily step goals to stay motivated and track your progress")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 24)
        .whiteCardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Goals header section")
    }
    
    // MARK: - Goals Section
    
    @ViewBuilder
    private func goalsSection(user: User) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Goals")
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Set targets for workouts, daily steps and water intake")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                
                if !isEditing {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Activity goals section")
            
            VStack(spacing: 20) {
                // Weekly Workout Goal
                goalRow(
                    icon: "dumbbell.fill",
                    title: "Weekly Workouts",
                    subtitle: "Number of workouts you aim to complete each week",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 8) {
                                Stepper(value: $editedWeeklyWorkoutGoal, in: 1...10) {
                                    Text("\(editedWeeklyWorkoutGoal) workout\(editedWeeklyWorkoutGoal == 1 ? "" : "s")/week")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.textPrimary)
                                }
                                .accessibilityLabel("Weekly workout goal")
                                .accessibilityValue("\(editedWeeklyWorkoutGoal) workouts per week")
                                .accessibilityHint("Use stepper to adjust between 1 and 10 workouts per week")
                                
                                Text("Range: 1-10 workouts per week")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        } else {
                            Text("\(user.weeklyWorkoutGoal) workout\(user.weeklyWorkoutGoal == 1 ? "" : "s")/week")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                                .accessibilityLabel("Weekly workout goal: \(user.weeklyWorkoutGoal) workouts per week")
                        }
                    }
                )
                
                Divider()
                    .background(Color.border.opacity(0.5))
                
                // Daily Step Goal
                goalRow(
                    icon: "figure.walk",
                    title: "Daily Steps",
                    subtitle: "Synced from Apple Health · set your daily target",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 8) {
                                Stepper(value: $editedDailyStepGoal, in: 1000...50000, step: 1000) {
                                    Text("\(formatSteps(editedDailyStepGoal)) steps/day")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.textPrimary)
                                }
                                .accessibilityLabel("Daily step goal")
                                .accessibilityValue("\(formatSteps(editedDailyStepGoal)) steps per day")
                                .accessibilityHint("Use stepper to adjust between 1,000 and 50,000 steps per day in increments of 1,000")
                                
                                Text("Range: 1,000-50,000 steps (increments of 1,000)")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        } else {
                            Text("\(formatSteps(user.dailyStepGoal)) steps/day")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                                .accessibilityLabel("Daily step goal: \(formatSteps(user.dailyStepGoal)) steps per day")
                        }
                    }
                )

                Divider()
                    .background(Color.border.opacity(0.5))

                // Daily Water Goal
                goalRow(
                    icon: "drop.fill",
                    title: "Daily Water",
                    subtitle: "Target water intake per day",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 8) {
                                Stepper(value: $editedDailyWaterGoal, in: 500...5000, step: 250) {
                                    Text("\(formatWater(editedDailyWaterGoal))/day")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.textPrimary)
                                }
                                .accessibilityLabel("Daily water goal")
                                .accessibilityValue("\(formatWater(editedDailyWaterGoal)) per day")
                                .accessibilityHint("Use stepper to adjust between 500 mL and 5,000 mL per day in increments of 250 mL")

                                Text("Range: 0.5 L – 5 L (increments of 250 mL)")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        } else {
                            Text("\(formatWater(user.dailyWaterGoal))/day")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                                .accessibilityLabel("Daily water goal: \(formatWater(user.dailyWaterGoal)) per day")
                        }
                    }
                )
            }
            
            // Goal Guidance
            if !isEditing {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.border)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.accent)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Goal Recommendations")
                                .font(.label)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Text("• Beginners: 3-4 workouts/week, 8,000 steps/day, 2 L water\n• Intermediate: 4-5 workouts/week, 10,000 steps/day, 2.5 L water\n• Advanced: 5-6 workouts/week, 12,000+ steps/day, 3+ L water")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
            
            // Save Button (when editing)
            if isEditing {
                VStack(spacing: 12) {
                    Button(action: {
                        showingSaveConfirmation = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                        }
                        .font(.buttonPrimary)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Save workout and activity goal changes")
                    .accessibilityHint("Save all changes to your goals")
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 24)
        .whiteCardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Activity goals details")
    }
    
    // MARK: - No User Section
    
    @ViewBuilder
    private var noUserSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)
            
            Text("Setting up your profile...")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .whiteCardStyle()
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func goalRow<Content: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accent)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Content
            content()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Toolbar Buttons
    
    private var editButton: some View {
        Button(action: {
            startEditing()
        }) {
            Text("Edit")
                .font(.buttonSecondary)
        }
    }
    
    private var cancelButton: some View {
        Button(action: {
            if hasUnsavedChanges() {
                showingCancelConfirmation = true
            } else {
                cancelEditing()
            }
        }) {
            Text("Cancel")
                .font(.buttonSecondary)
        }
    }
    
    // MARK: - Edit Mode Management
    
    private func startEditing() {
        guard let user = currentUser else { return }
        
        editedWeeklyWorkoutGoal = user.weeklyWorkoutGoal
        editedDailyStepGoal = user.dailyStepGoal
        editedDailyWaterGoal = user.dailyWaterGoal
        
        saveError = nil
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        saveError = nil
    }
    
    private func hasUnsavedChanges() -> Bool {
        guard let user = currentUser else { return false }
        
        return editedWeeklyWorkoutGoal != user.weeklyWorkoutGoal ||
               editedDailyStepGoal != user.dailyStepGoal ||
               editedDailyWaterGoal != user.dailyWaterGoal
    }
    
    // MARK: - Save Changes
    
    private func saveChanges() {
        guard let user = currentUser else {
            saveError = "No user profile found"
            return
        }
        
        user.weeklyWorkoutGoal = editedWeeklyWorkoutGoal
        user.dailyStepGoal = editedDailyStepGoal
        user.dailyWaterGoal = editedDailyWaterGoal
        user.updatedAt = Date()
        
        // Save to SwiftData
        do {
            try modelContext.save()
            
            // Log successful save
            print("✅ Workout goals updated successfully")
            print("🎯 Weekly workout goal: \(editedWeeklyWorkoutGoal) workouts")
            print("👟 Daily step goal: \(formatSteps(editedDailyStepGoal)) steps")
            print("📅 Goal change timestamp: \(user.updatedAt)")
            
            // Exit edit mode
            isEditing = false
            saveError = nil
            
            // Provide haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            print("❌ Failed to save workout goals: \(error.localizedDescription)")
            saveError = "Failed to save changes. Please try again."
            
            // Provide haptic feedback for error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    private func formatWater(_ ml: Double) -> String {
        let litres = ml / 1000
        if litres >= 1 {
            return String(format: "%.1f L", litres)
        } else {
            return String(format: "%.0f mL", ml)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        WorkoutGoalsSettingsView()
            .modelContainer(for: [User.self], inMemory: true)
    }
}

