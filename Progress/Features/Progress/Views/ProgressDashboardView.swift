//
//  ProgressDashboardView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Progress Dashboard View

struct ProgressDashboardView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("📊")
                .font(.system(size: 80))
            
            Text("Progress")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
            
            Text("Track your fitness journey")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Text("Complete some workouts and log meals to see your progress here!")
                    .font(.body)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AdaptiveGradientBackground())
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingPaywall = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.textSecondary)
                        
                        if let tier = subscriptionService.activeSubscription {
                            Text(tier.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            SettingsView()
        }
    }
}
