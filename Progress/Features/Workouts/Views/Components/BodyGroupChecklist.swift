//
//  BodyGroupChecklist.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

/// A checklist showing which body groups have been trained this week
struct BodyGroupChecklist: View {
    let trainedBodyGroups: Set<MuscleGroup>
    
    // MARK: - Body Groups to Display
    
    private let bodyGroups: [MuscleGroup] = [
        .chest,
        .back,
        .shoulders,
        .arms,
        .core,
        .quads,
        .posteriorChain
    ]
    
    // MARK: - Computed Properties
    
    private var allGroupsTrained: Bool {
        bodyGroups.allSatisfy { trainedBodyGroups.contains($0) }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("This Week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            // Checklist
            VStack(alignment: .leading, spacing: 10) {
                ForEach(bodyGroups, id: \.self) { muscleGroup in
                    bodyGroupRow(for: muscleGroup)
                }
            }
            
            // Congratulatory message when all groups are trained
            if allGroupsTrained {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Full body week!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly body group training checklist\(allGroupsTrained ? ". All body groups trained this week!" : "")")
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func bodyGroupRow(for muscleGroup: MuscleGroup) -> some View {
        let isTrained = trainedBodyGroups.contains(muscleGroup)
        
        HStack(spacing: 10) {
            // Muscle group icon
            Image(systemName: muscleGroup.icon)
                .font(.body)
                .foregroundColor(isTrained ? .blue : .gray)
                .frame(width: 20)
            
            // Muscle group name
            Text(muscleGroup.displayName)
                .font(.body)
                .foregroundColor(isTrained ? .textPrimary : .gray)
                .fontWeight(isTrained ? .medium : .regular)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(muscleGroup.displayName)\(isTrained ? ", trained" : ", not trained yet")")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Empty state
        BodyGroupChecklist(trainedBodyGroups: [])
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        // Partially trained
        BodyGroupChecklist(trainedBodyGroups: [.chest, .back, .arms])
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        
        // All trained
        BodyGroupChecklist(trainedBodyGroups: Set(MuscleGroup.allCases))
            .padding()
            .background(Color.white)
            .cornerRadius(16)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

