//
//  FoodPhotoLogView.swift
//  Progress
//
//  Created by Progress Team on 10/10/2026.
//

import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct FoodPhotoLogView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var modelContext
    @EnvironmentObject private var subscriptionService: SubscriptionService

    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var isAnalyzing = false
    @State private var draft: FoodPhotoDraft?
    @State private var statusMessage: String?
    @State private var saveError: String?
    @State private var showingPaywall = false

    private var canLogPhotos: Bool {
        subscriptionService.isAIUser || subscriptionService.isSandboxMode
    }

    var body: some View {
        NavigationStack {
            Group {
                if !canLogPhotos {
                    upgradeContent
                } else if isAnalyzing {
                    analyzingContent
                } else if draft != nil {
                    reviewContent
                } else {
                    pickerContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AdaptiveGradientBackground())
            .navigationTitle("Take Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            FoodCameraCapture { outcome in
                handleCameraOutcome(outcome)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                await loadPickerItem(item)
            }
        }
    }

    private var pickerContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.titleLarge)
                .foregroundColor(.primary)

            Text("Photograph a meal")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)

            Text("We'll estimate the food and macros on this device. You can correct anything that looks wrong.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let statusMessage {
                Text(statusMessage)
                    .font(.bodySmall)
                    .foregroundColor(.warning)
                    .multilineTextAlignment(.center)
            }

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Choose Photo")
                    .primaryButtonStyle()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button("Take Photo") {
                openCamera()
            }
            .secondaryButtonStyle()
        }
        .padding(24)
    }

    private var analyzingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Reading photo...")
                .font(.body)
                .foregroundColor(.textSecondary)
        }
    }

    private var upgradeContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.titleLarge)
                .foregroundColor(.primary)

            Text("Photo logging is part of Plus AI")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text("Upgrade to photograph a meal and fill in the macros automatically.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button("See plans") {
                showingPaywall = true
            }
            .primaryButtonStyle()
        }
        .padding(24)
    }

    private var reviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photoPreview
                confidenceBanner
                draftFields
                if let saveError {
                    Text(saveError)
                        .font(.bodySmall)
                        .foregroundColor(.error)
                }
                Button("Add Food") {
                    saveDraft()
                }
                .primaryButtonStyle()
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.45)

                Button("Choose another photo") {
                    draft = nil
                    photoData = nil
                    statusMessage = nil
                    saveError = nil
                }
                .secondaryButtonStyle()
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder private var photoPreview: some View {
        if let photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder private var confidenceBanner: some View {
        if let draft {
            if let statusMessage {
                Text(statusMessage)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            } else if let confidence = draft.confidence {
                HStack {
                    Image(systemName: draft.needsVerification ? "exclamationmark.circle" : "checkmark.seal.fill")
                    Text(draft.needsVerification ? "Check this guess" : "High confidence")
                    Spacer()
                    Text("\(Int((confidence * 100).rounded()))%")
                }
                .font(.bodySmall)
                .foregroundColor(draft.needsVerification ? .warning : .success)
            }
        }
    }

    private var draftFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            labeledField("Food", text: draftBinding(\.foodName))
            labeledField("Serving", text: draftBinding(\.servingSize))
            quantityRow
            numberField("Calories", value: draftBinding(\.calories))
            numberField("Protein (g)", value: draftBinding(\.protein))
            numberField("Carbs (g)", value: draftBinding(\.carbohydrates))
            numberField("Fat (g)", value: draftBinding(\.fat))
        }
        .cardStyle()
    }

    private var quantityRow: some View {
        HStack {
            Text("Quantity")
                .font(.body)
                .foregroundColor(.textPrimary)
            Spacer()
            Button("-") {
                updateQuantity(by: -0.25)
            }
            .disabled((draft?.quantity ?? 1) <= 0.25)
            Text(String(format: "%.2g", draft?.quantity ?? 1))
                .font(.numberSmall)
                .frame(minWidth: 44)
            Button("+") {
                updateQuantity(by: 0.25)
            }
        }
    }

    private var canSave: Bool {
        guard let draft else { return false }
        return !draft.foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.calories >= 0
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            TextField(title, text: text)
                .font(.body)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func numberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            TextField(title, value: value, format: .number)
                .font(.body)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func draftBinding<Value>(_ keyPath: WritableKeyPath<FoodPhotoDraft, Value>) -> Binding<Value> {
        Binding(
            get: { (draft ?? .empty)[keyPath: keyPath] },
            set: { newValue in
                var updated = draft ?? .empty
                updated[keyPath: keyPath] = newValue
                draft = updated
            }
        )
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            statusMessage = "Camera isn't available on this device. Choose a photo instead."
            return
        }
        statusMessage = nil
        showingCamera = true
    }

    private func handleCameraOutcome(_ outcome: FoodCameraOutcome) {
        showingCamera = false
        switch outcome {
        case .cancelled:
            break
        case .unreadable:
            statusMessage = FoodPhotoAnalysisError.unreadableImage.localizedDescription
            draft = .empty
        case .captured(let data):
            photoData = data
            Task {
                await analyze(data)
            }
        }
    }

    private func loadPickerItem(_ item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        do {
            guard let transfer = try await item.loadTransferable(type: FoodPhotoTransfer.self) else {
                statusMessage = FoodPhotoAnalysisError.unreadableImage.localizedDescription
                return
            }
            photoData = transfer.data
            await analyze(transfer.data)
        } catch {
            statusMessage = FoodPhotoAnalysisError.unreadableImage.localizedDescription
        }
    }

    private func analyze(_ data: Data) async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        statusMessage = nil
        saveError = nil
        defer { isAnalyzing = false }

        do {
            let classifications = try await VisionFoodClassifier.classify(imageData: data)
            apply(FoodPhotoAnalyzer.analyze(classifications))
        } catch let error as FoodPhotoAnalysisError {
            draft = .empty
            statusMessage = error.localizedDescription
        } catch {
            draft = .empty
            statusMessage = FoodPhotoAnalysisError.analysisFailed(
                "The photo couldn't be analysed. Enter the food manually."
            ).localizedDescription
        }
    }

    private func apply(_ result: Result<FoodPhotoGuess, FoodPhotoAnalysisError>) {
        switch result {
        case .success(let guess):
            draft = FoodPhotoDraft(guess: guess)
            statusMessage = nil
        case .failure(let error):
            draft = .empty
            statusMessage = error.localizedDescription
        }
    }

    private func updateQuantity(by delta: Double) {
        var updated = draft ?? .empty
        updated.quantity = max(0.25, updated.quantity + delta)
        draft = updated
    }

    private func saveDraft() {
        guard let draft, canSave else { return }

        let entry = NutritionEntry(
            foodName: draft.foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            servingSize: draft.servingSize.isEmpty ? "1 serving" : draft.servingSize,
            quantity: draft.quantity,
            calories: draft.calories,
            protein: draft.protein,
            carbohydrates: draft.carbohydrates,
            fat: draft.fat,
            logMethod: .aiCamera
        )
        entry.fiber = draft.fiber
        if let confidence = draft.confidence {
            entry.setAIData(confidence: confidence)
            if !draft.needsVerification {
                entry.verify()
            }
        }

        modelContext.insert(entry)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(entry)
            saveError = "Couldn't save that meal. Try again."
        }
    }
}

private struct FoodPhotoDraft {
    var foodName: String
    var servingSize: String
    var quantity: Double
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var fiber: Double
    var confidence: Double?

    var needsVerification: Bool {
        guard let confidence else { return true }
        return confidence < FoodPhotoAnalyzer.verificationThreshold
    }

    static let empty = FoodPhotoDraft(
        foodName: "",
        servingSize: "1 serving",
        quantity: 1,
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        fiber: 0,
        confidence: nil
    )

    init(
        foodName: String,
        servingSize: String,
        quantity: Double,
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        fiber: Double,
        confidence: Double?
    ) {
        self.foodName = foodName
        self.servingSize = servingSize
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.confidence = confidence
    }

    init(guess: FoodPhotoGuess) {
        self.init(
            foodName: guess.foodName,
            servingSize: guess.servingSize,
            quantity: 1,
            calories: guess.calories,
            protein: guess.protein,
            carbohydrates: guess.carbohydrates,
            fat: guess.fat,
            fiber: guess.fiber,
            confidence: guess.confidence
        )
    }
}

private struct FoodPhotoTransfer: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            FoodPhotoTransfer(data: data)
        }
    }
}

#Preview {
    FoodPhotoLogView()
        .environmentObject(SubscriptionService())
}
