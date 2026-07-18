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
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                if hasAnyProgress {
                    bodyMapContainer
                } else {
                    emptyStateView
                }
            }
            
            // Legend button overlay at top right of card
            VStack {
                HStack {
                    Spacer()
                    legendButton
                }
                Spacer()
            }
        }
        .whiteCardStyle(cornerRadius: 16, padding: 20)
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
        .frame(height: 280)
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
    
    // MARK: - Legend Button
    
    private var legendButton: some View {
        Button(action: {
            showingLegend = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                Text("Legend")
                    .font(.caption)
            }
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.backgroundSecondary.opacity(0.8))
            .clipShape(Capsule())
        }
        .accessibilityLabel("Show progress tier legend")
        .accessibilityHint("Double tap to view explanations of progress levels")
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
