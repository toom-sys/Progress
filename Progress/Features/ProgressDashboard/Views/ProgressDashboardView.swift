//
//  ProgressDashboardView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Progress Dashboard View (Journey)

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @State private var showingSettings = false

    @Query private var allWorkouts: [Workout]
    @Query private var allNutritionEntries: [NutritionEntry]
    @Query private var allWaterEntries: [WaterEntry]
    @Query private var allWeightEntries: [BodyWeightEntry]
    @Query private var users: [User]

    private var currentUser: User? { users.first }

    private var weeklyWorkoutGoal: Int {
        currentUser?.weeklyWorkoutGoal ?? 3
    }

    private var dashboardData: DashboardData {
        DashboardData(
            workouts: allWorkouts.filter { !$0.isDeleted },
            nutritionEntries: allNutritionEntries,
            waterEntries: allWaterEntries,
            weightEntries: allWeightEntries,
            weeklyWorkoutGoal: weeklyWorkoutGoal,
            dailyWaterGoal: currentUser?.dailyWaterGoal ?? 2500
        )
    }

    var body: some View {
        let data = dashboardData

        return VStack(spacing: 0) {
            journeyHeader(streak: data.currentStreak)

            ScrollView {
                // VStack (not LazyVStack) so height changes animate sibling
                // positions in sync with expand/collapse.
                VStack(spacing: 12) {
                    DailyStepsCardView()

                    if data.hasData {
                        BodyMapSection()
                    } else {
                        EmptyJourneyCallToAction()
                    }

                    WeightTrendCard()

                    AchievementsRowView(dashboardData: data)

                    Color.clear
                        .frame(height: 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(subscriptionService)
        }
    }

    private func journeyHeader(streak: Int) -> some View {
        HStack(spacing: 8) {
            Text("Journey")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundColor(AppPalette.ink)

            Spacer(minLength: 8)

            Text("🔥 \(streak)")
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(AppPalette.ink)
                .frame(height: 36)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(AppPalette.surface)
                        .overlay(Capsule().strokeBorder(AppPalette.line, lineWidth: 1))
                )
                .accessibilityLabel("\(streak) day streak")

            Button {
                showingSettings = true
            } label: {
                Text(subscriptionService.membershipLabel)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(subscriptionService.isSubscribed ? Color.brand : AppPalette.muted)
                    .frame(height: 36)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule().fill(
                            subscriptionService.isSubscribed ? AppPalette.accentSoft : AppPalette.optionFill
                        )
                    )
            }
            .buttonStyle(.plain)

            CircleIconButton(
                systemName: "gearshape",
                style: .plain,
                size: 38,
                accessibilityLabel: "Settings",
                action: { showingSettings = true }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Card header

struct JourneyCardHeader<Trailing: View>: View {
    let emoji: String
    let tint: Color
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            EmojiTile(emoji: emoji, size: 34, background: AppPalette.tint(tint))

            Text(title)
                .font(.appCardTitle)
                .foregroundColor(AppPalette.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                trailing()
            }
        }
    }
}

// MARK: - Achievement Badges

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    /// Short explanation of how to unlock this achievement
    let description: String
    /// User's current progress toward the requirement
    let progressCurrent: Int
    /// Target value required to unlock
    let progressTarget: Int

    var progressFraction: Double {
        guard progressTarget > 0 else { return isUnlocked ? 1 : 0 }
        return min(Double(progressCurrent) / Double(progressTarget), 1)
    }

    var progressLabel: String {
        if isUnlocked {
            return "Completed"
        }
        return "\(min(progressCurrent, progressTarget))/\(progressTarget)"
    }
}

struct AchievementsRowView: View {
    let dashboardData: DashboardData

    @State private var selectedAchievementID: String?

    private var achievements: [Achievement] {
        [
            // Workouts
            Achievement(
                id: "first_workout", title: "First Step", icon: "figure.walk", color: .brand,
                isUnlocked: dashboardData.totalWorkouts >= 1,
                description: "Complete your first workout to get started on your journey.",
                progressCurrent: dashboardData.totalWorkouts, progressTarget: 1
            ),
            Achievement(
                id: "five_workouts", title: "5 Workouts", icon: "dumbbell.fill", color: .brand,
                isUnlocked: dashboardData.totalWorkouts >= 5,
                description: "Finish 5 workouts. Consistency beats intensity early on.",
                progressCurrent: dashboardData.totalWorkouts, progressTarget: 5
            ),
            Achievement(
                id: "ten_workouts", title: "10 Workouts", icon: "trophy.fill", color: .yellow,
                isUnlocked: dashboardData.totalWorkouts >= 10,
                description: "Hit 10 completed workouts and build real momentum.",
                progressCurrent: dashboardData.totalWorkouts, progressTarget: 10
            ),
            Achievement(
                id: "25_workouts", title: "25 Workouts", icon: "medal.fill", color: .orange,
                isUnlocked: dashboardData.totalWorkouts >= 25,
                description: "Complete 25 workouts — you're building a lasting habit.",
                progressCurrent: dashboardData.totalWorkouts, progressTarget: 25
            ),
            Achievement(
                id: "50_workouts", title: "Half Century", icon: "flag.fill", color: .orange,
                isUnlocked: dashboardData.totalWorkouts >= 50,
                description: "Reach 50 completed workouts. That's serious dedication.",
                progressCurrent: dashboardData.totalWorkouts, progressTarget: 50
            ),
            Achievement(
                id: "100_workouts", title: "Century Club", icon: "crown.fill", color: .yellow,
                isUnlocked: dashboardData.totalWorkouts >= 100,
                description: "Complete 100 workouts and join the Century Club.",
                progressCurrent: dashboardData.totalWorkouts, progressTarget: 100
            ),
            Achievement(
                id: "hour_session", title: "Hour Power", icon: "clock.fill", color: .brand,
                isUnlocked: dashboardData.longestWorkoutMinutes >= 60,
                description: "Complete a single workout lasting at least 60 minutes.",
                progressCurrent: min(dashboardData.longestWorkoutMinutes, 60), progressTarget: 60
            ),
            Achievement(
                id: "plan_finisher", title: "Plan Finisher", icon: "list.clipboard.fill", color: .purple,
                isUnlocked: dashboardData.completedPlanWorkouts >= 1,
                description: "Complete a workout from one of your training plans.",
                progressCurrent: dashboardData.completedPlanWorkouts, progressTarget: 1
            ),

            // Nutrition
            Achievement(
                id: "first_nutrition", title: "Fuel Up", icon: "leaf.fill", color: .green,
                isUnlocked: dashboardData.totalNutritionEntries >= 1,
                description: "Log your first food entry to start tracking nutrition.",
                progressCurrent: dashboardData.totalNutritionEntries, progressTarget: 1
            ),
            Achievement(
                id: "week_nutrition", title: "Week Tracker", icon: "calendar.badge.checkmark", color: .green,
                isUnlocked: dashboardData.totalNutritionEntries >= 7,
                description: "Log 7 food entries — enough to see a full week's patterns.",
                progressCurrent: dashboardData.totalNutritionEntries, progressTarget: 7
            ),
            Achievement(
                id: "month_nutrition", title: "Food Diary", icon: "book.fill", color: .green,
                isUnlocked: dashboardData.totalNutritionEntries >= 30,
                description: "Reach 30 food logs and keep a solid food diary going.",
                progressCurrent: dashboardData.totalNutritionEntries, progressTarget: 30
            ),
            Achievement(
                id: "century_nutrition", title: "Macro Master", icon: "chart.pie.fill", color: .green,
                isUnlocked: dashboardData.totalNutritionEntries >= 100,
                description: "Log 100 foods. You're dialed in on your macros.",
                progressCurrent: dashboardData.totalNutritionEntries, progressTarget: 100
            ),
            Achievement(
                id: "first_photo", title: "Snap It", icon: "camera.fill", color: .blue,
                isUnlocked: dashboardData.foodPhotosLogged >= 1,
                description: "Log a meal with a photo using the camera.",
                progressCurrent: dashboardData.foodPhotosLogged, progressTarget: 1
            ),
            Achievement(
                id: "photo_pro", title: "Photo Pro", icon: "photo.fill", color: .blue,
                isUnlocked: dashboardData.foodPhotosLogged >= 10,
                description: "Snap and log 10 meal photos.",
                progressCurrent: dashboardData.foodPhotosLogged, progressTarget: 10
            ),
            Achievement(
                id: "barcode_scan", title: "Scan It", icon: "barcode.viewfinder", color: .blue,
                isUnlocked: dashboardData.barcodeScans >= 1,
                description: "Scan a food barcode to log nutrition instantly.",
                progressCurrent: dashboardData.barcodeScans, progressTarget: 1
            ),
            Achievement(
                id: "ai_chef", title: "AI Chef", icon: "sparkles", color: .purple,
                isUnlocked: dashboardData.aiFoodScans >= 1,
                description: "Use AI camera recognition to identify and log a meal.",
                progressCurrent: dashboardData.aiFoodScans, progressTarget: 1
            ),

            // Streaks & consistency
            Achievement(
                id: "streak_7", title: "7-Day Streak", icon: "flame.fill", color: .orange,
                isUnlocked: dashboardData.currentStreak >= 7,
                description: "Log a workout or food for 7 days in a row.",
                progressCurrent: dashboardData.currentStreak, progressTarget: 7
            ),
            Achievement(
                id: "streak_14", title: "Two Weeks", icon: "bolt.fill", color: .orange,
                isUnlocked: dashboardData.currentStreak >= 14,
                description: "Keep a 14-day streak of workouts or nutrition logs.",
                progressCurrent: dashboardData.currentStreak, progressTarget: 14
            ),
            Achievement(
                id: "streak_30", title: "Month Strong", icon: "star.fill", color: .yellow,
                isUnlocked: dashboardData.currentStreak >= 30,
                description: "Maintain a 30-day streak. A full month of showing up.",
                progressCurrent: dashboardData.currentStreak, progressTarget: 30
            ),
            Achievement(
                id: "streak_60", title: "Unstoppable", icon: "heart.fill", color: .red,
                isUnlocked: dashboardData.currentStreak >= 60,
                description: "Hit a 60-day streak — that's unstoppable consistency.",
                progressCurrent: dashboardData.currentStreak, progressTarget: 60
            ),
            Achievement(
                id: "perfect_week", title: "Perfect Week", icon: "checkmark.seal.fill", color: .purple,
                isUnlocked: dashboardData.perfectWeeks >= 1,
                description: "Hit your weekly workout goal and log food on at least 5 days in the same week.",
                progressCurrent: dashboardData.perfectWeeks, progressTarget: 1
            ),
            Achievement(
                id: "perfect_month", title: "Perfect Month", icon: "seal.fill", color: .purple,
                isUnlocked: dashboardData.perfectWeeks >= 4,
                description: "Earn 4 perfect weeks — a full month of balanced tracking.",
                progressCurrent: dashboardData.perfectWeeks, progressTarget: 4
            ),

            // Hydration & body weight
            Achievement(
                id: "first_water", title: "Hydrated", icon: "drop.fill", color: .cyan,
                isUnlocked: dashboardData.totalWaterLogs >= 1,
                description: "Log your first glass of water.",
                progressCurrent: dashboardData.totalWaterLogs, progressTarget: 1
            ),
            Achievement(
                id: "water_week", title: "Water Week", icon: "humidity.fill", color: .cyan,
                isUnlocked: dashboardData.waterGoalDays >= 7,
                description: "Hit your daily water goal on 7 different days.",
                progressCurrent: dashboardData.waterGoalDays, progressTarget: 7
            ),
            Achievement(
                id: "first_weigh_in", title: "On the Scale", icon: "scalemass.fill", color: .indigo,
                isUnlocked: dashboardData.totalWeightLogs >= 1,
                description: "Log your first body weight entry.",
                progressCurrent: dashboardData.totalWeightLogs, progressTarget: 1
            ),
            Achievement(
                id: "consistent_weigh", title: "Keep Weighing", icon: "chart.line.uptrend.xyaxis", color: .indigo,
                isUnlocked: dashboardData.totalWeightLogs >= 4,
                description: "Log your weight 4 times to start seeing a real trend.",
                progressCurrent: dashboardData.totalWeightLogs, progressTarget: 4
            ),
        ]
    }

    private var selectedAchievement: Achievement? {
        guard let selectedAchievementID else { return nil }
        return achievements.first { $0.id == selectedAchievementID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let unlocked = achievements.filter(\.isUnlocked).count
            JourneyCardHeader(emoji: "🏆", tint: .yellow, title: "Achievements") {
                HStack(spacing: 4) {
                    Text("\(unlocked)")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(AppPalette.ink)
                    Text(" / \(achievements.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppPalette.muted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppPalette.muted)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(unlocked) of \(achievements.count) unlocked")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            isSelected: selectedAchievementID == achievement.id
                        ) {
                            selectAchievement(achievement.id)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }

            if let selected = selectedAchievement {
                AchievementDetailPanel(achievement: selected)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
            }
        }
        .appCard(cornerRadius: 22, padding: 14)
    }

    private func selectAchievement(_ id: String) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            if selectedAchievementID == id {
                selectedAchievementID = nil
            } else {
                selectedAchievementID = id
            }
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if achievement.isUnlocked {
                        Circle()
                            .fill(LinearGradient(
                                colors: [
                                    achievement.color.opacity(0.14),
                                    achievement.color.opacity(0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(Circle().strokeBorder(AppPalette.surface, lineWidth: 2))
                            .shadow(color: achievement.color.opacity(0.22), radius: 7, y: 6)

                        Image(systemName: achievement.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(achievement.color)
                    } else {
                        Circle()
                            .fill(AppPalette.optionFill)
                            .overlay(
                                Circle().strokeBorder(
                                    AppPalette.line,
                                    style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                                )
                            )

                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppPalette.muted)
                    }
                }
                .frame(width: 58, height: 58)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(Color.brand, lineWidth: 2)
                    }
                }
                .scaleEffect(isSelected ? 1.08 : 1)

                Text(achievement.title)
                    .font(.system(size: 11, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(achievement.isUnlocked ? AppPalette.ink : AppPalette.muted)
                    .frame(width: 72)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(achievement.isUnlocked ? "unlocked" : "locked")")
        .accessibilityHint(isSelected ? "Shows details. Double tap to collapse." : "Double tap to show details.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct AchievementDetailPanel: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                achievement.color.opacity(achievement.isUnlocked ? 0.28 : 0.12),
                                achievement.color.opacity(achievement.isUnlocked ? 0.12 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            Circle()
                                .stroke(achievement.color.opacity(0.35), lineWidth: 1)
                        )

                    Image(systemName: achievement.icon)
                        .font(.body.weight(.semibold))
                        .foregroundColor(achievement.isUnlocked ? achievement.color : .textTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .contentTransition(.opacity)

                    Text(achievement.isUnlocked ? "Unlocked" : "Locked")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(achievement.isUnlocked ? achievement.color : .textTertiary)
                        .contentTransition(.opacity)
                }

                Spacer(minLength: 0)

                Text(achievement.progressLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (achievement.isUnlocked ? achievement.color : Color.textSecondary)
                            .opacity(0.12)
                    )
                    .clipShape(Capsule())
                    .contentTransition(.opacity)
            }

            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.backgroundSecondary)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    achievement.color.opacity(0.85),
                                    achievement.color
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * achievement.progressFraction))
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.color.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title). \(achievement.isUnlocked ? "Unlocked" : "Locked"). \(achievement.description). Progress \(achievement.progressLabel).")
    }
}

