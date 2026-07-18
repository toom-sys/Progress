//
//  WorkoutTimer.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutTimer: View {
    @StateObject private var timerService: WorkoutTimerService
    @State private var showingEditTimer = false
    
    init(workoutId: String, defaultDuration: TimeInterval = 90) {
        self._timerService = StateObject(wrappedValue: WorkoutTimerService.forWorkout(workoutId))
        
        Task { @MainActor in
            WorkoutTimerService.forWorkout(workoutId).setDefaultDuration(defaultDuration)
        }
    }
    
    private var timerProgress: CGFloat {
        guard timerService.defaultDuration > 0 else { return 1 }
        return timerService.timeRemaining / timerService.defaultDuration
    }
    
    private var borderColor: Color {
        if timerService.isFinished { return .green }
        if timerService.timeRemaining <= 10 && timerService.isRunning { return .red }
        return .blue
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(timerService.formattedTime)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(timerService.timeRemaining <= 10 ? .red : (timerService.isRunning ? .blue : .primary))
                .frame(minWidth: 50, alignment: .center)
                .monospacedDigit()
            
            Text("Timer")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            HapticFeedback.timerAction()
            timerService.resetTimer()
        }
        .onTapGesture(count: 1) {
            HapticFeedback.timerAction()
            timerService.toggleTimer()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            showingEditTimer = true
        }
        .sheet(isPresented: $showingEditTimer) {
            TimerSettingsView(
                defaultDuration: Binding(
                    get: { timerService.defaultDuration },
                    set: { timerService.setDefaultDuration($0, fromUser: true) }
                ),
                onSave: { newDuration in
                    timerService.setDefaultDuration(newDuration, fromUser: true)
                }
            )
        }
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .trim(from: 0, to: timerService.isFinished ? 1 : timerProgress)
                .stroke(borderColor, lineWidth: timerService.isFinished ? 2.5 : 1.5)
                .animation(.linear(duration: 1), value: timerService.timeRemaining)
        )
    }
}

// MARK: - Timer Settings View

struct TimerSettingsView: View {
    @Binding var defaultDuration: TimeInterval
    @State private var selectedMinutes: Int
    @State private var selectedSeconds: Int
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (TimeInterval) -> Void
    
    init(defaultDuration: Binding<TimeInterval>, onSave: @escaping (TimeInterval) -> Void) {
        self._defaultDuration = defaultDuration
        self.onSave = onSave
        
        let totalSeconds = Int(defaultDuration.wrappedValue)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        self._selectedMinutes = State(initialValue: minutes)
        self._selectedSeconds = State(initialValue: seconds)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Set Default Timer Duration")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                // Time picker
                HStack(spacing: 20) {
                    // Minutes picker
                    VStack(spacing: 8) {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(0...59, id: \.self) { minute in
                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)

                    }
                    
                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Seconds picker
                    VStack(spacing: 8) {
                        Text("Seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Seconds", selection: $selectedSeconds) {
                            ForEach(0...59, id: \.self) { second in
                                Text("\(second)")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)

                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newDuration = TimeInterval(selectedMinutes * 60 + selectedSeconds)
                        onSave(newDuration)
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        WorkoutTimer(workoutId: "preview-1", defaultDuration: 300) // 5 minutes
        
        WorkoutTimer(workoutId: "preview-2", defaultDuration: 60) // 1 minute
        
        WorkoutTimer(workoutId: "preview-3", defaultDuration: 900) // 15 minutes
    }
    .padding()
    .background(.regularMaterial)
}
