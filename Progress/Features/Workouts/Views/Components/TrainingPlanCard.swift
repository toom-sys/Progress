//
//  TrainingPlanCard.swift
//  Progress
//

import SwiftUI
import SwiftData

struct TrainingPlanCard: View {
    let plan: TrainingPlan
    var history: [Workout] = []
    let onStartWorkout: (Workout) -> Void

    @AppStorage("workouts.planCard.expanded") private var isExpanded = true

    private var activeWorkouts: [Workout] {
        plan.workouts.filter { !$0.isDeleted }
    }

    private var orderedWorkouts: [Workout] {
        PlanWorkoutQueue.ordered(activeWorkouts, history: history)
    }

    private var sessionProgress: (done: Int, total: Int) {
        PlanWorkoutQueue.progress(for: activeWorkouts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    progressSection

                    if !orderedWorkouts.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(orderedWorkouts, id: \.id) { workout in
                                planRow(workout)
                            }
                        }
                    }
                }
            } else {
                collapsedPills
            }
        }
        .appCard(cornerRadius: 26, padding: 18)
    }

    @ViewBuilder
    private func planRow(_ workout: Workout) -> some View {
        if workout.id == orderedWorkouts.first?.id {
            UpNextPlanRow(workout: workout, onStart: start)
        } else {
            PlanWorkoutRow(workout: workout, onStart: { start(workout) })
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR PLAN")
                    .font(.appEyebrow)
                    .tracking(1)
                    .foregroundColor(AppPalette.muted)

                Text(plan.name)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(AppPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ChevronToggleButton(
                isExpanded: isExpanded,
                size: 34,
                accessibilityLabel: isExpanded ? "Collapse plan" : "Expand plan",
                action: toggleExpanded
            )
        }
    }

    private var progressSection: some View {
        let done = sessionProgress.done
        let total = sessionProgress.total
        let fraction = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 8) {
            AppProgressBar(progress: fraction)
            Text("\(done) of \(total) sessions done")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
        }
    }

    private var collapsedPills: some View {
        PillWrapLayout(spacing: 6) {
            ForEach(orderedWorkouts, id: \.id) { workout in
                let sessionIndex = workout.planSessionIndex ?? 1
                Text("\(planEmoji(for: workout.name)) \(workout.name) \(sessionIndex)/5")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(AppPalette.ink.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppPalette.optionFill))
                    .accessibilityLabel("\(workout.name), session \(sessionIndex) of 5")
            }
        }
    }

    private func toggleExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isExpanded.toggle()
        }
    }

    private func start(_ workout: Workout) {
        HapticFeedback.workoutButtonTap()
        onStartWorkout(workout)
    }
}

// MARK: - Up next

private struct UpNextPlanRow: View {
    let workout: Workout
    let onStart: (Workout) -> Void

    private var sessionIndex: Int {
        workout.planSessionIndex ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                EmojiTile(
                    emoji: planEmoji(for: workout.name),
                    background: AppPalette.surface
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(workout.name)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(AppPalette.ink)
                            .lineLimit(1)

                        Text("UP NEXT")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.brand))
                            .fixedSize()
                    }

                    HStack(spacing: 8) {
                        Text("Session \(sessionIndex) of 5")
                            .font(.appSubtitle)
                            .foregroundColor(AppPalette.muted)

                        SessionDots(current: sessionIndex)
                    }
                }

                Spacer(minLength: 0)
            }

            Button {
                onStart(workout)
            } label: {
                HStack(spacing: 8) {
                    Text("Start workout")
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(AppPillButtonStyle(.ink, .large))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.accentSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.brand, lineWidth: 2)
        )
    }
}

// MARK: - Other plan rows

private struct PlanWorkoutRow: View {
    let workout: Workout
    let onStart: () -> Void

    private var sessionIndex: Int {
        workout.planSessionIndex ?? 1
    }

    var body: some View {
        HStack(spacing: 12) {
            EmojiTile(
                emoji: planEmoji(for: workout.name),
                background: AppPalette.surface
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("Session \(sessionIndex) of 5")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)

                    SessionDots(current: sessionIndex)
                }
            }

