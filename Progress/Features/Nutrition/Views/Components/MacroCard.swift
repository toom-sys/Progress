//
//  MacroCard.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Macro Card Component

struct MacroCard: View {
    let value: Double
    let target: Double
    let label: String
    let icon: String
    let color: Color
    
    private var remaining: Double {
        max(0, target - value)
    }
    
    private var progress: Double {
        target > 0 ? min(value / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("\(Int(remaining))g")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Circular progress with icon
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .whiteCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
