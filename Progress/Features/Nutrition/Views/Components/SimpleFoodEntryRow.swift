//
//  SimpleFoodEntryRow.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Simple Food Entry Row Component

struct SimpleFoodEntryRow: View {
    let entry: NutritionEntry
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header row with food name and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.foodName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if entry.quantity != 1.0 {
                            Text("\(String(format: "%.2g", entry.quantity)) × \(entry.servingSize)")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text(entry.servingSize)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if entry.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if let brandName = entry.brandName {
                            Text("• \(brandName)")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: entry.loggedAt))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(Int(entry.totalCalories))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Macros row
            HStack(spacing: 20) {
                MacroMiniCard(
                    value: entry.totalProtein,
                    label: "Protein",
                    unit: "g",
                    color: .red,
                    icon: "fish.fill"
                )
                
                MacroMiniCard(
                    value: entry.totalCarbohydrates,
                    label: "Carbs",
                    unit: "g", 
                    color: .orange,
                    icon: "leaf.fill"
                )
                
                MacroMiniCard(
                    value: entry.totalFat,
                    label: "Fat",
                    unit: "g",
                    color: .blue,
                    icon: "drop.fill"
                )
                
                Spacer()
            }
        }
        .whiteCardStyle(cornerRadius: 16, padding: 20)
    }
}
