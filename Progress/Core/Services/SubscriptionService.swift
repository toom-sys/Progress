//
//  SubscriptionService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

import RevenueCat

/// Service for managing subscriptions via RevenueCat
@MainActor
class SubscriptionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentOfferings: [SubscriptionOffering] = []
    @Published var activeSubscription: SubscriptionTier? = nil
    @Published var isLoading = false
    @Published var purchaseError: String? = nil
    @Published var isSandboxMode = true // Enable sandbox testing mode
    
    // MARK: - Subscription Tiers
    
    enum SubscriptionTier: String, CaseIterable {
        case standard = "standard_monthly"
        case aiNative = "ai_native_monthly"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .aiNative: return "AI Native"
            }
        }
        
        var monthlyPrice: String {
            switch self {
            case .standard: return "£1"
            case .aiNative: return "£3"
            }
        }
        
        var features: [String] {
            switch self {
            case .standard:
                return [
                    "Unlimited workout tracking",
                    "Nutrition logging with search",
                    "Progress charts and analytics",
                    "CloudKit sync across devices",
                    "Export your data anytime"
                ]
            case .aiNative:
                return [
                    "Everything in Standard",
                    "AI-powered workout generation",
                    "Smart nutrition recommendations", 
                    "Camera food logging with AI",
                    "Personalized insights engine",
                    "Priority customer support"
                ]
            }
        }
        
        var tagline: String {
            switch self {
            case .standard: return "Perfect for focused tracking"
            case .aiNative: return "Powered by artificial intelligence"
            }
        }
    }
    
    // MARK: - Offering Model
    
    struct SubscriptionOffering {
        let tier: SubscriptionTier
        let productId: String
        let price: String
        let pricePerMonth: String
        let isPopular: Bool
        let isMockOffering: Bool
        
        let package: Package?
    }
    
    // MARK: - Initialization
    
    init() {
        setupMockOfferings()
        // Don't check subscription status immediately - wait for RevenueCat to be configured
    }
    
    // MARK: - Public Methods
    
    func loadOfferings() async {
        isLoading = true
        purchaseError = nil
        
        // For sandbox testing, skip RevenueCat calls and use mock offerings directly
        #if DEBUG && targetEnvironment(simulator)
        print("🧪 Simulator mode: Using mock offerings for sandbox testing")
        setupMockOfferings()
        isLoading = false
        return
        #else
        
        // Ensure RevenueCat is configured before making calls
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, using mock offerings")
            setupMockOfferings()
            isLoading = false
            return
        }
        #endif
        
        do {
            let offerings = try await Purchases.shared.offerings()
            
            guard let currentOffering = offerings.current else {
                print("⚠️ No current offering found, using mock data")
                setupMockOfferings()
                isLoading = false
                return
            }
            
            var newOfferings: [SubscriptionOffering] = []
            
            // Look for packages by identifier
            let standardPackage = currentOffering.package(identifier: "standard_monthly") ?? currentOffering.monthly
            let aiPackage = currentOffering.package(identifier: "ai_native_monthly")
            
            if let standard = standardPackage {
                newOfferings.append(SubscriptionOffering(
                    tier: .standard,
                    productId: standard.storeProduct.productIdentifier,
                    price: standard.storeProduct.localizedPriceString,
                    pricePerMonth: standard.storeProduct.localizedPriceString,
                    isPopular: false,
                    isMockOffering: false,
                    package: standard
                ))
            }
            
            if let ai = aiPackage {
                newOfferings.append(SubscriptionOffering(
                    tier: .aiNative,
                    productId: ai.storeProduct.productIdentifier,
                    price: ai.storeProduct.localizedPriceString,
                    pricePerMonth: ai.storeProduct.localizedPriceString,
                    isPopular: true,
                    isMockOffering: false,
                    package: ai
                ))
            }
            
            // If no packages found, use mock data
            if newOfferings.isEmpty {
                print("⚠️ No packages found in offering, using mock data")
                setupMockOfferings()
            } else {
                currentOfferings = newOfferings
                isSandboxMode = false
                print("✅ Loaded \(newOfferings.count) real offerings from RevenueCat")
            }
            
        } catch {
            print("❌ Failed to load offerings: \(error.localizedDescription)")
            // Don't show configuration errors to users in sandbox mode
            if !error.localizedDescription.contains("configuration") {
                purchaseError = error.localizedDescription
            }
            setupMockOfferings()
        }
        
        isLoading = false
    }
    
    func purchase(_ offering: SubscriptionOffering) async {
        isLoading = true
        purchaseError = nil
        
        // Handle mock offerings in sandbox mode
        if offering.isMockOffering && isSandboxMode {
            print("🧪 Simulating sandbox purchase for \(offering.tier.displayName)")
            
            // Simulate purchase delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Simulate successful purchase
            activeSubscription = offering.tier
            print("🎉 Mock purchase successful: \(offering.tier.displayName)")
            
            // Store the mock subscription locally for this session
            UserDefaults.standard.set(offering.tier.rawValue, forKey: "mock_subscription")
            
            isLoading = false
            return
        }
        
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, cannot purchase")
            purchaseError = "RevenueCat not configured"
            isLoading = false
            return
        }
        
        do {
            guard let package = offering.package else {
                print("❌ No package available for offering")
                purchaseError = "This is a demo offering. Configure products in RevenueCat dashboard to enable real purchases."
                isLoading = false
                return
            }
            
            let (_, _, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            if !userCancelled {
                checkSubscriptionStatus()
                print("🎉 Purchase successful: \(offering.tier.displayName)")
            } else {
                print("🚫 Purchase cancelled by user")
            }
            
        } catch {
            print("❌ Purchase failed: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        
        // Check for mock subscription first
        if isSandboxMode {
            if let mockSub = UserDefaults.standard.string(forKey: "mock_subscription"),
               let tier = SubscriptionTier(rawValue: mockSub) {
                activeSubscription = tier
                print("🔄 Restored mock subscription: \(tier.displayName)")
                isLoading = false
                return
            }
        }
        
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, cannot restore")
            purchaseError = "RevenueCat not configured"
            isLoading = false
            return
        }
        
        do {
            _ = try await Purchases.shared.restorePurchases()
            checkSubscriptionStatus()
            print("🔄 Purchases restored successfully")
            
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() {
        // Check for mock subscription first
        if isSandboxMode {
            if let mockSub = UserDefaults.standard.string(forKey: "mock_subscription"),
               let tier = SubscriptionTier(rawValue: mockSub) {
                activeSubscription = tier
                print("ℹ️ Mock subscription active: \(tier.displayName)")
                return
            }
        }
        
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, skipping subscription status check")
            activeSubscription = nil
            return
        }
        
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                guard let info = customerInfo, error == nil else {
                    print("❌ Failed to get customer info: \(error?.localizedDescription ?? "Unknown error")")
                    self?.activeSubscription = nil
                    return
                }
                
                // Check entitlements for active subscriptions
                if info.entitlements.active["standard"]?.isActive == true {
                    self?.activeSubscription = .standard
                    print("✅ Standard subscription active")
                } else if info.entitlements.active["ai_native"]?.isActive == true {
                    self?.activeSubscription = .aiNative
                    print("✅ AI Native subscription active")
                } else {
                    self?.activeSubscription = nil
                    print("ℹ️ No active subscription found")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupMockOfferings() {
        currentOfferings = [
            SubscriptionOffering(
                tier: .standard,
                productId: "com.myname.progress.standard.monthly",
                price: "£0.99",
                pricePerMonth: "£0.99",
                isPopular: false,
                isMockOffering: true,
                package: nil
            ),
            SubscriptionOffering(
                tier: .aiNative,
                productId: "com.myname.progress.ai_native.monthly",
                price: "£2.99",
                pricePerMonth: "£2.99",
                isPopular: true,
                isMockOffering: true,
                package: nil
            )
        ]
        print("📝 Using mock offerings - configure products in RevenueCat dashboard for real purchases")
        isSandboxMode = true
    }
    
    // MARK: - Computed Properties
    
    var hasActiveSubscription: Bool {
        activeSubscription != nil
    }
    
    var isStandardUser: Bool {
        activeSubscription == .standard
    }
    
    var isAIUser: Bool {
        activeSubscription == .aiNative
    }
    
    func isActiveTier(_ tier: SubscriptionTier) -> Bool {
        return activeSubscription == tier
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case noOfferingsFound
    case purchaseFailed
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .noOfferingsFound:
            return "No subscription offerings available"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .restoreFailed:
            return "Failed to restore purchases"
        }
    }
} 