//
//  NutritionTab.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

// MARK: - Nutrition Tab View

struct NutritionTab: View {
    @Binding var showingFoodSearch: Bool
    @Binding var showingBarcodeScanner: Bool
    
    var body: some View {
        NavigationStack {
            NutritionDashboardView(
                showingFoodSearch: $showingFoodSearch,
                showingBarcodeScanner: $showingBarcodeScanner
            )
        }
    }
}
