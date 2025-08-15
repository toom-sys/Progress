//
//  CalorieCard.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Calorie Card Component

struct CalorieCard: View {
    let consumed: Double
    let target: Double
    
    private var remaining: Double {
        max(0, target - consumed)
    }
    
    private var progress: Double {
        target > 0 ? min(consumed / target, 1.0) : 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(remaining))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 8) {
                    Text("Calories left")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("+\(Int(consumed))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Calorie circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: consumed)
                
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        }
        .whiteCardStyle(cornerRadius: 16, padding: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
