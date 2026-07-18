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
    
    // Enhanced animation state
    @State private var headerScale: Double = 0.8
    @State private var progressRingScale: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var slideOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with muscle group info
            headerSection
            
            // Progress visualization
            progressSection
            
            // Recent workouts
            if !recentWorkouts.isEmpty {
                recentWorkoutsSection
            }
            
            // Motivational message
            motivationalSection
        }
        .elevatedCardStyle(cornerRadius: 20, padding: 0)
        .scaleEffect(headerScale)
        .opacity(contentOpacity)
        .offset(y: slideOffset)
        .onAppear {
            loadProgressData()
            startEntranceAnimation()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Enhanced muscle group icon and name
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    progress.color.opacity(0.3),
                                    progress.color.opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: muscleGroup.icon)
                        .font(.title2)
                        .foregroundColor(progress.color)
                        .fontWeight(.semibold)
                }
                .scaleEffect(headerScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: headerScale)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(muscleGroup.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(progress.displayName)
                        .font(.subheadline)
                        .foregroundColor(progress.color)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Enhanced progress tier badge
            enhancedProgressBadge
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var enhancedProgressBadge: some View {
        Text(progress.displayName.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        progress.color,
                        progress.color.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: progress.color.opacity(0.4), radius: 4, x: 0, y: 2)
            .scaleEffect(headerScale)
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0), value: headerScale)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        HStack(spacing: 24) {
            // Progress Circle Area
            VStack(spacing: 8) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    // Glow effect ring
                    Circle()
                        .stroke(progress.color.opacity(0.3), lineWidth: 12)
                        .frame(width: 100, height: 100)
                        .blur(radius: 4)
                    
                    // Main progress ring
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    progress.color,
                                    progress.color.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(progressRingScale)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0), value: progressRingScale)
                        .animation(.easeInOut(duration: 1.5), value: progressPercentage)
                    
                    // Center content
                    VStack(spacing: 3) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 1.0), value: progressPercentage)
                        
                        Text("PROGRESS")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                            .tracking(1)
                    }
                    .scaleEffect(progressRingScale * 0.9)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.2), value: progressRingScale)
                }
                
                Text("\(workoutCount) workouts completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Trend Arrow Area
            VStack(spacing: 8) {
                Image(systemName: trendPercentage == 0 ? "arrow.right" : trendIcon)
                    .foregroundColor(trendPercentage == 0 ? .gray : trendColor)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                
                Text(trendMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("vs 30-day avg")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
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
            return .green
        } else if trendPercentage < -10 {
            return .orange
        } else {
            return .blue
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
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack {
                Text("Recent Workouts")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(recentWorkouts.count) this week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentWorkouts.prefix(5), id: \.id) { workout in
                        recentWorkoutCard(workout)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }
    
    private func recentWorkoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if let completedAt = workout.completedAt {
                Text(RelativeDateTimeFormatter().localizedString(for: completedAt, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Exercise count for this muscle group
            let exerciseCount = workout.exercises.filter { exercise in
                exercise.primaryMuscleGroup == muscleGroup ||
                exercise.secondaryMuscleGroupsDecoded.keys.contains(muscleGroup)
            }.count
            
            if exerciseCount > 0 {
                Text("\(exerciseCount) exercises")
                    .font(.caption2)
                    .foregroundColor(progress.color)
                    .fontWeight(.medium)
            }
        }
        .padding(12)
        .frame(width: 120)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Motivational Section
    
    private var motivationalSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 8) // Extra bottom padding since this is now the last section
        }
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
    
    // MARK: - Animation Methods
    
    private func startEntranceAnimation() {
        // Staggered entrance animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            headerScale = 1.0
            contentOpacity = 1.0
            slideOffset = 0
        }
        
        // Progress ring animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                progressRingScale = 1.0
            }
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
    .padding()
    .background(Color(.systemGray6))
}
