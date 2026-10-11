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
            weeklyWorkoutGoal: weeklyWorkoutGoal
        )
    }

    private var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    private var adaptiveSpacing: CGFloat { isCompact ? 16 : 20 }
    private var adaptivePadding: CGFloat { isCompact ? 20 : 24 }

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
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)

            ScrollView {
                LazyVStack(spacing: adaptiveSpacing) {
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
    func journeyCardStyle(padding: CGFloat = 20) -> some View {
        whiteCardStyle(cornerRadius: 16, padding: padding)
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
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))

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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
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
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brand, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text(initials)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 64, height: 64)
            .overlay(
                Circle()
                    .stroke(Color.brand.opacity(0.25), lineWidth: 3)
                    .padding(-4)
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name ?? "My Journey")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                if let goal = user?.fitnessGoal {
                    Label(goal.displayName, systemImage: "target")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brand)
                }

                Text("Member since \(memberSince)")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }

            Spacer(minLength: 12)

            // Active streak badge
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .journeyCardStyle()
    }
}

// MARK: - Streak Cards

struct StreakCardsView: View {
    let dashboardData: DashboardData

    var body: some View {
        HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 26, height: 26)
                    .background(color.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
                    .font(.numberLarge)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .journeyCardStyle(padding: 16)
    }
}

// MARK: - Daily Steps Card

struct DailyStepsCardView: View {
    @StateObject private var progressTracker: WorkoutProgressTracker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Workout.updatedAt, order: .reverse) private var allWorkouts: [Workout]

    init() {
        _progressTracker = StateObject(wrappedValue: WorkoutProgressTracker(modelContext: nil))
    }

    var body: some View {
        DailyStepsBar(
            currentSteps: progressTracker.currentSteps,
            goalSteps: progressTracker.dailyStepGoal
        )
        .journeyCardStyle()
        .onAppear {
            progressTracker.setModelContext(modelContext)
            progressTracker.startObservingSteps()
            Task { await progressTracker.refresh() }
        }
        .onDisappear {
            progressTracker.stopObservingSteps()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                progressTracker.startObservingSteps()
                Task { await progressTracker.refresh() }
            } else {
                progressTracker.stopObservingSteps()
            }
        }
        .onChange(of: allWorkouts.count) { _, _ in
            Task { await progressTracker.refresh() }
        }
    }
}

// MARK: - Achievement Badges

struct Achievement: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

struct AchievementsRowView: View {
    let dashboardData: DashboardData

    private var achievements: [Achievement] {
        [
            Achievement(id: "first_workout", title: "First Step", icon: "figure.walk", color: .brand,
                        isUnlocked: dashboardData.totalWorkouts >= 1),
            Achievement(id: "five_workouts", title: "5 Workouts", icon: "dumbbell.fill", color: .brand,
                        isUnlocked: dashboardData.totalWorkouts >= 5),
            Achievement(id: "ten_workouts", title: "10 Workouts", icon: "trophy.fill", color: .yellow,
                        isUnlocked: dashboardData.totalWorkouts >= 10),
            Achievement(id: "25_workouts", title: "25 Workouts", icon: "medal.fill", color: .orange,
                        isUnlocked: dashboardData.totalWorkouts >= 25),
            Achievement(id: "first_nutrition", title: "Fuel Up", icon: "leaf.fill", color: .green,
                        isUnlocked: dashboardData.totalNutritionEntries >= 1),
            Achievement(id: "week_nutrition", title: "Week Tracker", icon: "calendar.badge.checkmark", color: .green,
                        isUnlocked: dashboardData.totalNutritionEntries >= 7),
            Achievement(id: "streak_7", title: "7-Day Streak", icon: "flame.fill", color: .orange,
                        isUnlocked: dashboardData.currentStreak >= 7),
            Achievement(id: "streak_30", title: "Month Strong", icon: "star.fill", color: .yellow,
                        isUnlocked: dashboardData.currentStreak >= 30),
            Achievement(id: "perfect_week", title: "Perfect Week", icon: "checkmark.seal.fill", color: .purple,
                        isUnlocked: dashboardData.perfectWeeks >= 1),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let unlocked = achievements.filter(\.isUnlocked).count
            JourneyCardHeader(
                icon: "trophy.fill",
                iconColor: .yellow,
                title: "Achievements",
                trailing: "\(unlocked)/\(achievements.count)"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .journeyCardStyle()
    }
}

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
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
                                .stroke(achievement.color.opacity(0.35), lineWidth: 1)
                        )
                } else {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .overlay(
                            Circle()
                                .stroke(Color.border.opacity(0.25), lineWidth: 1)
                        )
                }

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .textTertiary)
            }
            .frame(width: 52, height: 52)
            .opacity(achievement.isUnlocked ? 1 : 0.7)

            Text(achievement.title)
                .font(.caption2)
                .fontWeight(achievement.isUnlocked ? .medium : .regular)
                .multilineTextAlignment(.center)
                .foregroundColor(achievement.isUnlocked ? .textPrimary : .textTertiary)
                .frame(width: 64)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(achievement.isUnlocked ? "unlocked" : "locked")")
    }
}

// MARK: - Empty Journey Call to Action

struct EmptyJourneyCallToAction: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.brand)
                .frame(width: 56, height: 56)
                .background(Color.brand.opacity(0.12))
                .clipShape(Circle())

            Text("Start tracking to unlock your stats, streaks, and achievements.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button(action: {
                    NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
                }) {
                    Label("Add Workout", systemImage: "dumbbell.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    NotificationCenter.default.post(name: .navigateToNutrition, object: nil)
                }) {
                    Label("Log Food", systemImage: "leaf.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    let weeklyWorkoutGoal: Int

    var hasData: Bool {
        !workouts.isEmpty || !nutritionEntries.isEmpty
    }

    init(workouts: [Workout], nutritionEntries: [NutritionEntry], weeklyWorkoutGoal: Int = 3) {
        self.workouts = workouts
        self.nutritionEntries = nutritionEntries
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
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

    // MARK: - Nutrition Metrics

    var totalNutritionEntries: Int {
        nutritionEntries.count
    }

    /// Number of foods logged with an uploaded photo (AI camera entries)
    var foodPhotosLogged: Int {
        nutritionEntries.filter { $0.imageData != nil }.count
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
        for dayOffset in 0..<30 {
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
    .modelContainer(for: [User.self, Workout.self, NutritionEntry.self, BodyWeightEntry.self], inMemory: true)
    .environmentObject(SubscriptionService())
}
