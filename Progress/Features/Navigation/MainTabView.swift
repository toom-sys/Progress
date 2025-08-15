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
    @StateObject private var subscriptionService = SubscriptionService()
    @State private var isInWorkoutDetail = false
    @State private var showingFoodSearch = false
    @State private var showingBarcodeScanner = false
    
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
                    NutritionTab(
                        showingFoodSearch: $showingFoodSearch,
                        showingBarcodeScanner: $showingBarcodeScanner
                    )
                }
            }
            .environmentObject(subscriptionService)
            
            // Floating + Button for Nutrition Tab
            if selectedTab == .nutrition {
                FloatingAddButton(
                    showingFoodSearch: $showingFoodSearch,
                    showingBarcodeScanner: $showingBarcodeScanner
                )
            }
            
            // Floating Tab Bar
            FloatingTabBar(
                selectedTab: $selectedTab,
                isInWorkoutDetail: isInWorkoutDetail,
                onTabSelected: handleTabSelection
            )
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
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView()
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
        }
    }
    
    private func handleTabSelection(_ tab: Tab) {
        // If we're in workout detail and tap workouts, dismiss detail view
        if tab == .workouts && isInWorkoutDetail {
            isInWorkoutDetail = false
            // Trigger navigation back - this will be handled by the environment
            NotificationCenter.default.post(name: .dismissWorkoutDetail, object: nil)
        } else {
            selectedTab = tab
        }
    }
}

#Preview {
    MainTabView()
}