//
//  ExerciseDetailPopup.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData
import UIKit

struct ExerciseDetailPopup: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    let exercise: Exercise
    let onDismiss: () -> Void
    let onEdit: () -> Void
    
    @State private var showingEditSet: ExerciseSet? = nil
    @State private var showingHistorySheet = false
    @AppStorage("exerciseDetailMediaExpanded") private var isMediaExpanded = false
    
    private var userUnitSystem: UnitSystem {
        users.first?.preferredUnits ?? .metric
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Header section - Static
                headerSection

                // Sets title bar
                setsTitleBar

                // Scrollable sets list
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if exercise.sets.isEmpty {
                            // Add button at top when no sets exist
                            Button(action: {
                                HapticFeedback.workoutButtonTap()
                                addNewSet()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                    Text("Add First Set")
                                }
                            }
                            .buttonStyle(AppPillButtonStyle(.outline, .large))
                        } else {
                            ForEach(exercise.sets.sorted { $0.order < $1.order }, id: \.id) { set in
                                SetRowView(
                                    set: set,
                                    exercise: exercise,
                                    setNumber: set.order + 1,
                                    onEdit: {
                                        showingEditSet = set
                                    },
                                    onToggleComplete: {
                                        toggleSetCompletion(set)
                                    },
                                    onDelete: {
                                        deleteSet(set)
                                    }
                                )
                            }

                            // Add set button at bottom when sets exist
                            addSetButton
                        }
                    }
                    .padding(.horizontal, SetRowLayout.listHorizontalPadding)
                    .padding(.vertical, 16)
                }

                // Bottom action buttons
                bottomActionButtons
            }
            // Explicit dimensions force the VStack to fill the available space,
            // with the ScrollView expanding to take whatever height remains.
            .frame(
                width: proxy.size.width - 40,
                height: proxy.size.height - safeAreaBottom
            )
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(AppPalette.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
        .overlay(
            Group {
                if let editingSet = showingEditSet {
                    SetEntryView(
                        exercise: exercise,
                        set: editingSet,
                        onSetSaved: { _ in },
                        onDismiss: {
                            showingEditSet = nil
                        }
                    )
                    .zIndex(1000)
                }
            }
        )
        .sheet(isPresented: $showingHistorySheet) {
            ExerciseHistorySheet(exerciseName: exercise.name, units: userUnitSystem)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Top bar with name, subtitle and close button
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.appSectionTitle)
                        .foregroundColor(AppPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Image(systemName: exercise.type.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(typeColor)

                        Text(exercise.type.displayName)
                        Text("·")
                        Text("\(exercise.completedSetsCount)/\(exercise.sets.count) sets")
                    }
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
                }

                Spacer(minLength: 8)

                CircleIconButton(
                    systemName: "xmark",
                    style: .plain,
                    size: 36,
                    accessibilityLabel: "Close",
                    action: {
                        HapticFeedback.workoutButtonTap()
                        onDismiss()
                    }
                )
            }
            
            // Collapsible media section (gif/preview placeholder)
            VStack(spacing: 0) {
                Button(action: {
                    HapticFeedback.workoutButtonTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isMediaExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 13, weight: .bold))

                        Text(isMediaExpanded ? "Hide preview" : "Show preview")
                            .font(.system(size: 13, weight: .heavy))

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .rotationEffect(.degrees(isMediaExpanded ? 180 : 0))
                    }
                    .foregroundColor(AppPalette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.optionFill)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isMediaExpanded ? "Hide preview" : "Show preview")
                .accessibilityValue(isMediaExpanded ? "Expanded" : "Collapsed")
                
                if isMediaExpanded {
                    mediaPreview
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Media Preview
    
    @ViewBuilder
    private var mediaPreview: some View {
        let poseFrames = ExerciseImageService.shared.getPoseFrames(for: exercise.name)

        if exercise.isCustom {
            mediaPlaceholder {
                Image(systemName: exercise.type.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(typeColor)
                Text("Custom Exercise")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
            }
        } else if poseFrames.count > 1 {
            ExercisePoseCarousel(frames: poseFrames)
        } else if let single = poseFrames.first {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppPalette.optionFill)
                Image(uiImage: single)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            }
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppPalette.line, lineWidth: 1)
            )
        } else {
            mediaPlaceholder {
                Image(systemName: exercise.type.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(typeColor)
                Text("Preview coming soon")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
            }
        }
    }

    private func mediaPlaceholder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppPalette.tint(typeColor))
            VStack(spacing: 6, content: content)
        }
        .frame(height: 110)
    }
    
    // MARK: - Sets Title Bar
    
    private var setsTitleBar: some View {
        HStack(spacing: 0) {
            Text("Sets")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.ink)
                .frame(width: SetRowLayout.leadingColumnWidth, alignment: .leading)

            // Column titles line up with the value columns in each set row
            variableTitles

            // Matches the edit/complete buttons column in each set row
            Color.clear
                .frame(width: SetRowLayout.trailingColumnWidth, height: 1)
        }
        .padding(.horizontal, SetRowLayout.listHorizontalPadding + SetRowLayout.rowHorizontalPadding)
        .padding(.vertical, 10)
        .background(AppPalette.optionFill.opacity(0.65))
    }
    
    // MARK: - Variable Titles
    
    @ViewBuilder
    private var variableTitles: some View {
        switch exercise.type {
        case .resistance, .strength:
            columnTitle(userUnitSystem.weightUnit)
            Color.clear.frame(width: SetRowLayout.multiplierColumnWidth, height: 1)
            columnTitle("Reps")

        case .cardio:
            columnTitle("Duration")
            Color.clear.frame(width: SetRowLayout.multiplierColumnWidth, height: 1)
            columnTitle("Distance")

        case .recovery, .flexibility:
            columnTitle("Duration")
            Color.clear.frame(width: SetRowLayout.multiplierColumnWidth, height: 1)
            columnTitle("Intensity")
        }
    }

    private func columnTitle(_ title: String) -> some View {
        Text(title)
            .font(.appSubtitle)
            .foregroundColor(AppPalette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Add Set Button
    
    private var addSetButton: some View {
        Button(action: {
            HapticFeedback.workoutButtonTap()
            addNewSet()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add Set")
            }
        }
        .buttonStyle(AppPillButtonStyle(.outline, .large))
    }
    
    // MARK: - Bottom Action Buttons
    
    private var bottomActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                HapticFeedback.workoutButtonTap()
                exercise.toggleHidden()

                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save exercise hidden state: \(error)")
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: exercise.isHidden ? "eye" : "eye.slash")
                    Text(exercise.isHidden ? "Unhide" : "Hide")
                }
            }
            .buttonStyle(AppPillButtonStyle(.outline, .large))
            .accessibilityLabel(exercise.isHidden ? "Unhide exercise" : "Hide exercise")

            Button(action: {
                HapticFeedback.workoutButtonTap()
                showingHistorySheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("History")
                }
            }
            .buttonStyle(AppPillButtonStyle(.ink, .large))
            .accessibilityLabel("Exercise history")
            .accessibilityHint("View progress history for \(exercise.name)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Computed Properties

    /// Bottom clearance for the popup — positions it so the gap between the
    /// popup's bottom edge and the tab bar pill matches the gap below the pill.
    /// The 16pt adjustment accounts for the iOS 18 tab bar's internal top padding
    /// (the space between the UITabBar frame top and the visual pill top).
    private var safeAreaBottom: CGFloat {
        let windowInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.bottom ?? 34
        return max(windowInset - 16, 0)
    }

    private var typeColor: Color {
        switch exercise.type {
        case .resistance, .strength:
            return Color.brand
        case .cardio:
            return AppPalette.protein
        case .recovery, .flexibility:
            return AppPalette.live
        }
    }
    
    // MARK: - Methods
    
    private func addNewSet() {
        print("➕ ADD SET - Current sets: \(exercise.sets.map { "Set(order: \($0.order), id: \($0.id))" })")
        
        // Get the last set to copy values from
        let lastSet = exercise.sets.sorted { $0.order < $1.order }.last
        
        let newSet = ExerciseSet(
            weight: lastSet?.weight ?? (exercise.type == .resistance ? 0.0 : 0.0),
            reps: lastSet?.reps ?? (exercise.type == .resistance ? 0 : 0),
            duration: lastSet?.duration ?? (exercise.type == .cardio || exercise.type == .recovery ? 0 : 0),
            distance: lastSet?.distance ?? (exercise.type == .cardio ? 0.0 : 0.0)
            // Don't set order here - let Exercise.addSet() handle it
        )
        
        // Copy intensity level for recovery exercises
        if exercise.type == .recovery {
            newSet.intensityLevel = lastSet?.intensityLevel ?? 5
        }
        
        print("➕ ADD SET - Copying from last set: weight=\(newSet.weight), reps=\(newSet.reps), duration=\(newSet.duration), distance=\(newSet.distance)")
        
        exercise.addSet(newSet) // This will set the correct order
        print("➕ ADD SET - After adding: \(exercise.sets.map { "Set(order: \($0.order), id: \($0.id))" })")
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to add new set: \(error)")
        }
    }
    
    private func toggleSetCompletion(_ set: ExerciseSet) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if set.isCompleted {
                set.reset()
                exercise.workout?.revertToPlannedIfNoSetsTicked()
            } else {
                set.complete()
                exercise.workout?.start()
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to update set completion: \(error)")
            }
        }
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        print("🗑️ BEFORE DELETE - Set order: \(set.order)")
        print("🗑️ BEFORE DELETE - All sets: \(exercise.sets.map { "Set(order: \($0.order), id: \($0.id))" })")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            let deletedOrder = set.order
            
            // Remove the set from the exercise and delete from context
            if let index = exercise.sets.firstIndex(of: set) {
                exercise.sets.remove(at: index)
            }
            modelContext.delete(set)
            
            // Reorder remaining sets to preserve visual order
            // All sets with order > deletedOrder should shift down by 1
            for remainingSet in exercise.sets {
                if remainingSet.order > deletedOrder {
                    remainingSet.order -= 1
                    print("🗑️ REORDER - Set \(remainingSet.id): \(remainingSet.order + 1) → \(remainingSet.order)")
                }
            }
            
            print("🗑️ AFTER VISUAL-PRESERVING REORDER - All sets: \(exercise.sets.map { "Set(order: \($0.order), id: \($0.id))" })")
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete set: \(error)")
            }
        }
    }
}

#Preview {
    ExerciseDetailPopup(
        exercise: Exercise(
            name: "Bench Press",
            type: .resistance
        ),
        onDismiss: { },
        onEdit: { }
    )
    .background(AppBackground())
}
