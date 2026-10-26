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
            Text("Nutrition")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundColor(AppPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
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

                    HStack(alignment: .firstTextBaseline) {
                        Text(isToday ? "Today's food" : "Food")
                            .font(.appSectionTitle)
                            .foregroundColor(AppPalette.ink)
                        Spacer()
                        Text("\(Int(selectedDateEntries.reduce(0) { $0 + $1.totalCalories })) kcal")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppPalette.muted)
                    }
                    .padding(.horizontal, 20)
                    
                    // Food List or empty message
                    if selectedDateEntries.isEmpty {
                        emptyFoodMessage
                    } else {
                        foodEntriesList
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
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
        HStack(spacing: 14) {
            EmojiTile(emoji: "🍽️", size: 56, background: AppPalette.tint(.green))

            VStack(alignment: .leading, spacing: 3) {
                Text("Log your first meal")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(AppPalette.ink)
                Text("Snap a photo, describe it or enter it manually.")
                    .font(.system(size: 14))
                    .foregroundColor(AppPalette.muted)
            }

            Spacer(minLength: 0)

            AddFoodMenu(
                showingCameraAI: $showingCameraAI,
                showingDescribeFood: $showingDescribeFood,
                showingManualEntry: $showingManualEntry,
                showingWaterLog: $showingWaterLog
            ) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppPalette.onInk)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppPalette.ink))
                    .shadow(color: Color.black.opacity(0.25), radius: 8, y: 6)
            }
            .accessibilityLabel("Log food")
        }
        .appCard(cornerRadius: 24, padding: 20)
        .padding(.horizontal, 20)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(validatedSelectedDate, inSameDayAs: Date())
    }
    
    private var foodEntriesList: some View {
        LazyVStack(spacing: 20) {
            logFoodButton

            ForEach(selectedDateEntries) { entry in
                SwipeableNutritionRow(
                    entry: entry,
                    onDelete: {
                        deleteNutritionEntry(entry)
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private var logFoodButton: some View {
        AddFoodMenu(
            showingCameraAI: $showingCameraAI,
            showingDescribeFood: $showingDescribeFood,
            showingManualEntry: $showingManualEntry,
            showingWaterLog: $showingWaterLog
        ) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppPalette.onInk)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppPalette.ink))
                Text("Log food")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppPalette.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppPalette.surface.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppPalette.muted.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .accessibilityLabel("Log food")
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
        .frame(height: 86)
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
        .padding(.horizontal, 14)
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

/// The four ways to log food. Both the empty state and the list button use this menu.
private struct AddFoodMenu<Label: View>: View {
    @Binding var showingCameraAI: Bool
    @Binding var showingDescribeFood: Bool
    @Binding var showingManualEntry: Bool
    @Binding var showingWaterLog: Bool
    @ViewBuilder var label: () -> Label

    var body: some View {
        Menu {
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
        } label: {
            label()
        }
    }
}

// MARK: - Preview

private struct NutritionDashboardPreview: View {
    private let container: ModelContainer

    init(withEntries: Bool) {
        let container = try! ModelContainer(
            for: User.self, Workout.self, NutritionEntry.self, BodyWeightEntry.self, WaterEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        if withEntries {
            let context = container.mainContext
            context.insert(
                NutritionEntry(
                    foodName: "Greek yogurt",
                    servingSize: "150 g",
                    quantity: 1,
                    calories: 130,
                    protein: 15,
                    carbohydrates: 8,
                    fat: 4,
                    mealType: .breakfast
                )
            )
            context.insert(
                NutritionEntry(
                    foodName: "Chicken salad",
                    servingSize: "1 bowl",
                    quantity: 1,
                    calories: 420,
                    protein: 35,
                    carbohydrates: 18,
                    fat: 22,
                    mealType: .lunch
                )
            )
        }
        self.container = container
    }

    var body: some View {
        NavigationStack {
            NutritionDashboardView()
        }
        .modelContainer(container)
        .environmentObject(SubscriptionService())
    }
}

#Preview("Empty") {
    NutritionDashboardPreview(withEntries: false)
        .preferredColorScheme(.light)
}

#Preview("Empty Dark") {
    NutritionDashboardPreview(withEntries: false)
        .preferredColorScheme(.dark)
}

#Preview("With entries") {
    NutritionDashboardPreview(withEntries: true)
        .preferredColorScheme(.light)
}

#Preview("With entries Dark") {
    NutritionDashboardPreview(withEntries: true)
        .preferredColorScheme(.dark)
}
