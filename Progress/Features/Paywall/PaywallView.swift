//
//  PaywallView.swift
//  Progress
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection

                        if subscriptionService.isSandboxMode {
                            sandboxBanner
                        }

                        if subscriptionService.isSubscribed {
                            activeSubscriptionBanner
                        }

                        proCard

                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Progress Pro")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .task {
            #if DEBUG && targetEnvironment(simulator)
            await subscriptionService.loadOfferings()
            await subscriptionService.checkSubscriptionStatus()
            #else
            try? await Task.sleep(nanoseconds: 100_000_000)
            await subscriptionService.loadOfferings()
            await subscriptionService.checkSubscriptionStatus()
            #endif
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("Unlock Everything")
                .font(.titleXL)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text("Every feature. Start free for 3 days.")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Sandbox Banner

    private var sandboxBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "flask.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sandbox Mode")
                    .font(.bodyLarge).fontWeight(.semibold)
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

    // MARK: - Active Subscription Banner

    private var activeSubscriptionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("You're on Progress Pro")
                    .font(.bodyLarge).fontWeight(.semibold)
                    .foregroundColor(.green)
                Text("All features unlocked")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Pro Card

    private var proCard: some View {
        VStack(spacing: 20) {
            // Plan selector
            planSelector

            Divider()

            // Feature list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(SubscriptionService.ServiceTier.pro.features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primary)
                            .font(.body)
                        Text(feature)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                }
            }

            // CTA
            purchaseButton

            if subscriptionService.isSandboxMode {
                Text("Simulator: purchases are simulated")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
            }

            if let error = subscriptionService.purchaseError,
               !subscriptionService.isSandboxMode {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(Color.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.4), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionService.Plan.allCases) { plan in
                if let offering = subscriptionService.offerings[plan] {
                    planOption(offering)
                }
            }
        }
    }

    private func planOption(_ offering: SubscriptionService.SubscriptionOffering) -> some View {
        let isSelected = subscriptionService.selectedPlan == offering.plan

        return Button {
            subscriptionService.selectedPlan = offering.plan
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .primary : .textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(offering.plan.title)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        if offering.plan == .annual {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.primary)
                                .clipShape(Capsule())
                        }
                    }

                    if offering.plan == .annual {
                        Text("\(offering.pricePerMonth)/mo · billed yearly")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("Billed monthly")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let original = offering.originalPrice {
                        Text(original)
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                            .strikethrough()
                    }
                    Text(offering.price)
                        .font(.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    Text(offering.plan.billingPeriodText)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(16)
            .background(isSelected ? Color.primary.opacity(0.08) : Color.backgroundSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.primary : Color.primary.opacity(0.15),
                            lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var ctaTitle: String {
        guard let offering = subscriptionService.currentOffering else { return "Subscribe" }
        if offering.hasTrial {
            return "Start \(offering.trialDays)-Day Free Trial"
        }
        return "Subscribe · \(offering.price)/\(offering.plan == .annual ? "yr" : "mo")"
    }

    @ViewBuilder
    private var purchaseButton: some View {
        let isCurrentPlan = subscriptionService.isSubscribed

        Button {
            if !isCurrentPlan {
                Task { await subscriptionService.purchase() }
            }
        } label: {
            HStack {
                if subscriptionService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.buttonPrimary).fontWeight(.semibold)
                } else if isCurrentPlan {
                    Image(systemName: "checkmark.circle.fill").font(.title3)
                    Text("Current Plan")
                        .font(.buttonPrimary).fontWeight(.semibold)
                } else {
                    Text(ctaTitle)
                        .font(.buttonPrimary).fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(isCurrentPlan ? .textSecondary : .white)
            .background(isCurrentPlan ? Color.backgroundSecondary : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(subscriptionService.isLoading || isCurrentPlan)
    }

    // MARK: - Footer

    private var renewalNote: String {
        guard let offering = subscriptionService.currentOffering else {
            return "• Subscription auto-renews until cancelled"
        }
        let period = offering.plan == .annual ? "yearly" : "monthly"
        if offering.hasTrial {
            return "• Auto-renews \(period) at \(offering.price) after the free trial"
        }
        return "• Auto-renews \(period) at \(offering.price) until cancelled"
    }

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await subscriptionService.restorePurchases() }
            }
            .font(.body)
            .foregroundColor(.textSecondary)
            .disabled(subscriptionService.isLoading)

            VStack(spacing: 6) {
                Text("• Cancel anytime in Settings")
                Text(renewalNote)
                HStack(spacing: 20) {
                    Button("Terms of Service") {}
                        .foregroundColor(.textSecondary)
                    Button("Privacy Policy") {}
                        .foregroundColor(.textSecondary)
                }
            }
            .font(.caption)
            .foregroundColor(.textTertiary)
            .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview("Paywall") {
    PaywallView()
        .environmentObject(SubscriptionService())
}
