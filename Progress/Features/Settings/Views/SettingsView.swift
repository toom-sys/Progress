//
//  SettingsView.swift
//  Progress
//

import SwiftUI
import RevenueCatUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    settingsGroup("Account") {
                        settingsLink(title: "Profile", systemImage: "person.circle") {
                            ProfileView()
                        }
                        settingsDivider
                        Button {
                            HapticFeedback.workoutButtonTap()
                            showingPaywall = true
                        } label: {
                            settingsRow(
                                title: "Subscription",
                                systemImage: "bolt.circle",
                                detail: subscriptionService.membershipLabel,
                                detailColor: subscriptionService.isSubscribed ? AppPalette.liveText : AppPalette.muted,
                                showsChevron: false
                            )
                        }
                        .buttonStyle(.plain)
                        if subscriptionService.isSubscribed {
                            settingsDivider
                            settingsLink(title: "Manage Subscription", systemImage: "creditcard") {
                                CustomerCenterView()
                                    .onCustomerCenterRestoreCompleted { customerInfo in
                                        subscriptionService.apply(customerInfo)
                                    }
                            }
                        }
                        settingsDivider
                        Button {
                            HapticFeedback.workoutButtonTap()
                            subscriptionService.redeemAnnualCode()
                        } label: {
                            settingsRow(title: "Redeem annual code", systemImage: "gift", showsChevron: false)
                        }
                        .buttonStyle(.plain)
                        if let error = subscriptionService.purchaseError {
                            Text(error)
                                .font(.appSubtitle)
                                .foregroundStyle(AppPalette.protein)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 12)
                        }
                    }

                    settingsGroup("Preferences") {
                        settingsLink(title: "Workout & Activity Goals", systemImage: "figure.run") {
                            WorkoutGoalsSettingsView()
                        }
                        settingsDivider
                        settingsLink(title: "Nutrition Goals", systemImage: "fork.knife") {
                            NutritionGoalsSettingsView()
                        }
                        settingsDivider
                        settingsLink(title: "Training Plan", systemImage: "list.bullet.clipboard") {
                            TrainingPlanSettingsView()
                        }
                        settingsDivider
                        settingsLink(title: "Units & Preferences", systemImage: "ruler") {
                            UnitsSettingsView()
                        }
                        settingsDivider
                        settingsLink(title: "Notifications", systemImage: "bell") {
                            NotificationsSettingsView()
                        }
                        settingsDivider
                        settingsLink(title: "Export Data", systemImage: "square.and.arrow.up") {
                            DataExportView()
                        }
                    }

                    settingsGroup("About") {
                        settingsLink(title: "Privacy Policy", systemImage: "hand.raised") {
                            PrivacyPolicyView()
                        }
                        settingsDivider
                        settingsLink(title: "Terms of Service", systemImage: "doc.text") {
                            TermsOfServiceView()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        DeleteAccountButton(usesPlainStyle: true) {
                            settingsRow(
                                title: "Delete Account",
                                systemImage: "person.crop.circle.badge.minus",
                                tint: AppPalette.protein,
                                showsChevron: false
                            )
                        }
                        .appCard(cornerRadius: 22, padding: 0)

                        Text(
                            "Permanently deletes the account created for this install and the profile, "
                            + "workouts, nutrition, water, and weight history saved in Progress. "
                            + "An App Store subscription is not cancelled."
                        )
                        .font(.appSubtitle)
                        .foregroundStyle(AppPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppBackground())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .presentationBackground { AppBackground() }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await subscriptionService.checkSubscriptionStatus() }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("Settings")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundStyle(AppPalette.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            CircleIconButton(
                systemName: "xmark",
                style: .plain,
                size: 40,
                accessibilityLabel: "Close",
                action: {
                    HapticFeedback.workoutButtonTap()
                    dismiss()
                }
            )
        }
        .padding(.top, 20)
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(AppPalette.line)
            .frame(height: 1)
            .padding(.leading, 62)
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .tracking(0.4)
                .foregroundStyle(AppPalette.muted)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                content()
            }
            .appCard(cornerRadius: 22, padding: 0)
        }
    }

    private func settingsLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            settingsRow(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func settingsRow(
        title: String,
        systemImage: String,
        detail: String? = nil,
        detailColor: Color = AppPalette.muted,
        tint: Color = AppPalette.ink,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppPalette.optionFill))
                .accessibilityHidden(true)

            Text(title)
                .font(.appCardTitle)
                .foregroundStyle(tint)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .font(.appSubtitle)
                    .foregroundStyle(detailColor)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppPalette.muted.opacity(0.7))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct SettingsPlaceholder: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppPalette.ink)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppPalette.optionFill))

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(AppPalette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .appCard()
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppBackground())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
