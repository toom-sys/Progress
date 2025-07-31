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
        case plusAI = "plus_ai_monthly"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .plusAI: return "Plus AI"
            }
        }
        
        var monthlyPrice: String {
            switch self {
            case .standard: return "£1"
            case .plusAI: return "£3"
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
            case .plusAI:
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
            case .plusAI: return "Powered by artificial intelligence"
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
            
            // Look for packages by product identifier (matching StoreKit configuration)
            let standardPackage = currentOffering.availablePackages.first { package in
                package.storeProduct.productIdentifier == "com.tom.progress.standard.monthly"
            } ?? currentOffering.monthly
            
            let aiPackage = currentOffering.availablePackages.first { package in
                package.storeProduct.productIdentifier == "com.tom.progress.plus_ai.monthly"
            }
            
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
                    tier: .plusAI,
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
            
            // Provide helpful debug information for common configuration issues
            if error.localizedDescription.contains("configuration") || 
               error.localizedDescription.contains("OfferingsManager.Error") {
                print("🔧 Configuration Issue Detected:")
                print("   • Check that products are configured in RevenueCat dashboard")
                print("   • Product IDs should match: com.tom.progress.standard.monthly, com.tom.progress.plus_ai.monthly")
                print("   • Ensure offerings are set up with these products as packages")
                print("   • See Scripts/REVENUECAT_SETUP.md for detailed setup instructions")
            }
            
            // Don't show configuration errors to users in sandbox mode - use mock offerings instead
            if !error.localizedDescription.contains("configuration") && 
               !error.localizedDescription.contains("OfferingsManager.Error") {
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
                } else if info.entitlements.active["plus_ai"]?.isActive == true {
                    self?.activeSubscription = .plusAI
                    print("✅ Plus AI subscription active")
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
                productId: "com.tom.progress.standard.monthly",
                price: "£0.99",
                pricePerMonth: "£0.99",
                isPopular: false,
                isMockOffering: true,
                package: nil
            ),
            SubscriptionOffering(
                tier: .plusAI,
                productId: "com.tom.progress.plus_ai.monthly",
                price: "£2.99",
                pricePerMonth: "£2.99",
                isPopular: true,
                isMockOffering: true,
                package: nil
            )
        ]
        print("📝 Using mock offerings for development")
        print("💡 To enable real purchases:")
        print("   1. Configure products in RevenueCat dashboard (see Scripts/REVENUECAT_SETUP.md)")
        print("   2. Set up offerings with product IDs: com.tom.progress.standard.monthly, com.tom.progress.plus_ai.monthly")
        print("   3. Ensure products are approved in App Store Connect")
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
        activeSubscription == .plusAI
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