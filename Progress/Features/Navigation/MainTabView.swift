//
//  MainTabView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .workouts
    @State private var isInWorkoutDetail = false
    @State private var isInWorkoutHistory = false
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @StateObject private var keyboardObserver = KeyboardObserver()
    @StateObject private var deepLinkService = DeepLinkService.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutTab()
                .tabItem {
                    let isActive = selectedTab == .workouts && !(isInWorkoutDetail || isInWorkoutHistory)
                    Label(Tab.workouts.displayName, systemImage: isActive ? Tab.workouts.activeIcon : Tab.workouts.icon)
                }
                .tag(Tab.workouts)
                .overlay(gateOverlay)
            
            JourneyTab()
                .tabItem {
                    Label(Tab.journey.displayName, systemImage: selectedTab == .journey ? Tab.journey.activeIcon : Tab.journey.icon)
                }
                .tag(Tab.journey)
                .overlay(gateOverlay)
            
            NutritionTab()
                .tabItem {
                    Label(Tab.nutrition.displayName, systemImage: selectedTab == .nutrition ? Tab.nutrition.activeIcon : Tab.nutrition.icon)
                }
                .tag(Tab.nutrition)
                .overlay(gateOverlay)
        }
        .environmentObject(subscriptionService)
        .environmentObject(keyboardObserver)
        .toolbar(keyboardObserver.isKeyboardVisible ? .hidden : .visible, for: .tabBar)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToProgress)) { _ in
            selectedTab = .journey
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToWorkouts)) { _ in
            selectedTab = .workouts
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToNutrition)) { _ in
            selectedTab = .nutrition
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWorkoutDetail)) { _ in
            isInWorkoutDetail = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissWorkoutDetail)) { _ in
            isInWorkoutDetail = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWorkoutHistory)) { _ in
            isInWorkoutHistory = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissWorkoutHistory)) { _ in
            isInWorkoutHistory = false
        }
        .onChange(of: deepLinkService.shouldNavigateToWorkouts) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = .workouts
            }
        }
    }
    // MARK: - Gate Overlay

    @ViewBuilder
    private var gateOverlay: some View {
        if !subscriptionService.isSubscribed {
            SubscriptionGateView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionService())
}
