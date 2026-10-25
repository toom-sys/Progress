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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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

    private var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    private var adaptiveSpacing: CGFloat { isCompact ? 12 : 16 }
    private var adaptivePadding: CGFloat { 24 }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title header
            HStack {
                Text("Journey")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: { showingSettings = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textPrimary)

                        Text(subscriptionService.membershipLabel)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(subscriptionService.isSubscribed ? .primary : .textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (subscriptionService.isSubscribed ? Color.primary : Color.textSecondary)
                                    .opacity(0.1)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, adaptivePadding)
            .padding(.top, 12)
            .padding(.bottom, 12)

            ScrollView {
                // VStack (not LazyVStack) so height changes animate sibling
                // positions in sync with expand/collapse.
                VStack(spacing: adaptiveSpacing) {
                    // Personal hero card
                    JourneyHeroCard(user: currentUser, dashboardData: dashboardData)

                    // Streak cards
                    StreakCardsView(dashboardData: dashboardData)

                    // Daily Steps progress bar
                    DailyStepsCardView()

                    // Body weight progression chart
                    WeightTrendCard()

                    if dashboardData.hasData {
                        // Body Map Visualization
                        BodyMapSection()
                    } else {
                        EmptyJourneyCallToAction()
                    }

                    // Achievement badges
                    AchievementsRowView(dashboardData: dashboardData)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 32)
                }
                .padding(.horizontal, adaptivePadding)
            }
        }
        .background(AdaptiveGradientBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(subscriptionService)
        }
    }
}

// MARK: - Shared Widget Styling

/// Single card treatment shared by every Journey widget so the page reads
/// as one coherent surface (matches the body map card's `whiteCardStyle`).
private extension View {
    func journeyCardStyle(padding: CGFloat = 14) -> some View {
        whiteCardStyle(cornerRadius: 14, padding: padding)
    }
}

/// Consistent header used at the top of Journey widgets:
/// tinted icon chip, title, and an optional trailing detail.
struct JourneyCardHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.backgroundSecondary)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Journey Hero Card

struct JourneyHeroCard: View {
    let user: User?
    let dashboardData: DashboardData

    private var initials: String {
        let name = user?.name ?? "Me"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var memberSince: String {
        let date = user?.createdAt ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brand, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text(initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .overlay(
                Circle()
                    .stroke(Color.brand.opacity(0.25), lineWidth: 2)
                    .padding(-3)
            )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user?.name ?? "My Journey")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                if let user = user {
                    Label(user.fitnessGoal.displayName, systemImage: "target")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brand)
                        .lineLimit(2)
                }

                Text("Member since \(memberSince)")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }

            Spacer(minLength: 8)

            // Active streak badge
            VStack(spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text("\(dashboardData.currentStreak)")
                        .font(.numberMedium)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                Text("Day Streak")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .journeyCardStyle()
    }
}

// MARK: - Streak Cards

struct StreakCardsView: View {
    let dashboardData: DashboardData

