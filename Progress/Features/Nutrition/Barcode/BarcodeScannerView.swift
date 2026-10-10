//
//  BarcodeScannerView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import SwiftData

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var barcodeService = BarcodeSearchService()

    @State private var showingAddFood = false
    @State private var scannedProduct: BarcodeResult?
    @State private var hasScannedSuccessfully = false
    @State private var cameraError: String?
    @State private var rescanToken = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                BarcodeCameraPreview(
                    rescanToken: rescanToken,
                    onBarcodeDetected: { barcode in
                        guard !hasScannedSuccessfully else { return }

                        Task {
                            if let result = await barcodeService.searchByBarcode(barcode) {
                                scannedProduct = result
                                showingAddFood = true
                                hasScannedSuccessfully = true

                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }
                    },
                    onFailure: { message in
                        cameraError = message
                    }
                )
                .ignoresSafeArea()

                if let cameraError {
                    cameraFailure(cameraError)
                } else {
                VStack {
                    Spacer()
                    
                    // Scanning Frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(width: 250, height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundColor(.primary)
                                
                                Text("Align barcode within frame")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        )
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("Scan product barcode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Hold your phone steady and align the barcode")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
                }
                
                // Loading Overlay
                if barcodeService.isLoading {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Looking up product...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingAddFood) {
                if let product = scannedProduct {
                    AddBarcodeProductView(product: product) {
                        dismiss()
                    }
                }
            }
            .alert(
                "Scan Error",
                isPresented: Binding(
                    get: { barcodeService.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            barcodeService.errorMessage = nil
                            hasScannedSuccessfully = false
                        }
                    }
                )
            ) {
                Button("Try Again", role: .cancel) {
                    rescanToken += 1
                }
                Button("Close") {
                    dismiss()
                }
            } message: {
                Text(barcodeService.errorMessage ?? "")
            }
            .onAppear {
                // Lock orientation to portrait when scanner appears
                AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
            }
            .onDisappear {
                // Restore all orientations when scanner disappears
                AppDelegate.orientationLock = UIInterfaceOrientationMask.all
            }
        }
    }

    private func cameraFailure(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.titleLarge)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
            Button("Close") {
                dismiss()
            }
        }
        .foregroundColor(.textPrimary)
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(24)
    }
}

// MARK: - Add Barcode Product View

struct AddBarcodeProductView: View {
    @Environment(\.modelContext) private var modelContext
    
    let product: BarcodeResult
    @State private var quantity: Double = 1.0
    @State private var notes: String = ""
    
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Product Info
                Section("Product Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if let brand = product.brandName {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Serving: \(product.servingSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if product.isVerified {
                                Label("Verified", systemImage: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                

                
                // Quantity
                Section("Quantity") {
                    HStack {
                        Text("Servings")
                        Spacer()
                        
                        Button("-") {
                            if quantity > 0.25 {
                                quantity -= 0.25
                            }
                        }
                        .disabled(quantity <= 0.25)
                        
                        Text(String(format: "%.2g", quantity))
                            .frame(minWidth: 40)
                            .fontWeight(.medium)
                        
                        Button("+") {
                            quantity += 0.25
                        }
                    }
                }
                
                // Nutrition Preview
                if let calories = product.calories {
                    Section("Nutrition (per serving)") {
                        HStack {
                            Text("Calories")
                            Spacer()
                            Text("\(Int(calories * quantity))")
                                .fontWeight(.medium)
                        }
                        
                        if let protein = product.protein {
                            HStack {
                                Text("Protein")
                                Spacer()
                                Text("\(String(format: "%.1f", protein * quantity))g")
                            }
                        }
                        
                        if let carbs = product.carbohydrates {
                            HStack {
                                Text("Carbs")
                                Spacer()
                                Text("\(String(format: "%.1f", carbs * quantity))g")
                            }
                        }
                        
                        if let fat = product.fat {
                            HStack {
                                Text("Fat")
                                Spacer()
                                Text("\(String(format: "%.1f", fat * quantity))g")
                            }
                        }
                    }
                }
                
                // Notes
                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .background(AdaptiveGradientBackground())
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onSave()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        saveProduct()
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveProduct() {
        let nutritionEntry = NutritionEntry(
            foodName: product.displayName,
            servingSize: product.servingSize,
            quantity: quantity,
            calories: (product.calories ?? 0),
            protein: (product.protein ?? 0),
            carbohydrates: (product.carbohydrates ?? 0),
            fat: (product.fat ?? 0),
            mealType: .breakfast, // Default value since we're not using meal types
            logMethod: .barcode
        )
        
        // Set additional properties after initialization
        nutritionEntry.fiber = product.fiber
        nutritionEntry.foodDatabaseId = product.barcode
        nutritionEntry.isVerified = product.isVerified
        nutritionEntry.brandName = product.brandName
        if !notes.isEmpty {
            nutritionEntry.notes = notes
        }
        
        modelContext.insert(nutritionEntry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save nutrition entry: \(error)")
        }
    }
}

#Preview {
    BarcodeScannerView()
}