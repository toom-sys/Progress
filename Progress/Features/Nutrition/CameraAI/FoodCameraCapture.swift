//
//  FoodCameraCapture.swift
//  Progress
//
//  Created by Progress Team on 10/10/2026.
//

import SwiftUI

enum FoodCameraOutcome {
    case cancelled
    case captured(Data)
    case unreadable
}

/// Camera capture for a meal photo. Refuses to select the camera source when the device has none,
/// which otherwise raises an uncaught exception.
struct FoodCameraCapture: UIViewControllerRepresentable {
    let onFinished: (FoodCameraOutcome) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return picker
        }

        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinished: (FoodCameraOutcome) -> Void
        private var hasFinished = false

        init(onFinished: @escaping (FoodCameraOutcome) -> Void) {
            self.onFinished = onFinished
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            guard !hasFinished else { return }
            hasFinished = true
            onFinished(.cancelled)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard !hasFinished else { return }
            hasFinished = true

            let image = info[.originalImage] as? UIImage
            guard let data = image?.jpegData(compressionQuality: 0.85) else {
                onFinished(.unreadable)
                return
            }
            onFinished(.captured(data))
        }
    }
}
