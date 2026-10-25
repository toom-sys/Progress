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
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.blue)

                                    Text("Add First Set")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
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
                width: proxy.size.width - 48,  // 24pt margin each side
                height: proxy.size.height - safeAreaBottom
            )
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.border, lineWidth: 1)
                    .opacity(0.3)
            )
            .padding(.horizontal, 24)
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
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: exercise.type.icon)
                            .font(.caption)
                            .foregroundColor(typeColor)
                        
                        Text(exercise.type.displayName)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                        
                        Text("\(exercise.completedSetsCount)/\(exercise.sets.count) sets")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.workoutButtonTap()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .frame(width: 30, height: 30)
                .background(Color.backgroundSecondary)
                .clipShape(Circle())
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
                            .font(.system(size: 13, weight: .medium))
                        
                        Text(isMediaExpanded ? "Hide preview" : "Show preview")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: isMediaExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.backgroundSecondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: isMediaExpanded ? 10 : 10))
                }
                .buttonStyle(.plain)
                
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
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(typeColor)
                Text("Custom Exercise")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        } else if poseFrames.count > 1 {
            ExercisePoseCarousel(frames: poseFrames)
        } else if let single = poseFrames.first {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                Image(uiImage: single)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            }
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brand, lineWidth: 1)
            )
        } else {
            mediaPlaceholder {
                Image(systemName: exercise.type.icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(typeColor)
                Text("Preview coming soon")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func mediaPlaceholder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(typeColor.opacity(0.1))
            VStack(spacing: 6, content: content)
        }
        .frame(height: 110)
    }
    
    // MARK: - Sets Title Bar
    
    private var setsTitleBar: some View {
        HStack(spacing: 0) {
            Text("Sets")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .frame(width: SetRowLayout.leadingColumnWidth, alignment: .leading)

            // Column titles line up with the value columns in each set row
            variableTitles

            // Matches the edit/complete buttons column in each set row
            Color.clear
                .frame(width: SetRowLayout.trailingColumnWidth, height: 1)
        }
        .padding(.horizontal, SetRowLayout.listHorizontalPadding + SetRowLayout.rowHorizontalPadding)
        .padding(.vertical, 12)
        .background(Color.backgroundSecondary.opacity(0.3))
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
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.textSecondary)
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
                    .font(.system(size: 16, weight: .medium))
                
                Text("Add Set")
                    .font(.headline)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Bottom Action Buttons
    
    private var bottomActionButtons: some View {
        HStack(spacing: 12) {
            // Hide/Unhide Exercise button
            Button(action: {
                HapticFeedback.workoutButtonTap()
                exercise.toggleHidden()
                
                // Save the change immediately to ensure persistence
                do {
                    try modelContext.save()
                    print("💾 Exercise hidden state saved successfully")
                } catch {
                    print("❌ Failed to save exercise hidden state: \(error)")
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: exercise.isHidden ? "eye" : "eye.slash")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(exercise.isHidden ? "Unhide" : "Hide Exercise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(exercise.isHidden ? .green : .orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background((exercise.isHidden ? Color.green : Color.orange).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
            
            // History button
            Button(action: {
                HapticFeedback.workoutButtonTap()
                showingHistorySheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("History")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.brand.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
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
            return .blue
        case .cardio:
            return .red
        case .recovery, .flexibility:
            return .green
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
    .background(Color.backgroundSecondary)
}
