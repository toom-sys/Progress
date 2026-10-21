//
//  SubscriptionService.swift
//  Progress
//

import Foundation
import Combine
import RevenueCat

/// Service for managing the "Progress Pro" subscription via RevenueCat.
/// One membership, three prices: yearly, monthly, and weekly.
@MainActor
class SubscriptionService: ObservableObject {

    // MARK: - Published Properties

    /// Offerings keyed by plan. Populated from RevenueCat, or with mock data in sandbox.
    @Published var offerings: [Plan: SubscriptionOffering] = [:]
    /// The plan the user currently has selected in the paywall. Annual is default (best value).
    @Published var selectedPlan: Plan = .annual
    @Published var isSubscribed: Bool = false
    /// The price the member is actually on. Nil when they are not subscribed.
    @Published var activePlan: Plan?
    @Published var isLoading = false
    @Published var purchaseError: String? = nil
    @Published var isSandboxMode = true

    private var customerInfoTask: Task<Void, Never>?

    // MARK: - Plan

    /// RevenueCat entitlement that unlocks Progress Pro.
    static let entitlementID = "progress_train_and_log_pro"

    /// The three prices for the single Progress Pro membership.
    /// Yearly is first so the paywall leads with it.
    enum Plan: String, CaseIterable, Identifiable {
        case annual
        case monthly
        case weekly

        var id: String { rawValue }

        /// RevenueCat Test Store identifier, then the App Store product ID.
        var productIds: [String] {
            switch self {
            case .annual: return ["yearly", "com.tom.progress.pro.annual"]
            case .monthly: return ["monthly", "com.tom.progress.pro.monthly"]
            case .weekly: return ["weekly", "com.tom.progress.pro.weekly"]
            }
        }

        var productId: String { productIds[0] }

        var title: String {
            switch self {
            case .annual: return "Yearly"
            case .monthly: return "Monthly"
            case .weekly: return "Weekly"
            }
        }

        var billingPeriodText: String {
            switch self {
            case .annual: return "per year"
            case .monthly: return "per month"
            case .weekly: return "per week"
            }
        }

        var renewalAdverb: String {
            switch self {
            case .annual: return "yearly"
            case .monthly: return "monthly"
            case .weekly: return "weekly"
            }
        }

        var priceSuffix: String {
            switch self {
            case .annual: return "yr"
            case .monthly: return "mo"
            case .weekly: return "wk"
            }
        }

        /// Free-trial length for the plan (0 = no trial). The trial is on the yearly price only.
        var trialDays: Int {
            switch self {
            case .annual: return 3
            case .monthly, .weekly: return 0
            }
        }

        func detailLine(pricePerMonth: String) -> String {
            switch self {
            case .annual: return "\(pricePerMonth)/mo · billed yearly"
            case .monthly: return "Billed monthly"
            case .weekly: return "Billed weekly"
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
                "Apple Health step tracking",
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
        /// The full price for the billing period, e.g. "£49.99" (yearly) or "£4.99" (weekly).
        let price: String
        /// Normalised per-month price for the yearly plan. Equals `price` for the other plans.
        let pricePerMonth: String
        let hasTrial: Bool
        let trialDays: Int
        let isMockOffering: Bool
        let package: Package?

        var id: String { plan.rawValue }
    }

    // MARK: - Initialization

    init() {
        setupMockOfferings()
        startObservingCustomerInfo()
    }

    // MARK: - Convenience Accessors

    /// The offering matching the currently selected plan.
    var currentOffering: SubscriptionOffering? {
        offerings[selectedPlan]
    }

    /// Short membership label for the Journey chip and Settings.
    var membershipLabel: String {
        guard isSubscribed else { return "See plans" }
        return activePlan?.title ?? "Subscribed"
    }

    /// Billing line for the active price, when one is loaded.
    var activePlanDetail: String? {
        guard let activePlan else { return nil }
        if let offering = offerings[activePlan] {
            return offering.plan.detailLine(pricePerMonth: offering.pricePerMonth)
        }
        return "Billed \(activePlan.renewalAdverb)"
    }

    // MARK: - Public Methods

    func loadOfferings() async {
        isLoading = true
        purchaseError = nil

        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, using mock offerings")
            setupMockOfferings()
            isLoading = false
            return
        }

        startObservingCustomerInfo()

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
                guard let pkg = package(for: plan, in: current) else { continue }
                loaded[plan] = makeOffering(for: plan, from: pkg)
            }

