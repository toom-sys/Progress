//
//  NewProgressBarWithTimer.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

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