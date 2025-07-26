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
                    "✓ Unlimited workout tracking",
                    "✓ Nutrition logging with search",
                    "✓ Progress charts and analytics",
                    "✓ CloudKit sync across devices",
                    "✓ Export your data anytime"
                ]
            case .aiNative:
                return [
                    "✓ Everything in Standard",
                    "✓ AI-powered workout generation",
                    "✓ Smart nutrition recommendations", 
                    "✓ Camera food logging with AI",
                    "✓ Personalized insights engine",
                    "✓ Priority customer support"
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
        
        let package: Package?
    }
    
    // MARK: - Initialization
    
    init() {
        setupMockOfferings()
        checkSubscriptionStatus()
    }
    
    // MARK: - Public Methods
    
    func loadOfferings() async {
        isLoading = true
        purchaseError = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            
            guard let currentOffering = offerings.current else {
                print("⚠️ No current offering found, using mock data")
                setupMockOfferings()
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
                    package: ai
                ))
            }
            
            // If no packages found, use mock data
            if newOfferings.isEmpty {
                print("⚠️ No packages found in offering, using mock data")
                setupMockOfferings()
            } else {
                currentOfferings = newOfferings
                print("✅ Loaded \(newOfferings.count) offerings from RevenueCat")
            }
            
        } catch {
            print("❌ Failed to load offerings: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
            setupMockOfferings()
        }
        
        isLoading = false
    }
    
    func purchase(_ offering: SubscriptionOffering) async {
        isLoading = true
        purchaseError = nil
        
        do {
            guard let package = offering.package else {
                print("❌ No package available for offering")
                purchaseError = "Package not available"
                return
            }
            
            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
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
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            checkSubscriptionStatus()
            print("🔄 Purchases restored successfully")
            
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                guard let customerInfo = customerInfo, error == nil else {
                    print("❌ Failed to get customer info: \(error?.localizedDescription ?? "Unknown error")")
                    self?.activeSubscription = nil
                    return
                }
                
                // Check entitlements for active subscriptions
                if customerInfo.entitlements.active["standard"]?.isActive == true {
                    self?.activeSubscription = .standard
                    print("✅ Standard subscription active")
                } else if customerInfo.entitlements.active["ai_native"]?.isActive == true {
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
                package: nil
            ),
            SubscriptionOffering(
                tier: .aiNative,
                productId: "com.myname.progress.ai_native.monthly",
                price: "£2.99",
                pricePerMonth: "£2.99",
                isPopular: true,
                package: nil
            )
        ]
        print("📝 Using mock offerings - configure products in RevenueCat dashboard")
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