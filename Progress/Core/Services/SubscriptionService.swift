//
//  SubscriptionService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

// TODO: Uncomment when RevenueCat is added
// import RevenueCat

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
        
        // TODO: Replace with actual RevenueCat Package when added
        // let package: Package
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
            // TODO: Uncomment when RevenueCat is added
            /*
            let offerings = try await Purchases.shared.offerings()
            
            guard let currentOffering = offerings.current else {
                throw SubscriptionError.noOfferingsFound
            }
            
            let standardPackage = currentOffering.monthly
            let aiPackage = currentOffering.package(identifier: "ai_native_monthly")
            
            var newOfferings: [SubscriptionOffering] = []
            
            if let standard = standardPackage {
                newOfferings.append(SubscriptionOffering(
                    tier: .standard,
                    productId: standard.storeProduct.productIdentifier,
                    price: standard.storeProduct.localizedPriceString,
                    pricePerMonth: standard.storeProduct.localizedPriceString,
                    isPopular: false
                ))
            }
            
            if let ai = aiPackage {
                newOfferings.append(SubscriptionOffering(
                    tier: .aiNative,
                    productId: ai.storeProduct.productIdentifier,
                    price: ai.storeProduct.localizedPriceString,
                    pricePerMonth: ai.storeProduct.localizedPriceString,
                    isPopular: true
                ))
            }
            
            currentOfferings = newOfferings
            */
            
            // Mock implementation for now
            setupMockOfferings()
            
        } catch {
            purchaseError = error.localizedDescription
            setupMockOfferings()
        }
        
        isLoading = false
    }
    
    func purchase(_ offering: SubscriptionOffering) async {
        isLoading = true
        purchaseError = nil
        
        do {
            // TODO: Uncomment when RevenueCat is added
            /*
            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: offering.package)
            
            if !userCancelled {
                await checkSubscriptionStatus()
            }
            */
            
            // Mock successful purchase for now
            activeSubscription = offering.tier
            print("🎉 Mock purchase successful: \(offering.tier.displayName)")
            
        } catch {
            purchaseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        
        do {
            // TODO: Uncomment when RevenueCat is added
            /*
            let customerInfo = try await Purchases.shared.restorePurchases()
            await checkSubscriptionStatus()
            */
            
            print("🔄 Mock restore purchases")
            
        } catch {
            purchaseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() {
        // TODO: Uncomment when RevenueCat is added
        /*
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                guard let customerInfo = customerInfo, error == nil else {
                    self?.activeSubscription = nil
                    return
                }
                
                if customerInfo.entitlements.active["standard"]?.isActive == true {
                    self?.activeSubscription = .standard
                } else if customerInfo.entitlements.active["ai_native"]?.isActive == true {
                    self?.activeSubscription = .aiNative
                } else {
                    self?.activeSubscription = nil
                }
            }
        }
        */
        
        // Mock check - no active subscription for now
        activeSubscription = nil
    }
    
    // MARK: - Helper Methods
    
    private func setupMockOfferings() {
        currentOfferings = [
            SubscriptionOffering(
                tier: .standard,
                productId: "com.myname.progress.standard.monthly",
                price: "£0.99",
                pricePerMonth: "£0.99",
                isPopular: false
            ),
            SubscriptionOffering(
                tier: .aiNative,
                productId: "com.myname.progress.ai_native.monthly",
                price: "£2.99",
                pricePerMonth: "£2.99",
                isPopular: true
            )
        ]
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