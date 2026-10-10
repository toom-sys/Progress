//
//  SettingsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: ProfileView()) {
                        Label("Profile", systemImage: "person.circle")
                    }
                    
                    Button(action: {
                        showingPaywall = true
                    }) {
                        HStack {
                            Label("Subscription", systemImage: "star.circle")
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text(subscriptionService.membershipLabel)
                                .font(.caption)
                                .foregroundColor(subscriptionService.isMember ? Color.primary : Color.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(subscriptionService.isMember ? Color.primary.opacity(0.1) : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: NutritionMetricsSettingsView()) {
                        Label("Nutrition Metrics", systemImage: "chart.bar.fill")
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
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionService)
        }
    }
}
