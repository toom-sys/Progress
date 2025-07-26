//
//  PaywallView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var loadingOffering: String? = nil // Track which card is loading
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Active Subscription Status
                        if let activeSubscription = subscriptionService.activeSubscription {
                            activeSubscriptionSection(activeSubscription)
                        }
                        
                        // Sandbox Mode Indicator
                        if subscriptionService.isSandboxMode {
                            sandboxModeIndicator
                        }
                        
                        // Subscription Cards
                        subscriptionCards
                        
                        // Features Comparison
                        featuresSection
                        
                        // Footer
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Choose Your Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .task {
            // In simulator, skip RevenueCat delays and use mock offerings immediately
            #if DEBUG && targetEnvironment(simulator)
            await subscriptionService.loadOfferings()
            subscriptionService.checkSubscriptionStatus()
            #else
            // Small delay to ensure RevenueCat is configured in production
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await subscriptionService.loadOfferings()
            subscriptionService.checkSubscriptionStatus()
            #endif
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Unlock Your Progress")
                .font(.titleXL)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Choose the plan that fits your fitness journey")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Active Subscription Section
    
    private func activeSubscriptionSection(_ subscription: SubscriptionService.SubscriptionTier) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.success)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Subscription")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.success)
                
                Text("\(subscription.displayName) - \(subscription.monthlyPrice)/month")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.success.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Sandbox Mode Indicator
    
    private var sandboxModeIndicator: some View {
        HStack {
            Image(systemName: "flask.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sandbox Mode")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text("Mock purchases enabled for testing")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Subscription Cards
    
    private var subscriptionCards: some View {
        VStack(spacing: 16) {
            ForEach(subscriptionService.currentOfferings, id: \.productId) { offering in
                SubscriptionCard(
                    offering: offering,
                    isLoading: loadingOffering == offering.productId,
                    isActive: subscriptionService.activeSubscription == offering.tier,
                    onPurchase: {
                        loadingOffering = offering.productId
                        Task {
                            await subscriptionService.purchase(offering)
                            loadingOffering = nil
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Button("Restore Purchases") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(.body)
            .foregroundColor(Color.textSecondary)
            .disabled(subscriptionService.isLoading)
            
            // Only show purchase errors, not configuration errors in sandbox mode
            if let error = subscriptionService.purchaseError,
               !subscriptionService.isSandboxMode,
               !error.contains("configuration") {
                Text(error)
                    .font(.body)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
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

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let offering: SubscriptionService.SubscriptionOffering
    let isLoading: Bool
    let isActive: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with popular badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offering.tier.displayName)
                        .font(.titleMedium)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(offering.tier.tagline)
                        .font(.body)
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
                
                // Status indicators
                HStack(spacing: 8) {
                    // Active indicator
                    if isActive {
                        Text("ACTIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.success)
                            .clipShape(Capsule())
                    }
                    
                    // Mock indicator
                    if offering.isMockOffering {
                        Text("DEMO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Key features preview
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(offering.tier.features.prefix(3)), id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(Color.success)
                        
                        Text(feature)
                            .font(.body)
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
            
            // Purchase button
            Button(action: onPurchase) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Processing...")
                            .font(.body)
                            .fontWeight(.semibold)
                    } else if isActive {
                        Text("Current Plan")
                            .font(.body)
                            .fontWeight(.semibold)
                    } else {
                        Text("Start \(offering.tier.displayName)")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundColor(.white)
                .background(isActive ? Color.success : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || isActive)
        }
        .padding(20)
        .background(Color.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? Color.success : (offering.isPopular ? Color.primary : Color.border),
                    lineWidth: isActive ? 2 : (offering.isPopular ? 2 : 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Previews

#Preview("Paywall") {
    PaywallView()
}

#Preview("Subscription Card") {
    VStack(spacing: 16) {
        SubscriptionCard(
            offering: SubscriptionService.SubscriptionOffering(
                tier: .standard,
                productId: "standard",
                price: "£0.99",
                pricePerMonth: "£0.99",
                isPopular: false,
                isMockOffering: true,
                package: nil
            ),
            isLoading: false,
            isActive: false
        ) {}
        
        SubscriptionCard(
            offering: SubscriptionService.SubscriptionOffering(
                tier: .aiNative,
                productId: "ai_native",
                price: "£2.99",
                pricePerMonth: "£2.99",
                isPopular: true,
                isMockOffering: true,
                package: nil
            ),
            isLoading: false,
            isActive: true
        ) {}
    }
    .padding()
    .background(Color.background)
} 
