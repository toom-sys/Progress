//
//  BaselineConfirmationView.swift
//  Progress
//

import SwiftUI

/// Editable set row for onboarding baseline confirmation.
struct BaselineSetEntry: Equatable {
    var weightText: String
    var repsText: String
    var durationText: String

    init(weightText: String = "", repsText: String = "", durationText: String = "") {
        self.weightText = weightText
        self.repsText = repsText
        self.durationText = durationText
    }
}

/// One exercise with a fixed number of editable sets (default 4).
struct BaselineExerciseEntry: Identifiable, Equatable {
    let id: UUID
    var exerciseName: String
    var predefinedExerciseId: String?
    var mode: ExerciseProgressionMode
    var sets: [BaselineSetEntry]

    init(
        exerciseName: String,
        predefinedExerciseId: String?,
        mode: ExerciseProgressionMode,
        sets: [BaselineSetEntry]
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.predefinedExerciseId = predefinedExerciseId
        self.mode = mode
        self.sets = sets
    }

    var isBodyweight: Bool { mode == .bodyweight }
    var isTimed: Bool { mode == .timed }
}

/// One repeating workout with editable exercise baselines.
struct BaselineWorkoutEntry: Identifiable, Equatable {
    let id: UUID
    var workoutName: String
    var exercises: [BaselineExerciseEntry]

    init(workoutName: String, exercises: [BaselineExerciseEntry]) {
        self.id = UUID()
        self.workoutName = workoutName
        self.exercises = exercises
    }
}

struct BaselineConfirmationView: View {

    let units: UnitSystem
    let planWorkouts: [GeneratedWorkout]
    @Binding var workoutEntries: [BaselineWorkoutEntry]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingStepHeader(
                    title: "Your starting targets",
                    subtitle: "We've picked Session 1 targets for you — tweak them if you like, or just keep going."
                )
                .padding(.top, 12)

                // How a block progresses, shown visually instead of explained
                SessionProgressionVisual()
                    .padding(16)
                    .onboardingSurfaceCard(cornerRadius: 22)
                    .padding(.horizontal, 24)

                ForEach($workoutEntries) { $workoutEntry in
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workoutEntry.workoutName)
                                .font(.system(size: 19, weight: .heavy, design: .rounded))
                                .foregroundColor(OnboardingPalette.ink)

                            Text("Session 1 · Block 1")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(OnboardingPalette.muted)
                        }

                        ForEach($workoutEntry.exercises) { $entry in
                            BaselineExerciseSection(
                                entry: $entry,
                                units: units
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                OnboardingNotePill(
                    emoji: "🛡️",
                    text: "Session 5 is a lighter deload to protect your joints before the next block."
                )
                .padding(.horizontal, 24)

                Spacer(minLength: 100)
            }
        }
        .onAppear {
            loadEntriesIfNeeded()
        }
        .onChange(of: planWorkouts) { _, _ in
            if workoutEntries.isEmpty {
                loadEntriesIfNeeded()
            }
        }
    }

    // MARK: - Public Helpers

    /// Builds workouts without any validation gating — empty or unparsable
    /// fields fall back to sensible defaults so users are never blocked.
    static func buildGeneratedWorkouts(
        from workoutEntries: [BaselineWorkoutEntry],
        units: UnitSystem
    ) -> [GeneratedWorkout]? {
        let workouts = workoutEntries.map { workoutEntry in
            GeneratedWorkout(
                name: workoutEntry.workoutName,
                baselines: buildBaselines(from: workoutEntry.exercises, units: units)
            )
        }
        return workouts.isEmpty ? nil : workouts
    }

    static func buildBaselines(
        from entries: [BaselineExerciseEntry],
        units: UnitSystem
    ) -> [ExerciseBaseline] {
        entries.map { entry in
            let firstSet = entry.sets.first ?? BaselineSetEntry()

            switch entry.mode {
            case .timed:
                let duration = Double(firstSet.durationText).flatMap { $0 > 0 ? $0 : nil } ?? 30
                return ExerciseBaseline(
                    exerciseName: entry.exerciseName,
                    predefinedExerciseId: entry.predefinedExerciseId,
                    mode: .timed,
                    weightKg: 0,
                    reps: 0,
                    durationSec: duration,
                    setCount: max(entry.sets.count, 1)
                )
            case .bodyweight:
                let reps = Int(firstSet.repsText).flatMap { $0 > 0 ? $0 : nil } ?? 8
                return ExerciseBaseline(
                    exerciseName: entry.exerciseName,
                    predefinedExerciseId: entry.predefinedExerciseId,
                    mode: .bodyweight,
                    weightKg: 0,
                    reps: reps,
                    setCount: max(entry.sets.count, 1)
                )
            case .weighted:
                let reps = Int(firstSet.repsText).flatMap { $0 > 0 ? $0 : nil } ?? 8
                let weightKg = Double(firstSet.weightText)
                    .flatMap { $0 > 0 ? units.convertWeightToKg(from: $0) : nil } ?? 20
                return ExerciseBaseline(
                    exerciseName: entry.exerciseName,
                    predefinedExerciseId: entry.predefinedExerciseId,
                    mode: .weighted,
                    weightKg: weightKg,
                    reps: reps,
                    setCount: max(entry.sets.count, 1)
                )
            }
        }
    }

    // MARK: - Private

    private func loadEntriesIfNeeded() {
        guard workoutEntries.isEmpty, !planWorkouts.isEmpty else { return }

        workoutEntries = planWorkouts.map { workout in
            BaselineWorkoutEntry(
                workoutName: workout.name,
                exercises: workout.baselines.map { baseline in
                    let setEntry: BaselineSetEntry
                    switch baseline.mode {
                    case .timed:
                        setEntry = BaselineSetEntry(durationText: String(Int(baseline.durationSec)))
                    case .bodyweight:
                        setEntry = BaselineSetEntry(repsText: String(baseline.reps))
                    case .weighted:
                        let weightText = Self.weightDisplayString(kg: baseline.weightKg, units: units)
                        setEntry = BaselineSetEntry(
                            weightText: weightText,
                            repsText: String(baseline.reps)
                        )
                    }

                    return BaselineExerciseEntry(
                        exerciseName: baseline.exerciseName,
                        predefinedExerciseId: baseline.predefinedExerciseId,
                        mode: baseline.mode,
                        sets: Array(repeating: setEntry, count: baseline.setCount)
                    )
                }
            )
        }
    }

    static func weightDisplayString(kg: Double, units: UnitSystem) -> String {
        let displayWeight = units.convertWeight(from: kg)
        return String(format: "%.1f", displayWeight)
    }
}