            if loaded.isEmpty {
                print("⚠️ No Pro packages found, using mock data")
                setupMockOfferings()
            } else {
                offerings = loaded
                isSandboxMode = false
                if offerings[selectedPlan] == nil {
                    selectedPlan = Plan.allCases.first { offerings[$0] != nil } ?? .annual
                }
                print("✅ Loaded \(loaded.count) Pro price(s) from RevenueCat")
                await checkSubscriptionStatus()
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
            activePlan = offering.plan
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
               let plan = Plan(rawValue: mockSub) {
                isSubscribed = true
                activePlan = plan
                print("🔄 Restored mock subscription: Progress Pro (\(plan.title))")
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

    /// Presents Apple's code sheet. Codes are created in App Store Connect
    /// against the yearly product, so a redeemed code starts that price.
    func redeemAnnualCode() {
        purchaseError = nil
        guard Purchases.isConfigured else {
            purchaseError = "Annual codes redeem through the App Store once subscriptions are connected."
            return
        }
        Purchases.shared.presentCodeRedemptionSheet()
    }

    func checkSubscriptionStatus() async {
        if isSandboxMode {
            if let mockSub = UserDefaults.standard.string(forKey: "mock_subscription"),
               let plan = Plan(rawValue: mockSub) {
                isSubscribed = true
                activePlan = plan
                print("ℹ️ Mock subscription active: Progress Pro (\(plan.title))")
                return
            }
        }

        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, skipping subscription status check")
            return
        }

        do {
            let info = try await Purchases.shared.customerInfo(fetchPolicy: .cachedOrFetched)
            apply(info)
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
        if plan == .annual,
           let monthly = product.pricePerMonth,
           let formatted = product.priceFormatter?.string(from: monthly) {
            pricePerMonth = formatted
        } else {
            pricePerMonth = product.localizedPriceString
        }

        return SubscriptionOffering(
            plan: plan,
            productId: product.productIdentifier,
            price: product.localizedPriceString,
            pricePerMonth: pricePerMonth,
            hasTrial: hasTrial,
            trialDays: trialDays,
            isMockOffering: false,
            package: pkg
        )
    }

    /// Updates subscription state from RevenueCat customer info.
    /// An inactive result is ignored while mock offerings are in use, so a
    /// failed store fetch does not clear a simulated purchase.
    func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements.active[Self.entitlementID]
        guard entitlement?.isActive == true else {
            if !isSandboxMode {
                isSubscribed = false
                activePlan = nil
                print("ℹ️ No active \(Self.entitlementID) entitlement")
            }
            return
        }

        isSubscribed = true
        isSandboxMode = false
        activePlan = plan(matching: entitlement?.productIdentifier)
            ?? Plan.allCases.first { plan in
                plan.productIds.contains { info.activeSubscriptions.contains($0) }
            }
        print("✅ Progress Pro subscription active (\(activePlan?.title ?? "price unknown"))")
    }

    private func startObservingCustomerInfo() {
        guard Purchases.isConfigured, customerInfoTask == nil else { return }
        customerInfoTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
    }

    private func plan(matching productId: String?) -> Plan? {
        guard let productId else { return nil }
        return Plan.allCases.first { $0.productIds.contains(productId) }
    }

    private func package(for plan: Plan, in offering: Offering) -> Package? {
        if let match = offering.availablePackages.first(where: {
            plan.productIds.contains($0.storeProduct.productIdentifier)
        }) {
            return match
        }
        switch plan {
        case .annual: return offering.annual
        case .monthly: return offering.monthly
        case .weekly: return offering.weekly
        }
    }

    private func setupMockOfferings() {
        offerings = [
            .annual: SubscriptionOffering(
                plan: .annual,
                productId: Plan.annual.productId,
                price: "£49.99",
                pricePerMonth: "£4.17",
                hasTrial: true,
                trialDays: 3,
                isMockOffering: true,
                package: nil
            ),
            .monthly: SubscriptionOffering(
                plan: .monthly,
                productId: Plan.monthly.productId,
                price: "£9.99",
                pricePerMonth: "£9.99",
                hasTrial: false,
                trialDays: 0,
                isMockOffering: true,
                package: nil
            ),
            .weekly: SubscriptionOffering(
                plan: .weekly,
                productId: Plan.weekly.productId,
                price: "£4.99",
                pricePerMonth: "£4.99",
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
