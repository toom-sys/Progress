//
//  ProfileView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Profile View

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Query private var users: [User]
    
    private var currentUser: User? { users.first }
    
    // MARK: - Edit State
    @State private var isEditing = false
    @State private var showingCancelConfirmation = false
    @State private var saveError: String?
    
    // MARK: - Form Fields
    @State private var editedName = ""
    @State private var editedAge = 25
    @State private var editedFitnessGoal: FitnessGoal = .generalFitness
    @State private var editedFitnessLevel: FitnessLevel = .beginner
    @State private var editedUnits: UnitSystem = .metric
    @State private var editedBiologicalSex: BiologicalSex = .unspecified
    @State private var editedHeightCm: Double = 170
    @State private var editedWeightKg: Double = 70
    @State private var editedActivityLevel: ActivityLevel = .moderate
    @State private var showingGoalsUpdatedNotice = false
    
    
    // MARK: - Validation
    @State private var nameError: String?
    @State private var ageError: String?
    @State private var hasValidationErrors: Bool = false
    
    @State private var showingClearDataConfirmation = false
    @State private var dataClearedSuccessfully = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
            if let user = currentUser {
                        // Profile Header
                        profileHeaderSection(user: user)
                        
                        // Dedicated Goals Section
                        dedicatedGoalsSection(user: user)
                        
                        // Profile Information
                        profileInformationSection(user: user)
                        
                        // Account Actions
                        if !isEditing {
                            accountActionsSection()
                        }
                    } else {
                        // No User State
                        noUserSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppBackground())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(AppPalette.ink)
            .navigationBarBackButtonHidden(isEditing)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentUser != nil {
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        }
                        .fontWeight(isEditing ? .bold : .regular)
                    }
                }

                if isEditing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        cancelButton
                    }
                }
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
                Button("OK") { saveError = nil }
            } message: {
                if let error = saveError { Text(error) }
            }
            .alert("Clear All Data", isPresented: $showingClearDataConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Everything", role: .destructive) { clearAllData() }
            } message: {
                Text("This will permanently delete all your workouts, nutrition entries, and reset your profile. This cannot be undone.")
            }
            .alert("Data Cleared", isPresented: $dataClearedSuccessfully) {
                Button("OK") {}
            } message: {
                Text("All data has been cleared successfully.")
            }
            .alert("Nutrition Goals Updated", isPresented: $showingGoalsUpdatedNotice) {
                Button("OK") {}
            } message: {
                Text("Your daily calorie and macro targets have been recalculated to match your updated profile.")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Profile Management")
        .accessibilityHint("Manage your profile information and fitness goals")
    }
    
    // MARK: - Profile Header Section
    
    @ViewBuilder
    private func profileHeaderSection(user: User) -> some View {
        VStack(spacing: 20) {
            // Profile Picture
            Image(systemName: "person.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(AppPalette.ink)
                .accessibilityLabel("Profile picture")
                .accessibilityHint("User avatar")
            
            // Name and Email
            VStack(spacing: 12) {
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Full Name", text: $editedName)
                            .font(.appSectionTitle)
                            .fontWeight(.bold)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                validateName()
                            }
                            .onChange(of: editedName) { _, _ in
                                if nameError != nil {
                                    validateName()
                                }
                                updateValidationState()
                            }
                            .accessibilityLabel("Full name")
                            .accessibilityHint("Enter your full name")
                        
                        if let error = nameError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.error)
                                    .font(.caption)
                                Text(error)
                                    .errorStyle()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Name validation error: \(error)")
                        }
                    }
                } else {
                    Text(user.name)
                        .font(.appSectionTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppPalette.ink)
                        .accessibilityLabel("Name: \(user.name)")
                }
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(AppPalette.muted)
                    .accessibilityLabel("Email: \(user.email)")
            }
        }
        .padding(.vertical, 16)
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Profile header")
    }
    
    // MARK: - Dedicated Goals Section
    
    @ViewBuilder
    private func dedicatedGoalsSection(user: User) -> some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fitness Goal")
                        .font(.appCardTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(AppPalette.ink)
                    
                    Text("Your primary fitness objective")
                        .font(.caption)
                        .foregroundColor(AppPalette.muted)
                }
                Spacer()
                
                if !isEditing {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(Color.brand)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Fitness goal section")
            
            // Current Goal Display
            if isEditing {
                VStack(spacing: 16) {
                    Text("Select your primary fitness goal:")
                        .font(.body)
                        .foregroundColor(AppPalette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            goalSelectionCard(goal: goal, isSelected: editedFitnessGoal == goal)
                        }
                    }
                }
            } else {
                goalDisplayCard(goal: user.fitnessGoal)
            }
        }
        .padding(.vertical, 24)
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Fitness goals management")
    }
    
    @ViewBuilder
    private func goalDisplayCard(goal: FitnessGoal) -> some View {
        HStack(spacing: 16) {
            Image(systemName: goalIcon(for: goal))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.brand)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppPalette.accentSoft))

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.displayName)
                    .font(.appCardTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(AppPalette.ink)

                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(AppPalette.muted)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(14)
        .background(AppPalette.optionFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current fitness goal: \(goal.displayName). \(goal.description)")
    }
    
    @ViewBuilder
    private func goalSelectionCard(goal: FitnessGoal, isSelected: Bool) -> some View {
        Button(action: {
            handleGoalSelection(goal)
        }) {
                        VStack(spacing: 12) {
                Image(systemName: goalIcon(for: goal))
                    .font(.title2)
                    .foregroundColor(isSelected ? AppPalette.onInk : Color.brand)
                            
                            VStack(spacing: 4) {
                    Text(goal.displayName)
                        .font(.label)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? AppPalette.onInk : AppPalette.ink)
                        .multilineTextAlignment(.center)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? AppPalette.onInk.opacity(0.75) : AppPalette.muted)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? AppPalette.ink : AppPalette.optionFill)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppPalette.ink : AppPalette.line, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(goal.displayName) goal")
        .accessibilityHint("\(goal.description). \(isSelected ? "Currently selected" : "Tap to select this goal")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    private func goalIcon(for goal: FitnessGoal) -> String {
        switch goal {
        case .weightLoss: return "flame.fill"
        case .muscleGain: return "dumbbell.fill"
        case .strengthTraining: return "figure.strengthtraining.traditional"
        case .endurance: return "heart.fill"
        case .generalFitness: return "figure.walk"
        case .maintenance: return "checkmark.shield.fill"
        }
    }
    
    private func handleGoalSelection(_ goal: FitnessGoal) {
        editedFitnessGoal = goal
    }
    
        // MARK: - Profile Information Section
    
    @ViewBuilder
    private func profileInformationSection(user: User) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Details")
                        .font(.appCardTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(AppPalette.ink)
                    
                    Text("Personal information and preferences")
                        .font(.caption)
                        .foregroundColor(AppPalette.muted)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Profile details section")
            
            VStack(spacing: 20) {
                // Age
                enhancedProfileRow(
                    icon: "calendar",
                    title: "Age",
                    subtitle: "Used for fitness calculations",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 8) {
                                HStack(spacing: 12) {
                                    Text("\(editedAge) yrs")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppPalette.ink)
                                        .monospacedDigit()

                                    Stepper("", value: $editedAge, in: 18...100)
                                        .labelsHidden()
                                        .onChange(of: editedAge) { _, _ in
                                            if ageError != nil { validateAge() }
                                            updateValidationState()
                                        }
                                        .accessibilityLabel("Age: \(editedAge) years")
                                        .accessibilityHint("Adjust your age between 18 and 100")
                                }

                                if let error = ageError {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.error)
                                            .font(.caption)
                                        Text(error)
                                            .errorStyle()
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Age validation error: \(error)")
                                }
                            }
                        } else {
                            Text("\(user.age) years")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppPalette.ink)
                                .accessibilityLabel("Age: \(user.age) years")
                        }
                    }
                )
                
                Divider()
                    .background(AppPalette.line)

                // Biological Sex
                enhancedProfileRow(
                    icon: "person.fill",
                    title: "Biological Sex",
                    subtitle: "Used for calorie calculations",
                    content: {
                        if isEditing {
                            Picker("Biological Sex", selection: $editedBiologicalSex) {
                                ForEach(BiologicalSex.allCases, id: \.self) { sex in
                                    Text(sex.displayName).tag(sex)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .accessibilityLabel("Biological sex")
                        } else {
                            Text(user.biologicalSex.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppPalette.ink)
                                .accessibilityLabel("Biological sex: \(user.biologicalSex.displayName)")
                        }
                    }
                )

                Divider()
                    .background(AppPalette.line)

                // Height
                enhancedProfileRow(
                    icon: "ruler",
                    title: "Height",
                    subtitle: "Used for calorie calculations",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(editedUnits.formatHeight(editedHeightCm))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppPalette.ink)
                                    .monospacedDigit()
                                Stepper("Height", value: $editedHeightCm, in: 120...220, step: 1)
                                    .labelsHidden()
                                    .accessibilityLabel("Height")
                                    .accessibilityValue(editedUnits.formatHeight(editedHeightCm))
                            }
                        } else {
                            Text(user.preferredUnits.formatHeight(user.heightCm))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppPalette.ink)
                                .accessibilityLabel("Height: \(user.preferredUnits.formatHeight(user.heightCm))")
                        }
                    }
                )

                Divider()
                    .background(AppPalette.line)

                // Weight
                enhancedProfileRow(
                    icon: "scalemass",
                    title: "Weight",
                    subtitle: "Used for calorie calculations",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(editedUnits.formatWeightWithUnit(editedWeightKg, precision: 0))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppPalette.ink)
                                    .monospacedDigit()
                                Stepper("Weight", value: $editedWeightKg, in: 30...250, step: 0.5)
                                    .labelsHidden()
                                    .accessibilityLabel("Weight")
                                    .accessibilityValue(editedUnits.formatWeightWithUnit(editedWeightKg, precision: 0))
                            }
                        } else {
                            Text(user.preferredUnits.formatWeightWithUnit(user.weightKg, precision: 0))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppPalette.ink)
                                .accessibilityLabel("Weight: \(user.preferredUnits.formatWeightWithUnit(user.weightKg, precision: 0))")
                        }
                    }
                )

                Divider()
                    .background(AppPalette.line)

                // Activity Level
                enhancedProfileRow(
                    icon: "figure.walk.motion",
                    title: "Activity Level",
                    subtitle: "Your typical daily activity",
                    content: {
                        if isEditing {
                            Picker("Activity Level", selection: $editedActivityLevel) {
                                ForEach(ActivityLevel.allCases, id: \.self) { level in
                                    Text(level.displayName).tag(level)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .accessibilityLabel("Activity level")
                        } else {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(user.activityLevel.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppPalette.ink)
                                Text(user.activityLevel.description)
                                    .font(.caption)
                                    .foregroundColor(AppPalette.muted)
                                    .multilineTextAlignment(.trailing)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Activity level: \(user.activityLevel.displayName)")
                        }
                    }
                )

                Divider()
                    .background(AppPalette.line)
                
                // Fitness Level
                enhancedProfileRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Fitness Level",
                    subtitle: "Your exercise experience",
                    content: {
                        if isEditing {
                            VStack(alignment: .trailing, spacing: 12) {
                                Picker("Fitness Level", selection: $editedFitnessLevel) {
                                    ForEach(FitnessLevel.allCases, id: \.self) { level in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(level.displayName)
                                                .font(.body)
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundColor(AppPalette.muted)
                                        }
                                        .tag(level)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accessibilityLabel("Fitness level")
                                .accessibilityHint("Select your current fitness experience level")
                            }
                        } else {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(user.fitnessLevel.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppPalette.ink)
                                Text(user.fitnessLevel.description)
                                    .font(.caption)
                                    .foregroundColor(AppPalette.muted)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Fitness level: \(user.fitnessLevel.displayName). \(user.fitnessLevel.description)")
                        }
                    }
                )
                
                Divider()
                    .background(AppPalette.line)
                
                // Unit Preferences
                enhancedProfileRow(
                    icon: "ruler",
                    title: "Units",
                    subtitle: "Measurement preferences",
                    content: {
                        if isEditing {
                            VStack(spacing: 12) {
                                Picker("Units", selection: $editedUnits) {
                                    ForEach(UnitSystem.allCases, id: \.self) { unit in
                                        Text(unit.displayName)
                                            .tag(unit)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .accessibilityLabel("Unit system")
                                .accessibilityHint("Choose between metric and imperial units")
                            }
                        } else {
                            Text(user.preferredUnits.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppPalette.ink)
                                .accessibilityLabel("Units: \(user.preferredUnits.displayName)")
                        }
                    }
                )
                
                Divider()
                    .background(AppPalette.line)
                
                enhancedProfileRow(
                    icon: "star.circle",
                    title: "Subscription",
                    subtitle: "Current plan",
                    content: {
                        Text(subscriptionService.isSubscribed ? (subscriptionService.activePlan?.title ?? "Subscribed") : "Not subscribed")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(subscriptionService.isSubscribed ? Color.brand : AppPalette.muted)
                            .accessibilityLabel(
                                subscriptionService.isSubscribed
                                    ? "Subscription: \(subscriptionService.activePlan?.title ?? "active")"
                                    : "Subscription: not subscribed"
                            )
                    }
                )
            }
            
            if isEditing && hasValidationErrors {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.error)
                        .font(.caption)
                    Text("Please fix the errors above before saving.")
                        .font(.caption)
                        .foregroundColor(.error)
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Validation errors need to be fixed before saving")
            }
        }
        .padding(.vertical, 24)
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Profile details")
    }
    
    // MARK: - Account Actions Section

    @ViewBuilder
    private func accountActionsSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Data Management")
                    .font(.appCardTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(AppPalette.ink)
                Spacer()
            }

            Button(action: {
                HapticFeedback.medium()
                showingClearDataConfirmation = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(AppPalette.protein)
                    Text("Clear All Data")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppPalette.protein)
                    Spacer()
                }
                .padding(16)
                .background(AppPalette.protein.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppPalette.protein.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Text("Clears all workouts, nutrition entries, and resets your profile. Cannot be undone.")
                .font(.caption)
                .foregroundColor(AppPalette.muted)
                .multilineTextAlignment(.leading)

            DeleteAccountButton(usesPlainStyle: true) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .foregroundColor(AppPalette.protein)
                    Text("Delete Account")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppPalette.protein)
                    Spacer()
                }
                .padding(16)
                .background(AppPalette.protein.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppPalette.protein.opacity(0.25), lineWidth: 1)
                )
            }

            Text("Deletes your account and the data saved in Progress on this device. Cannot be undone.")
                .font(.caption)
                .foregroundColor(AppPalette.muted)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 24)
        .appCard()
    }

    private func clearAllData() {
        guard let user = currentUser else { return }
        for workout in user.workouts { modelContext.delete(workout) }
        for entry in user.nutritionEntries { modelContext.delete(entry) }
        user.name = "Me"
        user.age = 25
        user.fitnessGoal = .generalFitness
        user.fitnessLevel = .beginner
        user.weeklyWorkoutGoal = 4
        user.biologicalSex = .unspecified
        user.heightCm = 170
        user.weightKg = 70
        user.activityLevel = .moderate
        user.usesCustomNutritionGoals = false
        user.recalculateNutritionGoals(force: true)
        user.updatedAt = Date()
        try? modelContext.save()
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        dataClearedSuccessfully = true
    }
    
    // MARK: - No User Section
    
    @ViewBuilder
    private func noUserSection() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppPalette.muted)
            
            Text("Setting up your profile...")
                .font(.appCardTitle)
                .fontWeight(.semibold)
                .foregroundColor(AppPalette.ink)
        }
        .appCard()
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func enhancedProfileRow<Content: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppPalette.ink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppPalette.optionFill))
                .accessibilityHidden(true)
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppPalette.ink)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppPalette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Content
            content()
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
        
        // Initialize edit fields with current values
        editedName = user.name
        editedAge = user.age
        editedFitnessGoal = user.fitnessGoal
        editedFitnessLevel = user.fitnessLevel
        editedUnits = user.preferredUnits
        editedBiologicalSex = user.biologicalSex
        editedHeightCm = user.heightCm
        editedWeightKg = user.weightKg
        editedActivityLevel = user.activityLevel
        
        nameError = nil
        ageError = nil
        saveError = nil
        hasValidationErrors = false
        
        // Enter edit mode
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        nameError = nil
        ageError = nil
        saveError = nil
        hasValidationErrors = false
    }
    
    private func hasUnsavedChanges() -> Bool {
        guard let user = currentUser else { return false }
        
        return editedName != user.name ||
               editedAge != user.age ||
               editedFitnessGoal != user.fitnessGoal ||
               editedFitnessLevel != user.fitnessLevel ||
               editedUnits != user.preferredUnits ||
               editedBiologicalSex != user.biologicalSex ||
               editedHeightCm != user.heightCm ||
               editedWeightKg != user.weightKg ||
               editedActivityLevel != user.activityLevel
    }
    
    private func updateValidationState() {
        hasValidationErrors = nameError != nil || ageError != nil
    }
    
    // MARK: - Form Validation
    
    private func validateForm() -> Bool {
        validateName()
        validateAge()
        updateValidationState()
        
        return nameError == nil && ageError == nil
    }
    
    private func validateName() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            nameError = "Name cannot be empty"
        } else if trimmedName.count < 2 {
            nameError = "Name must be at least 2 characters"
        } else if trimmedName.count > 50 {
            nameError = "Name must be less than 50 characters"
        } else if !trimmedName.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "'" || $0 == "-" }) {
            nameError = "Name can only contain letters, spaces, apostrophes, and hyphens"
        } else {
            nameError = nil
        }
    }
    
    private func validateAge() {
        if editedAge < 18 {
            ageError = "Age must be at least 18 years"
        } else if editedAge > 100 {
            ageError = "Age must be 100 years or less"
        } else {
            ageError = nil
        }
    }
    
    // MARK: - Save Changes
    
    private func saveChanges() {
        guard let user = currentUser else {
            saveError = "No user profile found"
            return
        }

        guard validateForm() else {
            return
        }
        
        // Detect changes that affect the personalised nutrition targets.
        let goalChanged = editedFitnessGoal != user.fitnessGoal
        let bodyMetricsChanged = editedAge != user.age ||
            editedBiologicalSex != user.biologicalSex ||
            editedHeightCm != user.heightCm ||
            editedWeightKg != user.weightKg ||
            editedActivityLevel != user.activityLevel

        // Update user properties
        user.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.age = editedAge
        user.fitnessGoal = editedFitnessGoal
        user.fitnessLevel = editedFitnessLevel
        user.preferredUnits = editedUnits
        user.biologicalSex = editedBiologicalSex
        user.heightCm = editedHeightCm
        user.weightKg = editedWeightKg
        user.activityLevel = editedActivityLevel
        user.updatedAt = Date()

        // Adjust the nutrition plan when relevant inputs change. Changing the
        // fitness goal always re-derives targets (overriding any manual goals);
        // body-metric changes only re-derive when goals aren't manually set.
        var didRecalculateGoals = false
        if goalChanged {
            didRecalculateGoals = user.recalculateNutritionGoals(force: true)
        } else if bodyMetricsChanged {
            didRecalculateGoals = user.recalculateNutritionGoals()
        }
        
        do {
            try modelContext.save()
            isEditing = false
            saveError = nil
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if didRecalculateGoals {
                showingGoalsUpdatedNotice = true
            }
        } catch {
            saveError = "Failed to save changes. Please try again."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(SubscriptionService())
        .modelContainer(for: [User.self, Workout.self, NutritionEntry.self], inMemory: true)
}