import SwiftUI
import SwiftData

/// Interactive progress card that displays detailed muscle group information
/// with trend analysis, recent workouts, and motivational messaging
struct MuscleGroupProgressCard: View {
    let muscleGroup: MuscleGroup
    let progress: ProgressTier
    let opacity: Double
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var recentWorkouts: [Workout] = []
    @State private var trendPercentage: Double = 0
    @State private var workoutCount: Int = 0
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                progressSection

                if !recentWorkouts.isEmpty {
                    recentWorkoutsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(AppBackground())
        .onAppear {
            loadProgressData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(muscleGroup.displayName)
                .font(.appSectionTitle)
                .foregroundStyle(AppPalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(muscleGroup.description)
                .font(.appSubtitle)
                .foregroundStyle(AppPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppPalette.tint(progress.color))
                        .frame(width: 44, height: 44)
                    Image(systemName: muscleGroup.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(progress.color)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.displayName)
                        .font(.appCardTitle)
                        .foregroundStyle(AppPalette.ink)
                    Text(progress.description)
                        .font(.appSubtitle)
                        .foregroundStyle(AppPalette.muted)
                }

                Spacer(minLength: 8)

                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppPalette.line)
                    Capsule()
                        .fill(progress.color)
                        .frame(width: max(0, geo.size.width * progressPercentage))
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(workoutCount)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                    Text(workoutCount == 1 ? "Workout" : "Workouts")
                        .font(.appSubtitle)
                        .foregroundStyle(AppPalette.muted)
                }

                Rectangle()
                    .fill(AppPalette.line)
                    .frame(width: 1, height: 28)

                HStack(spacing: 6) {
                    Image(systemName: trendIcon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(trendColor)
                        .accessibilityHidden(true)
                    Text(trendMessage)
                        .font(.appSubtitle)
                        .foregroundStyle(AppPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Text(motivationalMessage)
                .font(.appSubtitle)
                .foregroundStyle(AppPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard(cornerRadius: 22, padding: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(muscleGroup.displayName), \(progress.displayName). \(workoutCount) workouts. \(trendMessage). \(motivationalMessage)")
    }
    
    private var progressPercentage: Double {
        switch progress {
        case .dormant: return 0.0
        case .beginnerSpark: return 0.2
        case .gettingTraction: return 0.4
        case .solidIntermediate: return 0.6
        case .advanced: return 0.8
        case .athleteTier: return 1.0
        }
    }
    
    private var trendIcon: String {
        if trendPercentage > 10 {
            return "arrow.up.right"
        } else if trendPercentage < -10 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        if trendPercentage > 10 {
            return AppPalette.live
        } else if trendPercentage < -10 {
            return AppPalette.carbs
        } else {
            return AppPalette.muted
        }
    }
    
    private var trendMessage: String {
        let absPercentage = abs(trendPercentage)
        if trendPercentage > 10 {
            return "Trending up \(Int(absPercentage))%"
        } else if trendPercentage < -10 {
            return "Down \(Int(absPercentage))% recently"
        } else {
            return "Steady progress"
        }
    }
    
    // MARK: - Recent Workouts Section
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK")
                .font(.system(size: 13, weight: .heavy))
                .tracking(0.4)
                .foregroundStyle(AppPalette.muted)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(recentWorkouts.prefix(5), id: \.id) { workout in
                    recentWorkoutCard(workout)
                }
            }
        }
    }

    private func recentWorkoutCard(_ workout: Workout) -> some View {
        let exerciseCount = workout.exercises.filter { exercise in
            exercise.primaryMuscleGroup == muscleGroup ||
            exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
        }.count

        return HStack(spacing: 12) {
            EmojiTile(emoji: "🏋️", size: 40, background: AppPalette.surface)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.appCardTitle)
                    .foregroundStyle(AppPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let completedAt = workout.completedAt {
                    Text(RelativeDateTimeFormatter().localizedString(for: completedAt, relativeTo: Date()))
                        .font(.appSubtitle)
                        .foregroundStyle(AppPalette.muted)
                }
            }

            Spacer(minLength: 8)

            if exerciseCount > 0 {
                Text(exerciseCount == 1 ? "1 exercise" : "\(exerciseCount) exercises")
                    .font(.appSubtitle)
                    .foregroundStyle(progress.color)
                    .multilineTextAlignment(.trailing)
            }
        }
        .appGroupRow(cornerRadius: 18)
        .accessibilityElement(children: .combine)
    }

