//
//  DailyStepsCircle.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

/// A circular progress indicator showing daily step completion
struct DailyStepsCircle: View {
    let currentSteps: Int
    let goalSteps: Int
    
    // MARK: - Number Formatter
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.locale = Locale.current
        return formatter
    }
    
    private func formatSteps(_ steps: Int) -> String {
        return numberFormatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard goalSteps > 0 else { return 0 }
        return min(Double(currentSteps) / Double(goalSteps), 1.0)
    }
    
    private var isGoalMet: Bool {
        currentSteps >= goalSteps
    }
    
    private var progressColor: Color {
        let percentage = progress * 100
        
        if percentage >= 100 {
            return .yellow // Gold when goal exceeded
        } else if percentage >= 80 {
            return .orange // Orange when close to goal (80-100%)
        } else {
            return .blue // Blue when under 80%
        }
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
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                
                // Step Count
                VStack(spacing: 4) {
                    Text(formatSteps(currentSteps))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    if isGoalMet {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // Label
            Text("steps today")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily steps progress")
        .accessibilityValue("\(formatSteps(currentSteps)) of \(formatSteps(goalSteps)) steps completed\(isGoalMet ? ". Goal achieved!" : "")")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        DailyStepsCircle(currentSteps: 2500, goalSteps: 10000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        DailyStepsCircle(currentSteps: 6242, goalSteps: 10000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        DailyStepsCircle(currentSteps: 12500, goalSteps: 10000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

