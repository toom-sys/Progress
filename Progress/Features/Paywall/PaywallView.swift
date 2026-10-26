//
//  PaywallView.swift
//  Progress
//

import SwiftUI

/// Progress Pro paywall. Embedded at the end of onboarding, and presented
/// from the subscription gate, Settings, and locked features.
struct PaywallView: View {
    /// Onboarding already draws the page background, back button, and progress.
    var isEmbedded: Bool = false
    var onPurchased: () -> Void = {}
    var onSkip: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var presentedLegalDocument: LegalDocument?
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        VStack(spacing: 0) {
            if !isEmbedded {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(OnboardingPalette.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(OnboardingPalette.optionFill))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.top, 12)
                .padding(.horizontal, 24)
            }

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 14) {
                        Text("ONE MEMBERSHIP")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(0.5)
                            .foregroundColor(OnboardingPalette.onInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(OnboardingPalette.ink))
                            .padding(.top, isEmbedded ? 20 : 8)

                        (Text("Start free.\nKeep the ")
                            .foregroundColor(OnboardingPalette.ink)
                         + Text("momentum")
                            .foregroundColor(Color.brand)
                         + Text(".")
                            .foregroundColor(OnboardingPalette.ink))
                            .font(.system(size: 29, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineSpacing(1)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .frame(maxWidth: .infinity)

                    Text("Yearly, monthly, or weekly. Same access on each.")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(OnboardingPalette.muted)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        ForEach(SubscriptionService.Plan.allCases) { plan in
                            if let offering = subscriptionService.offerings[plan] {
                                SubscriptionPlanCard(
                                    offering: offering,
                                    isSelected: subscriptionService.selectedPlan == plan
                                ) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        subscriptionService.selectedPlan = plan
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)

                    VStack(spacing: 10) {
                        Button("Redeem an annual code") {
                            subscriptionService.redeemAnnualCode()
                        }

                        Button(isRestoring ? "Restoring..." : "Restore purchases") {
                            restore()
                        }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OnboardingPalette.ink)
                    .disabled(isPurchasing || isRestoring)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("WHAT YOU GET")
                            .font(.system(size: 11.5, weight: .heavy))
                            .tracking(0.4)
                            .foregroundColor(OnboardingPalette.muted)
                            .padding(.bottom, 8)

                        ForEach(SubscriptionService.ServiceTier.pro.features, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(Color.brand)
                                Text(feature)
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundColor(OnboardingPalette.ink)
                                Spacer()
                            }
                            .padding(.vertical, 9)
                            .overlay(Rectangle().fill(OnboardingPalette.line).frame(height: 1), alignment: .top)
                        }
                    }

                    if let error = subscriptionService.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button("Maybe later") {
                        skip()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OnboardingPalette.muted)
                    .disabled(isPurchasing || isRestoring)

                    Text("Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Cancel anytime in Settings → Subscriptions.")
                        .font(.system(size: 11.5))
                        .foregroundColor(OnboardingPalette.muted)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        Button("Terms of Service") {
                            presentedLegalDocument = .terms
                        }
                        Button("Privacy Policy") {
                            presentedLegalDocument = .privacy
                        }
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(OnboardingPalette.ink)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }

            Button(action: purchase) {
                Text(purchaseButtonTitle)
            }
            .buttonStyle(OnboardingPrimaryButtonStyle(isEnabled: canPurchase))
            .disabled(!canPurchase)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, isEmbedded ? 34 : 12)
            .accessibilityLabel(purchaseButtonTitle)
            .accessibilityHint("Subscribe to Progress Pro")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if !isEmbedded {
                OnboardingBackground()
            }
        }
        .task {
            let needsLivePrices = subscriptionService.offerings.values.allSatisfy(\.isMockOffering)
            if needsLivePrices || subscriptionService.offerings.isEmpty {
                await subscriptionService.loadOfferings()
            }
        }
        .onChange(of: subscriptionService.isSubscribed) { _, isSubscribed in
            guard isSubscribed, !isPurchasing, !isRestoring else { return }
            finishPurchase()
        }
        .sheet(item: $presentedLegalDocument) { document in
            NavigationStack {
                document.destination
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                presentedLegalDocument = nil
                            }
                        }
                    }
            }
        }
    }

    private var purchaseButtonTitle: String {
        if isPurchasing { return "Processing..." }
        if let offering = subscriptionService.currentOffering, offering.hasTrial {
            return "Start \(offering.trialDays)-Day Free Trial"
        }
        return "Subscribe"
    }

    private var canPurchase: Bool {
        subscriptionService.currentOffering != nil && !isPurchasing && !isRestoring
    }

    private func purchase() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            if subscriptionService.isSubscribed {
                finishPurchase()
                return
            }

            await subscriptionService.purchase()
            if subscriptionService.isSubscribed {
                finishPurchase()
            }
        }
    }

    private func restore() {
        Task {
            isRestoring = true
            defer { isRestoring = false }

            await subscriptionService.restorePurchases()
            if subscriptionService.isSubscribed {
                finishPurchase()
            } else if subscriptionService.purchaseError == nil {
                subscriptionService.purchaseError = "No active Progress Pro subscription was found for this account."
            }
        }
    }

    private func finishPurchase() {
        onPurchased()
        if !isEmbedded {
            dismiss()
        }
    }

    private func skip() {
        onSkip()
        if !isEmbedded {
            dismiss()
        }
    }
}

private struct SubscriptionPlanCard: View {
    let offering: SubscriptionService.SubscriptionOffering
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? Color.brand : OnboardingPalette.muted)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(offering.plan.title)
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundColor(OnboardingPalette.ink)

                        if offering.plan == .annual {
                            Text("BEST VALUE")
                                .font(.system(size: 9.5, weight: .heavy))
                                .tracking(0.4)
                                .foregroundColor(OnboardingPalette.onInk)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.brand))
                        }
                    }

                    Text(offering.plan.detailLine(pricePerMonth: offering.pricePerMonth))
                        .font(.system(size: 11.5))
                        .foregroundColor(OnboardingPalette.muted)

                    if offering.hasTrial {
                        Text("\(offering.trialDays)-day free trial")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.brand)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(offering.price)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingPalette.ink)
                    Text(offering.plan.billingPeriodText)
                        .font(.system(size: 11))
                        .foregroundColor(OnboardingPalette.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected ? OnboardingPalette.ink : OnboardingPalette.line,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(offering.plan.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Paywall") {
    PaywallView()
        .environmentObject(SubscriptionService())
}
