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
        HStack {
            Text("Workouts")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: onHistoryTapped) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.textPrimary)
            }

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
                    .font(.title2)
                    .foregroundColor(sortOption != .dateCreated ? .accentColor : .textPrimary)
            }
            .padding(.leading, 16)

            Button(action: onAddTapped) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.textPrimary)
            }
            .padding(.leading, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

#Preview {
    @Previewable @State var sortOption: WorkoutSortOption = .dateCreated
    WorkoutListHeader(
        sortOption: $sortOption,
        onHistoryTapped: {},
        onAddTapped: {}
    )
    .background(Color.gray.opacity(0.1))
}
