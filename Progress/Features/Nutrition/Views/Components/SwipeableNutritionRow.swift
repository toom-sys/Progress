//
//  SwipeableNutritionRow.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Swipeable Nutrition Row Component

struct SwipeableNutritionRow: View {
    let entry: NutritionEntry
    let onDelete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    @State private var showingDetail = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Main card content
            SimpleFoodEntryRow(entry: entry)
                .offset(x: offset)
            
            // Delete button positioned off-screen to the right
            HStack {
                Spacer()
                Button(action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                        Text("Delete")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 16,
                            topTrailingRadius: 16
                        )
                    )
                }
                .offset(x: deleteButtonWidth + offset) // Position off-screen initially
            }
        }
        .clipped()
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    let translation = value.translation.width
                    let verticalTranslation = abs(value.translation.height)
                    let horizontalTranslation = abs(translation)
                    
                    // Only respond if this is VERY horizontal (3:1 ratio) and leftward
                    if horizontalTranslation > verticalTranslation * 3 && translation < 0 {
                        let progress = min(horizontalTranslation, deleteButtonWidth)
                        offset = -progress
                        showingDeleteButton = progress > 30
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    let verticalTranslation = abs(value.translation.height)
                    let horizontalTranslation = abs(translation)
                    
                    // Only handle if this was VERY horizontal (3:1 ratio)
                    if horizontalTranslation > verticalTranslation * 3 && horizontalTranslation > 30 {
                        if horizontalTranslation > deleteButtonWidth / 2 {
                            // Show delete button
                            withAnimation(.easeOut(duration: 0.2)) {
                                offset = -deleteButtonWidth
                                showingDeleteButton = true
                            }
                        } else {
                            // Snap back
                            withAnimation(.easeOut(duration: 0.2)) {
                                offset = 0
                                showingDeleteButton = false
                            }
                        }
                    } else {
                        // If it wasn't a strong horizontal gesture, reset
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = 0
                            showingDeleteButton = false
                        }
                    }
                }
        )
        .onTapGesture {
            // Tap to close if delete button is showing, otherwise show detail
            if showingDeleteButton {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                    showingDeleteButton = false
                }
            } else {
                showingDetail = true
            }
        }
        .sheet(isPresented: $showingDetail) {
            FoodDetailView(entry: entry)
        }
    }
}
