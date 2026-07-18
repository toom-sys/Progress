//
//  WorkoutSortOptionsDialog.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct WorkoutSortOptionsDialog: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var sortOption: WorkoutSortOption
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("Sort Workouts", isPresented: $isPresented, titleVisibility: .visible) {
                Button("Date Created (Newest)") {
                    sortOption = .dateCreated
                }
                Button("Date Created (Oldest)") {
                    sortOption = .dateCreatedOldest
                }
                Button("Name (A-Z)") {
                    sortOption = .nameAscending
                }
                Button("Name (Z-A)") {
                    sortOption = .nameDescending
                }
                Button("Exercise Count") {
                    sortOption = .exerciseCount
                }
                Button("Cancel", role: .cancel) { }
            }
    }
}

extension View {
    func workoutSortOptionsDialog(isPresented: Binding<Bool>, sortOption: Binding<WorkoutSortOption>) -> some View {
        modifier(WorkoutSortOptionsDialog(isPresented: isPresented, sortOption: sortOption))
    }
}

#Preview {
    @State var isPresented = true
    @State var sortOption: WorkoutSortOption = .dateCreated
    
    return Text("Preview")
        .workoutSortOptionsDialog(isPresented: $isPresented, sortOption: $sortOption)
}
