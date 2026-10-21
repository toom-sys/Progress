//
//  PaywallView.swift
//  Progress
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Presents the current RevenueCat paywall for the Progress Pro offering.
/// Terms and Privacy stay in the purchase flow for App Review.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService

    var body: some View {
        NavigationStack {
            RevenueCatUI.PaywallView(displayCloseButton: true)
                .onPurchaseCompleted { _, customerInfo in
                    subscriptionService.apply(customerInfo)
                    if customerInfo.entitlements.active[SubscriptionService.entitlementID]?.isActive == true {
                        dismiss()
                    }
                }
                .onPurchaseFailure { error in
                    subscriptionService.purchaseError = error.localizedDescription
                }
                .onRestoreCompleted { customerInfo in
                    subscriptionService.apply(customerInfo)
                    if customerInfo.entitlements.active[SubscriptionService.entitlementID]?.isActive == true {
                        dismiss()
                    } else {
                        subscriptionService.purchaseError = "No active Progress Pro subscription was found for this account."
                    }
                }
                .onRestoreFailure { error in
                    subscriptionService.purchaseError = error.localizedDescription
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        HStack(spacing: 20) {
                            NavigationLink("Terms of Service") {
                                TermsOfServiceView()
                            }
                            NavigationLink("Privacy Policy") {
                                PrivacyPolicyView()
                            }
                        }
                        .font(.caption)
                    }
                }
                .alert("Subscription", isPresented: Binding(
                    get: { subscriptionService.purchaseError != nil },
                    set: { if !$0 { subscriptionService.purchaseError = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(subscriptionService.purchaseError ?? "")
                }
        }
    }
}

#Preview("Paywall") {
    PaywallView()
        .environmentObject(SubscriptionService())
}
