//
//  DayPickerCard.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Day Picker Card Component

struct DayPickerCard: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter day (M, T, W, etc.)
        return formatter
    }
    
    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? AppPalette.onInk.opacity(0.75) : AppPalette.muted)

                Text(dayNumberFormatter.string(from: date))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(isSelected ? AppPalette.onInk : AppPalette.ink)

                Circle()
                    .fill(isToday && !isSelected ? Color.brand : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 62)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppPalette.ink)
                        .shadow(color: Color.black.opacity(0.22), radius: 8, y: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
