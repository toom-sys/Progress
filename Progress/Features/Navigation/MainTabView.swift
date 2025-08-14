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
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        
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
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(Color.border.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        Spacer()
                    }
                    .padding(.bottom, 120) // Position above the tab bar
                }
            }
            
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
        .sheet(isPresented: $showingFoodSearch) {
            FoodSearchView()
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
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
    @Binding var showingFoodSearch: Bool
    @Binding var showingBarcodeScanner: Bool
    
    var body: some View {
        NavigationStack {
            NutritionDashboardView(
                showingFoodSearch: $showingFoodSearch,
                showingBarcodeScanner: $showingBarcodeScanner
            )
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
    @Binding var showingFoodSearch: Bool
    @Binding var showingBarcodeScanner: Bool
    @State private var selectedDate = Date()
    
    private var validatedSelectedDate: Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Get 3 months ago (for lower limit)
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) ?? today
        
        // If selectedDate is outside bounds, clamp it to the valid range
        if selectedDate > today {
            return today
        } else if selectedDate < threeMonthsAgo {
            return threeMonthsAgo
        } else {
            return selectedDate
        }
    }
    
    // Filter entries for selected date
    private var selectedDateEntries: [NutritionEntry] {
        let calendar = Calendar.current
        return nutritionEntries.filter { entry in
            calendar.isDate(entry.loggedAt, inSameDayAs: validatedSelectedDate)
        }
    }
    
    // Generate date range for the week view (Monday to Sunday)
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Find the start of the week containing the validated selected date (Monday)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: validatedSelectedDate)?.start ?? today
        
        // Adjust to start on Monday (if calendar doesn't already)
        let mondayStart: Date
        let weekday = calendar.component(.weekday, from: weekStart)
        if weekday == 1 { // Sunday
            mondayStart = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart
        } else if weekday == 2 { // Monday
            mondayStart = weekStart
        } else {
            let daysToSubtract = weekday - 2
            mondayStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: weekStart) ?? weekStart
        }
        
        // Generate Monday through Sunday
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: mondayStart) {
                dates.append(date)
            }
        }
        return dates
    }
    
    // Calculate totals for selected date
    private var selectedDateTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let calories = selectedDateEntries.reduce(0) { $0 + $1.totalCalories }
        let protein = selectedDateEntries.reduce(0) { $0 + $1.totalProtein }
        let carbs = selectedDateEntries.reduce(0) { $0 + $1.totalCarbohydrates }
        let fat = selectedDateEntries.reduce(0) { $0 + $1.totalFat }
        return (calories, protein, carbs, fat)
    }
    

    
    var body: some View {
        VStack(spacing: 0) {
            // Day Picker Header
            dayPickerHeader
            
            ScrollView {
                VStack(spacing: 16) {
                    // Daily Summary with swipeable metrics
                    SwipeableNutritionMetrics(nutritionEntries: selectedDateEntries)
                    
                    // Meals Section Header
                    HStack {
                        Text(isToday ? "Today's Food" : "Food")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Food List or empty message
                    if selectedDateEntries.isEmpty {
                        emptyFoodMessage
                    } else {
                        foodEntriesList
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AdaptiveGradientBackground())
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    private var emptyFoodMessage: some View {
        VStack(spacing: 16) {
            Text("No food logged yet")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Text("Use the + button to add food")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(validatedSelectedDate, inSameDayAs: Date())
    }
    
    private var selectedDateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: validatedSelectedDate)
    }
    

    
    private var foodEntriesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(selectedDateEntries) { entry in
                SwipeableNutritionRow(
                    entry: entry,
                    onDelete: {
                        deleteNutritionEntry(entry)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var dayPickerHeader: some View {
        VStack(spacing: 0) {
            // Day picker - full width
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    DayPickerCard(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: validatedSelectedDate),
                        onTap: {
                            // Only allow selection if the date is within bounds
                            if canNavigateToWeek(date) {
                                selectedDate = date
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.clear)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Only respond to horizontal swipes that are primarily horizontal (not vertical)
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    
                    // Require horizontal movement to be at least 2x vertical movement
                    guard horizontalMovement > verticalMovement * 2 && horizontalMovement > 50 else { return }
                    
                    if value.translation.width > 0 {
                        // Swipe right - go to previous week (with limits)
                        let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                        let newWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: newDate)?.start ?? newDate
                        if canNavigateToWeekStart(newWeekStart) {
                            selectedDate = newDate
                        }
                    } else {
                        // Swipe left - go to next week (with limits)
                        let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                        let newWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: newDate)?.start ?? newDate
                        if canNavigateToWeekStart(newWeekStart) {
                            selectedDate = newDate
                        }
                    }
                }
        )
    }
    

    
    private func canNavigateToWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Get 3 months ago (for lower limit)
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) ?? today
        
        // Check if the date is within our allowed range
        // Can't go beyond today
        // Can't go before 3 months ago
        return date >= threeMonthsAgo && date <= today
    }
    
    private func canNavigateToWeekStart(_ weekStartDate: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of this week (for upper limit)
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // Get 3 months ago (for lower limit)
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) ?? today
        
        // For week navigation, check if the week start is within bounds
        // Allow current week and previous weeks within 3 months
        return weekStartDate >= threeMonthsAgo && weekStartDate <= thisWeekStart
    }
    
    private func deleteNutritionEntry(_ entry: NutritionEntry) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(entry)
            
            do {
                try modelContext.save()
                print("Successfully deleted nutrition entry: \(entry.foodName)")
            } catch {
                print("Failed to delete nutrition entry: \(error)")
                // Re-insert the entry if save fails
                modelContext.insert(entry)
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

struct CalorieCard: View {
    let consumed: Double
    let target: Double
    
    private var remaining: Double {
        max(0, target - consumed)
    }
    
    private var progress: Double {
        target > 0 ? min(consumed / target, 1.0) : 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(remaining))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 8) {
                    Text("Calories left")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("+\(Int(consumed))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Calorie circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: consumed)
                
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        }
        .whiteCardStyle(cornerRadius: 16, padding: 20)
    }
}

struct MacroCard: View {
    let value: Double
    let target: Double
    let label: String
    let icon: String
    let color: Color
    
    private var remaining: Double {
        max(0, target - value)
    }
    
    private var progress: Double {
        target > 0 ? min(value / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("\(Int(remaining))g")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Circular progress with icon
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .whiteCardStyle()
    }
}

struct SwipeableNutritionRow: View {
    let entry: NutritionEntry
    let onDelete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Main card content
            SimpleFoodEntryRow(entry: entry)
                .frame(height: 120)
                .offset(x: offset)
            
            // Delete button positioned off-screen to the right
            HStack {
                Spacer()
                Button(action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                        Text("Delete")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth, height: 120)
                    .background(Color.red)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 16,
                            topTrailingRadius: 16
                        )
                    )
                }
                .offset(x: deleteButtonWidth + offset) // Position off-screen initially
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.width
                    
                    // Only allow leftward swipes (negative translation)
                    if translation < 0 {
                        let progress = min(abs(translation), deleteButtonWidth)
                        offset = -progress
                        showingDeleteButton = progress > 20
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    
                    if abs(translation) > deleteButtonWidth / 2 {
                        // Show delete button
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = -deleteButtonWidth
                            showingDeleteButton = true
                        }
                    } else {
                        // Snap back
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = 0
                            showingDeleteButton = false
                        }
                    }
                }
        )
        .onTapGesture {
            // Tap to close if delete button is showing
            if showingDeleteButton {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                    showingDeleteButton = false
                }
            }
        }
    }
}

