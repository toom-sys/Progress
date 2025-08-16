//
//  ManualFoodEntryView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

/// View shown when a barcode is not found in any database
struct BarcodeNotFoundView: View {
    @Environment(\.dismiss) private var dismiss
    let barcode: String?
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Food Not Found")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("We couldn't find this product in our database. You can add it manually or try taking a photo of the nutrition label.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if let barcode = barcode {
                        Text("Barcode: \(barcode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                VStack(spacing: 12) {
                    Button("Add Food Manually") {
                        // TODO: Navigate to manual food entry
                        onSave()
                    }
                    .primaryButtonStyle()
                    
                    Button("Take Photo of Label") {
                        // TODO: Navigate to camera OCR
                        onSave()
                    }
                    .secondaryButtonStyle()
                    
                    Button("Search by Name") {
                        // TODO: Navigate to text search
                        onSave()
                    }
                    .secondaryButtonStyle()
                }
                
                Spacer()
            }
            .padding()
            .background(AdaptiveGradientBackground())
            .navigationTitle("Not Found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