            Spacer(minLength: 0)

            Button("Start", action: onStart)
                .buttonStyle(AppPillButtonStyle(.outline, .compact))
        }
        .appGroupRow(cornerRadius: 20)
    }
}

// MARK: - Wrapping pills

private struct PillWrapLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews, maxWidth: maxWidth)
        let width = maxWidth.isFinite ? maxWidth : rows.width
        return CGSize(width: width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews, maxWidth: bounds.width)
        for (index, frame) in rows.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> (frames: [CGRect], width: CGFloat, height: CGFloat) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
        }

        return (frames, usedWidth, y + rowHeight)
    }
}

// MARK: - Up-next ordering

/// Up next is the non-deleted plan workout with the lowest session index.
/// Ties go to the one trained least recently (never trained first), then name.
private enum PlanWorkoutQueue {
    static func ordered(_ workouts: [Workout], history: [Workout]) -> [Workout] {
        guard let next = workouts.min(by: { isBefore($0, $1, history: history) }) else {
            return []
        }
        let rest = workouts
            .filter { $0.id != next.id }
            .sorted { nameAscending($0.name, $1.name) }
        return [next] + rest
    }

    static func progress(for workouts: [Workout]) -> (done: Int, total: Int) {
        let done = workouts.reduce(0) { partial, workout in
            partial + ((workout.planSessionIndex ?? 1) - 1)
        }
        return (done, workouts.count * 5)
    }

    private static func isBefore(_ lhs: Workout, _ rhs: Workout, history: [Workout]) -> Bool {
        let leftSession = lhs.planSessionIndex ?? 1
        let rightSession = rhs.planSessionIndex ?? 1
        if leftSession != rightSession {
            return leftSession < rightSession
        }

        switch (lastCompletedAt(for: lhs, history: history), lastCompletedAt(for: rhs, history: history)) {
        case (nil, nil):
            break
        case (nil, .some):
            return true
        case (.some, nil):
            return false
        case let (left?, right?):
            if left != right {
                return left < right
            }
        }

        return nameAscending(lhs.name, rhs.name)
    }

    /// Latest completion of a historical clone. Nil means this plan workout has never been trained.
    private static func lastCompletedAt(for workout: Workout, history: [Workout]) -> Date? {
        var latest: Date?
        for candidate in history {
            guard !candidate.isDeleted,
                  candidate.sourceWorkoutId == workout.id,
                  let completedAt = candidate.completedAt else {
                continue
            }
            latest = latest.map { max($0, completedAt) } ?? completedAt
        }
        return latest
    }

    private static func nameAscending(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }
}

func planEmoji(for name: String) -> String {
    let lowered = name.lowercased()
    if lowered.contains("upper") { return "💪" }
    if lowered.contains("lower") || lowered.contains("leg") { return "🦵" }
    if lowered.contains("abs") || lowered.contains("core") { return "🔥" }
    if lowered.contains("push") { return "🏋️" }
    if lowered.contains("pull") { return "🧗" }
    if lowered.contains("full") { return "⚡️" }
    return "🏋️"
}

// MARK: - Preview

private struct TrainingPlanCardPreview: View {
    private let plan: TrainingPlan
    private let history: [Workout]

    init() {
        let plan = TrainingPlan(name: "Strength plan", splitType: .upperLower)
        let upper = Workout(name: "Upper")
        upper.planSessionIndex = 2
        let lower = Workout(name: "Lower")
        lower.planSessionIndex = 1
        let abs = Workout(name: "Abs")
        abs.planSessionIndex = 1
        plan.workouts = [upper, lower, abs]

        let absHistory = Workout(name: "Abs")
        absHistory.sourceWorkoutId = abs.id
        absHistory.completedAt = Date()
        absHistory.status = .completed

        self.plan = plan
        self.history = [absHistory]
    }

    var body: some View {
        TrainingPlanCard(plan: plan, history: history, onStartWorkout: { _ in })
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppBackground())
    }
}

#Preview("Light") {
    TrainingPlanCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrainingPlanCardPreview()
        .preferredColorScheme(.dark)
}
