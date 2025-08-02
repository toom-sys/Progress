//
//  WorkoutDetailView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    @State private var editingName = false
    @State private var workoutName: String
    
    // Timer states
    @State private var timerSeconds: Int = 90 // Default 1:30
    @State private var currentTimerSeconds: Int = 0
    @State private var timerIsRunning = false
    @State private var editingTimer = false
    @State private var editingTimerText = "1:30"
    @State private var timer: Timer?
    @State private var timerEditingDebouncer: Timer?
    
    // Exercise creation states
    @State private var showingCreateExercise = false
    @State private var selectedExerciseType: ExerciseType = .resistance
    @State private var newExerciseName = ""
    @State private var selectedExercise: Exercise?
    @State private var showingExerciseDetail = false
    @FocusState private var isNameFieldFocused: Bool
    
    // Inspirational comments
    private let inspirationalComments = [
        "You've got this",
        "Push through the burn",
        "Every rep counts",
        "Stronger than yesterday",
        "Mind over muscle",
        "Progress over perfection",
        "Feel the power",
        "Unleash your potential",
        "Embrace the challenge",
        "Rise and grind"
    ]
    
    @State private var currentComment: String = ""
    
    init(workout: Workout) {
        self.workout = workout
        self._workoutName = State(initialValue: workout.name)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Static Top Section
                VStack(spacing: 20) {
                    // Name and Edit Button
                    HStack {
                        if editingName {
                            TextField("Workout name", text: $workoutName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($isNameFieldFocused)
                                .onSubmit {
                                    saveWorkoutName()
                                }
                                .onAppear {
                                    isNameFieldFocused = true
                                }
                        } else {
                            Text(workout.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                                .onTapGesture {
                                    startEditing()
                                }
                        }
                        
                        Spacer()
                        
                        // 3-dot menu button
                        Menu {
                            // Edit name option
                            Button(action: {
                                if editingName {
                                    saveWorkoutName()
                                } else {
                                    startEditing()
                                }
                            }) {
                                Label(editingName ? "Save Name" : "Edit Name", systemImage: editingName ? "checkmark" : "pencil")
                            }
                            
                            Divider()
                            
                            // Add Exercise submenu
                            Menu {
                                ForEach(ExerciseType.allCases, id: \.self) { type in
                                    Button(action: {
                                        selectedExerciseType = type
                                        showingCreateExercise = true
                                    }) {
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                            Spacer()
                                            Text(getTypeDescription(for: type))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            } label: {
                                Label("Add Exercise", systemImage: "plus")
                            }
                            
                            Divider()
                            
                            // Complete workout button
                            Button(action: {
                                // TODO: Complete workout functionality
                            }) {
                                Label("Complete Workout", systemImage: "checkmark.circle.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                    }
                    
                    // Inspirational Comment
                    Text(currentComment)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Progress Bar with Timer (New Design)
                    NewProgressBarWithTimer(
                        workout: workout,
                        seconds: $timerSeconds,
                        currentSeconds: $currentTimerSeconds,
                        isRunning: $timerIsRunning,
                        isEditing: $editingTimer,
                        editingText: $editingTimerText,
                        timer: $timer,
                        editingDebouncer: $timerEditingDebouncer
                    )
                }
                .padding(20)
                .background(Color.clear)
                
                // Exercise List with proper reordering and delete
                VStack(spacing: 0) {
                    if workout.exercises.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 40))
                                .foregroundColor(.textSecondary)
                            
                            Text("No exercises yet")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Text("Add your first exercise to get started")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Exercise List
                        List {
                            ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                                ExerciseRowView(
                                    exercise: exercise,
                                    onDelete: {
                                        deleteExercise(exercise)
                                    },
                                    onTap: {
                                        selectedExercise = exercise
                                        showingExerciseDetail = true
                                    }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteExercise(exercise)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onMove(perform: moveExercises)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                    }

                }
            }
            .onTapGesture {
                // Save workout name when tapping anywhere while editing name
                if editingName {
                    saveWorkoutName()
                }
            }
            .onAppear {
                setupView()
                // Notify that we're showing workout detail
                NotificationCenter.default.post(name: .showWorkoutDetail, object: nil)
            }
            .onDisappear {
                stopTimer()
                // Notify that we're leaving workout detail
                NotificationCenter.default.post(name: .dismissWorkoutDetail, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dismissWorkoutDetail)) { _ in
                // Dismiss this view when the notification is received
                dismiss()
            }
            .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showingCreateExercise) {
            CreateExerciseView(
                exerciseType: selectedExerciseType,
                onSave: { name, type, setCount, weight, reps, distance, duration in
                    createExercise(name: name, type: type, setCount: setCount, weight: weight, reps: reps, distance: distance, duration: duration)
                    showingCreateExercise = false
                }
            )
        }
        .overlay {
            if showingExerciseDetail, let exercise = selectedExercise {
                // Clear background for tap to dismiss
                Color.clear
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingExerciseDetail = false
                            selectedExercise = nil
                        }
                    }
                
                // Centered Exercise Detail Window that expands from exercise row
                ExerciseDetailWindowView(
                    exercise: exercise,
                    isShowing: $showingExerciseDetail,
                    onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingExerciseDetail = false
                            selectedExercise = nil
                        }
                    }
                )
                .scaleEffect(
                    x: showingExerciseDetail ? 1.0 : 1.0,
                    y: showingExerciseDetail ? 1.0 : 0.01
                )
                .opacity(showingExerciseDetail ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingExerciseDetail)
            }
        }

    }
    
    // MARK: - Helper Methods
    
    private func setupView() {
        // Set random inspirational comment
        currentComment = inspirationalComments.randomElement() ?? "You've got this"
        currentTimerSeconds = timerSeconds
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerEditingDebouncer?.invalidate()
        timerEditingDebouncer = nil
    }
    
    private func saveWorkoutName() {
        workout.name = workoutName
        workout.updateTimestamp()
        try? modelContext.save()
        editingName = false
    }
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        try? modelContext.save()
        dismiss()
    }
    
    private func getTypeDescription(for type: ExerciseType) -> String {
        switch type {
        case .resistance: return "Weight, Sets & Reps"
        case .cardio: return "Distance & Time"
        case .recovery: return "Category & Duration"
        }
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sortedExercises = workout.exercises.sorted { $0.order < $1.order }
        sortedExercises.move(fromOffsets: source, toOffset: destination)
        
        // Update order for all exercises
        for (index, exercise) in sortedExercises.enumerated() {
            exercise.order = index
        }
        
        try? modelContext.save()
    }
    
    private func createExercise(name: String, type: ExerciseType, setCount: Int, weight: Double, reps: Int, distance: Double, duration: String) {
        let newExercise = Exercise(
            name: name,
            type: type,
            order: workout.exercises.count
        )
        newExercise.workout = workout
        workout.exercises.append(newExercise)
        
        // Create sets based on exercise type and input
        for i in 0..<setCount {
            let exerciseSet: ExerciseSet
            
            switch type {
            case .resistance:
                exerciseSet = ExerciseSet(
                    weight: weight,
                    reps: reps,
                    duration: 0,
                    distance: 0,
                    order: i
                )
            case .cardio:
                // Parse duration string (assuming format like "30" for 30 minutes)
                let durationMinutes = Double(duration) ?? 30.0
                let durationSeconds = durationMinutes * 60
                
                exerciseSet = ExerciseSet(
                    weight: 0,
                    reps: 0,
                    duration: durationSeconds,
                    distance: distance,
                    order: i
                )
            case .recovery:
                // Parse duration string for recovery
                let durationMinutes = Double(duration) ?? 30.0
                let durationSeconds = durationMinutes * 60
                
                exerciseSet = ExerciseSet(
                    weight: 0,
                    reps: 0,
                    duration: durationSeconds,
                    distance: 0,
                    order: i
                )
            }
            
            newExercise.addSet(exerciseSet)
            modelContext.insert(exerciseSet)
        }
        
        try? modelContext.save()
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        withAnimation {
            if let index = workout.exercises.firstIndex(of: exercise) {
                workout.exercises.remove(at: index)
                modelContext.delete(exercise)
                
                // Reorder remaining exercises
                for (newIndex, remainingExercise) in workout.exercises.enumerated() {
                    remainingExercise.order = newIndex
                }
                
                try? modelContext.save()
            }
        }
    }

    
    private func startEditing() {
        editingName = true
        // Focus will be set by the TextField's onAppear modifier
    }
    
    // MARK: - Supporting Methods
}

