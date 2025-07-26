//
//  ContentView.swift
//  Progress
//
//  Created by Tom Cameron on 12/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    Text("Progress")
                        .font(.titleXL)
                        .foregroundColor(.textPrimary)
                    
                    Text("Track workouts, log nutrition and visualise progress")
                        .font(.bodyLarge)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Feature Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    FeatureCard(
                        title: "Workouts",
                        subtitle: "Plan & track",
                        icon: "figure.strengthtraining.traditional",
                        color: .primary
                    )
                    
                    FeatureCard(
                        title: "Nutrition",
                        subtitle: "Log meals",
                        icon: "leaf.fill",
                        color: .accent
                    )
                    
                    FeatureCard(
                        title: "Progress",
                        subtitle: "View insights",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .primary
                    )
                    
                    FeatureCard(
                        title: "Rest Timer",
                        subtitle: "Time breaks",
                        icon: "timer",
                        color: .warning
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Coming Soon Badge & Subscription
                VStack(spacing: 16) {
                    Button("View Subscription Plans") {
                        showingPaywall = true
                    }
                    .font(.buttonPrimary)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(spacing: 8) {
                        Text("Coming Soon")
                            .font(.label)
                            .foregroundColor(.textSecondary)
                        
                        Text("Full app launching with iOS 18 support")
                            .font(.bodySmall)
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.titleLarge)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.surface)
        .cornerRadius(12)
        .shadow(
            color: .textPrimary.opacity(0.1),
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
