//
//  WeeklyWorkoutCircle.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

/// A circular progress indicator showing weekly workout completion
struct WeeklyWorkoutCircle: View {
    let completedCount: Int
    let goalCount: Int
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard goalCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(goalCount), 1.0)
    }
    
    private var isGoalMet: Bool {
        completedCount >= goalCount
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // Circular Progress Indicator
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress Arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isGoalMet ? Color.green : Color.blue,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                
                // Fraction Text
                VStack(spacing: 4) {
                    Text("\(completedCount)/\(goalCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    if isGoalMet {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Label
            Text("workouts completed")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly workout progress")
        .accessibilityValue("\(completedCount) of \(goalCount) workouts completed\(isGoalMet ? ". Goal achieved!" : "")")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        WeeklyWorkoutCircle(completedCount: 0, goalCount: 4)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        WeeklyWorkoutCircle(completedCount: 2, goalCount: 4)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        WeeklyWorkoutCircle(completedCount: 4, goalCount: 4)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