// MARK: - Empty Journey Call to Action

struct EmptyJourneyCallToAction: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.brand)
                .frame(width: 44, height: 44)
                .background(Color.brand.opacity(0.12))
                .clipShape(Circle())

            Text("Start tracking to unlock your stats, streaks, and achievements.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 10) {
                Button(action: {
                    NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
                }) {
                    Label("Add Workout", systemImage: "dumbbell.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {
                    NotificationCenter.default.post(name: .navigateToNutrition, object: nil)
                }) {
                    Label("Log Food", systemImage: "leaf.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .appCard(cornerRadius: 22, padding: 14)
    }
}

// MARK: - Dashboard Data Model

struct DashboardData {
    let workouts: [Workout]
    let nutritionEntries: [NutritionEntry]
    let waterEntries: [WaterEntry]
    let weightEntries: [BodyWeightEntry]
    let weeklyWorkoutGoal: Int
    let dailyWaterGoal: Double
    private let metrics: Metrics

    var hasData: Bool {
        !workouts.isEmpty || !nutritionEntries.isEmpty
    }

    init(
        workouts: [Workout],
        nutritionEntries: [NutritionEntry],
        waterEntries: [WaterEntry] = [],
        weightEntries: [BodyWeightEntry] = [],
        weeklyWorkoutGoal: Int = 3,
        dailyWaterGoal: Double = 2500
    ) {
        self.workouts = workouts
        self.nutritionEntries = nutritionEntries
        self.waterEntries = waterEntries
        self.weightEntries = weightEntries
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.metrics = Metrics(
            workouts: workouts,
            nutritionEntries: nutritionEntries,
            waterEntries: waterEntries,
            weeklyWorkoutGoal: weeklyWorkoutGoal,
            dailyWaterGoal: dailyWaterGoal
        )
    }

    var totalWorkouts: Int { metrics.totalWorkouts }
    var workoutsThisWeek: Int { metrics.workoutsThisWeek }
    /// Longest completed workout duration in minutes
    var longestWorkoutMinutes: Int { metrics.longestWorkoutMinutes }
    /// Completed workouts that belong to a training plan
    var completedPlanWorkouts: Int { metrics.completedPlanWorkouts }
    var totalNutritionEntries: Int { metrics.totalNutritionEntries }
    /// Foods logged from the camera. Counted by log method so photo bytes stay unloaded.
    var foodPhotosLogged: Int { metrics.foodPhotosLogged }
    var barcodeScans: Int { metrics.barcodeScans }
    var aiFoodScans: Int { metrics.aiFoodScans }
    var totalWaterLogs: Int { metrics.totalWaterLogs }
    /// Distinct days where total water logged met or exceeded the daily goal
    var waterGoalDays: Int { metrics.waterGoalDays }
    var totalWeightLogs: Int { weightEntries.count }
    var perfectWeeks: Int { metrics.perfectWeeks }
    var currentStreak: Int { metrics.currentStreak }

    private struct Metrics {
        let totalWorkouts: Int
        let workoutsThisWeek: Int
        let longestWorkoutMinutes: Int
        let completedPlanWorkouts: Int
        let totalNutritionEntries: Int
        let foodPhotosLogged: Int
        let barcodeScans: Int
        let aiFoodScans: Int
        let totalWaterLogs: Int
        let waterGoalDays: Int
        let perfectWeeks: Int
        let currentStreak: Int

        init(
            workouts: [Workout],
            nutritionEntries: [NutritionEntry],
            waterEntries: [WaterEntry],
            weeklyWorkoutGoal: Int,
            dailyWaterGoal: Double
        ) {
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

            var totalWorkouts = 0
            var workoutsThisWeek = 0
            var longestWorkoutMinutes = 0
            var completedPlanWorkouts = 0
            var activeDays = Set<Date>()

            for workout in workouts {
                if let completedAt = workout.completedAt {
                    activeDays.insert(calendar.startOfDay(for: completedAt))
                }
                guard workout.isCompleted else { continue }
                totalWorkouts += 1
                if (workout.completedAt ?? now) >= weekAgo {
                    workoutsThisWeek += 1
                }
                if let duration = workout.duration {
                    longestWorkoutMinutes = max(longestWorkoutMinutes, Int(duration / 60))
                }
                if workout.trainingPlanId != nil {
                    completedPlanWorkouts += 1
                }
            }

            var foodPhotosLogged = 0
            var barcodeScans = 0
            var aiFoodScans = 0
            for entry in nutritionEntries {
                activeDays.insert(calendar.startOfDay(for: entry.loggedAt))
                switch entry.logMethod {
                case .aiCamera:
                    foodPhotosLogged += 1
                    aiFoodScans += 1
                case .aiPrompt:
                    aiFoodScans += 1
                case .barcode:
                    barcodeScans += 1
                case .manual, .search, .favorite, .recent:
                    break
                }
            }

            let totalsByDay = Dictionary(grouping: waterEntries) { entry in
                calendar.startOfDay(for: entry.loggedAt)
            }.mapValues { entries in
                entries.reduce(0.0) { $0 + $1.amount }
            }

            var streak = 0
            for dayOffset in 0..<90 {
                guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { break }
                if activeDays.contains(calendar.startOfDay(for: day)) {
                    streak += 1
                } else {
                    break
                }
            }

            let completedDates = workouts.compactMap(\.completedAt)
            let nutritionDates = nutritionEntries.map(\.loggedAt)
            let perfectWeeks = (0..<4).compactMap { calendar.date(byAdding: .weekOfYear, value: -$0, to: now) }
                .filter { weekStart in
                    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                    let weekWorkouts = completedDates.filter { $0 >= weekStart && $0 < weekEnd }.count
                    let weekNutritionDays = Set(nutritionDates.compactMap { date -> Date? in
                        guard date >= weekStart && date < weekEnd else { return nil }
                        return calendar.startOfDay(for: date)
                    }).count
                    return weekWorkouts >= weeklyWorkoutGoal && weekNutritionDays >= 5
                }.count

            self.totalWorkouts = totalWorkouts
            self.workoutsThisWeek = workoutsThisWeek
            self.longestWorkoutMinutes = longestWorkoutMinutes
            self.completedPlanWorkouts = completedPlanWorkouts
            self.totalNutritionEntries = nutritionEntries.count
            self.foodPhotosLogged = foodPhotosLogged
            self.barcodeScans = barcodeScans
            self.aiFoodScans = aiFoodScans
            self.totalWaterLogs = waterEntries.count
            self.waterGoalDays = totalsByDay.values.filter { $0 >= dailyWaterGoal }.count
            self.perfectWeeks = perfectWeeks
            self.currentStreak = streak
        }
    }
}


// MARK: - Preview

#Preview("Journey") {
    NavigationStack {
        ProgressDashboardView()
    }
    .modelContainer(for: [User.self, Workout.self, NutritionEntry.self, BodyWeightEntry.self, WaterEntry.self], inMemory: true)
    .environmentObject(SubscriptionService())
}
