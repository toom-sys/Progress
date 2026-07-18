import SwiftUI

/// Debug/Test interface for OpenAI API integration
/// This view provides a simple interface for testing ChatGPT API communication
/// during development and debugging
struct OpenAITestView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var openAIService = OpenAIService()
    @StateObject private var workoutTester = WorkoutPromptTester()
    @StateObject private var promptBuilder = WorkoutPromptBuilder()
    @StateObject private var responseParser = WorkoutResponseParser()
    
    @State private var selectedTab = 0
    
    // Basic testing state
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var connectionStatus: (success: Bool, message: String)?
    
    // Workout testing state
    @State private var workoutRequest = ""
    @State private var selectedAge = 25
    @State private var selectedGoal = FitnessGoal.generalFitness
    @State private var selectedLevel = FitnessLevel.beginner
    @State private var workoutResponse = ""
    @State private var lastTestResult: WorkoutGenerationTestResult?
    @State private var showCreateWorkout = false
    @State private var createdWorkout: Workout?
    
    // Predefined test prompts for quick testing
    private let testPrompts = [
        "Hello, how are you?",
        "What is 2 + 2?",
        "Explain what a workout is in one sentence.",
        "List 3 basic exercises for beginners.",
        "What are the main macronutrients?"
    ]
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Basic API Testing Tab
                basicTestingTab
                    .tabItem {
                        Image(systemName: "text.bubble")
                        Text("Basic")
                    }
                    .tag(0)
                
                // Workout Generation Testing Tab
                workoutTestingTab
                    .tabItem {
                        Image(systemName: "dumbbell")
                        Text("Workouts")
                    }
                    .tag(1)
                
                // Batch Testing Tab
                batchTestingTab
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Batch Tests")
                    }
                    .tag(2)
            }
            .navigationTitle("OpenAI Test")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Tab Views
    
    private var basicTestingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Connection Status Section
                connectionStatusSection
                
                // Quick Test Prompts Section
                quickTestSection
                
                // Custom Prompt Section
                customPromptSection
                
                // Response Section
                responseSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var workoutTestingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // User Profile Section
                userProfileSection
                
                // Workout Request Section
                workoutRequestSection
                
                // Workout Response Section
                workoutResponseSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var batchTestingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Batch Test Controls
                batchTestSection
                
                // Test Results
                if let results = workoutTester.lastTestResults {
                    testResultsSection(results)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Connection Status Section
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Status")
                .font(.headline)
            
            if let status = connectionStatus {
                HStack {
                    Image(systemName: status.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(status.success ? .green : .red)
                    
                    Text(status.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Test Connection") {
                Task {
                    await testConnection()
                }
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Test Section
    
    private var quickTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Test Prompts")
                .font(.headline)
            
            Text("Tap any prompt below to test the API:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(testPrompts, id: \.self) { testPrompt in
                    Button(action: {
                        prompt = testPrompt
                        Task {
                            await sendPrompt()
                        }
                    }) {
                        Text(testPrompt)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Custom Prompt Section
    
    private var customPromptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Prompt")
                .font(.headline)
            
            TextField("Enter your prompt here...", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            HStack {
                Button("Send Prompt") {
                    Task {
                        await sendPrompt()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isLoading)
                
                Button("Clear") {
                    prompt = ""
                    response = ""
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Response Section
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Response")
                    .font(.headline)
                
                Spacer()
                
                if !response.isEmpty {
                    Button("Copy") {
                        UIPasteboard.general.string = response
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            
            if response.isEmpty && !isLoading {
                Text("No response yet. Send a prompt to test the API.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView {
                    Text(response)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func testConnection() async {
        isLoading = true
        connectionStatus = nil
        
        let result = await openAIService.testConnection()
        
        await MainActor.run {
            connectionStatus = result
            isLoading = false
        }
    }
    
    private func sendPrompt() async {
        guard !prompt.isEmpty else { return }
        
        isLoading = true
        response = ""
        
        let result = await openAIService.testPrompt(prompt)
        
        await MainActor.run {
            isLoading = false
            
            if result.success, let responseText = result.response {
                response = responseText
            } else if let error = result.error {
                errorMessage = error
                showError = true
                response = "Error: \(error)"
            }
        }
    }
    
    // MARK: - Workout Testing Sections
    
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Profile")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Age:")
                    Spacer()
                    Stepper("\(selectedAge)", value: $selectedAge, in: 18...100)
                        .frame(maxWidth: 120)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fitness Goal:")
                    Picker("Goal", selection: $selectedGoal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fitness Level:")
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var workoutRequestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Request")
                .font(.headline)
            
            TextField("Enter workout request (e.g., 'chest day', 'full body strength')", text: $workoutRequest, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            
            // Quick workout request buttons
            Text("Quick Requests:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach([
                    "chest day",
                    "leg workout", 
                    "full body strength",
                    "upper body",
                    "quick cardio",
                    "beginner workout"
                ], id: \.self) { request in
                    Button(request) {
                        workoutRequest = request
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(isLoading || workoutTester.isRunningTests)
                }
            }
            
            HStack {
                Button("Generate Workout") {
                    Task {
                        await generateWorkout()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(workoutRequest.isEmpty || isLoading || workoutTester.isRunningTests)
                
                if let result = lastTestResult, result.success, 
                   let parsingResult = workoutTester.lastParsingResult,
                   let parsedWorkout = parsingResult.workout {
                    Button("Create Workout") {
                        Task {
                            await createWorkoutFromParsed(parsedWorkout)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }
                
                Button("Clear") {
                    workoutRequest = ""
                    workoutResponse = ""
                    lastTestResult = nil
                }
                .buttonStyle(.bordered)
                .disabled(isLoading || workoutTester.isRunningTests)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var workoutResponseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Workout")
                    .font(.headline)
                
                Spacer()
                
                if let result = lastTestResult {
                    Text("Score: \(String(format: "%.2f", result.validationResults.overallScore)) (\(result.validationResults.grade))")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.success ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
                
                if !workoutResponse.isEmpty {
                    Button("Copy") {
                        UIPasteboard.general.string = workoutResponse
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            
            if workoutResponse.isEmpty && !isLoading {
                Text("No workout generated yet. Enter a request above to test workout generation.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if let result = lastTestResult {
                            // Show validation results
                            validationResultsView(result.validationResults)
                        }
                        
                        // Show parsing results if available
                        if let parsingResult = workoutTester.lastParsingResult {
                            parsingResultsView(parsingResult)
                        }
                        
                        Text(workoutResponse)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        // Show created workout confirmation
                        if let workout = createdWorkout {
                            createdWorkoutView(workout)
                        }
                    }
                }
                .frame(maxHeight: 500)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var batchTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Batch Testing")
                .font(.headline)
            
            Text("Run all predefined workout scenarios to test prompt effectiveness:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Run All Tests") {
                    Task {
                        await runBatchTests()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(workoutTester.isRunningTests || isLoading)
                
                Spacer()
                
                if workoutTester.isRunningTests {
                    VStack(alignment: .trailing, spacing: 4) {
                        ProgressView(value: workoutTester.currentTestProgress)
                            .frame(width: 100)
                        Text("\(Int(workoutTester.currentTestProgress * 100))%")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testResultsSection(_ results: BatchTestResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
            
            // Summary stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Success Rate:")
                    Spacer()
                    Text("\(String(format: "%.1f", results.successRate * 100))%")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Average Score:")
                    Spacer()
                    Text("\(String(format: "%.2f", results.averageScore)) (\(results.overallGrade))")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Average Duration:")
                    Spacer()
                    Text("\(String(format: "%.1f", results.averageDuration))s")
                        .fontWeight(.semibold)
                }
            }
            .font(.caption)
            
            // Individual results
            if !results.results.isEmpty {
                Text("Individual Results:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(Array(results.results.enumerated()), id: \.offset) { index, result in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(result.request.userInput)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(result.success ? "✅" : "❌")
                        
                        Text(result.validationResults.grade)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Button("Copy Full Report") {
                UIPasteboard.general.string = workoutTester.getTestReport(for: results)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func validationResultsView(_ validation: WorkoutGenerationTestResult.ValidationResults) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Validation Results:")
                .font(.caption)
                .fontWeight(.medium)
            
            HStack {
                validationItem("Exercises Valid", validation.allExercisesValid)
                validationItem("Structure", validation.hasValidStructure)
                validationItem("Count", validation.exerciseCountAppropriate)
                validationItem("Sets", validation.setsReasonable)
            }
            
            HStack {
                validationItem("Reps", validation.repsAppropriate)
                validationItem("Weights", validation.weightSuggestionsReasonable)
                validationItem("Rest", validation.restPeriodsAppropriate)
                validationItem("Match", validation.matchesUserRequest)
            }
            
            if !validation.invalidExercises.isEmpty {
                Text("Invalid: \(validation.invalidExercises.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    private func validationItem(_ label: String, _ isValid: Bool) -> some View {
        HStack(spacing: 2) {
            Text(isValid ? "✅" : "❌")
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
    }
    
    private func parsingResultsView(_ parsingResult: WorkoutParsingResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Parsing Results:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(parsingResult.success ? "✅ Success" : "❌ Failed")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(parsingResult.success ? .green : .red)
            }
            
            if parsingResult.hasWarnings {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Warnings:")
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    ForEach(Array(parsingResult.warnings.enumerated()), id: \.offset) { _, warning in
                        Text("• \(warning.description)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if parsingResult.hasSanitizations {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔧 Sanitizations:")
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    ForEach(Array(parsingResult.sanitizedParameters.enumerated()), id: \.offset) { _, sanitization in
                        Text("• \(sanitization.exerciseName): \(sanitization.parameter) adjusted")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if parsingResult.hasErrors {
                VStack(alignment: .leading, spacing: 4) {
                    Text("❌ Errors:")
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    ForEach(Array(parsingResult.errors.enumerated()), id: \.offset) { _, error in
                        Text("• \(error.localizedDescription)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    private func createdWorkoutView(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("✅ Workout Created Successfully!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
                
                Button("View in App") {
                    // This would navigate to the workout in the main app
                    // For now, just show an alert
                    showCreateWorkout = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            Text("Workout '\(workout.name)' has been added to your workout library with \(workout.exercises.count) exercises.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
        .alert("Workout Created", isPresented: $showCreateWorkout) {
            Button("OK") { }
        } message: {
            Text("The workout '\(workout.name)' has been successfully created and added to your workout library. You can find it in the main Workouts section of the app.")
        }
    }
    
    // MARK: - Actions
    
    private func createWorkoutFromParsed(_ parsedWorkout: ParsedWorkout) async {
        do {
            let userProfile = WorkoutGenerationRequest.UserProfile(
                age: selectedAge,
                fitnessGoal: selectedGoal,
                fitnessLevel: selectedLevel,
                preferredUnits: .metric
            )
            
            let workout = try responseParser.createWorkoutModels(
                from: parsedWorkout,
                userProfile: userProfile,
                modelContext: modelContext
            )
            
            try modelContext.save()
            
            await MainActor.run {
                createdWorkout = workout
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create workout: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func generateWorkout() async {
        guard !workoutRequest.isEmpty else { return }
        
        isLoading = true
        workoutResponse = ""
        lastTestResult = nil
        
        let userProfile = WorkoutGenerationRequest.UserProfile(
            age: selectedAge,
            fitnessGoal: selectedGoal,
            fitnessLevel: selectedLevel,
            preferredUnits: .metric
        )
        
        let result = await workoutTester.testCustomWorkout(
            userInput: workoutRequest,
            userProfile: userProfile
        )
        
        await MainActor.run {
            isLoading = false
            lastTestResult = result
            
            if result.success, let parsedResponse = result.parsedResponse {
                // Format the response nicely
                workoutResponse = formatWorkoutResponse(parsedResponse)
            } else {
                workoutResponse = result.rawResponse.isEmpty ? (result.error ?? "No response") : result.rawResponse
            }
        }
    }
    
    private func runBatchTests() async {
        let results = await workoutTester.testAllScenarios()
        // Results are automatically stored in workoutTester.lastTestResults
    }
    
    private func formatWorkoutResponse(_ response: WorkoutGenerationResponse) -> String {
        var formatted = """
        🏋️ \(response.workoutName)
        
        📝 \(response.description)
        ⏱️ Duration: \(response.estimatedDuration)
        
        EXERCISES:
        """
        
        for (index, exercise) in response.exercises.enumerated() {
            formatted += """
            
            \(index + 1). \(exercise.name)
               Sets: \(exercise.sets) | Reps: \(exercise.reps)
               Weight: \(exercise.weight) | Rest: \(exercise.rest)
            """
            
            if let notes = exercise.notes, !notes.isEmpty {
                formatted += "\n   Notes: \(notes)"
            }
        }
        
        if let notes = response.workoutNotes, !notes.isEmpty {
            formatted += """
            
            💡 Workout Notes:
            \(notes)
            """
        }
        
        return formatted
    }
}

// MARK: - Preview

#Preview {
    OpenAITestView()
}
