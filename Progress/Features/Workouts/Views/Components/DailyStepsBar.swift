//
//  DailyStepsBar.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

/// A progress bar showing daily step count progress
struct DailyStepsBar: View {
    let currentSteps: Int
    let goalSteps: Int
    
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
            return .brand // Brand blue when under 80%
        }
    }
    
    private var textColor: Color {
        if isGoalMet {
            return .green
        } else {
            return .textSecondary
        }
    }
    
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
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon chip, label, and step counts
            HStack(spacing: 10) {
                Image(systemName: isGoalMet ? "figure.walk.motion" : "figure.walk")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(progressColor)
                    .frame(width: 28, height: 28)
                    .background(progressColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("Daily Steps")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(formatSteps(currentSteps)) / \(formatSteps(goalSteps))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.backgroundSecondary)
                    .clipShape(Capsule())
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background capsule
                    Capsule()
                        .fill(Color.border.opacity(0.2))
                        .frame(height: 8)
                    
                    // Foreground progress capsule
                    Capsule()
                        .fill(LinearGradient(
                            colors: [progressColor.opacity(0.75), progressColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily steps progress")
        .accessibilityValue("\(formatSteps(currentSteps)) of \(formatSteps(goalSteps)) steps completed\(isGoalMet ? ". Goal achieved!" : "")")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Low progress
        DailyStepsBar(currentSteps: 2500, goalSteps: 10000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        // Mid progress
        DailyStepsBar(currentSteps: 6242, goalSteps: 10000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        // Goal met
        DailyStepsBar(currentSteps: 12500, goalSteps: 10000)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

