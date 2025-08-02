//
//  MainTabView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - NotificationCenter Extension
extension Notification.Name {
    static let dismissWorkoutDetail = Notification.Name("dismissWorkoutDetail")
    static let showWorkoutDetail = Notification.Name("showWorkoutDetail")
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .workouts
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var isInWorkoutDetail = false
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                switch selectedTab {
                case .workouts:
                    WorkoutTab()
                case .progress:
                    ProgressTab()
                case .nutrition:
                    NutritionTab()
                }
            }
            .environmentObject(subscriptionService)
            
            // Floating Tab Bar
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    ForEach([Tab.workouts, Tab.progress, Tab.nutrition], id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // If we're in workout detail and tap workouts, dismiss detail view
                                if tab == .workouts && isInWorkoutDetail {
                                    isInWorkoutDetail = false
                                    // Trigger navigation back - this will be handled by the environment
                                    NotificationCenter.default.post(name: .dismissWorkoutDetail, object: nil)
                                } else {
                                    selectedTab = tab
                                }
                            }
                        }) {
                            // Special logic for workouts tab - only highlight when NOT in workout detail
                            let isTabActive = tab == .workouts ? (selectedTab == tab && !isInWorkoutDetail) : (selectedTab == tab)
                            
                            VStack(spacing: 4) {
                                ZStack {
                                    Image(systemName: isTabActive ? tab.activeIcon : tab.icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(isTabActive ? .primary : .textSecondary)
                                    
                                    // Blue indicator dot for workout detail
                                    if tab == .workouts && isInWorkoutDetail {
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 6, height: 6)
                                            .offset(x: 12, y: -8)
                                    }
                                }
                                
                                Text(tab.displayName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(isTabActive ? .primary : .textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.border.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area bottom padding
            }
        }
        .task {
            // Load subscription status when app starts
            await subscriptionService.loadOfferings()
            subscriptionService.checkSubscriptionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWorkoutDetail)) { _ in
            isInWorkoutDetail = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissWorkoutDetail)) { _ in
            isInWorkoutDetail = false
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case workouts = "workouts"
    case progress = "progress"
    case nutrition = "nutrition"
    
    var displayName: String {
        switch self {
        case .workouts: return "Workouts"
        case .progress: return "Progress"
        case .nutrition: return "Nutrition"
        }
    }
    
    var icon: String {
        switch self {
        case .workouts: return "dumbbell"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .nutrition: return "leaf"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .workouts: return "dumbbell.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .nutrition: return "leaf.fill"
        }
    }
}

// MARK: - Tab Views

struct WorkoutTab: View {
    var body: some View {
        NavigationStack {
            WorkoutListView()
        }
    }
}

struct NutritionTab: View {
    var body: some View {
        NavigationStack {
            NutritionDashboardView()
        }
    }
}

struct ProgressTab: View {
    var body: some View {
        NavigationStack {
            ProgressDashboardView()
        }
    }
}



// MARK: - Placeholder Views (to be implemented next)



struct NutritionDashboardView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("🥗")
                .font(.system(size: 80))
            
            Text("Nutrition")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
            
            Text("Log your meals and track macros")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Log First Meal") {
                // TODO: Navigate to nutrition logging
            }
            .primaryButtonStyle()
        }
        .padding()
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // TODO: Add meal action
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct ProgressDashboardView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("📊")
                .font(.system(size: 80))
            
            Text("Progress")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
            
            Text("Track your fitness journey")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Text("Complete some workouts and log meals to see your progress here!")
                    .font(.body)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Progress")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingPaywall = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.textSecondary)
                        
                        if let tier = subscriptionService.activeSubscription {
                            Text(tier.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            SettingsView()
        }
    }
}

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
                            
                            if let tier = subscriptionService.activeSubscription {
                                Text(tier.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.1))
                                    .clipShape(Capsule())
                            } else {
                                Text("Free")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                }
                
                Section {
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
        }
    }
}

// MARK: - Settings Placeholder Views

struct ProfileView: View {
    var body: some View {
        Text("Profile Settings Coming Soon")
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
    }
}

struct UnitsSettingsView: View {
    var body: some View {
        Text("Units Settings Coming Soon")
            .navigationTitle("Units")
            .navigationBarTitleDisplayMode(.large)
    }
}

struct NotificationsSettingsView: View {
    var body: some View {
        Text("Notification Settings Coming Soon")
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
    }
}

struct DataExportView: View {
    var body: some View {
        Text("Data Export Coming Soon")
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.large)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy Coming Soon")
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.large)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service Coming Soon")
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    MainTabView()
}