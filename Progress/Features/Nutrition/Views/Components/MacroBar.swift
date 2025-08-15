//
//  MacroBar.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Macro Bar Component

struct MacroBar: View {
    let value: Double
    let target: Double
    let label: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        target > 0 ? min(value / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("\(Int(value))")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(unit)
                        .font(.caption2)
                }
                .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
    }
}
