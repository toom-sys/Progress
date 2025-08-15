//
//  FloatingAddButton.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Floating Add Button Component

struct FloatingAddButton: View {
    @Binding var showingFoodSearch: Bool
    @Binding var showingBarcodeScanner: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                
                Menu {
                    Button(action: {
                        showingFoodSearch = true
                    }) {
                        Label("Search Foods", systemImage: "magnifyingglass")
                    }
                    
                    Button(action: {
                        showingBarcodeScanner = true
                    }) {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.border.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
            .padding(.bottom, 120) // Position above the tab bar
        }
    }
}
