//
//  ExerciseSearchBar.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

struct ExerciseSearchBar: View {
    @Binding var searchText: String
    let onSearchChanged: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.textSecondary)
            
            TextField("Search exercises...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.subheadline)
                .textInputAutocapitalization(.words)
                .onChange(of: searchText) { _, _ in
                    onSearchChanged()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    HapticFeedback.workoutButtonTap()
                    searchText = ""
                    onSearchChanged()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    @State var searchText = ""
    
    return ExerciseSearchBar(
        searchText: $searchText,
        onSearchChanged: {}
    )
}
