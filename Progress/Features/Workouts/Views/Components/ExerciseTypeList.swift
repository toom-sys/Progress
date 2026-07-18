//
//  ExerciseTypeList.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseTypeList: View {
    let types: [ExerciseDatabase.ExerciseType]
    let onTypeSelected: (ExerciseDatabase.ExerciseType) -> Void
    
    var body: some View {
        ForEach(types, id: \.type) { type in
            TypeRowView(
                type: type,
                onTap: {
                    HapticFeedback.workoutButtonTap()
                    onTypeSelected(type)
                }
            )
        }
    }
}

private struct TypeRowView: View {
    let type: ExerciseDatabase.ExerciseType
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Type icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: typeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Type info
            VStack(alignment: .leading, spacing: 4) {
                Text(type.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text("\(type.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var typeIcon: String {
        switch type.type.lowercased() {
        // Resistance Training Types
        case "chest":
            return "figure.strengthtraining.traditional"
        case "back":
            return "figure.strengthtraining.traditional"
        case "shoulders":
            return "figure.arms.open"
        case "biceps":
            return "dumbbell.fill"
        case "triceps":
            return "dumbbell.fill"
        case "forearms":
            return "hand.raised.fill"
        case "quadriceps":
            return "figure.strengthtraining.traditional"
        case "hamstrings":
            return "figure.strengthtraining.traditional"
        case "calves":
            return "figure.strengthtraining.traditional"
        case "core":
            return "figure.core.training"
        case "full body / compound":
            return "figure.strengthtraining.traditional"
        case "arms": // Legacy - keeping for backward compatibility
            return "dumbbell.fill"
        case "legs": // Legacy - keeping for backward compatibility
            return "figure.strengthtraining.traditional"
            
        // Cardio Types
        case "running":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "rowing":
            return "figure.rowing"
        case "swimming":
            return "figure.pool.swim"
        case "hiit / circuits":
            return "bolt.circle.fill"
        case "walking / hiking":
            return "figure.hiking"
        case "machine-based":
            return "gear"
            
        // Recovery Types
        case "stretching":
            return "figure.flexibility"
        case "mobility":
            return "figure.roll"
        case "yoga":
            return "figure.mind.and.body"
        case "breathing / mindfulness":
            return "lungs.fill"
        case "foam rolling": // Legacy - keeping for backward compatibility
            return "figure.roll"
        case "meditation": // Legacy - keeping for backward compatibility
            return "figure.mind.and.body"
            
        default:
            return "dumbbell.fill"
        }
    }
}

#Preview {
    ExerciseTypeList(
        types: [],
        onTypeSelected: { _ in }
    )
}
