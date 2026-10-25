//
//  SimpleFoodEntryRow.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import ImageIO

// MARK: - Simple Food Entry Row Component

struct SimpleFoodEntryRow: View {
    let entry: NutritionEntry
    
    private static let thumbnailSide: CGFloat = 46

    @State private var thumbnail: UIImage?
    
    private var detailLine: String {
        if entry.quantity != 1.0 {
            return "\(String(format: "%.2g", entry.quantity)) × \(entry.servingSize)"
        }
        return entry.servingSize
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(AppPalette.ink)
                    .lineLimit(2)

                if entry.isPending {
                    Text("Analyzing photo...")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppPalette.muted)
                } else {
                    Text(detailLine)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppPalette.muted)
                        .lineLimit(1)

                    if entry.logMethod == .aiCamera {
                        Text("📸 logged from photo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppPalette.liveText)
                    }
                }
            }

            Spacer(minLength: 0)

            if entry.isPending {
                ProgressView()
            } else {
                Text("\(Int(entry.totalCalories))")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(AppPalette.ink)
                    .lineLimit(1)
            }
        }
        .appCard(cornerRadius: 20, padding: 12)
        .task(id: entry.id) {
            loadThumbnail()
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Self.thumbnailSide, height: Self.thumbnailSide)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else if entry.imageData != nil {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppPalette.optionFill)
                .frame(width: Self.thumbnailSide, height: Self.thumbnailSide)
        } else {
            EmojiTile(emoji: "🍽️", size: 46, background: AppPalette.tint(.green))
        }
    }
    
    /// Decodes and downsamples the captured image once, off the main thread, and
    /// caches the result so it isn't re-decoded on every render pass.
    private func loadThumbnail() {
        guard thumbnail == nil, let imageData = entry.imageData else { return }
        let maxPixelSize = Self.thumbnailSide * (UIScreen.main.scale > 0 ? UIScreen.main.scale : 2)
        Task.detached(priority: .userInitiated) {
            let downsampled = Self.downsampledImage(from: imageData, maxPixelSize: maxPixelSize)
            if let downsampled {
                await MainActor.run { self.thumbnail = downsampled }
            }
        }
    }
    
    /// Uses ImageIO to decode directly to a thumbnail, avoiding a full-resolution decode.
    nonisolated private static func downsampledImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return UIImage(data: data)
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 1)
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
