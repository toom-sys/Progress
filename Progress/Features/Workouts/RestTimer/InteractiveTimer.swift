//
//  InteractiveTimer.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

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