// MARK: - Supporting Views

struct NewProgressBarWithTimer: View {
    let workout: Workout
    @Binding var seconds: Int
    @Binding var currentSeconds: Int
    @Binding var isRunning: Bool
    @Binding var isEditing: Bool
    @Binding var editingText: String
    @Binding var timer: Timer?
    @Binding var editingDebouncer: Timer?
    
    @State private var dragOffset: CGFloat = 0
    
    private var completionProgress: Double {
        guard !workout.exercises.isEmpty else { return 0.0 }
        
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        guard totalSets > 0 else { return 0.0 }
        
        let completedSets = workout.exercises.reduce(0) { result, exercise in
            result + exercise.sets.filter { $0.isCompleted }.count
        }
        
        return Double(completedSets) / Double(totalSets)
    }
    
    private var timeString: String {
        if isEditing {
            return editingText
        }
        let minutes = currentSeconds / 60
        let remainingSeconds = currentSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Slightly narrower progress bar with embedded percentage
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 44)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: geometry.size.width * completionProgress, height: 44)
                        .animation(.easeInOut(duration: 0.5), value: completionProgress)
                    
                    // Percentage text embedded in bar
                    HStack {
                        Text("\(Int(completionProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.leading, 12)
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .padding(.trailing, 16) // Make progress bar slightly less wide
            
            // Larger Timer with blue border
            HStack(spacing: 4) {
                if isEditing {
                    TextField("0:00", text: $editingText)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                        .frame(width: 65)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            saveTimerEdit()
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                    debounceTimerEdit()
                                }
                                .onEnded { _ in
                                    dragOffset = 0
                                }
                        )
                } else {
                    Text(timeString)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .onTapGesture(count: 2) {
                // Double tap: Reset timer
                resetTimer()
            }
            .onTapGesture(count: 1) {
                // Single tap: Play/Pause
                if !isEditing {
                    toggleTimer()
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long press: Edit timer
                startTimerEdit()
            }
        }
    }
    
    // MARK: - Timer Methods
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if currentSeconds > 0 {
                    currentSeconds -= 1
                } else {
                    pauseTimer()
                }
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        pauseTimer()
        currentSeconds = seconds
    }
    
    private func startTimerEdit() {
        isEditing = true
        editingText = timeString
    }
    
    private func saveTimerEdit() {
        isEditing = false
        
        // Parse the editing text back to seconds
        let components = editingText.split(separator: ":").compactMap { Int($0) }
        if components.count == 2 {
            let newSeconds = components[0] * 60 + components[1]
            seconds = newSeconds
            currentSeconds = newSeconds
        }
        
        editingDebouncer?.invalidate()
        editingDebouncer = nil
    }
    
    private func debounceTimerEdit() {
        editingDebouncer?.invalidate()
        editingDebouncer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                saveTimerEdit()
            }
        }
    }
}

