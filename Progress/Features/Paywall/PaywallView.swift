//
//  PaywallView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedOffering: SubscriptionService.SubscriptionOffering?
    @State private var showingPurchaseSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    headerSection
                    
                    // Subscription Tiers
                    subscriptionTiersSection
                    
                    // Features Comparison
                    featuresSection
                    
                    // Purchase Button
                    purchaseSection
                    
                    // Footer
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.background)
            .navigationTitle("Choose Your Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color.textSecondary)
                }
            }
        }
        .task {
            await subscriptionService.loadOfferings()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.primary)
            
            Text("Unlock Progress Premium")
                .font(.titleLarge)
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Choose the plan that fits your fitness journey")
                .font(.bodyLarge)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Subscription Tiers
    
    private var subscriptionTiersSection: some View {
        VStack(spacing: 16) {
            ForEach(subscriptionService.currentOfferings, id: \.productId) { offering in
                SubscriptionTierCard(
                    offering: offering,
                    isSelected: selectedOffering?.productId == offering.productId
                ) {
                    selectedOffering = offering
                }
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's Included")
                .font(.titleMedium)
                .foregroundColor(Color.textPrimary)
            
            if let selected = selectedOffering {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(selected.tier.features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.success)
                                .font(.body)
                            
                            Text(feature)
                                .font(.body)
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let selected = selectedOffering {
                Button {
                    Task {
                        await subscriptionService.purchase(selected)
                        if subscriptionService.activeSubscription != nil {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if subscriptionService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start \(selected.tier.displayName) - \(selected.pricePerMonth)/month")
                                .font(.buttonPrimary)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(subscriptionService.isLoading)
            }
            
            Button("Restore Purchases") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(.body)
            .foregroundColor(Color.textSecondary)
            .disabled(subscriptionService.isLoading)
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("• Cancel anytime in Settings")
                .font(.caption)
                .foregroundColor(Color.textTertiary)
            
            Text("• Subscription auto-renews monthly")
                .font(.caption)
                .foregroundColor(Color.textTertiary)
            
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    // TODO: Open terms
                }
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                
                Button("Privacy Policy") {
                    // TODO: Open privacy policy
                }
                .font(.caption)
                .foregroundColor(Color.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Subscription Tier Card

struct SubscriptionTierCard: View {
    let offering: SubscriptionService.SubscriptionOffering
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header with popular badge
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(offering.tier.displayName)
                            .font(.titleMedium)
                            .foregroundColor(Color.textPrimary)
                        
                        Text(offering.tier.tagline)
                            .font(.bodySmall)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    if offering.isPopular {
                        Text("POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary)
                            .clipShape(Capsule())
                    }
                }
                
                // Price
                HStack(alignment: .bottom) {
                    Text(offering.pricePerMonth)
                        .font(.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("/month")
                        .font(.body)
                        .foregroundColor(Color.textSecondary)
                    
                    Spacer()
                }
                
                // Key features preview
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(offering.tier.features.prefix(3)), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(Color.success)
                            
                            Text(feature)
                                .font(.bodySmall)
                                .foregroundColor(Color.textSecondary)
                            
                            Spacer()
                        }
                    }
                    
                    if offering.tier.features.count > 3 {
                        Text("+ \(offering.tier.features.count - 3) more features")
                            .font(.caption)
                            .foregroundColor(Color.textTertiary)
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(20)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.primary : Color.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Paywall") {
    PaywallView()
}

#Preview("Subscription Card") {
    VStack(spacing: 16) {
        SubscriptionTierCard(
            offering: SubscriptionService.SubscriptionOffering(
                tier: .standard,
                productId: "standard",
                price: "£0.99",
                pricePerMonth: "£0.99",
                isPopular: false,
                package: nil
            ),
            isSelected: false
        ) {}
        
        SubscriptionTierCard(
            offering: SubscriptionService.SubscriptionOffering(
                tier: .aiNative,
                productId: "ai_native",
                price: "£2.99",
                pricePerMonth: "£2.99",
                isPopular: true,
                package: nil
            ),
            isSelected: true
        ) {}
    }
    .padding()
    .background(Color.background)
} 
