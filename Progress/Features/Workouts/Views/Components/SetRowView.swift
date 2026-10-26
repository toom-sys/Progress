//
//  SetRowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

/// Shared column metrics so the sets header and each set row line up in a grid.
/// Value columns are flexible (they share the space between the fixed leading
/// and trailing columns evenly), so only the fixed columns are defined here.
enum SetRowLayout {
    /// Holds the set number in rows and the "Sets" title in the header.
    static let leadingColumnWidth: CGFloat = 36
    /// Width of the "×" separator / gap between the two value columns.
    static let multiplierColumnWidth: CGFloat = 24
    /// Holds the edit + complete buttons in rows; empty spacer in the header.
    static let trailingColumnWidth: CGFloat = 64
    /// Horizontal inset inside each set row card.
    static let rowHorizontalPadding: CGFloat = 16
    /// Horizontal inset applied to the scrolling sets list.
    static let listHorizontalPadding: CGFloat = 16
}

struct SetRowView: View {
    let set: ExerciseSet
    let exercise: Exercise
    let setNumber: Int
    let onEdit: () -> Void
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var dragOffset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    private var userUnitSystem: UnitSystem {
        users.first?.preferredUnits ?? .metric
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(setNumber)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(AppPalette.muted)
                .frame(width: SetRowLayout.leadingColumnWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                setMetricsView

                if let targetLabel = planTargetLabel, shouldShowTargetLabel {
                    Text(targetLabel)
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                }

                if let notes = set.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button {
                    HapticFeedback.workoutButtonTap()
                    onEdit()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppPalette.ink)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit set \(setNumber)")
                .accessibilityHint("Edit weight, reps, or duration for this set")

                Button(action: {
                    HapticFeedback.setCompleted()
                    onToggleComplete()
                }) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(set.isCompleted ? AppPalette.live : AppPalette.muted)
                        .scaleEffect(set.isCompleted ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
                }
            }
            .frame(width: SetRowLayout.trailingColumnWidth, alignment: .trailing)
        }
        .padding(.horizontal, SetRowLayout.rowHorizontalPadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(rowBorderColor, lineWidth: 1)
        )
        .offset(x: dragOffset)
        .background(
            // Delete button background
            HStack {
                Spacer()
                Button(action: {
                    HapticFeedback.itemDeleted()
                    onDelete()
                    resetSwipe()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 40)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .opacity(showingDeleteButton ? 1 : 0)
            }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    let translation = value.translation.width
                    let verticalTranslation = abs(value.translation.height)
                    
                    // Only process if it's a strong horizontal gesture (horizontal must be 4x vertical)
                    if abs(translation) > 30 && abs(translation) > verticalTranslation * 4 && translation < 0 {
                        dragOffset = max(translation, -80)
                        showingDeleteButton = dragOffset < -40
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    let verticalTranslation = abs(value.translation.height)
                    
                    // Only complete swipe if it was a very clear horizontal gesture
                    if abs(translation) > 50 && abs(translation) > verticalTranslation * 4 && translation < -50 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = -80
                            showingDeleteButton = true
                        }
                    } else {
                        resetSwipe()
                    }
                }
        )
        .animation(.easeInOut(duration: 0.3), value: set.isCompleted)
        .animation(.easeOut(duration: 0.2), value: dragOffset)
    }
    
    // MARK: - Methods
    
    private func resetSwipe() {
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = 0
            showingDeleteButton = false
        }
    }
    
    @ViewBuilder
    private var setMetricsView: some View {
        switch exercise.type {
        case .resistance, .strength:
            resistanceMetricsView

        case .cardio:
            cardioMetricsView

        case .recovery, .flexibility:
            recoveryMetricsView
        }
    }

    private var resistanceMetricsView: some View {
        HStack(spacing: 0) {
            if isBodyweightPlanSet {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)

                Color.clear
                    .frame(width: SetRowLayout.multiplierColumnWidth, height: 1)
            } else {
                Text(userUnitSystem.formatWeight(set.weight))
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(actualMetricsColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("×")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppPalette.muted)
                    .frame(width: SetRowLayout.multiplierColumnWidth, alignment: .center)
            }

            Text("\(set.reps)")
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(actualMetricsColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cardioMetricsView: some View {
        HStack(spacing: 0) {
            Text(set.formattedDuration)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(AppPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: SetRowLayout.multiplierColumnWidth, height: 1)

            Text(set.distance > 0 ? userUnitSystem.formatDistanceWithUnit(set.distance) : "—")
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(set.distance > 0 ? AppPalette.ink : AppPalette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recoveryMetricsView: some View {
        HStack(spacing: 0) {
            Text(set.formattedDuration)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(isPlanSet ? actualMetricsColor : AppPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: SetRowLayout.multiplierColumnWidth, height: 1)

            if let intensity = set.intensityLevel {
                Text("\(intensity)/10")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(AppPalette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
            }
        }
    }
    
    // MARK: - Plan Target Helpers

    private var isPlanSet: Bool {
        let currentSet = set
        return currentSet.targetDuration != nil
            || currentSet.targetReps != nil
            || (currentSet.targetWeight != nil && (currentSet.targetWeight ?? 0) > 0)
    }

    private var isBodyweightPlanSet: Bool {
        isPlanSet && planSetMode == .bodyweight
    }

    /// Targets are only surfaced when the logged value differs from the plan target,
    /// keeping the list clean while still calling out deviations for comparison.
    private var shouldShowTargetLabel: Bool {
        guard isPlanSet, let mode = planSetMode else { return false }
        switch mode {
        case .weighted:
            guard let targetWeight = set.targetWeight, let targetReps = set.targetReps else { return false }
            return set.weight != targetWeight || set.reps != targetReps
        case .bodyweight:
            guard let targetReps = set.targetReps else { return false }
            return set.reps != targetReps
        case .timed:
            guard let targetDuration = set.targetDuration else { return false }
            return set.duration != targetDuration
        }
    }

    private var planSetMode: ExerciseProgressionMode? {
        guard isPlanSet else { return nil }
        if set.targetDuration != nil { return .timed }
        if let targetWeight = set.targetWeight, targetWeight > 0 { return .weighted }
        if set.targetReps != nil { return .bodyweight }
        return nil
    }

    private var planTargetLabel: String? {
        guard isPlanSet, let mode = planSetMode else { return nil }
        switch mode {
        case .weighted:
            guard let targetWeight = set.targetWeight, let targetReps = set.targetReps else { return nil }
            let weightText = userUnitSystem.formatWeight(targetWeight)
            return "target: \(weightText) × \(targetReps)"
        case .bodyweight:
            guard let targetReps = set.targetReps else { return nil }
            return "target: \(targetReps) reps"
        case .timed:
            guard let targetDuration = set.targetDuration else { return nil }
            return "target: \(Int(targetDuration))s"
        }
    }

    private enum TargetPerformance {
        case met
        case below
        case neutral
    }

    private var targetPerformance: TargetPerformance {
        guard isPlanSet, set.isCompleted, let mode = planSetMode else { return .neutral }
        switch mode {
        case .weighted:
            let weightMet = set.targetWeight.map { set.weight >= $0 } ?? true
            let repsMet = set.targetReps.map { set.reps >= $0 } ?? true
            return weightMet && repsMet ? .met : .below
        case .bodyweight:
            guard let targetReps = set.targetReps else { return .neutral }
            return set.reps >= targetReps ? .met : .below
        case .timed:
            guard let targetDuration = set.targetDuration else { return .neutral }
            return set.duration >= targetDuration ? .met : .below
        }
    }

    private var actualMetricsColor: Color {
        guard isPlanSet, set.isCompleted else { return AppPalette.ink }
        switch targetPerformance {
        case .met: return AppPalette.ink
        case .below: return AppPalette.carbs
        case .neutral: return AppPalette.ink
        }
    }

    private var isCompletedWithSuccessStyle: Bool {
        guard set.isCompleted else { return false }
        if isPlanSet {
            return targetPerformance == .met || targetPerformance == .neutral
        }
        return true
    }

    private var isCompletedWithWarningStyle: Bool {
        isPlanSet && set.isCompleted && targetPerformance == .below
    }

    private var rowBackground: Color {
        if isCompletedWithWarningStyle {
            return AppPalette.tint(AppPalette.carbs)
        }
        if isCompletedWithSuccessStyle {
            return AppPalette.tint(AppPalette.live)
        }
        return AppPalette.optionFill
    }

    private var rowBorderColor: Color {
        if isCompletedWithWarningStyle {
            return AppPalette.carbs.opacity(0.35)
        }
        if isCompletedWithSuccessStyle {
            return AppPalette.live.opacity(0.35)
        }
        return AppPalette.line
    }
}

#Preview {
    VStack(spacing: 12) {
        // Resistance set
        SetRowView(
            set: {
                let set = ExerciseSet(weight: 80, reps: 10, order: 0)
                set.isCompleted = true
                return set
            }(),
            exercise: Exercise(name: "Bench Press", type: .resistance),
            setNumber: 1,
            onEdit: { },
            onToggleComplete: { },
            onDelete: { }
        )
        
        // Cardio set
        SetRowView(
            set: {
                let set = ExerciseSet(duration: 1800, distance: 5.0, order: 0) // 30 min, 5km
                set.isCompleted = false
                return set
            }(),
            exercise: Exercise(name: "Running", type: .cardio),
            setNumber: 1,
            onEdit: { },
            onToggleComplete: { },
            onDelete: { }
        )
        
        // Recovery set
        SetRowView(
            set: {
                let set = ExerciseSet(duration: 300, order: 0) // 5 minutes
                set.intensityLevel = 7
                set.isCompleted = true
                return set
            }(),
            exercise: Exercise(name: "Stretching", type: .recovery),
            setNumber: 1,
            onEdit: { },
            onToggleComplete: { },
            onDelete: { }
        )
    }
    .padding()
    .background(AppBackground())
}