struct SimpleFoodEntryRow: View {
    let entry: NutritionEntry
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header row with food name and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.foodName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if entry.quantity != 1.0 {
                            Text("\(String(format: "%.2g", entry.quantity)) × \(entry.servingSize)")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text(entry.servingSize)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if entry.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if let brandName = entry.brandName {
                            Text("• \(brandName)")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: entry.loggedAt))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(Int(entry.totalCalories))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Macros row
            HStack(spacing: 20) {
                MacroMiniCard(
                    value: entry.totalProtein,
                    label: "Protein",
                    unit: "g",
                    color: .red,
                    icon: "fish.fill"
                )
                
                MacroMiniCard(
                    value: entry.totalCarbohydrates,
                    label: "Carbs",
                    unit: "g", 
                    color: .orange,
                    icon: "leaf.fill"
                )
                
                MacroMiniCard(
                    value: entry.totalFat,
                    label: "Fat",
                    unit: "g",
                    color: .blue,
                    icon: "drop.fill"
                )
                
                Spacer()
            }
        }
        .whiteCardStyle(cornerRadius: 16, padding: 20)
    }
}

struct MacroMiniCard: View {
    let value: Double
    let label: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(value))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AdaptiveGradientBackground())
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
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

struct DayPickerCard: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter day (M, T, W, etc.)
        return formatter
    }
    
    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textSecondary)
                
                Text(dayNumberFormatter.string(from: date))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .textPrimary)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary : (isToday ? Color.primary.opacity(0.1) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday && !isSelected ? Color.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
}