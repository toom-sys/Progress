//
//  SubscriptionGateView.swift
//  Progress
//

import SwiftUI

/// Full-screen overlay shown over tab content when the user has no active subscription.
/// The tab bar remains visible so users can explore tabs, but all content is gated.
struct SubscriptionGateView: View {
    @State private var showingPaywall = false
    @State private var showingExport = false

    var body: some View {
        ZStack {
            // Dimmed, blurred backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }

                VStack(spacing: 10) {
                    Text("Subscribe to Unlock")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Start your 3-day free trial to access\nworkouts, nutrition and progress insights.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button {
                    showingPaywall = true
                } label: {
                    Text("Start Free Trial")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(spacing: 12) {
                    Button("Export Data") {
                        showingExport = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    DeleteAccountButton(usesPlainStyle: true) {
                        Text("Delete Account")
                            .font(.subheadline)
                    }
                }
            }
            .padding(32)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack {
                DataExportView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingExport = false }
                        }
                    }
            }
        }
    }
}

#Preview {
    SubscriptionGateView()
}
