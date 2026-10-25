//
//  BodyMapSection.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

// MARK: - Navigation Extensions

extension Notification.Name {
    static let navigateToWorkoutCreation = Notification.Name("navigateToWorkoutCreation")
}

/// Body map section that integrates seamlessly with the workout list interface
struct BodyMapSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @Query private var users: [User]
    @StateObject private var progressService = BodyMapProgressService.shared
    
    @State private var showTestColors = false
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var showProgressCard = false
    @State private var selectedProgress: ProgressTier = .dormant
    @State private var selectedOpacity: Double = 0.3
    
    // Add a stable identifier to track sheet presentations
    @State private var sheetId = UUID()
    
    // Create a more stable state container that survives view updates
    @StateObject private var sheetManager = SheetManager()
    
    class SheetManager: ObservableObject {
        @Published var isPresented = false
        @Published var muscleGroup: MuscleGroup?
        @Published var progress: ProgressTier = .dormant
        @Published var opacity: Double = 0.3
        @Published var sheetId = UUID()
        
        func presentSheet(muscleGroup: MuscleGroup, progress: ProgressTier, opacity: Double) {
            print("🎯 POPUP: SheetManager - Setting data for \(muscleGroup.displayName)")
            self.muscleGroup = muscleGroup
            self.progress = progress
            self.opacity = opacity
            self.sheetId = UUID()
            
            print("🎯 POPUP: SheetManager - Data set, presenting sheet")
            self.isPresented = true
        }
        
        func dismissSheet() {
            print("🎯 POPUP: SheetManager - Dismissing sheet")
            self.isPresented = false
            self.muscleGroup = nil
        }
    }
    
    // Performance optimization - cache computed values
    @State private var cachedProgress: [MuscleGroup: ProgressTier] = [:]
    @State private var cachedOpacity: [MuscleGroup: Double] = [:]
    @State private var lastUpdateTime: Date = Date()
    @State private var showingLegend: Bool = false
    /// Persisted separately from layout state so UserDefaults writes
    /// don't interrupt the expand/collapse animation transaction.
    @AppStorage("journey.bodyMap.expanded") private var storedIsExpanded = false
    /// Seed from UserDefaults so the first frame matches the persisted state
    /// (avoids a collapse→expand flash on appear).
    @State private var isExpanded = UserDefaults.standard.bool(forKey: "journey.bodyMap.expanded")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            if isExpanded {
                Group {
                    if hasAnyProgress {
                        bodyMapContainer
                    } else {
                        emptyStateView
                    }
                }
                .padding(.top, 10)
            }
        }
        .appCard(cornerRadius: 22, padding: 14)
        .onAppear {
            progressService.setModelContext(modelContext)
            Task {
                await progressService.refreshProgress()
            }
        }
        .onChange(of: workouts) { oldWorkouts, newWorkouts in
            Task {
                await progressService.refreshProgress()
            }
        }
        .onChange(of: progressService.currentProgress) { oldProgress, newProgress in
            // Progress data updated - UI will refresh automatically
        }
        .sheet(isPresented: $showingLegend) {
            ProgressLegendView()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        JourneyCardHeader(emoji: "🧍", tint: Color.brand, title: "Body map") {
            HStack(spacing: 8) {
                if isExpanded {
                    Button("Legend") {
                        showingLegend = true
                    }
                    .buttonStyle(AppPillButtonStyle(.outline, .compact))
                    .frame(height: 30)
                    .accessibilityLabel("Show progress tier legend")
                    .accessibilityHint("Double tap to view explanations of progress levels")
                }

                ChevronToggleButton(
                    isExpanded: isExpanded,
                    size: 30,
                    accessibilityLabel: isExpanded ? "Collapse body map" : "Expand body map",
                    action: toggleExpanded
                )
            }
        }
    }
    
    private func toggleExpanded() {
        HapticFeedback.workoutButtonTap()
        let newValue = !isExpanded
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            isExpanded = newValue
        }
        // Persist after the current turn so UserDefaults doesn't
        // publish inside the animation transaction.
        DispatchQueue.main.async {
            storedIsExpanded = newValue
        }
    }
    
    // MARK: - Body Map Container
    
    private var bodyMapContainer: some View {
        BodyMapView(
            muscleGroupProgress: optimizedProgress,
            muscleGroupOpacity: optimizedOpacity,
            showTestColors: showTestColors,
            variant: bodyMapVariant,
            onMuscleGroupTap: handleMuscleGroupTap
        )
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topLeading) {
            if let leader = topTrainedGroups.first {
                trainingChip(leader, caption: "on fire")
                    .offset(x: 6, y: 8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if topTrainedGroups.count > 1 {
                trainingChip(topTrainedGroups[1], caption: "lighting up")
                    .offset(x: -6, y: -8)
            }
        }
        .clipped()
        .scaleEffect(1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: progressService.currentProgress)
        .animation(.easeInOut(duration: 0.4), value: hasAnyProgress)
        .sheet(isPresented: $sheetManager.isPresented) {
            let _ = print("🎯 POPUP: Sheet presentation triggered via SheetManager")
            let _ = print("🎯 POPUP: SheetManager muscleGroup at render: \(sheetManager.muscleGroup?.displayName ?? "nil")")
            
            if let muscleGroup = sheetManager.muscleGroup {
                let _ = print("🎯 POPUP: Presenting card for \(muscleGroup.displayName) using SheetManager")
                MuscleGroupProgressCard(
                    muscleGroup: muscleGroup,
                    progress: sheetManager.progress,
                    opacity: sheetManager.opacity,
                    onDismiss: {
                        print("🎯 POPUP: Card dismissed via SheetManager")
                        sheetManager.dismissSheet()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .id(sheetManager.sheetId) // Force recreation when sheetId changes
            } else {
                let _ = print("🎯 POPUP: ERROR - SheetManager muscleGroup is nil, showing fallback")
                // Fallback content if muscleGroup is nil
                VStack {
                    Text("Loading...")
                        .foregroundColor(.secondary)
                    Button("Close") {
                        print("🎯 POPUP: Fallback close button tapped")
                        sheetManager.dismissSheet()
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .presentationDetents([.medium])
                .id(sheetManager.sheetId) // Force recreation when sheetId changes
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        BodyMapEmptyState(variant: bodyMapVariant)
    }
    
    // MARK: - Interaction Handlers
    
    private func handleMuscleGroupTap(_ muscleGroup: MuscleGroup, progress: ProgressTier, opacity: Double) {
        let isFirstOpen = !sheetManager.isPresented
        print("🎯 POPUP: Tap detected - \(muscleGroup.displayName) (First open: \(isFirstOpen))")
        
        // Handle existing sheet dismissal first
        if sheetManager.isPresented {
            print("🎯 POPUP: Dismissing existing sheet first")
            sheetManager.dismissSheet()
            
            // Small delay to allow dismissal animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🎯 POPUP: Re-presenting sheet for \(muscleGroup.displayName)")
                self.sheetManager.presentSheet(muscleGroup: muscleGroup, progress: progress, opacity: opacity)
            }
        } else {
            print("🎯 POPUP: Presenting sheet immediately for \(muscleGroup.displayName)")
            sheetManager.presentSheet(muscleGroup: muscleGroup, progress: progress, opacity: opacity)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Illustration variant based on the sex the user selected during onboarding
    private var bodyMapVariant: BodyMapVariant {
        (users.first?.biologicalSex ?? .unspecified).bodyMapVariant
    }
    
    /// Optimized progress data with caching to reduce unnecessary updates
    private var optimizedProgress: [MuscleGroup: ProgressTier] {
        let currentTime = Date()
        let shouldUpdate = currentTime.timeIntervalSince(lastUpdateTime) > 0.5 // Throttle updates to 2 FPS
        
        if shouldUpdate || cachedProgress.isEmpty {
            DispatchQueue.main.async {
                self.cachedProgress = progressService.getBodyMapProgress()
                self.lastUpdateTime = currentTime
            }
        }
        
        return cachedProgress.isEmpty ? progressService.getBodyMapProgress() : cachedProgress
    }
    
    /// Optimized opacity data with caching
    private var optimizedOpacity: [MuscleGroup: Double] {
        let currentTime = Date()
        let shouldUpdate = currentTime.timeIntervalSince(lastUpdateTime) > 0.5
        
        if shouldUpdate || cachedOpacity.isEmpty {
            DispatchQueue.main.async {
                self.cachedOpacity = progressService.getBodyMapOpacity()
            }
        }
        
        return cachedOpacity.isEmpty ? progressService.getBodyMapOpacity() : cachedOpacity
    }
    
    private var hasAnyProgress: Bool {
        !optimizedProgress.isEmpty && 
        optimizedProgress.values.contains { $0 != .dormant }
    }

    /// Highest training tiers on the map, then the stronger tint. Dormant groups are omitted.
    private var topTrainedGroups: [MuscleGroup] {
        optimizedProgress
            .filter { $0.value != .dormant }
            .sorted { lhs, rhs in
                let leftRank = ProgressTier.allCases.firstIndex(of: lhs.value) ?? 0
                let rightRank = ProgressTier.allCases.firstIndex(of: rhs.value) ?? 0
                if leftRank != rightRank {
                    return leftRank > rightRank
                }
                let leftOpacity = optimizedOpacity[lhs.key] ?? 0
                let rightOpacity = optimizedOpacity[rhs.key] ?? 0
                if leftOpacity != rightOpacity {
                    return leftOpacity > rightOpacity
                }
                return lhs.key.displayName < rhs.key.displayName
            }
            .prefix(2)
            .map(\.key)
    }

    private func trainingChip(_ group: MuscleGroup, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.displayName)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(AppPalette.ink)
            Text(caption)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppPalette.muted)
        }
        .appFloatingChip()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Most trained: \(group.displayName)")
    }
    
}

// MARK: - Preview

#Preview {
    NavigationView {
        ScrollView {
            VStack(spacing: 20) {
                BodyMapSection()
                
                // Sample workout list items for context
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surfaceWhite)
                            .frame(height: 80)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .overlay(
                                Text("Sample Workout")
                                    .foregroundColor(.textSecondary)
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }
        .background(AdaptiveGradientBackground())
    }
    .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self])
}
