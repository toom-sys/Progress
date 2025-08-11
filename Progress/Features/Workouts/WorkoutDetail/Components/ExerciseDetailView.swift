//
//  ExerciseDetailView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 24) {
                    // Exercise Header
                    HStack {
                        // Exercise Icon (Large)
                        Image(systemName: exercise.type.icon)
                            .foregroundColor(.blue)
                            .font(.system(size: 50, weight: .medium))
                        
                        Spacer()
                        
                        // Close Button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.textSecondary)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 30, height: 30)
                                .background(Color.backgroundTertiary)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Exercise Name
                    Text(exercise.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Sets Header
                    HStack {
                        Text("Sets")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Text("\(exercise.completedSetsCount)/\(exercise.sets.count) completed")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Sets List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            SetRowView(
                                setNumber: index + 1,
                                set: set,
                                exerciseType: exercise.type
                            )
                        }
                        
                        // Add Set Button
                        Button(action: {
                            // TODO: Add set functionality
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .foregroundColor(.blue)
                                Text("Add Set")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Bottom Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        // TODO: Hide exercise functionality
                    }) {
                        Text("Hide Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        // TODO: Coming soon functionality
                    }) {
                        Text("Coming Soon")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.backgroundGradient)
            .navigationBarHidden(true)
        }
    }
}