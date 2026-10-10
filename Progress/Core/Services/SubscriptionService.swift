//
//  SubscriptionService.swift
//  Progress
//
//  Created by Progress Team
//

import Foundation
import Combine

import RevenueCat

/// Catalogue prices for the single Progress membership.
/// Week £4.99, month £9.99, year £49.99. The year is the plan the paywall selects.
enum MembershipPricing {
    static let weekly = Decimal(string: "4.99")!
    static let monthly = Decimal(string: "9.99")!
    static let yearly = Decimal(string: "49.99")!

    static var costOfPayingMonthlyForAYear: Decimal {
        monthly * 12
    }

    static var yearlyEquivalentPerMonth: Decimal {
        yearly / 12
    }

    static func price(for period: MembershipPeriod) -> Decimal {
        switch period {
        case .weekly: weekly
        case .monthly: monthly
        case .yearly: yearly
        }
    }

    static func format(_ value: Decimal, currencyCode: String = "GBP", locale: Locale = Locale(identifier: "en_GB")) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

enum MembershipPeriod: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    static let paywallOrder: [MembershipPeriod] = [.yearly, .monthly, .weekly]

    var productIdentifier: String {
        switch self {
        case .weekly: "com.tom.progress.member.weekly"
        case .monthly: "com.tom.progress.member.monthly"
        case .yearly: "com.tom.progress.member.yearly"
        }
    }

    var displayName: String {
        switch self {
        case .weekly: String(localized: "subscription.weekly")
        case .monthly: String(localized: "subscription.monthly")
        case .yearly: String(localized: "subscription.yearly")
        }
    }

    var cadence: String {
        switch self {
        case .weekly: String(localized: "paywall.a_week")
        case .monthly: String(localized: "paywall.a_month")
        case .yearly: String(localized: "paywall.a_year")
        }
    }

    var renewalAdverb: String {
        switch self {
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .yearly: "yearly"
        }
    }

    var isBestValue: Bool { self == .yearly }
}

struct MembershipOffering: Identifiable {
    let period: MembershipPeriod
    let productId: String
    let price: Decimal
    let localizedPrice: String
    let currencyCode: String
    let isMockOffering: Bool
    let package: Package?

    var id: String { productId }

    func formatted(_ value: Decimal) -> String {
        MembershipPricing.format(value, currencyCode: currencyCode)
    }
}

/// Service for the single Progress membership, billed weekly, monthly, or yearly.
@MainActor
class SubscriptionService: ObservableObject {

    static let entitlementID = "member"

    @Published var currentOfferings: [MembershipOffering] = []
    @Published var activePeriod: MembershipPeriod?
    @Published var isMember = false
    @Published var isLoading = false
    @Published var purchaseError: String?
    @Published var isSandboxMode = false

    private let mockSubscriptionKey = "mock_membership_period"

    init() {
        setupMockOfferings()
    }

    var hasActiveSubscription: Bool { isMember }

    var membershipLabel: String {
        if let activePeriod {
            return activePeriod.displayName
        }
        return isMember
            ? String(localized: "subscription.member")
            : String(localized: "subscription.subscribe")
    }

    func offering(for period: MembershipPeriod) -> MembershipOffering? {
        currentOfferings.first { $0.period == period }
    }

    func loadOfferings() async {
        isLoading = true
        purchaseError = nil

        #if DEBUG && targetEnvironment(simulator)
        setupMockOfferings()
        isLoading = false
        return
        #else
        guard Purchases.isConfigured else {
            setupMockOfferings()
            isLoading = false
            return
        }
        #endif

        do {
            let offerings = try await Purchases.shared.offerings()
            guard let currentOffering = offerings.current else {
                setupMockOfferings()
                isLoading = false
                return
            }

            let loaded = MembershipPeriod.paywallOrder.compactMap { period in
                self.makeOffering(period, from: currentOffering)
            }

            if loaded.isEmpty {
                setupMockOfferings()
            } else {
                currentOfferings = loaded
                isSandboxMode = false
            }
        } catch {
            if !error.localizedDescription.contains("configuration") &&
                !error.localizedDescription.contains("OfferingsManager.Error") {
                purchaseError = error.localizedDescription
            }
            setupMockOfferings()
        }

        isLoading = false
    }

