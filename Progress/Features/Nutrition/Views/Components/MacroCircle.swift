//
//  MacroCircle.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Macro Circle Component

struct MacroCircle: View {
    let value: Double
    let target: Double
    let label: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        target > 0 ? min(value / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(Int(value))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}