struct ProgressBarWithTimer: View {
    let workout: Workout
    @Binding var seconds: Int
    @Binding var currentSeconds: Int
    @Binding var isRunning: Bool
    @Binding var isEditing: Bool
    @Binding var editingText: String
    @Binding var timer: Timer?
    @Binding var editingDebouncer: Timer?
    
    @State private var dragOffset: CGFloat = 0
    
    private var completionProgress: Double {
        guard !workout.exercises.isEmpty else { return 0.0 }
        
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        guard totalSets > 0 else { return 0.0 }
        
        let completedSets = workout.exercises.reduce(0) { result, exercise in
            result + exercise.sets.filter { $0.isCompleted }.count
        }
        
        return Double(completedSets) / Double(totalSets)
    }
    
    private var timerProgress: Double {
        guard seconds > 0 else { return 0 }
        return Double(currentSeconds) / Double(seconds)
    }
    
    private var timeString: String {
        if isEditing {
            return editingText
        }
        let minutes = currentSeconds / 60
        let remainingSeconds = currentSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Progress percentage and Timer
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(Int(completionProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                // Compact Timer
                HStack(spacing: 8) {
                    ZStack {
                        // Timer background circle
                        Circle()
                            .stroke(Color.backgroundTertiary, lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        // Timer progress circle
                        Circle()
                            .trim(from: 0, to: 1 - timerProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.primary, .accent],
                                    startPoint: .topTrailing,
                                    endPoint: .bottomLeading
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: isRunning ? 1.0 : 0.3), value: timerProgress)
                        
                        // Play/Pause icon
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .onTapGesture(count: 2) {
                        // Double tap: Reset timer
                        resetTimer()
                    }
                    .onTapGesture(count: 1) {
                        // Single tap: Play/Pause
                        if !isEditing {
                            toggleTimer()
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long press: Edit timer
                        startTimerEdit()
                    }
                    
                    // Timer text
                    if isEditing {
                        TextField("0:00", text: $editingText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                            .frame(width: 50)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                saveTimerEdit()
                            }
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.width
                                        debounceTimerEdit()
                                    }
                                    .onEnded { _ in
                                        dragOffset = 0
                                    }
                            )
                    } else {
                        Text(timeString)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                            .frame(width: 50)
                    }
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.primary, .accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * completionProgress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: completionProgress)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Timer Methods
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if currentSeconds > 0 {
                    currentSeconds -= 1
                } else {
                    pauseTimer()
                }
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        pauseTimer()
        currentSeconds = seconds
    }
    
    private func startTimerEdit() {
        isEditing = true
        editingText = timeString
    }
    
    private func saveTimerEdit() {
        isEditing = false
        
        // Parse the editing text back to seconds
        let components = editingText.split(separator: ":").compactMap { Int($0) }
        if components.count == 2 {
            let newSeconds = components[0] * 60 + components[1]
            seconds = newSeconds
            currentSeconds = newSeconds
        }
        
        editingDebouncer?.invalidate()
        editingDebouncer = nil
    }
    
    private func debounceTimerEdit() {
        editingDebouncer?.invalidate()
        editingDebouncer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                saveTimerEdit()
            }
        }
    }
}

