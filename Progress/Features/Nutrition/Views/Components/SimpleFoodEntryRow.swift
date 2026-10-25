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
    
    private static let thumbnailSide: CGFloat = 50
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header row with food name and time
            HStack {
                // Captured image for AI camera entries
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Self.thumbnailSide, height: Self.thumbnailSide)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.foodName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                        
                        // AI log indicators
                        if entry.logMethod == .aiCamera {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                        } else if entry.logMethod == .aiPrompt {
                            Image(systemName: "text.bubble.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if entry.quantity != 1.0 {
                            Text("\(String(format: "%.2g", entry.quantity)) × \(entry.servingSize)")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text(entry.servingSize)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if entry.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if let brandName = entry.brandName {
                            Text("• \(brandName)")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                if !entry.isPending {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Self.timeFormatter.string(from: entry.loggedAt))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("\(Int(entry.totalCalories))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // Macros row or loading indicator
            if entry.isPending {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing photo...")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
            } else {
                HStack(spacing: 20) {
                    MacroMiniCard(
                        value: entry.totalProtein,
                        label: "Protein",
                        unit: "g",
                        color: .red,
                        icon: "fish.fill"
                    )
                    
                    MacroMiniCard(
                        value: entry.totalCarbohydrates,
                        label: "Carbs",
                        unit: "g",
                        color: .orange,
                        icon: "leaf.fill"
                    )
                    
                    MacroMiniCard(
                        value: entry.totalFat,
                        label: "Fat",
                        unit: "g",
                        color: .blue,
                        icon: "drop.fill"
                    )
                    
                    Spacer()
                }
            }
        }
        .whiteCardStyleWithBorder(cornerRadius: 16)
        .task(id: entry.id) {
            loadThumbnail()
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