    private var motivationalMessage: String {
        switch progress {
        case .dormant:
            return "Ready to light up this muscle group? Add it to your next workout!"
        case .beginnerSpark:
            return "Great start! Keep training to build momentum."
        case .gettingTraction:
            return "You're building consistency! Keep up the excellent work."
        case .solidIntermediate:
            return "Impressive dedication! Your consistency is paying off."
        case .advanced:
            return "Elite level training! You're in the top tier of commitment."
        case .athleteTier:
            return "Legendary consistency! You've mastered this muscle group."
        }
    }
    
    
    // MARK: - Data Loading
    
    private func loadProgressData() {
        Task {
            await loadRecentWorkouts()
            await calculateTrend()
            await loadWorkoutCount()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func loadRecentWorkouts() async {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            
            let recent = allWorkouts.filter { workout in
                !workout.isDeleted &&
                workout.status == .completed &&
                (workout.completedAt ?? Date.distantPast) >= sevenDaysAgo &&
                workout.exercises.contains { exercise in
                    exercise.primaryMuscleGroup == muscleGroup ||
                    exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
                }
            }
            
            await MainActor.run {
                self.recentWorkouts = recent
            }
        } catch { /* silently ignore */ }
    }
    
    private func calculateTrend() async {
        // Calculate 7-day vs 30-day average trend
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            let completedWorkouts = allWorkouts.filter { !$0.isDeleted && $0.status == .completed }
            
            // Recent 7 days
            let recentWorkouts = completedWorkouts.filter {
                ($0.completedAt ?? Date.distantPast) >= sevenDaysAgo
            }
            
            // Previous 23 days (to make 30 total)
            let previousWorkouts = completedWorkouts.filter {
                let date = $0.completedAt ?? Date.distantPast
                return date >= thirtyDaysAgo && date < sevenDaysAgo
            }
            
            let recentCount = recentWorkouts.filter { workout in
                workout.exercises.contains { exercise in
                    exercise.primaryMuscleGroup == muscleGroup ||
                    exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
                }
            }.count
            
            let previousCount = previousWorkouts.filter { workout in
                workout.exercises.contains { exercise in
                    exercise.primaryMuscleGroup == muscleGroup ||
                    exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
                }
            }.count
            
            // Calculate trend percentage
            let recentAverage = Double(recentCount) / 7.0  // per day
            let previousAverage = Double(previousCount) / 23.0  // per day
            
            let trend = previousAverage > 0 ? 
                ((recentAverage - previousAverage) / previousAverage) * 100 : 0
            
            await MainActor.run {
                self.trendPercentage = trend
            }
        } catch { /* silently ignore */ }
    }
    
    private func loadWorkoutCount() async {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            let count = allWorkouts.filter { workout in
                !workout.isDeleted &&
                workout.status == .completed &&
                workout.exercises.contains { exercise in
                    exercise.primaryMuscleGroup == muscleGroup ||
                    exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
                }
            }.count
            
            await MainActor.run {
                self.workoutCount = count
            }
        } catch { /* silently ignore */ }
    }
}

#Preview("Light") {
    MuscleGroupProgressCard(
        muscleGroup: .chest,
        progress: .gettingTraction,
        opacity: 0.8,
        onDismiss: {}
    )
    .background(AppBackground())
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    MuscleGroupProgressCard(
        muscleGroup: .chest,
        progress: .gettingTraction,
        opacity: 0.8,
        onDismiss: {}
    )
    .background(AppBackground())
    .preferredColorScheme(.dark)
}
