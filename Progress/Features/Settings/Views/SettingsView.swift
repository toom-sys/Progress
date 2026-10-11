//
//  SettingsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Query private var users: [User]
    @State private var showingPaywall = false
    #if DEBUG
    @State private var showingOnboardingResetConfirmation = false
    #endif

    private var currentUser: User? { users.first }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ProfileView()) {
                        Label("Profile", systemImage: "person.circle")
                    }
                    
                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        showingPaywall = true
                    }) {
                        HStack {
                            Label("Subscription", systemImage: "bolt.circle")
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text(subscriptionService.membershipLabel)
                                .font(.caption)
                                .foregroundColor(subscriptionService.isSubscribed ? .primary : .textTertiary)
                        }
                    }

                    Button(action: {
                        HapticFeedback.workoutButtonTap()
                        subscriptionService.redeemAnnualCode()
                    }) {
                        Label("Redeem annual code", systemImage: "gift")
                            .foregroundColor(.textPrimary)
                    }

                    if let error = subscriptionService.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    NavigationLink(destination: WorkoutGoalsSettingsView()) {
                        Label("Workout & Activity Goals", systemImage: "figure.run.circle")
                    }

                    NavigationLink(destination: NutritionGoalsSettingsView()) {
                        Label("Nutrition Goals", systemImage: "fork.knife.circle")
                    }

                    NavigationLink(destination: TrainingPlanSettingsView()) {
                        Label("Training Plan", systemImage: "list.bullet.clipboard")
                    }
                    
                    NavigationLink(destination: UnitsSettingsView()) {
                        Label("Units & Preferences", systemImage: "ruler")
                    }
                    
                    NavigationLink(destination: NotificationsSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: DataExportView()) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section("Debug") {
                    Toggle(isOn: onboardingCompletedBinding) {
                        Label("Onboarding Completed", systemImage: "flag.checkered")
                    }

                    NavigationLink(destination: OpenAITestView()) {
                        Label("OpenAI Test", systemImage: "brain.head.profile")
                    }
                }
                #endif
                
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.workoutButtonTap()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await subscriptionService.checkSubscriptionStatus() }
        }
        #if DEBUG
        .alert("Reset Onboarding?", isPresented: $showingOnboardingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("You'll go through the setup flow again from the start.")
        }
        #endif
    }

    #if DEBUG
    private var onboardingCompletedBinding: Binding<Bool> {
        Binding(
            get: { currentUser?.hasCompletedOnboarding ?? false },
            set: { isCompleted in
                guard !isCompleted, currentUser?.hasCompletedOnboarding == true else { return }
                showingOnboardingResetConfirmation = true
            }
        )
    }

    private func resetOnboarding() {
        guard let user = currentUser else { return }

        user.hasCompletedOnboarding = false
        user.updatedAt = Date()
        OnboardingProgressStore.resetSavedProgress()

        do {
            try modelContext.save()
            HapticFeedback.workoutButtonTap()
            dismiss()
        } catch {
            print("❌ Failed to reset onboarding: \(error.localizedDescription)")
        }
    }
    #endif
}

