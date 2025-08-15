//
//  NutritionDashboardView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Nutrition Dashboard View

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
                    .padding(.horizontal, 24)
                    
                    // Food List or empty message
                    if selectedDateEntries.isEmpty {
                        emptyFoodMessage
                    } else {
                        foodEntriesList
                    }
                }
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
        .padding(.horizontal, 24)
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
        .padding(.horizontal, 24)
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
