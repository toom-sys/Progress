//
//  FoodEntryMethodsView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct FoodEntryMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingCameraAI = false
    @State private var showingManualEntry = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    headerSection
                    quickActionsSection
                    methodCardsSection
                }
                .padding()
            }
            .background(AdaptiveGradientBackground())
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingCameraAI) {
            CameraFoodView()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualFoodEntryView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("How would you like to add food?")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Choose the method that works best for you")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Photo",
                    subtitle: "AI Recognition",
                    color: .orange
                ) {
                    showingCameraAI = true
                }
                
                QuickActionButton(
                    icon: "plus.circle",
                    title: "Manual",
                    subtitle: "Custom entry",
                    color: .purple
                ) {
                    showingManualEntry = true
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Method Cards
    
    private var methodCardsSection: some View {
        VStack(spacing: 16) {
            // AI Camera Recognition
            MethodCard(
                icon: "camera.circle.fill",
                title: "AI Food Recognition",
                description: "Take a photo of your meal and let AI identify the food automatically",
                features: [
                    "Instant food identification",
                    "Portion size estimation",
                    "Multiple foods per photo",
                    "Confidence indicators"
                ],
                primaryAction: "Take Photo",
                isPremiumFeature: false
            ) {
                showingCameraAI = true
            }
            
            // Manual Entry
            MethodCard(
                icon: "pencil.circle.fill",
                title: "Manual Entry",
                description: "Create custom food entries with your own nutrition data",
                features: [
                    "Custom food names",
                    "Flexible serving sizes",
                    "Complete nutrition control"
                ],
                primaryAction: "Create Entry",
                isPremiumFeature: false
            ) {
                showingManualEntry = true
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isPremium: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    if isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 16, height: 16)
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 50, height: 50)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Method Card

struct MethodCard: View {
    let icon: String
    let title: String
    let description: String
    let features: [String]
    let primaryAction: String
    let isPremiumFeature: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                    }
                }
            }
            
            Button(action: action) {
                HStack {
                    Text(primaryAction)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(isPremiumFeature ? .orange : .primary)
            }
            .padding()
            .background((isPremiumFeature ? Color.orange : Color.primary).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FoodEntryMethodsView()
}
