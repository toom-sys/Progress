//
//  WorkoutRowView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct WorkoutRowView: View {
    let workout: Workout

    private static let creationDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private var creationDate: String {
        Self.creationDateFormatter.string(from: workout.createdAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            EmojiTile(emoji: "🏋️", background: AppPalette.accentSoft)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                    .lineLimit(1)

                Text("\(workout.exercises.count) exercises · Created \(creationDate)")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if workout.isInProgress {
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppPalette.live)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text("In progress")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundColor(AppPalette.liveText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppPalette.tint(AppPalette.live)))
                .accessibilityLabel("In progress")
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppPalette.muted.opacity(0.7))
                    .accessibilityHidden(true)
            }
        }
        .appCard(cornerRadius: 22, padding: 14)
    }
}

#Preview {
    WorkoutRowView(workout: Workout(name: "Push day"))
        .padding(20)
        .background(AppBackground())
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self, ExerciseSetSnapshot.self])
}
