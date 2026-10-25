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
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                progressSection

                if !recentWorkouts.isEmpty {
                    recentWorkoutsSection
                }

                motivationalSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppBackground())
        .onAppear {
            loadProgressData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppPalette.tint(progress.color))
                    .frame(width: 46, height: 46)
                Image(systemName: muscleGroup.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(progress.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(muscleGroup.displayName)
                    .font(.appSectionTitle)
                    .foregroundStyle(AppPalette.ink)
                    .lineLimit(1)
                Text(progress.description)
                    .font(.appSubtitle)
                    .foregroundStyle(AppPalette.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(progress.displayName)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(progress.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppPalette.tint(progress.color)))
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppPalette.line, lineWidth: 8)
                    .frame(width: 84, height: 84)

                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(progress.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(workoutCount == 1 ? "1 workout" : "\(workoutCount) workouts")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(AppPalette.ink)

                HStack(spacing: 6) {
                    Image(systemName: trendIcon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(trendColor)
                    Text(trendMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppPalette.ink)
                        .lineLimit(2)
                }

                Text("Compared with your 30-day average")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppPalette.muted)
            }

            Spacer(minLength: 0)
        }
        .appCard(cornerRadius: 22, padding: 16)
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
    
    // MARK: - Trend Section
    
    private var trendSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                        .font(.title3)
                    
                    Text(trendMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text("vs your 30-day average")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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
            return Color(hex: "E07A3D")
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
            HStack(alignment: .firstTextBaseline) {
                Text("Recent")
                    .font(.appCardTitle)
                    .foregroundStyle(AppPalette.ink)
                Spacer()
                Text("\(recentWorkouts.count) this week")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppPalette.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentWorkouts.prefix(5), id: \.id) { workout in
                        recentWorkoutCard(workout)
                    }
                }
            }
        }
    }

    private func recentWorkoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppPalette.ink)
                .lineLimit(1)

            if let completedAt = workout.completedAt {
                Text(RelativeDateTimeFormatter().localizedString(for: completedAt, relativeTo: Date()))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppPalette.muted)
            }

            let exerciseCount = workout.exercises.filter { exercise in
                exercise.primaryMuscleGroup == muscleGroup ||
                exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
            }.count

            if exerciseCount > 0 {
                Text("\(exerciseCount) exercises")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(progress.color)
            }
        }
        .padding(12)
        .frame(width: 148, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppPalette.line, lineWidth: 1)
        )
    }

    // MARK: - Motivational Section

    private var motivationalSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("✨")
                .font(.system(size: 18))
            Text(motivationalMessage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .appCard(cornerRadius: 22, padding: 16)
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
    
    
    // MARK: - Background
    
    private var enhancedBackgroundGradient: some View {
        ZStack {
            // Primary gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle accent gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    progress.color.opacity(0.05),
                    Color.clear,
                    progress.color.opacity(0.02)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

// MARK: - Supporting Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Accessibility

extension MuscleGroupProgressCard {
    private var accessibilityLabel: String {
        "\(muscleGroup.displayName) progress: \(progress.displayName). \(workoutCount) workouts completed. \(motivationalMessage)"
    }
}

#Preview {
    MuscleGroupProgressCard(
        muscleGroup: .chest,
        progress: .gettingTraction,
        opacity: 0.8,
        onDismiss: {}
    )
    .background(AppBackground())
}