// MARK: - Session Progression Visual

/// Five-bar visual showing how a training block works: Sessions 1–4 build,
/// Session 5 deloads. Replaces text explanations and input validation.
struct SessionProgressionVisual: View {
    @State private var animated = false

    private let sessions: [(label: String, height: CGFloat, isDeload: Bool)] = [
        ("S1", 0.45, false),
        ("S2", 0.60, false),
        ("S3", 0.75, false),
        ("S4", 0.90, false),
        ("S5", 0.38, true)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW YOUR BLOCK WORKS")
                .font(.system(size: 11.5, weight: .heavy))
                .tracking(0.4)
                .foregroundColor(OnboardingPalette.muted)

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    VStack(spacing: 6) {
                        if session.isDeload {
                            Text("😮‍💨")
                                .font(.system(size: 13))
                        } else if index == 3 {
                            Text("🔥")
                                .font(.system(size: 13))
                        }

                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(
                                session.isDeload
                                    ? AnyShapeStyle(OnboardingPalette.accentSoft)
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [OnboardingPalette.brandLight, Color.brand],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .frame(height: animated ? 110 * session.height : 8)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.75)
                                    .delay(Double(index) * 0.08),
                                value: animated
                            )

                        Text(session.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(session.isDeload ? Color.brand : OnboardingPalette.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)

            HStack(spacing: 6) {
                Text("Build for 4 sessions")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(OnboardingPalette.ink)
                Text("·")
                    .foregroundColor(OnboardingPalette.muted)
                Text("Deload on the 5th")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.brand)
            }
        }
        .onAppear { animated = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chart showing targets rising across sessions one to four, then dropping for a lighter deload on session five")
    }
}

// MARK: - Exercise Section

private struct BaselineExerciseSection: View {
    @Binding var entry: BaselineExerciseEntry
    let units: UnitSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.exerciseName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(OnboardingPalette.ink)

                Spacer()

                Button("Copy set 1 to all") {
                    guard let first = entry.sets.first else { return }
                    for index in entry.sets.indices {
                        entry.sets[index].weightText = first.weightText
                        entry.sets[index].repsText = first.repsText
                        entry.sets[index].durationText = first.durationText
                    }
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.brand)
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("Set")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .leading)

                    if entry.isTimed {
                        Text("Duration (sec)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        if !entry.isBodyweight {
                            Text("Weight (\(units.weightUnit))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("Reps")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.brand.opacity(0.08))

                ForEach(entry.sets.indices, id: \.self) { index in
                    BaselineSetRow(
                        setNumber: index + 1,
                        mode: entry.mode,
                        weightText: $entry.sets[index].weightText,
                        repsText: $entry.sets[index].repsText,
                        durationText: $entry.sets[index].durationText
                    )

                    if index < entry.sets.count - 1 {
                        Divider()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onboardingSurfaceCard(cornerRadius: 16)
        }
    }
}

// MARK: - Set Row

private struct BaselineSetRow: View {
    let setNumber: Int
    let mode: ExerciseProgressionMode
    @Binding var weightText: String
    @Binding var repsText: String
    @Binding var durationText: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .leading)

            if mode == .timed {
                TextField("0", text: $durationText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
            } else {
                if mode == .weighted {
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                }

                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    BaselineConfirmationView(
        units: .metric,
        planWorkouts: [
            GeneratedWorkout(
                name: "Upper",
                baselines: [
                    ExerciseBaseline(
                        exerciseName: "Bench Press",
                        predefinedExerciseId: "Bench Press",
                        mode: .weighted,
                        weightKg: 30,
                        reps: 8,
                        setCount: 4
                    ),
                    ExerciseBaseline(
                        exerciseName: "Plank",
                        predefinedExerciseId: "Plank",
                        mode: .timed,
                        weightKg: 0,
                        reps: 0,
                        durationSec: 30,
                        setCount: 4
                    )
                ]
            )
        ],
        workoutEntries: .constant([])
    )
}
