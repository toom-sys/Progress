//
//  SubscriptionService.swift
//  Progress
//

import Foundation
import Combine
import RevenueCat

/// Service for managing the "Progress Pro" subscription (annual + monthly) via RevenueCat.
@MainActor
class SubscriptionService: ObservableObject {

    // MARK: - Published Properties

    /// Offerings keyed by plan. Populated from RevenueCat, or with mock data in sandbox.
    @Published var offerings: [Plan: SubscriptionOffering] = [:]
    /// The plan the user currently has selected in the paywall. Annual is default (best value).
    @Published var selectedPlan: Plan = .annual
    @Published var isSubscribed: Bool = false
    @Published var isLoading = false
    @Published var purchaseError: String? = nil
    @Published var isSandboxMode = true

    // MARK: - Plan

    /// The two purchasable billing plans for Progress Pro.
    enum Plan: String, CaseIterable, Identifiable {
        case annual
        case monthly

        var id: String { rawValue }

        var productId: String {
            switch self {
            case .annual: return "com.tom.progress.pro.annual"
            case .monthly: return "com.tom.progress.pro.monthly"
            }
        }

        var title: String {
            switch self {
            case .annual: return "Annual"
            case .monthly: return "Monthly"
            }
        }

        var billingPeriodText: String {
            switch self {
            case .annual: return "per year"
            case .monthly: return "per month"
            }
        }

        /// Free-trial length for the plan (0 = no trial).
        var trialDays: Int {
            switch self {
            case .annual: return 3
            case .monthly: return 0
            }
        }
    }

    // MARK: - Subscription Tier

    enum ServiceTier: String, CaseIterable {
        case pro = "pro"

        var displayName: String { "Progress Pro" }

        var features: [String] {
            [
                "Unlimited workout tracking",
                "Nutrition logging and search",
                "AI-powered workout generation",
                "Camera food logging with AI",
                "Progress charts and analytics",
                "Smart nutrition recommendations",
                "CloudKit sync across devices",
                "Personalised insights engine",
                "Export your data anytime"
            ]
        }

        var tagline: String { "Everything you need to crush your goals" }
    }

    // MARK: - Offering Model

    struct SubscriptionOffering: Identifiable {
        let plan: Plan
        let productId: String
        /// The full price for the billing period, e.g. "£35.00" (annual) or "£4.99" (monthly).
        let price: String
        /// Normalised per-month price, e.g. "£2.92" for the annual plan.
        let pricePerMonth: String
        /// Original (pre-sale) price shown struck through, e.g. "£49.00". Nil when not on sale.
        let originalPrice: String?
        let hasTrial: Bool
        let trialDays: Int
        let isMockOffering: Bool
        let package: Package?

        var id: String { plan.rawValue }
    }

    // MARK: - Initialization

    init() {
        setupMockOfferings()
    }

    // MARK: - Convenience Accessors

    /// The offering matching the currently selected plan.
    var currentOffering: SubscriptionOffering? {
        offerings[selectedPlan]
    }

    // MARK: - Public Methods

    func loadOfferings() async {
        isLoading = true
        purchaseError = nil

        #if DEBUG && targetEnvironment(simulator)
        print("🧪 Simulator mode: Using mock offerings for sandbox testing")
        setupMockOfferings()
        isLoading = false
        return
        #else
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, using mock offerings")
            setupMockOfferings()
            isLoading = false
            return
        }
        #endif

        do {
            let offeringsResponse = try await Purchases.shared.offerings()

            guard let current = offeringsResponse.current else {
                print("⚠️ No current offering found, using mock data")
                setupMockOfferings()
                isLoading = false
                return
            }

            var loaded: [Plan: SubscriptionOffering] = [:]

            for plan in Plan.allCases {
                let package = current.availablePackages.first {
                    $0.storeProduct.productIdentifier == plan.productId
                } ?? (plan == .annual ? current.annual : current.monthly)

                guard let pkg = package else { continue }
                loaded[plan] = makeOffering(for: plan, from: pkg)
            }

            if loaded.isEmpty {
                print("⚠️ No Pro packages found, using mock data")
                setupMockOfferings()
            } else {
                offerings = loaded
                isSandboxMode = false
                // Keep a sensible selection if the previously selected plan is unavailable.
                if offerings[selectedPlan] == nil {
                    selectedPlan = offerings[.annual] != nil ? .annual : .monthly
                }
                print("✅ Loaded \(loaded.count) Pro offering(s) from RevenueCat")
            }
        } catch {
            print("❌ Failed to load offerings: \(error.localizedDescription)")
            if !error.localizedDescription.contains("configuration") &&
               !error.localizedDescription.contains("OfferingsManager.Error") {
                purchaseError = error.localizedDescription
            }
            setupMockOfferings()
        }

