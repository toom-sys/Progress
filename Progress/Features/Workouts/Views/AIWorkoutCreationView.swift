//
//  AIWorkoutCreationView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct AIWorkoutCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    private var currentUser: User? { users.first }
    
    @StateObject private var workoutPromptBuilder = WorkoutPromptBuilder()
    @StateObject private var workoutResponseParser = WorkoutResponseParser()
    @StateObject private var openAIService = OpenAIService()
    
    let initialRequest: String
    
    @State private var workoutRequest: String = ""
    @State private var isGenerating: Bool = false
    @State private var generationProgress: Double = 0.0
    @State private var generationMessage: String = "Preparing your workout..."
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var generatedWorkout: ParsedWorkout?
    @State private var parsingResult: WorkoutParsingResult?
    @State private var showingPreview: Bool = false
    
    // Profile editing state
    @State private var showingProfileEdit: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    let onWorkoutCreated: (Workout) -> Void
    
    init(initialRequest: String = "", onWorkoutCreated: @escaping (Workout) -> Void) {
        self.initialRequest = initialRequest
        self.onWorkoutCreated = onWorkoutCreated
        _workoutRequest = State(initialValue: initialRequest)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                if showingPreview, let workout = generatedWorkout {
                    // Preview screen
                    workoutPreviewView(workout)
                } else {
                    // Main creation screen
                    mainCreationView
                }
                
                // Loading overlay
                if isGenerating {
                    loadingOverlay
                }
            }
            .navigationTitle("AI Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("Try Again") {
                generateWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingProfileEdit) {
            NavigationView {
                ProfileView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingProfileEdit = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Main Creation View
    
    private var mainCreationView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // User Profile Display
                userProfileSection
                
                // Workout Request Input
                workoutRequestSection
                
                // Generate Button
                generateButton
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("AI Workout Generator")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Text("Describe the workout you want, and AI will create a personalized routine based on your profile and available exercises.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Your Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showingProfileEdit = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                        Text("Edit")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            if let user = currentUser {
                VStack(spacing: 12) {
                    profileInfoRow(icon: "calendar", title: "Age", value: "\(user.age) years old")
                    profileInfoRow(icon: "target", title: "Goal", value: user.fitnessGoal.displayName)
                    profileInfoRow(icon: "chart.line.uptrend.xyaxis", title: "Level", value: user.fitnessLevel.displayName)
                    profileInfoRow(icon: "scalemass", title: "Units", value: user.preferredUnits.displayName)
                }
            } else {
                Text("Loading profile...")
                    .foregroundColor(.textSecondary)
                    .font(.subheadline)
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func profileInfoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
    }
    
    private var workoutRequestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Workout Request")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe your ideal workout:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("e.g., 'upper body strength training' or 'full body HIIT workout'", text: $workoutRequest, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    .onChange(of: workoutRequest) { _, newValue in
                        if newValue.count > 200 {
                            workoutRequest = String(newValue.prefix(200))
                        }
                    }
                
                Text("\(workoutRequest.count)/200 characters")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            // Example suggestions
            VStack(alignment: .leading, spacing: 8) {
                Text("Popular requests:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(exampleRequests, id: \.self) { example in
                        Button(action: {
                            workoutRequest = example
                            HapticFeedback.selectionChanged()
                        }) {
                            Text(example)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var generateButton: some View {
        Button(action: {
            HapticFeedback.workoutButtonTap()
            generateWorkout()
        }) {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(isGenerating ? "Generating..." : "Generate Workout")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                canGenerate ? Color.blue : Color.gray
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canGenerate || isGenerating)
    }
    
    // MARK: - Workout Preview View
    
    private func workoutPreviewView(_ workout: ParsedWorkout) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                previewHeaderSection(workout)
                
                // Exercises
                exercisesSection(workout)
                
                // Action buttons
                previewActionButtons
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    private func previewHeaderSection(_ workout: ParsedWorkout) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Workout Generated!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                if !workout.description.isEmpty {
                    Text(workout.description)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                HStack {
                    Label(workout.estimatedDuration, systemImage: "clock")
                    Spacer()
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func exercisesSection(_ workout: ParsedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                exercisePreviewCard(exercise, index: index + 1)
            }
        }
    }
    
    private func exercisePreviewCard(_ exercise: ParsedExercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(index).")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(width: 24, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    if !exercise.category.isEmpty {
                        Text(exercise.category)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if !exercise.isValidExercise {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Sets information
            VStack(alignment: .leading, spacing: 4) {
                ForEach(1...exercise.sets, id: \.self) { setIndex in
                    HStack {
                        Text("Set \(setIndex):")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Text(formatSetInfo(exercise))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                }
            }
            
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var previewActionButtons: some View {
        VStack(spacing: 12) {
            // Create Workout Button
            Button(action: {
                createWorkoutFromGenerated()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Create This Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            HStack(spacing: 12) {
                // Regenerate Button
                Button(action: {
                    regenerateWorkout()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Regenerate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Back to Edit Button
                Button(action: {
                    showingPreview = false
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Edit Request")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: generationProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: generationProgress)
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Generating Your Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(generationMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canGenerate: Bool {
        !workoutRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        currentUser != nil
    }
    
    private var exampleRequests: [String] {
        [
            "Upper body strength",
            "Full body HIIT",
            "Leg day workout",
            "Core and abs",
            "Cardio session",
            "Push day routine"
        ]
    }
    
    // MARK: - Helper Methods
    
    private func formatSetInfo(_ exercise: ParsedExercise) -> String {
        let repsString = exercise.reps.displayString
        
        if !exercise.weight.isBodyweight && exercise.weight.min > 0 {
            return "\(repsString) reps × \(exercise.weight.displayString)"
        } else if exercise.weight.isBodyweight {
            return "\(repsString) reps (bodyweight)"
        } else {
            return "\(repsString) reps"
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func generateWorkout() {
        guard let user = currentUser else {
            errorMessage = "User profile not found. Please try signing in again."
            showingError = true
            return
        }
        
        let trimmedRequest = workoutRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRequest.isEmpty else {
            errorMessage = "Please describe the workout you want to generate."
            showingError = true
            return
        }
        
        Task {
            await performWorkoutGeneration(request: trimmedRequest, user: user)
        }
    }
    
    private func performWorkoutGeneration(request: String, user: User) async {
        await MainActor.run {
            isGenerating = true
            generationProgress = 0.0
            generationMessage = "Analyzing your request..."
        }
        
        do {
            // Step 1: Build the prompt
            await MainActor.run {
                generationProgress = 0.2
                generationMessage = "Building personalized prompt..."
            }
            
            let exerciseDatabase = ExerciseDatabase.shared
            var allExercises: [String] = []
            for category in exerciseDatabase.getCategories() {
                for type in category.types {
                    allExercises.append(contentsOf: type.exercises)
                }
            }
            
            let generationRequest = WorkoutGenerationRequest(
                userInput: request,
                userProfile: WorkoutGenerationRequest.UserProfile(
                    age: user.age,
                    fitnessGoal: FitnessGoal(rawValue: user.fitnessGoal.rawValue) ?? .generalFitness,
                    fitnessLevel: FitnessLevel(rawValue: user.fitnessLevel.rawValue) ?? .beginner,
                    preferredUnits: UnitSystem(rawValue: user.preferredUnits.rawValue) ?? .metric
                ),
                availableExercises: allExercises,
                workoutType: nil,
                duration: nil,
                equipment: nil
            )
            
            let prompt = workoutPromptBuilder.buildWorkoutPrompt(for: generationRequest)
            
            // Step 2: Send to OpenAI
            await MainActor.run {
                generationProgress = 0.4
                generationMessage = "Consulting AI fitness expert..."
            }
            
            let response = try await openAIService.sendPrompt(
                prompt,
                configuration: .workoutGeneration
            )
            
            // Step 3: Parse the response
            await MainActor.run {
                generationProgress = 0.7
                generationMessage = "Processing workout plan..."
            }
            
            let parsingResult = workoutResponseParser.parseWorkoutResponse(
                response,
                userProfile: generationRequest.userProfile
            )
            
            await MainActor.run {
                generationProgress = 1.0
                generationMessage = "Workout ready!"
            }
            
            // Small delay to show completion
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                self.parsingResult = parsingResult
                
                if let workout = parsingResult.workout {
                    self.generatedWorkout = workout
                    self.showingPreview = true
                } else {
                    // Handle parsing failure
                    let errorMessages = parsingResult.errors.map { $0.localizedDescription }.joined(separator: "\n")
                    self.errorMessage = "Failed to generate a valid workout:\n\(errorMessages)\n\nPlease try a different request or try again."
                    self.showingError = true
                }
                
                self.isGenerating = false
            }
            
        } catch {
            await MainActor.run {
                self.isGenerating = false
                self.errorMessage = "Failed to generate workout: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
    
    private func regenerateWorkout() {
        guard let user = currentUser else { return }
        
        HapticFeedback.workoutButtonTap()
        
        Task {
            await performWorkoutGeneration(request: workoutRequest, user: user)
        }
    }
    
    private func createWorkoutFromGenerated() {
        guard let generatedWorkout = generatedWorkout,
              let user = currentUser else {
            errorMessage = "No workout to create or user not found."
            showingError = true
            return
        }
        
        do {
            let workout = try workoutResponseParser.createWorkoutModels(
                from: generatedWorkout,
                userProfile: WorkoutGenerationRequest.UserProfile(
                    age: user.age,
                    fitnessGoal: FitnessGoal(rawValue: user.fitnessGoal.rawValue) ?? .generalFitness,
                    fitnessLevel: FitnessLevel(rawValue: user.fitnessLevel.rawValue) ?? .beginner,
                    preferredUnits: UnitSystem(rawValue: user.preferredUnits.rawValue) ?? .metric
                ),
                modelContext: modelContext
            )
            
            // Add AI generation note
            workout.notes = (workout.notes ?? "") + "\n\nGenerated by AI from request: \"\(workoutRequest)\""
            
            try modelContext.save()
            
            HapticFeedback.workoutCreated()
            onWorkoutCreated(workout)
            dismiss()
            
        } catch {
            errorMessage = "Failed to create workout: \(error.localizedDescription)"
            showingError = true
        }
    }
    
}

#Preview {
    AIWorkoutCreationView(onWorkoutCreated: { _ in })
        .modelContainer(for: [User.self, Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
