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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(remaining))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("Calories left")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
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
                    .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                    .frame(width: 56, height: 56)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: consumed)
                
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .whiteCardStyle(cornerRadius: 16, padding: 20)
    }
}
