//
//  MacroMiniCard.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Macro Mini Card Component

struct MacroMiniCard: View {
    let value: Double
    let label: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(value))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}
