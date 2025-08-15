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
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Main card content
            SimpleFoodEntryRow(entry: entry)
                .frame(height: 120)
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
                    .frame(width: deleteButtonWidth, height: 120)
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
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.width
                    
                    // Only allow leftward swipes (negative translation)
                    if translation < 0 {
                        let progress = min(abs(translation), deleteButtonWidth)
                        offset = -progress
                        showingDeleteButton = progress > 20
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    
                    if abs(translation) > deleteButtonWidth / 2 {
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
                }
        )
        .onTapGesture {
            // Tap to close if delete button is showing
            if showingDeleteButton {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                    showingDeleteButton = false
                }
            }
        }
    }
}
