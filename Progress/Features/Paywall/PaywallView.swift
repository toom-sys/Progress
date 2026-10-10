//
//  PaywallView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var selectedPeriod: MembershipPeriod = .yearly

    private var selectedOffering: MembershipOffering? {
        subscriptionService.offering(for: selectedPeriod)
    }

    private var monthlyOffering: MembershipOffering? {
        subscriptionService.offering(for: .monthly)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        if subscriptionService.isSandboxMode {
                            sandboxModeIndicator
                        }

                        if subscriptionService.isMember {
                            activeMembershipStatus
                        }

                        planList
                        featureList
                        purchaseSection
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "paywall.close")) {
                        dismiss()
                    }
                    .font(.buttonSecondary)
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .task {
            await subscriptionService.loadOfferings()
            subscriptionService.checkSubscriptionStatus()
            if subscriptionService.offering(for: .yearly) != nil {
                selectedPeriod = .yearly
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(String(localized: "paywall.title"))
                .font(.titleXL)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "paywall.subtitle"))
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var sandboxModeIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "flask.fill")
                .foregroundColor(.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "paywall.sandbox_title"))
                    .font(.bodyLarge)
                    .foregroundColor(.warning)

                Text(String(localized: "paywall.sandbox_body"))
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var activeMembershipStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.success)
                .font(.titleMedium)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "paywall.active"))
                    .font(.bodyLarge)
                    .foregroundColor(.success)

                Text(subscriptionService.membershipLabel)
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.success.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var planList: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionService.currentOfferings) { offering in
                MembershipPlanRow(
                    offering: offering,
                    monthlyOffering: monthlyOffering,
                    isSelected: selectedPeriod == offering.period
                ) {
                    selectedPeriod = offering.period
                }
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("paywall.feature.workouts")
            featureRow("paywall.feature.timer")
            featureRow("paywall.feature.nutrition")
            featureRow("paywall.feature.dashboard")
            featureRow("paywall.feature.device")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(_ key: String.LocalizationValue) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.success)
            Text(String(localized: key))
                .font(.body)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            Button(action: purchaseSelected) {
                HStack {
                    if subscriptionService.isLoading {
                        ProgressView()
                            .tint(Color.textOnPrimary)
                        Text(String(localized: "paywall.processing"))
                            .font(.buttonPrimary)
                    } else if subscriptionService.isCurrentPeriod(selectedPeriod) {
                        Text(String(localized: "paywall.current_plan"))
                            .font(.buttonPrimary)
                    } else if let offering = selectedOffering {
                        Text(continueTitle(for: offering))
                            .font(.buttonPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundColor(subscriptionService.isCurrentPeriod(selectedPeriod) ? Color.textSecondary : Color.textOnPrimary)
                .background(subscriptionService.isCurrentPeriod(selectedPeriod) ? Color.backgroundSecondary : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(subscriptionService.isLoading || selectedOffering == nil || subscriptionService.isCurrentPeriod(selectedPeriod))

            Button(String(localized: "paywall.restore")) {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(.body)
            .foregroundColor(.textSecondary)
            .disabled(subscriptionService.isLoading)

            if let error = subscriptionService.purchaseError, !subscriptionService.isSandboxMode {
                Text(error)
                    .font(.bodySmall)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 12) {
            Text(String(format: String(localized: "paywall.renews"), selectedPeriod.renewalAdverb))
                .font(.caption)
                .foregroundColor(.textTertiary)

            Text(String(localized: "paywall.cancel_anytime"))
                .font(.caption)
                .foregroundColor(.textTertiary)

            HStack(spacing: 20) {
                Button(String(localized: "paywall.terms")) {}
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Button(String(localized: "paywall.privacy")) {}
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    private func continueTitle(for offering: MembershipOffering) -> String {
        String(
            format: String(localized: "paywall.continue"),
            offering.localizedPrice,
            offering.period.cadence
        )
    }

    private func purchaseSelected() {
        guard let offering = selectedOffering else { return }
        Task {
            await subscriptionService.purchase(offering)
            if subscriptionService.isMember {
                dismiss()
            }
        }
    }
}

private struct MembershipPlanRow: View {
    let offering: MembershipOffering
    let monthlyOffering: MembershipOffering?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(offering.period.displayName)
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)

                        if offering.period.isBestValue {
                            Text(String(localized: "paywall.best_value"))
                                .font(.caption)
                                .foregroundColor(.textOnPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(detail)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Text(offering.localizedPrice)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
            }
            .padding(16)
            .background(isSelected ? Color.primary.opacity(0.08) : Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primary : Color.border, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var detail: String {
        if offering.period == .yearly, let monthlyOffering {
            let perMonth = offering.formatted(offering.price / 12)
            let yearOfMonthly = monthlyOffering.formatted(monthlyOffering.price * 12)
            return String(format: String(localized: "paywall.yearly_detail"), perMonth, yearOfMonthly)
        }
        return offering.period.cadence
    }
}

#Preview("Paywall") {
    PaywallView()
        .environmentObject(SubscriptionService())
}
