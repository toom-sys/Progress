//
//  ProgressLegendView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

/// Legend view explaining the progress tiers and color coding
struct ProgressLegendView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress Legend")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Understanding your workout progress levels")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Progress tiers explanation
                    VStack(spacing: 16) {
                        ForEach(ProgressTier.allCases, id: \.self) { tier in
                            ProgressTierRow(tier: tier)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // How it works section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How Progress is Calculated")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Progress is based on workout frequency and consistency")
                            BulletPoint(text: "Each muscle group advances independently")
                            BulletPoint(text: "More recent workouts have greater impact")
                            BulletPoint(text: "Progress gradually fades without regular training")
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Better Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Train each muscle group 2-3 times per week")
                            BulletPoint(text: "Focus on consistency over intensity")
                            BulletPoint(text: "Tap muscle groups to see detailed progress")
                            BulletPoint(text: "Balance all muscle groups for best results")
                        }
                    }
                    
                    // Bottom padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .background(AdaptiveGradientBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProgressTierRow: View {
    let tier: ProgressTier
    
    var body: some View {
        HStack(spacing: 16) {
            // Color indicator
            Circle()
                .fill(tier.color)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.border, lineWidth: 1)
                )
            
            // Tier info
            VStack(alignment: .leading, spacing: 4) {
                Text(tier.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(tier.accessibilityDescription)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .foregroundColor(.textSecondary)
                .padding(.top, 1)
            
            Text(text)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ProgressLegendView()
}