    var body: some View {
        HStack(spacing: 10) {
            StreakCard(
                title: "Foods Logged",
                value: dashboardData.foodPhotosLogged,
                unit: "photos",
                icon: "camera.fill",
                color: .green,
                description: dashboardData.foodPhotosLogged == 0 ? "Snap a meal to start" : "Keep logging!"
            )

            StreakCard(
                title: "This Week",
                value: dashboardData.workoutsThisWeek,
                unit: "/ \(dashboardData.weeklyWorkoutGoal)",
                icon: "dumbbell.fill",
                color: .brand,
                description: dashboardData.workoutsThisWeek >= dashboardData.weeklyWorkoutGoal ? "Goal reached!" : "\(dashboardData.weeklyWorkoutGoal - dashboardData.workoutsThisWeek) more to goal"
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct StreakCard: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let color: Color
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 22, height: 22)
                    .background(color.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(value)")
                    .font(.numberMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Text(unit)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }

            Text(description)
                .font(.caption2)
                .foregroundColor(value > 0 ? color : .textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .journeyCardStyle(padding: 12)
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
            JourneyCardHeader(
                icon: "trophy.fill",
                iconColor: .yellow,
                title: "Achievements",
                trailing: "\(unlocked)/\(achievements.count)"
            )

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
        .journeyCardStyle()
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
            VStack(spacing: 4) {
                ZStack {
                    if achievement.isUnlocked {
                        Circle()
                            .fill(LinearGradient(
                                colors: [achievement.color.opacity(0.28), achievement.color.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? achievement.color : achievement.color.opacity(0.35),
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                    } else {
                        Circle()
                            .fill(Color.backgroundSecondary)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? Color.textSecondary.opacity(0.5) : Color.border.opacity(0.25),
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                    }

                    Image(systemName: achievement.icon)
                        .font(.subheadline)
                        .foregroundColor(achievement.isUnlocked ? achievement.color : .textTertiary)
                }
                .frame(width: 44, height: 44)
                .scaleEffect(isSelected ? 1.08 : 1)
                .opacity(achievement.isUnlocked ? 1 : 0.7)

                Text(achievement.title)
                    .font(.caption2)
                    .fontWeight(isSelected || achievement.isUnlocked ? .medium : .regular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(
                        isSelected
                            ? .textPrimary
                            : (achievement.isUnlocked ? .textPrimary : .textTertiary)
                    )
                    .frame(width: 56)
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
        .journeyCardStyle()
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
    }

    // MARK: - Workout Metrics

    var totalWorkouts: Int {
        workouts.filter { $0.isCompleted }.count
    }

    var workoutsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workouts.filter { workout in
            workout.isCompleted &&
            (workout.completedAt ?? Date()) >= weekAgo
        }.count
    }

    /// Longest completed workout duration in minutes
    var longestWorkoutMinutes: Int {
        workouts.compactMap { workout -> Int? in
            guard workout.isCompleted, let duration = workout.duration else { return nil }
            return Int(duration / 60)
        }.max() ?? 0
    }

    /// Completed workouts that belong to a training plan
    var completedPlanWorkouts: Int {
        workouts.filter { $0.isCompleted && $0.trainingPlanId != nil }.count
    }

    // MARK: - Nutrition Metrics

    var totalNutritionEntries: Int {
        nutritionEntries.count
    }

    /// Number of foods logged with an uploaded photo (AI camera entries)
    var foodPhotosLogged: Int {
        nutritionEntries.filter { $0.imageData != nil }.count
    }

    var barcodeScans: Int {
        nutritionEntries.filter { $0.logMethod == .barcode }.count
    }

    var aiFoodScans: Int {
        nutritionEntries.filter { $0.logMethod == .aiCamera || $0.logMethod == .aiPrompt }.count
    }

    // MARK: - Water & Weight Metrics

    var totalWaterLogs: Int {
        waterEntries.count
    }

    /// Distinct days where total water logged met or exceeded the daily goal
    var waterGoalDays: Int {
        let calendar = Calendar.current
        let totalsByDay = Dictionary(grouping: waterEntries) { entry in
            calendar.startOfDay(for: entry.loggedAt)
        }.mapValues { entries in
            entries.reduce(0.0) { $0 + $1.amount }
        }
        return totalsByDay.values.filter { $0 >= dailyWaterGoal }.count
    }

    var totalWeightLogs: Int {
        weightEntries.count
    }

    // MARK: - Achievement & Streak Properties

    var perfectWeeks: Int {
        let calendar = Calendar.current
        return (0..<4).compactMap { calendar.date(byAdding: .weekOfYear, value: -$0, to: Date()) }
            .filter { weekStart in
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                let weekWorkouts = workouts.filter { w in
                    guard let c = w.completedAt else { return false }
                    return c >= weekStart && c < weekEnd
                }.count
                let weekNutritionDays = Set(nutritionEntries.compactMap { e -> Date? in
                    guard e.loggedAt >= weekStart && e.loggedAt < weekEnd else { return nil }
                    return calendar.startOfDay(for: e.loggedAt)
                }).count
                return weekWorkouts >= weeklyWorkoutGoal && weekNutritionDays >= 5
            }.count
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        for dayOffset in 0..<90 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { break }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let hasWorkout = workouts.contains { w in
                guard let c = w.completedAt else { return false }
                return c >= dayStart && c < dayEnd
            }
            let hasNutrition = nutritionEntries.contains { $0.loggedAt >= dayStart && $0.loggedAt < dayEnd }
            if hasWorkout || hasNutrition { streak += 1 } else { break }
        }
        return streak
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
