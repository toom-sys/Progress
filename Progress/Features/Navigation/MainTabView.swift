//
//  MainTabView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NutritionEntry.loggedAt, order: .reverse) private var nutritionEntries: [NutritionEntry]
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingFoodSearch = false
    @State private var showingBarcodeScanner = false
    
    // Filter entries for today
    private var todaysEntries: [NutritionEntry] {
        let calendar = Calendar.current
        let today = Date()
        return nutritionEntries.filter { entry in
            calendar.isDate(entry.loggedAt, inSameDayAs: today)
        }
    }
    
    // Calculate totals for today
    private var todaysTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let calories = todaysEntries.reduce(0) { $0 + $1.totalCalories }
        let protein = todaysEntries.reduce(0) { $0 + $1.totalProtein }
        let carbs = todaysEntries.reduce(0) { $0 + $1.totalCarbohydrates }
        let fat = todaysEntries.reduce(0) { $0 + $1.totalFat }
        return (calories, protein, carbs, fat)
    }
    
    // Group entries by meal type
    private var mealGroups: [MealType: [NutritionEntry]] {
        Dictionary(grouping: todaysEntries) { $0.mealType }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if todaysEntries.isEmpty {
                    emptyStateView
                } else {
                    // Daily Summary
                    dailySummaryCard
                    
                    // Meals
                    mealsSection
                }
            }
            .padding()
        }
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingFoodSearch = true
                    }) {
                        Label("Search Foods", systemImage: "magnifyingglass")
                    }
                    
                    Button(action: {
                        showingBarcodeScanner = true
                    }) {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView()
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Text("🥗")
                .font(.system(size: 80))
            
            Text("Start tracking nutrition")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
            
            Text("Log your meals and track macros to reach your fitness goals")
                .font(.bodyLarge)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Search Foods") {
                    showingFoodSearch = true
                }
                .primaryButtonStyle()
                
                Button("Scan Barcode") {
                    showingBarcodeScanner = true
                }
                .secondaryButtonStyle()
            }
        }
        .padding()
    }
    
    private var dailySummaryCard: some View {
        VStack(spacing: 16) {
            Text("Today's Nutrition")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                MacroCircle(
                    value: todaysTotals.calories,
                    target: 2000, // TODO: Make this user configurable
                    label: "Calories",
                    unit: "cal",
                    color: .orange
                )
                
                MacroBar(value: todaysTotals.protein, target: 150, label: "Protein", unit: "g", color: .blue)
                MacroBar(value: todaysTotals.carbs, target: 200, label: "Carbs", unit: "g", color: .green)
                MacroBar(value: todaysTotals.fat, target: 65, label: "Fat", unit: "g", color: .purple)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var mealsSection: some View {
        VStack(spacing: 16) {
            ForEach(MealType.allCases, id: \.self) { mealType in
                MealCard(
                    mealType: mealType,
                    entries: mealGroups[mealType] ?? [],
                    onAddFood: { showingFoodSearch = true }
                )
            }
        }
    }
}

struct MacroCircle: View {
    let value: Double
    let target: Double
    let label: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        target > 0 ? min(value / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(Int(value))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

struct MacroBar: View {
    let value: Double
    let target: Double
    let label: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        target > 0 ? min(value / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("\(Int(value))")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(unit)
                        .font(.caption2)
                }
                .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealCard: View {
    let mealType: MealType
    let entries: [NutritionEntry]
    let onAddFood: () -> Void
    
    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.totalCalories }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text(mealType.icon)
                        .font(.title2)
                    
                    Text(mealType.displayName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                if !entries.isEmpty {
                    Text("\(Int(totalCalories)) cal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                }
                
                Button(action: onAddFood) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            
            if entries.isEmpty {
                Button(action: onAddFood) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add food")
                            .font(.subheadline)
                    }
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
                        FoodEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FoodEntryRow: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                
                if entry.quantity != 1.0 {
                    Text("\(String(format: "%.2g", entry.quantity)) × \(entry.servingSize)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                } else {
                    Text(entry.servingSize)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Text("\(Int(entry.totalCalories)) cal")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
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