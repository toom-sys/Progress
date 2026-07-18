//
//  NutritionGoalsSettingsView.swift
//  Progress
//
//  Created by Progress Team
//
//  Lets the user review and manually adjust their daily calorie and macro
//  targets, or recalculate them automatically from their profile.
//

import SwiftUI
import SwiftData

struct NutritionGoalsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var currentUser: User? { users.first }

    // MARK: - Edit State
    @State private var isEditing = false
    @State private var showingSaveConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var showingRecalculateConfirmation = false
    @State private var saveError: String?

    // MARK: - Form Fields
    @State private var editedCalories: Double = 2000
    @State private var editedProtein: Double = 150
    @State private var editedCarbs: Double = 200
    @State private var editedFat: Double = 65

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = currentUser {
                    headerSection(user: user)
                    goalsSection(user: user)
                    if !isEditing {
                        recalculateSection(user: user)
                    }
                } else {
                    noUserSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Nutrition Goals")
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
            Button("Save") { saveChanges() }
        } message: {
            Text("Save these custom daily nutrition goals? Automatic recalculation will be turned off until you tap ‘Recalculate from profile’.")
        }
        .alert("Discard Changes", isPresented: $showingCancelConfirmation) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) { cancelEditing() }
        } message: {
            Text("Are you sure you want to discard your changes?")
        }
        .alert("Recalculate Goals", isPresented: $showingRecalculateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Recalculate") { recalculateFromProfile() }
        } message: {
            Text("This replaces your current goals with values calculated from your age, body metrics, activity level and fitness goal.")
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            if let error = saveError { Text(error) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nutrition goals management")
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(user: User) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accent)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Daily Nutrition Targets")
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text(user.usesCustomNutritionGoals
                     ? "You’re using custom goals you set yourself."
                     : "These targets are calculated from your profile and update automatically when your details change.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)

                statusBadge(isCustom: user.usesCustomNutritionGoals)
            }
        }
        .padding(.vertical, 24)
        .whiteCardStyle()
    }

    @ViewBuilder
    private func statusBadge(isCustom: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isCustom ? "slider.horizontal.3" : "sparkles")
                .font(.caption2)
            Text(isCustom ? "Custom" : "Auto-calculated")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accent.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Goals Section

    @ViewBuilder
    private func goalsSection(user: User) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Goals")
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    Text("Calorie and macronutrient targets per day")
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

            VStack(spacing: 20) {
                goalRow(
                    icon: "flame.fill",
                    title: "Calories",
                    subtitle: "Total energy target for the day",
                    displayValue: "\(Int(user.dailyCalorieGoal)) kcal",
                    editValue: "\(Int(editedCalories)) kcal",
                    binding: $editedCalories,
                    range: 1000...6000,
                    step: 50
                )

                Divider().background(Color.border.opacity(0.5))

                goalRow(
                    icon: "fish.fill",
                    title: "Protein",
                    subtitle: "Supports muscle repair and growth",
                    displayValue: "\(Int(user.dailyProteinGoal)) g",
                    editValue: "\(Int(editedProtein)) g",
                    binding: $editedProtein,
                    range: 20...400,
                    step: 5
                )

                Divider().background(Color.border.opacity(0.5))

                goalRow(
                    icon: "leaf.fill",
                    title: "Carbohydrates",
                    subtitle: "Primary fuel for training",
                    displayValue: "\(Int(user.dailyCarbGoal)) g",
                    editValue: "\(Int(editedCarbs)) g",
                    binding: $editedCarbs,
                    range: 0...700,
                    step: 5
                )

                Divider().background(Color.border.opacity(0.5))

                goalRow(
                    icon: "drop.fill",
                    title: "Fat",
                    subtitle: "Supports hormones and recovery",
                    displayValue: "\(Int(user.dailyFatGoal)) g",
                    editValue: "\(Int(editedFat)) g",
                    binding: $editedFat,
                    range: 20...200,
                    step: 5
                )
            }

            macroBreakdown

            if isEditing {
                Button(action: { showingSaveConfirmation = true }) {
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
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 24)
        .whiteCardStyle()
    }

    // MARK: - Macro Breakdown

    private var macroBreakdown: some View {
        let calories = isEditing ? editedCalories : (currentUser?.dailyCalorieGoal ?? 0)
        let protein = isEditing ? editedProtein : (currentUser?.dailyProteinGoal ?? 0)
        let carbs = isEditing ? editedCarbs : (currentUser?.dailyCarbGoal ?? 0)
        let fat = isEditing ? editedFat : (currentUser?.dailyFatGoal ?? 0)

        let proteinCals = protein * 4
        let carbCals = carbs * 4
        let fatCals = fat * 9
        let macroCals = max(1, proteinCals + carbCals + fatCals)

        return VStack(spacing: 12) {
            Divider().background(Color.border)

            HStack(spacing: 0) {
                macroPercent(label: "Protein", value: proteinCals / macroCals, color: .blue)
                macroPercent(label: "Carbs", value: carbCals / macroCals, color: .green)
                macroPercent(label: "Fat", value: fatCals / macroCals, color: .orange)
            }

            if abs(macroCals - calories) > 100 {
                Text("Macros total ≈ \(Int(macroCals)) kcal vs \(Int(calories)) kcal target")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.top, 4)
    }

    private func macroPercent(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int((value * 100).rounded()))%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recalculate Section

    @ViewBuilder
    private func recalculateSection(user: User) -> some View {
        VStack(spacing: 12) {
            Button(action: { showingRecalculateConfirmation = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                    Text("Recalculate from profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.accent)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.accent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accent.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Text("Uses the Mifflin-St Jeor formula with your age, height, weight, activity level and fitness goal. Update those in Profile for the most accurate targets.")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 24)
        .whiteCardStyle()
    }

    // MARK: - No User Section

    private var noUserSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
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
    private func goalRow(
        icon: String,
        title: String,
        subtitle: String,
        displayValue: String,
        editValue: String,
        binding: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accent)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

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

            if isEditing {
                Stepper(value: binding, in: range, step: step) {
                    Text(editValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .monospacedDigit()
                }
                .accessibilityLabel(title)
                .accessibilityValue(editValue)
            } else {
                Text(displayValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("\(title): \(displayValue)")
            }
        }
    }

    // MARK: - Toolbar Buttons

    private var editButton: some View {
        Button(action: { startEditing() }) {
            Text("Edit").font(.buttonSecondary)
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
            Text("Cancel").font(.buttonSecondary)
        }
    }

    // MARK: - Edit Mode Management

    private func startEditing() {
        guard let user = currentUser else { return }
        editedCalories = user.dailyCalorieGoal
        editedProtein = user.dailyProteinGoal
        editedCarbs = user.dailyCarbGoal
        editedFat = user.dailyFatGoal
        saveError = nil
        isEditing = true
    }

    private func cancelEditing() {
        isEditing = false
        saveError = nil
    }

    private func hasUnsavedChanges() -> Bool {
        guard let user = currentUser else { return false }
        return editedCalories != user.dailyCalorieGoal ||
               editedProtein != user.dailyProteinGoal ||
               editedCarbs != user.dailyCarbGoal ||
               editedFat != user.dailyFatGoal
    }

    // MARK: - Save & Recalculate

    private func saveChanges() {
        guard let user = currentUser else {
            saveError = "No user profile found"
            return
        }

        user.dailyCalorieGoal = editedCalories
        user.dailyProteinGoal = editedProtein
        user.dailyCarbGoal = editedCarbs
        user.dailyFatGoal = editedFat
        user.usesCustomNutritionGoals = true
        user.updatedAt = Date()

        do {
            try modelContext.save()
            isEditing = false
            saveError = nil
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            saveError = "Failed to save changes. Please try again."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func recalculateFromProfile() {
        guard let user = currentUser else { return }
        user.recalculateNutritionGoals(force: true)
        user.updatedAt = Date()

        do {
            try modelContext.save()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            saveError = "Failed to recalculate goals. Please try again."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NutritionGoalsSettingsView()
            .modelContainer(for: [User.self], inMemory: true)
    }
}
