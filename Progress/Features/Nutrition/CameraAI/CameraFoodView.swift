import SwiftUI
@preconcurrency import AVFoundation
import PhotosUI
import UIKit
import SwiftData

struct CameraFoodView: View {
    @StateObject private var openAIClient = OpenAIFoodClient()
    @StateObject private var cameraManager = CameraManager()
    
    @State private var showingImagePicker = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
                
                // Overlay UI
                VStack {
                    // Top bar
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("Point camera at your food")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("AI will identify and estimate nutrition")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Camera controls
                    HStack(spacing: 60) {
                        // Gallery picker
                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        // Capture button
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                            }
                        }
                        
                        // Flash toggle
                        Button(action: toggleFlash) {
                            Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cameraManager.requestPermission()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { selectedImage in
                analyzeImage(selectedImage)
            }
        }
    }
    
    private func capturePhoto() {
        cameraManager.capturePhoto { @Sendable image in
            Task { @MainActor in
                guard let image = image else { return }
                analyzeImage(image)
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        // Insert a pending placeholder so the dashboard shows a loading row immediately
        let pendingEntry = NutritionEntry(
            foodName: "Analyzing...",
            servingSize: "—",
            quantity: 1.0,
            calories: 0,
            protein: 0,
            carbohydrates: 0,
            fat: 0,
            mealType: .other,
            logMethod: .aiCamera
        )
        pendingEntry.isPending = true
        pendingEntry.loggedAt = Date()
        pendingEntry.setAIData(confidence: 0, capturedImage: image)
        modelContext.insert(pendingEntry)
        try? modelContext.save()

        // Close the camera immediately — dashboard is now visible with the loading row
        dismiss()

        // Capture stable references before the view tears down
        let context = modelContext
        let client = openAIClient

        Task { @MainActor in
            do {
                let result = try await client.analyzeFoodImage(image)

                let highConfidence = result.foods.filter { $0.confidence > 0.7 }
                let foodsToAdd = highConfidence.isEmpty ? result.foods : highConfidence

                if let first = foodsToAdd.first {
                    // Update the pending entry in-place with the first recognised food
                    pendingEntry.foodName = first.name
                    pendingEntry.servingSize = first.quantity
                    pendingEntry.calories = first.calories ?? 0
                    pendingEntry.protein = first.protein ?? 0
                    pendingEntry.carbohydrates = first.carbs ?? 0
                    pendingEntry.fat = first.fat ?? 0
                    pendingEntry.isPending = false
                    pendingEntry.aiConfidence = first.confidence
                    if let ext = first.extendedNutrition {
                        pendingEntry.extendedNutrition = ext
                    }

                    // Insert separate entries for any additional foods in the photo
                    for food in foodsToAdd.dropFirst() {
                        let extra = NutritionEntry(
                            foodName: food.name,
                            servingSize: food.quantity,
                            quantity: 1.0,
                            calories: food.calories ?? 0,
                            protein: food.protein ?? 0,
                            carbohydrates: food.carbs ?? 0,
                            fat: food.fat ?? 0,
                            mealType: .other,
                            logMethod: .aiCamera
                        )
                        extra.setAIData(confidence: food.confidence, capturedImage: image)
                        extra.loggedAt = Date()
                        if let ext = food.extendedNutrition {
                            extra.extendedNutrition = ext
                        }
                        context.insert(extra)
                    }
                } else {
                    // AI returned no foods — surface this to the user rather than silently vanishing
                    pendingEntry.foodName = "No food recognised"
                    pendingEntry.servingSize = "Swipe to remove"
                    pendingEntry.isPending = false
                }

                try? context.save()
            } catch {
                // Surface the failure as a visible row the user can dismiss themselves
                pendingEntry.foodName = "Analysis failed"
                pendingEntry.servingSize = "Swipe to remove"
                pendingEntry.isPending = false
                try? context.save()
            }
        }
    }
    
    private func toggleFlash() {
        cameraManager.toggleFlash()
    }
}

// MARK: - Image Picker (PHPickerViewController)

struct ImagePickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, dismiss: dismiss)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let dismiss: DismissAction
        
        init(onImageSelected: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            dismiss()
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.onImageSelected(image)
                    }
                }
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let previewLayer = cameraManager.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            cameraManager.previewLayer?.frame = uiView.bounds
        }
    }
}

// MARK: - Camera Manager

@MainActor
class CameraManager: NSObject, ObservableObject {
    private var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    
    @Published var isFlashOn = false
    @Published var hasPermission = false
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCompletionHandler: (@Sendable (UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
        setupSessionInterruptionHandling()
    }
    
    func requestPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            hasPermission = true
            startSessionSync()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.hasPermission = granted
                    if granted { self.startSessionSync() }
                }
            }
        default:
            hasPermission = false
        }
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            captureSession.commitConfiguration()
            return
        }
        
        currentDevice = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            if captureSession.canAddInput(input) { captureSession.addInput(input) }
            if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            captureSession.commitConfiguration()
        } catch {
            captureSession.commitConfiguration()
        }
    }
    
    private func startSessionSync() {
        let session = captureSession
        Task {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    continuation.resume()
                }
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                if !session.isRunning {
                    self.reconfigureSession()
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping @Sendable (UIImage?) -> Void) {
        guard captureSession.isRunning else {
            let session = captureSession
            Task {
                await withCheckedContinuation { continuation in
                    DispatchQueue.global(qos: .background).async {
                        session.startRunning()
                        continuation.resume()
                    }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    if session.isRunning {
                        self.capturePhoto(completion: completion)
                    } else {
                        completion(nil)
                    }
                }
            }
            return
        }
        
        photoCompletionHandler = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    private func reconfigureSession() {
        let session = captureSession
        Task {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .background).async {
                    session.stopRunning()
                    Thread.sleep(forTimeInterval: 0.2)
                    continuation.resume()
                }
            }
            await MainActor.run {
                self.setupCamera()
                self.startSessionSync()
            }
        }
    }
    
    private func setupSessionInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: captureSession,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleInterruptionEnded() }
        }
        
        NotificationCenter.default.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: captureSession,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reconfigureSession() }
        }
    }
    
    nonisolated private func handleInterruptionEnded() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let session = await MainActor.run { self.captureSession }
            if !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Photo Capture Delegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                self.photoCompletionHandler?(nil)
                self.photoCompletionHandler = nil
            }
            return
        }
        
        Task { @MainActor in
            self.photoCompletionHandler?(image)
            self.photoCompletionHandler = nil
        }
    }
}

// MARK: - Preview

#Preview {
    CameraFoodView()
}
