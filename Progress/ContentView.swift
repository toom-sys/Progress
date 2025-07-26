//
//  ContentView.swift
//  Progress
//
//  Created by Tom Cameron on 12/07/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: ProgressSpacing.paragraphSpacingLarge) {
                // Hero Section
                VStack(spacing: ProgressSpacing.paragraphSpacingMedium) {
                    Text("Progress")
                        .font(ProgressTypography.displayLarge)
                        .foregroundColor(ProgressColors.textPrimary)
                    
                    Text("Track workouts, log nutrition and visualise progress")
                        .font(ProgressTypography.bodyLarge)
                        .foregroundColor(ProgressColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ProgressSpacing.paragraphSpacingLarge)
                
                // Feature Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: ProgressSpacing.paragraphSpacingMedium) {
                    FeatureCard(
                        title: "Workouts",
                        subtitle: "Plan & track",
                        icon: "figure.strengthtraining.traditional",
                        color: ProgressColors.primaryBlue
                    )
                    
                    FeatureCard(
                        title: "Nutrition",
                        subtitle: "Log meals",
                        icon: "leaf.fill",
                        color: ProgressColors.accentGreen
                    )
                    
                    FeatureCard(
                        title: "Progress",
                        subtitle: "View insights",
                        icon: "chart.line.uptrend.xyaxis",
                        color: ProgressColors.secondaryBlue
                    )
                    
                    FeatureCard(
                        title: "Rest Timer",
                        subtitle: "Time breaks",
                        icon: "timer",
                        color: ProgressColors.timerProgress
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Coming Soon Badge
                VStack(spacing: ProgressSpacing.paragraphSpacingSmall) {
                    Text("Coming Soon")
                        .font(ProgressTypography.labelLarge)
                        .foregroundColor(ProgressColors.textSecondary)
                    
                    Text("Full app launching with iOS 18 support")
                        .font(ProgressTypography.bodySmall)
                        .foregroundColor(ProgressColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, ProgressSpacing.paragraphSpacingLarge)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ProgressColors.backgroundPrimary)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ProgressSpacing.paragraphSpacingSmall) {
            Image(systemName: icon)
                .font(ProgressTypography.displaySmall)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(ProgressTypography.titleMedium)
                    .foregroundColor(ProgressColors.textPrimary)
                
                Text(subtitle)
                    .font(ProgressTypography.bodySmall)
                    .foregroundColor(ProgressColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ProgressSpacing.paragraphSpacingMedium)
        .background(ProgressColors.surfaceCard)
        .cornerRadius(12)
        .shadow(
            color: ProgressColors.textPrimary.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