        isLoading = false
    }

    func purchase() async {
        guard let offering = currentOffering else { return }
        isLoading = true
        purchaseError = nil

        if offering.isMockOffering && isSandboxMode {
            print("🧪 Simulating sandbox purchase for Progress Pro (\(offering.plan.title))")
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isSubscribed = true
            UserDefaults.standard.set(offering.plan.rawValue, forKey: "mock_subscription")
            print("🎉 Mock purchase successful: Progress Pro (\(offering.plan.title))")
            isLoading = false
            return
        }

        guard Purchases.isConfigured else {
            purchaseError = "RevenueCat not configured"
            isLoading = false
            return
        }

        guard let package = offering.package else {
            purchaseError = "This is a demo offering. Configure products in RevenueCat to enable real purchases."
            isLoading = false
            return
        }

        do {
            let (_, _, userCancelled) = try await Purchases.shared.purchase(package: package)
            if !userCancelled {
                await checkSubscriptionStatus()
                print("🎉 Purchase successful: Progress Pro (\(offering.plan.title))")
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

        if isSandboxMode {
            if let mockSub = UserDefaults.standard.string(forKey: "mock_subscription"),
               Plan(rawValue: mockSub) != nil {
                isSubscribed = true
                print("🔄 Restored mock subscription: Progress Pro")
                isLoading = false
                return
            }
        }

        guard Purchases.isConfigured else {
            purchaseError = "RevenueCat not configured"
            isLoading = false
            return
        }

        do {
            _ = try await Purchases.shared.restorePurchases()
            await checkSubscriptionStatus()
            print("🔄 Purchases restored successfully")
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
        }

        isLoading = false
    }

    func checkSubscriptionStatus() async {
        if isSandboxMode {
            if let mockSub = UserDefaults.standard.string(forKey: "mock_subscription"),
               Plan(rawValue: mockSub) != nil {
                isSubscribed = true
                print("ℹ️ Mock subscription active: Progress Pro")
                return
            }
        }

        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, skipping subscription status check")
            return
        }

        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: .cachedOrFetched)
            if info.entitlements.active["pro"]?.isActive == true {
                isSubscribed = true
                print("✅ Progress Pro subscription active")
            } else {
                isSubscribed = false
                print("ℹ️ No active subscription found")
            }
        } catch {
            // Network unavailable or transient error — keep the existing isSubscribed
            // value so a paid user is not locked out while offline.
            print("⚠️ Could not verify subscription status (offline?): \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func makeOffering(for plan: Plan, from pkg: Package) -> SubscriptionOffering {
        let product = pkg.storeProduct
        let hasTrial = product.introductoryDiscount?.paymentMode == .freeTrial
        let trialDays = hasTrial ? plan.trialDays : 0

        let pricePerMonth: String
        switch plan {
        case .annual:
            // Show the annual price normalised per month using the product's own currency formatter.
            if let monthly = product.pricePerMonth,
               let formatted = product.priceFormatter?.string(from: monthly) {
                pricePerMonth = formatted
            } else {
                pricePerMonth = product.localizedPriceString
            }
        case .monthly:
            pricePerMonth = product.localizedPriceString
        }

        return SubscriptionOffering(
            plan: plan,
            productId: product.productIdentifier,
            price: product.localizedPriceString,
            pricePerMonth: pricePerMonth,
            originalPrice: plan == .annual ? "£49.00" : nil,
            hasTrial: hasTrial,
            trialDays: trialDays,
            isMockOffering: false,
            package: pkg
        )
    }

    private func setupMockOfferings() {
        offerings = [
            .annual: SubscriptionOffering(
                plan: .annual,
                productId: Plan.annual.productId,
                price: "£35.00",
                pricePerMonth: "£2.92",
                originalPrice: "£49.00",
                hasTrial: true,
                trialDays: 3,
                isMockOffering: true,
                package: nil
            ),
            .monthly: SubscriptionOffering(
                plan: .monthly,
                productId: Plan.monthly.productId,
                price: "£4.99",
                pricePerMonth: "£4.99",
                originalPrice: nil,
                hasTrial: false,
                trialDays: 0,
                isMockOffering: true,
                package: nil
            )
        ]
        print("📝 Using mock Pro offerings for development")
        isSandboxMode = true
    }

    // MARK: - Legacy Compatibility

    /// Retained so existing call sites (isAIUser / isStandardUser) that have
    /// not been migrated yet continue to compile. Both map to `isSubscribed`.
    var hasActiveSubscription: Bool { isSubscribed }
    var isAIUser: Bool { isSubscribed }
    var isStandardUser: Bool { isSubscribed }

    /// Legacy offering list for any remaining ForEach call sites.
    var currentOfferings: [SubscriptionOffering] {
        Plan.allCases.compactMap { offerings[$0] }
    }

    /// Legacy active subscription property.
    var activeSubscription: ServiceTier? {
        isSubscribed ? .pro : nil
    }

    func isActiveTier(_ tier: ServiceTier) -> Bool { isSubscribed }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case noOfferingFound
    case purchaseFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .noOfferingFound: return "No subscription offering available"
        case .purchaseFailed: return "Purchase failed. Please try again."
        case .restoreFailed: return "Failed to restore purchases"
        }
    }
}