struct WorkoutProgressBar: View {
    let workout: Workout
    
    private var completionProgress: Double {
        guard !workout.exercises.isEmpty else { return 0.0 }
        
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        guard totalSets > 0 else { return 0.0 }
        
        let completedSets = workout.exercises.reduce(0) { result, exercise in
            result + exercise.sets.filter { $0.isCompleted }.count
        }
        
        return Double(completedSets) / Double(totalSets)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(Int(completionProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.primary, .accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * completionProgress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: completionProgress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct InteractiveTimer: View {
    @Binding var seconds: Int
    @Binding var currentSeconds: Int
    @Binding var isRunning: Bool
    @Binding var isEditing: Bool
    @Binding var editingText: String
    @Binding var timer: Timer?
    @Binding var editingDebouncer: Timer?
    
    @State private var dragOffset: CGFloat = 0
    @State private var longPressActive = false
    
    private var timeString: String {
        if isEditing {
            return editingText
        }
        let minutes = currentSeconds / 60
        let remainingSeconds = currentSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private var progress: Double {
        guard seconds > 0 else { return 0 }
        return Double(currentSeconds) / Double(seconds)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.backgroundTertiary, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: 1 - progress)
                    .stroke(
                        LinearGradient(
                            colors: [.primary, .accent],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: isRunning ? 1.0 : 0.3), value: progress)
                
                // Timer text
                if isEditing {
                    TextField("0:00", text: $editingText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numbersAndPunctuation)
                        .onSubmit {
                            saveTimerEdit()
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                    debounceTimerEdit()
                                }
                                .onEnded { _ in
                                    dragOffset = 0
                                }
                        )
                } else {
                    Text(timeString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }
            }
            .onTapGesture(count: 2) {
                // Double tap: Reset timer
                resetTimer()
            }
            .onTapGesture(count: 1) {
                // Single tap: Play/Pause
                if !isEditing {
                    toggleTimer()
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long press: Enable editing
                startTimerEditing()
            }
            
            // Timer controls hint
            if !isEditing {
                Text(isRunning ? "Tap to pause • Double tap to reset" : "Tap to start • Hold to edit")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Slide to adjust • Tap done to save")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if currentSeconds > 0 {
                    currentSeconds -= 1
                } else {
                    pauseTimer()
                }
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        pauseTimer()
        currentSeconds = seconds
    }
    
    private func startTimerEditing() {
        pauseTimer()
        isEditing = true
        editingText = timeString
    }
    
    private func saveTimerEdit() {
        let components = editingText.split(separator: ":")
        if components.count == 2,
           let minutes = Int(components[0]),
           let secs = Int(components[1]) {
            let totalSeconds = minutes * 60 + secs
            seconds = totalSeconds
            currentSeconds = totalSeconds
        }
        isEditing = false
    }
    
    private func debounceTimerEdit() {
        editingDebouncer?.invalidate()
        editingDebouncer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                saveTimerEdit()
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text(exercise.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            if !exercise.sets.isEmpty {
                Text("\(exercise.sets.count) sets")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Exercise Views

struct ExerciseRowView: View {
    let exercise: Exercise
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Exercise Type Icon
            Image(systemName: exercise.type.icon)
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    Text(exercise.type.displayName)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    if !exercise.sets.isEmpty {
                        Text("• \(exercise.sets.count) sets")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Progress indicator
            if !exercise.sets.isEmpty {
                Text("\(exercise.completedSetsCount)/\(exercise.sets.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.backgroundTertiary)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
    }
}

struct CreateExerciseView: View {
    let exerciseType: ExerciseType
    let onSave: (String, ExerciseType, Int, Double, Int, Double, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName = ""
    @State private var weight = ""
    @State private var sets = "3"
    @State private var reps = "10"
    @State private var distance = ""
    @State private var duration = ""
    @State private var recoveryType = RecoveryType.active
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Name")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Exercise Name", text: $exerciseName)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Type-specific fields
                VStack(alignment: .leading, spacing: 16) {
                    switch exerciseType {
                    case .resistance:
                        ResistanceFieldsView(weight: $weight, sets: $sets, reps: $reps)
                    case .cardio:
                        CardioFieldsView(distance: $distance, duration: $duration)
                    case .recovery:
                        RecoveryFieldsView(recoveryType: $recoveryType, duration: $duration)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    if !exerciseName.isEmpty {
                        let setCount = Int(sets) ?? 3
                        let weightValue = Double(weight) ?? 0.0
                        let repsValue = Int(reps) ?? 10
                        let distanceValue = Double(distance) ?? 0.0
                        
                        onSave(exerciseName, exerciseType, setCount, weightValue, repsValue, distanceValue, duration)
                        dismiss()
                    }
                }) {
                    Text("Save Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(exerciseName.isEmpty ? Color.gray : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(exerciseName.isEmpty)
            }
            .padding()
            .navigationTitle(exerciseType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ResistanceFieldsView: View {
    @Binding var weight: String
    @Binding var sets: String
    @Binding var reps: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        TextField("20.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .font(.body)
                            .padding()
                            .background(Color.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("kg")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("03", text: $sets)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("10", text: $reps)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

struct CardioFieldsView: View {
    @Binding var distance: String
    @Binding var duration: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Distance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    TextField("5.0", text: $distance)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("km")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    TextField("00", text: .constant(""))
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Hour")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    TextField("30", text: $duration)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Min")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

struct RecoveryFieldsView: View {
    @Binding var recoveryType: RecoveryType
    @Binding var duration: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Menu {
                    ForEach(RecoveryType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            recoveryType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(recoveryType.displayName)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(.textSecondary)
                    }
                    .padding()
                    .background(Color.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    TextField("00", text: .constant(""))
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Hour")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    TextField("30", text: $duration)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding()
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Min")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

enum RecoveryType: String, CaseIterable {
    case active = "active"
    case mental = "mental"
    case mobility = "mobility"
    case passive = "passive"
    case thermal = "thermal"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .mental: return "Mental"
        case .mobility: return "Mobility"
        case .passive: return "Passive"
        case .thermal: return "Thermal"
        }
    }
}

struct ExerciseDetailWindowView: View {
    let exercise: Exercise
    @Binding var isShowing: Bool
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 20) {
                // Exercise Header
                HStack {
                    // Exercise Icon (Large)
                    Image(systemName: exercise.type.icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 40, weight: .medium))
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 30, height: 30)
                            .background(Color.backgroundTertiary)
                            .clipShape(Circle())
                    }
                }
                
                // Exercise Name
                Text(exercise.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Sets Header
                HStack {
                    Text("Sets")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Text("\(exercise.completedSetsCount)/\(exercise.sets.count) completed")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Sets List in ScrollView
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        SetRowView(
                            setNumber: index + 1,
                            set: set,
                            exerciseType: exercise.type
                        )
                    }
                    
                    // Add Set Button
                    Button(action: {
                        addNewSet()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                            Text("Add Set")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 300) // Limit height for window
            
            // Bottom Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Hide exercise functionality
                }) {
                    Text("Hide Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    // TODO: Coming soon functionality
                }) {
                    Text("Coming Soon")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity) // Match list item width
        .frame(height: 500) // Fixed height only
        .background(Color.backgroundSecondary) // Match exercise row background
        .clipShape(RoundedRectangle(cornerRadius: 12)) // Match list item corner radius
        .padding(.horizontal, 16) // Apply same gap as exercise list items
    }
    
    // MARK: - Helper Methods
    
    private func addNewSet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let newSet: ExerciseSet
            
            switch exercise.type {
            case .resistance:
                // Use the last set as a template or create default values
                if let lastSet = exercise.sets.last {
                    newSet = ExerciseSet(
                        weight: lastSet.weight,
                        reps: lastSet.reps,
                        duration: 0,
                        distance: 0,
                        order: exercise.sets.count
                    )
                } else {
                    newSet = ExerciseSet(
                        weight: 20.0,
                        reps: 10,
                        duration: 0,
                        distance: 0,
                        order: 0
                    )
                }
            case .cardio:
                if let lastSet = exercise.sets.last {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: lastSet.duration,
                        distance: lastSet.distance,
                        order: exercise.sets.count
                    )
                } else {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: 1800, // 30 minutes default
                        distance: 5.0,
                        order: 0
                    )
                }
            case .recovery:
                if let lastSet = exercise.sets.last {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: lastSet.duration,
                        distance: 0,
                        order: exercise.sets.count
                    )
                } else {
                    newSet = ExerciseSet(
                        weight: 0,
                        reps: 0,
                        duration: 1800, // 30 minutes default
                        distance: 0,
                        order: 0
                    )
                }
            }
            
            exercise.addSet(newSet)
            modelContext.insert(newSet)
            try? modelContext.save()
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 24) {
                    // Exercise Header
                    HStack {
                        // Exercise Icon (Large)
                        Image(systemName: exercise.type.icon)
                            .foregroundColor(.blue)
                            .font(.system(size: 50, weight: .medium))
                        
                        Spacer()
                        
                        // Close Button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.textSecondary)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 30, height: 30)
                                .background(Color.backgroundTertiary)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Exercise Name
                    Text(exercise.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Sets Header
                    HStack {
                        Text("Sets")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Text("\(exercise.completedSetsCount)/\(exercise.sets.count) completed")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Sets List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            SetRowView(
                                setNumber: index + 1,
                                set: set,
                                exerciseType: exercise.type
                            )
                        }
                        
                        // Add Set Button
                        Button(action: {
                            // TODO: Add set functionality
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .foregroundColor(.blue)
                                Text("Add Set")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Bottom Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        // TODO: Hide exercise functionality
                    }) {
                        Text("Hide Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        // TODO: Coming soon functionality
                    }) {
                        Text("Coming Soon")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

struct SetRowView: View {
    let setNumber: Int
    let set: ExerciseSet
    let exerciseType: ExerciseType
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Number
            Text("Set \(setNumber)")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .frame(width: 60, alignment: .leading)
            
            // Reps
            if exerciseType == .resistance {
                Text("\(Int(set.reps)) reps")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(width: 80, alignment: .center)
                
                // Weight
                Text("\(set.weight, specifier: "%.1f") kg")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .frame(width: 80, alignment: .center)
            } else {
                // For cardio and recovery, show different fields
                Text("Duration")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .frame(width: 80, alignment: .center)
                
                Text("Distance")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .frame(width: 80, alignment: .center)
            }
            
            Spacer()
            
            // Completion Checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if set.isCompleted {
                        set.reset()
                    } else {
                        set.complete()
                    }
                    try? modelContext.save()
                }
            }) {
                Image(systemName: set.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(set.isCompleted ? .blue : .textSecondary)
                    .font(.system(size: 24))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(
            name: "Push Day",
            isTemplate: false
        ))
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
    }
}