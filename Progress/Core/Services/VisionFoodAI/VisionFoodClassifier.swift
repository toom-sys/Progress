//
//  VisionFoodClassifier.swift
//  Progress
//
//  Created by Progress Team on 10/10/2026.
//

import Foundation
import ImageIO
import Vision

/// On-device food classification. Runs entirely offline and never crashes the photo flow.
enum VisionFoodClassifier {
    static func classify(imageData: Data) async throws -> [FoodClassification] {
        guard let cgImage = makeCGImage(from: imageData) else {
            throw FoodPhotoAnalysisError.unreadableImage
        }

        let orientation = imageOrientation(from: imageData)
        nonisolated(unsafe) let image = cgImage

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNClassifyImageRequest()
                let handler = VNImageRequestHandler(
                    cgImage: image,
                    orientation: orientation,
                    options: [:]
                )

                do {
                    try handler.perform([request])
                    let observations = (request.results as? [VNClassificationObservation]) ?? []
                    let classifications = observations.prefix(8).map { observation in
                        FoodClassification(
                            label: observation.identifier,
                            confidence: Double(observation.confidence)
                        )
                    }
                    continuation.resume(returning: Array(classifications))
                } catch {
                    continuation.resume(
                        throwing: FoodPhotoAnalysisError.analysisFailed(
                            "The photo couldn't be analysed. Enter the food manually."
                        )
                    )
                }
            }
        }
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static func imageOrientation(from data: Data) -> CGImagePropertyOrientation {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawValue) else {
            return .up
        }
        return orientation
    }
}
