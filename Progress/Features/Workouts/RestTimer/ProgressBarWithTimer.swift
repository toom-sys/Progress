//
//  ProgressBarWithTimer.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

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