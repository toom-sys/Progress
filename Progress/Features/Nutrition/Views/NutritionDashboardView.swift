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
    @Query(sort: \WaterEntry.loggedAt, order: .reverse) private var allWaterEntries: [WaterEntry]
    @Query private var users: [User]
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingCameraAI = false
    @State private var showingDescribeFood = false
    @State private var showingManualEntry = false
    @State private var showingWaterLog = false
    @State private var selectedDate = Date()
    @State private var weekDragOffset: CGFloat = 0
    
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
        weekDates(containing: validatedSelectedDate)
    }
    
    private var previousWeekDates: [Date] {
        let previous = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: validatedSelectedDate) ?? validatedSelectedDate
        return weekDates(containing: previous)
    }
    
    private var nextWeekDates: [Date] {
        let next = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: validatedSelectedDate) ?? validatedSelectedDate
        return weekDates(containing: next)
    }
    
    private func weekDates(containing date: Date) -> [Date] {
        let calendar = Calendar.current
        
        // Find the start of the week containing the date
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        
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
            if let weekDate = calendar.date(byAdding: .day, value: i, to: mondayStart) {
                dates.append(weekDate)
            }
        }
        return dates
    }
    
    private var totalWaterToday: Double {
        allWaterEntries
            .filter { Calendar.current.isDate($0.loggedAt, inSameDayAs: validatedSelectedDate) }
            .reduce(0) { $0 + $1.amount }
    }

    private var dailyWaterGoal: Double {
        users.first?.dailyWaterGoal ?? 2500
    }

    private var nutritionGoals: NutritionGoals {
        users.first?.nutritionGoals ?? .default
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title header
            HStack {
                Text("Nutrition")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // Day Picker Header
            dayPickerHeader
            
            ScrollView {
                VStack(spacing: 16) {
                    // Daily Summary with swipeable metrics
                    SwipeableNutritionMetrics(
                        nutritionEntries: selectedDateEntries,
                        totalWater: totalWaterToday,
                        waterGoal: dailyWaterGoal,
                        calorieGoal: nutritionGoals.calories,
                        proteinGoal: nutritionGoals.protein,
                        carbGoal: nutritionGoals.carbs,
                        fatGoal: nutritionGoals.fat
                    )

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
                .padding(.bottom, 88) // Keep last row clear of the floating add button
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AdaptiveGradientBackground())
        .overlay(alignment: .bottom) {
            FloatingAddButton {
                Button("Take Photo (AI)", systemImage: "camera.fill") {
                    HapticFeedback.workoutButtonTap()
                    showingCameraAI = true
                }
                Button("Describe Food", systemImage: "text.bubble.fill") {
                    HapticFeedback.workoutButtonTap()
                    showingDescribeFood = true
                }
                Button("Enter Manually", systemImage: "pencil") {
                    HapticFeedback.workoutButtonTap()
                    showingManualEntry = true
                }
                Button("Log Water", systemImage: "drop.fill") {
                    HapticFeedback.workoutButtonTap()
                    showingWaterLog = true
                }
            }
            .padding(.bottom, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCameraAI) {
            CameraFoodView()
                .environmentObject(subscriptionService)
        }
        .sheet(isPresented: $showingDescribeFood) {
            DescribeFoodView(selectedDate: validatedSelectedDate)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualFoodEntryView()
        }
        .sheet(isPresented: $showingWaterLog) {
            WaterLogSheet(selectedDate: validatedSelectedDate)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var emptyFoodMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 52, height: 52)
                .background(Color.green.opacity(0.12))
                .clipShape(Circle())
            
            Text("No food logged yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Text("Use the + button to add food")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .whiteCardStyle(cornerRadius: 16, padding: 20)
        .padding(.horizontal, 24)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(validatedSelectedDate, inSameDayAs: Date())
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
        GeometryReader { geometry in
            let pageWidth = geometry.size.width
            
            HStack(spacing: 0) {
                weekRow(dates: previousWeekDates, interactive: false)
                    .frame(width: pageWidth)
                
                weekRow(dates: weekDates, interactive: true)
                    .frame(width: pageWidth)
                
                weekRow(dates: nextWeekDates, interactive: false)
                    .frame(width: pageWidth)
            }
            .offset(x: -pageWidth + weekDragOffset)
            .gesture(weekDragGesture(pageWidth: pageWidth))
        }
        .frame(height: 74)
        .clipped()
    }
    
    private func weekRow(dates: [Date], interactive: Bool) -> some View {
        let selectedWeekday = Calendar.current.component(.weekday, from: validatedSelectedDate)
        
        return HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                DayPickerCard(
                    date: date,
                    isSelected: Calendar.current.component(.weekday, from: date) == selectedWeekday,
                    onTap: {
                        guard interactive, canNavigateToWeek(date) else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
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
    
    private func weekDragGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let horizontalMovement = abs(value.translation.width)
                let verticalMovement = abs(value.translation.height)
                
                // Only track primarily horizontal drags
                guard horizontalMovement > verticalMovement else { return }
                
                var translation = value.translation.width
                
                // Rubber-band at navigation limits
                if translation > 0 {
                    let previousDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: validatedSelectedDate) ?? validatedSelectedDate
                    let previousWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: previousDate)?.start ?? previousDate
                    if !canNavigateToWeekStart(previousWeekStart) {
                        translation *= 0.25
                    }
                } else if translation < 0 {
                    let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: validatedSelectedDate) ?? validatedSelectedDate
                    let nextWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: nextDate)?.start ?? nextDate
                    if !canNavigateToWeekStart(nextWeekStart) {
                        translation *= 0.25
                    }
                }
                
                weekDragOffset = translation
            }
            .onEnded { value in
                let horizontalMovement = abs(value.translation.width)
                let verticalMovement = abs(value.translation.height)
                let threshold = pageWidth * 0.22
                let predicted = value.predictedEndTranslation.width
                
                guard horizontalMovement > verticalMovement || abs(predicted) > threshold else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        weekDragOffset = 0
                    }
                    return
                }
                
                if (value.translation.width > threshold || predicted > pageWidth * 0.4) {
                    let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: validatedSelectedDate) ?? validatedSelectedDate
                    let newWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: newDate)?.start ?? newDate
                    if canNavigateToWeekStart(newWeekStart) {
                        animateWeekChange(to: newDate, targetOffset: pageWidth)
                        return
                    }
                } else if (value.translation.width < -threshold || predicted < -pageWidth * 0.4) {
                    let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: validatedSelectedDate) ?? validatedSelectedDate
                    let newWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: newDate)?.start ?? newDate
                    if canNavigateToWeekStart(newWeekStart) {
                        animateWeekChange(to: newDate, targetOffset: -pageWidth)
                        return
                    }
                }
                
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    weekDragOffset = 0
                }
            }
    }
    
    private func animateWeekChange(to newDate: Date, targetOffset: CGFloat) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            weekDragOffset = targetOffset
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selectedDate = newDate
                weekDragOffset = 0
            }
        }
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
            } catch {
                modelContext.insert(entry)
            }
        }
    }
}
