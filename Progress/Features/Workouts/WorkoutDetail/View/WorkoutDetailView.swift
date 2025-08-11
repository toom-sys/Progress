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
    @State private var isAnimatingExerciseDetail = false
    @State private var exerciseRowFrame: CGRect = .zero
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
                                                            onTap: { frame in
                            showExerciseDetail(exercise, fromFrame: frame)
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
            .background(AdaptiveGradientBackground())
            // Removed main VStack tap gesture to prevent interference with exercise row taps
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
        .overlay(alignment: .topLeading) {
            if showingExerciseDetail, let exercise = selectedExercise {
                
                GeometryReader { geometry in
                    let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let finalSize = CGSize(width: geometry.size.width - 40, height: min(500, geometry.size.height * 0.8))
                    
                    // Calculate initial position from exercise row frame
                    let initialX = exerciseRowFrame.midX - (exerciseRowFrame.width / 2)
                    let initialY = exerciseRowFrame.midY - (exerciseRowFrame.height / 2)
                    
                    // Calculate final position (centered)
                    let finalX = screenCenter.x - (finalSize.width / 2)
                    let finalY = screenCenter.y - (finalSize.height / 2)
                    
                    // Animation offsets
                    let offsetX = showingExerciseDetail ? finalX : initialX
                    let offsetY = showingExerciseDetail ? finalY : initialY
                    let width = showingExerciseDetail ? finalSize.width : exerciseRowFrame.width
                    let height = showingExerciseDetail ? finalSize.height : exerciseRowFrame.height
                    
                    ZStack {
                        // Background overlay with proper tap area (reduced opacity to eliminate shadow effect)
                        Rectangle()
                            .fill(Color.black.opacity(showingExerciseDetail ? 0.15 : 0.0))
                            .ignoresSafeArea()
                            .onTapGesture {
                                dismissExerciseDetail()
                            }
                        
                        // Hero animated Exercise Detail Window
                        ExerciseDetailWindowView(
                            exercise: exercise,
                            isShowing: $showingExerciseDetail,
                            onDismiss: {
                                dismissExerciseDetail()
                            }
                        )
                        .frame(width: width, height: height)
                        .position(x: offsetX + width/2, y: offsetY + height/2)
                        .opacity(showingExerciseDetail ? 1.0 : 0.8)
                        .shadow(radius: 0) // Explicitly remove any shadows from the popup

                    }
                    .shadow(radius: 0) // Remove any container shadows
                }

            } else {
                EmptyView()
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
            // Work with sorted exercises to maintain visual order
            var sortedExercises = workout.exercises.sorted { $0.order < $1.order }
            
            if let index = sortedExercises.firstIndex(of: exercise) {
                // Remove from sorted array and from workout
                sortedExercises.remove(at: index)
                workout.exercises.removeAll { $0.id == exercise.id }
                modelContext.delete(exercise)
                
                // Reorder remaining exercises based on visual positions
                for (newIndex, remainingExercise) in sortedExercises.enumerated() {
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
    
    private func showExerciseDetail(_ exercise: Exercise, fromFrame: CGRect) {
        // Prevent rapid taps during animation
        guard !isAnimatingExerciseDetail else { return }
        
        // Set state variables
        isAnimatingExerciseDetail = true
        selectedExercise = exercise
        exerciseRowFrame = fromFrame
        
        // Haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Set state immediately, then animate
        showingExerciseDetail = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Animation will handle the visual transition, state is already set
        }
        
        // Reset animation flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.isAnimatingExerciseDetail = false
        }
    }
    
    private func dismissExerciseDetail() {
        // Prevent rapid taps during animation
        guard !isAnimatingExerciseDetail else { return }
        
        isAnimatingExerciseDetail = true
        
        // Animate the state change explicitly with same timing as show
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingExerciseDetail = false
        }
        
        // Clear selectedExercise after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.selectedExercise = nil
            self.isAnimatingExerciseDetail = false
        }
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