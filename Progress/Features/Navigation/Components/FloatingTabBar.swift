//
//  FloatingTabBar.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Floating Tab Bar Component

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab
    let isInWorkoutDetail: Bool
    let onTabSelected: (Tab) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 0) {
                ForEach([Tab.workouts, Tab.progress, Tab.nutrition], id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onTabSelected(tab)
                        }
                    }) {
                        // Special logic for workouts tab - only highlight when NOT in workout detail
                        let isTabActive = tab == .workouts ? (selectedTab == tab && !isInWorkoutDetail) : (selectedTab == tab)
                        
                        VStack(spacing: 4) {
                            ZStack {
                                Image(systemName: isTabActive ? tab.activeIcon : tab.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(isTabActive ? .primary : .textSecondary)
                                
                                // Blue indicator dot for workout detail
                                if tab == .workouts && isInWorkoutDetail {
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 6, height: 6)
                                        .offset(x: 12, y: -8)
                                }
                            }
                            
                            Text(tab.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(isTabActive ? .primary : .textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.border.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area bottom padding
        }
    }
}