    func purchase(_ offering: MembershipOffering) async {
        isLoading = true
        purchaseError = nil

        if offering.isMockOffering && isSandboxMode {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            grant(offering.period)
            UserDefaults.standard.set(offering.period.rawValue, forKey: mockSubscriptionKey)
            isLoading = false
            return
        }

        guard Purchases.isConfigured else {
            purchaseError = "RevenueCat not configured"
            isLoading = false
            return
        }

        do {
            guard let package = offering.package else {
                purchaseError = "This plan is not available to purchase yet."
                isLoading = false
                return
            }

            let (_, _, userCancelled) = try await Purchases.shared.purchase(package: package)
            if !userCancelled {
                checkSubscriptionStatus()
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        purchaseError = nil

        if isSandboxMode {
            if let stored = UserDefaults.standard.string(forKey: mockSubscriptionKey),
               let period = MembershipPeriod(rawValue: stored) {
                grant(period)
            }
            isLoading = false
            return
        }

        guard Purchases.isConfigured else {
            purchaseError = "RevenueCat not configured"
            isLoading = false
            return
        }

        do {
            _ = try await Purchases.shared.restorePurchases()
            checkSubscriptionStatus()
        } catch {
            purchaseError = error.localizedDescription
        }

        isLoading = false
    }

    func checkSubscriptionStatus() {
        if isSandboxMode {
            if let stored = UserDefaults.standard.string(forKey: mockSubscriptionKey),
               let period = MembershipPeriod(rawValue: stored) {
                grant(period)
            }
            return
        }

        guard Purchases.isConfigured else {
            clearMembership()
            return
        }

        Task {
            do {
                let info = try await Purchases.shared.customerInfo()
                apply(customerInfo: info)
            } catch {
                clearMembership()
            }
        }
    }

    func isCurrentPeriod(_ period: MembershipPeriod) -> Bool {
        isMember && activePeriod == period
    }

    private func grant(_ period: MembershipPeriod) {
        activePeriod = period
        isMember = true
    }

    private func clearMembership() {
        activePeriod = nil
        isMember = false
    }

    private func apply(customerInfo: CustomerInfo) {
        let active = customerInfo.entitlements.active
        let member = active[Self.entitlementID]
        let legacy = active["standard"] ?? active["plus_ai"]
        guard let entitlement = member ?? legacy, entitlement.isActive else {
            clearMembership()
            return
        }

        isMember = true
        activePeriod = MembershipPeriod.allCases.first {
            $0.productIdentifier == entitlement.productIdentifier
        }
    }

    private func makeOffering(_ period: MembershipPeriod, from offering: Offering) -> MembershipOffering? {
        let package = offering.availablePackages.first {
            $0.storeProduct.productIdentifier == period.productIdentifier
        } ?? offering.availablePackages.first { candidate in
            switch period {
            case .weekly: candidate.packageType == .weekly
            case .monthly: candidate.packageType == .monthly
            case .yearly: candidate.packageType == .annual
            }
        }

        guard let package else { return nil }

        return MembershipOffering(
            period: period,
            productId: package.storeProduct.productIdentifier,
            price: package.storeProduct.price,
            localizedPrice: package.storeProduct.localizedPriceString,
            currencyCode: package.storeProduct.priceFormatter?.currencyCode ?? "GBP",
            isMockOffering: false,
            package: package
        )
    }

    private func setupMockOfferings() {
        currentOfferings = MembershipPeriod.paywallOrder.map { period in
            let price = MembershipPricing.price(for: period)
            return MembershipOffering(
                period: period,
                productId: period.productIdentifier,
                price: price,
                localizedPrice: MembershipPricing.format(price),
                currencyCode: "GBP",
                isMockOffering: true,
                package: nil
            )
        }
        isSandboxMode = true
    }
}
