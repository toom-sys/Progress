//
//  WorkoutListHeader.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutListHeader: View {
    @Binding var sortOption: WorkoutSortOption
    let onHistoryTapped: () -> Void
    let onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("Workouts")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundColor(AppPalette.ink)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            CircleIconButton(
                systemName: "chart.line.uptrend.xyaxis",
                style: .plain,
                size: 40,
                accessibilityLabel: "Progress history",
                action: onHistoryTapped
            )

            sortMenu

            CircleIconButton(
                systemName: "plus",
                style: .ink,
                size: 40,
                accessibilityLabel: "New workout",
                action: onAddTapped
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(WorkoutSortOption.allCases, id: \.self) { option in
                Button {
                    sortOption = option
                } label: {
                    HStack {
                        Text(option.displayName)
                        if sortOption == option {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 40 * 0.42, weight: .bold))
                .foregroundColor(sortOption != .dateCreated ? Color.brand : AppPalette.ink)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(AppPalette.surface)
                        .overlay(Circle().strokeBorder(AppPalette.line, lineWidth: 1))
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sort workouts")
    }
}

#Preview("Light") {
    @Previewable @State var sortOption: WorkoutSortOption = .dateCreated
    WorkoutListHeader(
        sortOption: $sortOption,
        onHistoryTapped: {},
        onAddTapped: {}
    )
    .background(AppBackground())
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var sortOption: WorkoutSortOption = .nameAscending
    WorkoutListHeader(
        sortOption: $sortOption,
        onHistoryTapped: {},
        onAddTapped: {}
    )
    .background(AppBackground())
    .preferredColorScheme(.dark)
}
