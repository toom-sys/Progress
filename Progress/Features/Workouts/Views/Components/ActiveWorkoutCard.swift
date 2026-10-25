//
//  ActiveWorkoutCard.swift
//  Progress
//

import SwiftUI

struct ActiveWorkoutCard: View {
    let workout: Workout
    let onResume: (Workout) -> Void

    private var orderedExercises: [Exercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = elapsedInterval(at: context.date)
                VStack(alignment: .leading, spacing: 14) {
                    header(elapsed: elapsed)
                    if !orderedExercises.isEmpty {
                        segmentBar
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary(elapsed: elapsed))
                .transaction { $0.disablesAnimations = true }
            }

            Button {
                HapticFeedback.workoutButtonTap()
                onResume(workout)
            } label: {
                HStack(spacing: 8) {
                    Text("Resume workout")
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(AppPillButtonStyle(.inverse, .large))
            .accessibilityLabel("Resume workout")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppPalette.ink)
        )
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.30), radius: 17, x: 0, y: 14)
    }

    private func header(elapsed: TimeInterval) -> some View {
        HStack(alignment: .top, spacing: 12) {
            EmojiTile(
                emoji: planEmoji(for: workout.name),
                background: AppPalette.onInk.opacity(0.10)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    LiveStatusDot()
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                    Text("IN PROGRESS")
                        .font(.appEyebrow)
                        .tracking(1)
                        .foregroundColor(AppPalette.live)
                }

                Text(workout.name)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(AppPalette.onInk)
                    .lineLimit(2)

                Text(statusLine)
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.onInk.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text(Self.elapsedText(elapsed))
                    .font(.system(size: 24, weight: .heavy))
                    .monospacedDigit()
                    .foregroundColor(AppPalette.onInk)
                Text("elapsed")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppPalette.onInk.opacity(0.7))
            }
            .fixedSize()
        }
    }

    private var segmentBar: some View {
        let currentIndex = orderedExercises.firstIndex { !$0.isCompleted }
        return HStack(spacing: 4) {
            ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                Capsule()
                    .fill(segmentColor(for: exercise, at: index, currentIndex: currentIndex))
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private var statusLine: String {
        guard let currentIndex = orderedExercises.firstIndex(where: { !$0.isCompleted }) else {
            return "All exercises done"
        }
        let exercise = orderedExercises[currentIndex]
        return "Exercise \(currentIndex + 1) of \(orderedExercises.count) · \(exercise.name)"
    }

    private func accessibilitySummary(elapsed: TimeInterval) -> String {
        let progress: String
        if let currentIndex = orderedExercises.firstIndex(where: { !$0.isCompleted }) {
            progress = "exercise \(currentIndex + 1) of \(orderedExercises.count)"
        } else {
            progress = "all exercises done"
        }
        return "Workout in progress, \(workout.name), \(progress), \(Self.elapsedText(elapsed)) elapsed"
    }

    private func elapsedInterval(at date: Date) -> TimeInterval {
        guard let startedAt = workout.startedAt else { return 0 }
        return max(0, date.timeIntervalSince(startedAt))
    }

    private func segmentColor(for exercise: Exercise, at index: Int, currentIndex: Int?) -> Color {
        if exercise.isCompleted {
            return AppPalette.brandLight
        }
        if index == currentIndex {
            return AppPalette.onInk
        }
        return AppPalette.onInk.opacity(0.18)
    }

    private static func elapsedText(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Core Animation pulse so the live dot does not invalidate SwiftUI layout on every frame.
private struct LiveStatusDot: UIViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> PulseDotView {
        PulseDotView()
    }

    func updateUIView(_ view: PulseDotView, context: Context) {
        view.setReduceMotion(reduceMotion)
    }
}

private final class PulseDotView: UIView {
    private let halo = CALayer()
    private let dot = CALayer()
    private var isReduced = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        let green = UIColor(red: 52.0 / 255.0, green: 199.0 / 255.0, blue: 89.0 / 255.0, alpha: 1)
        halo.backgroundColor = green.cgColor
        dot.backgroundColor = green.cgColor
        layer.addSublayer(halo)
        layer.addSublayer(dot)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 16, height: 16)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side: CGFloat = 8
        let origin = CGPoint(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2)
        let frame = CGRect(origin: origin, size: CGSize(width: side, height: side))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        halo.frame = frame
        dot.frame = frame
        halo.cornerRadius = side / 2
        dot.cornerRadius = side / 2
        CATransaction.commit()
        startPulseIfNeeded()
    }

    func setReduceMotion(_ reduced: Bool) {
        guard reduced != isReduced else { return }
        isReduced = reduced
        if reduced {
            halo.removeAnimation(forKey: "pulse")
            halo.isHidden = true
        } else {
            halo.isHidden = false
            startPulseIfNeeded()
        }
    }

    private func startPulseIfNeeded() {
        guard !isReduced, halo.animation(forKey: "pulse") == nil, halo.bounds.width > 0 else { return }
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1
        scale.toValue = 1.8
        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.35
        opacity.toValue = 0
        let group = CAAnimationGroup()
        group.animations = [scale, opacity]
        group.duration = 1.4
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.isRemovedOnCompletion = false
        halo.add(group, forKey: "pulse")
    }
}

private struct ActiveWorkoutCardPreview: View {
    private let workout: Workout

    init() {
        let workout = Workout(name: "Upper")
        workout.status = .inProgress
        workout.startedAt = Date().addingTimeInterval(-754)
        let bench = Exercise(name: "Bench Press", type: .strength, order: 0)
        bench.sets = [ExerciseSet(weight: 60, reps: 8, order: 0)]
        bench.sets[0].isCompleted = true
        let row = Exercise(name: "Bent-over Row", type: .strength, order: 1)
        row.sets = [ExerciseSet(weight: 50, reps: 8, order: 0)]
        let curl = Exercise(name: "Curl", type: .strength, order: 2)
        curl.sets = [ExerciseSet(weight: 20, reps: 10, order: 0)]
        workout.exercises = [bench, row, curl]
        self.workout = workout
    }

    var body: some View {
        ActiveWorkoutCard(workout: workout, onResume: { _ in })
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppBackground())
    }
}

#Preview("Light") {
    ActiveWorkoutCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ActiveWorkoutCardPreview()
        .preferredColorScheme(.dark)
}
