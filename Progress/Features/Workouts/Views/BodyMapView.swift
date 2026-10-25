//
//  BodyMapView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI
import UIKit

// MARK: - Body Map Variant

/// Which body illustration to render. Each variant has its own base/lines/mask
/// assets and slightly different geometry.
enum BodyMapVariant {
    case male
    case female

    /// Prefix shared by all asset names for this variant
    var assetPrefix: String {
        switch self {
        case .male: return "bodymap"
        case .female: return "bodymap_female"
        }
    }

    var baseImageName: String { "\(assetPrefix)_base" }
    var linesImageName: String { "\(assetPrefix)_lines" }

    func maskImageName(for group: MuscleGroup) -> String {
        "\(assetPrefix)_mask_\(group.rawValue)"
    }

    /// Width / height of the illustration
    var imageAspect: CGFloat {
        switch self {
        case .male: return 716.0 / 665.0
        case .female: return 816.0 / 815.0
        }
    }

    /// Normalized position of the heart illustration within the body map image
    var heartPosition: CGPoint {
        switch self {
        case .male: return CGPoint(x: 0.446, y: 0.378)
        case .female: return CGPoint(x: 0.504, y: 0.330)
        }
    }
}

extension BiologicalSex {
    /// Body map illustration matching the user's selection during onboarding.
    /// `.unspecified` falls back to the male illustration.
    var bodyMapVariant: BodyMapVariant {
        self == .female ? .female : .male
    }
}

// MARK: - Body Map View

/// Visual body map using the reference illustration with per-muscle-group
/// mask images so progress colors follow the exact muscle contours.
struct BodyMapView: View {

    // MARK: - Properties

    let muscleGroupProgress: [MuscleGroup: ProgressTier]
    let muscleGroupOpacity: [MuscleGroup: Double]
    let showTestColors: Bool
    let variant: BodyMapVariant
    let onMuscleGroupTap: ((MuscleGroup, ProgressTier, Double) -> Void)?

    private static let maskedGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .core, .quads, .posteriorChain]

    // MARK: - Animation State

    @State private var animationValues: [MuscleGroup: Double] = [:]
    @State private var revealAnimations: [MuscleGroup: Bool] = [:]
    @State private var pulseAnimations: [MuscleGroup: Bool] = [:]
    @State private var glowAnimations: [MuscleGroup: Bool] = [:]
    @State private var scaleAnimations: [MuscleGroup: Double] = [:]
    @State private var rotationAnimations: [MuscleGroup: Double] = [:]
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    @State private var particleEffects: [MuscleGroup: Bool] = [:]
    @State private var breathingAnimation: Bool = false
    @State private var overallGlow: Double = 0.0

    // MARK: - Initialization

    init(
        muscleGroupProgress: [MuscleGroup: ProgressTier] = [:],
        muscleGroupOpacity: [MuscleGroup: Double] = [:],
        showTestColors: Bool = false,
        variant: BodyMapVariant = .male,
        onMuscleGroupTap: ((MuscleGroup, ProgressTier, Double) -> Void)? = nil
    ) {
        self.muscleGroupProgress = muscleGroupProgress
        self.muscleGroupOpacity = muscleGroupOpacity
        self.showTestColors = showTestColors
        self.variant = variant
        self.onMuscleGroupTap = onMuscleGroupTap
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let renderedSize = fittedImageSize(in: geo.size)
            let offsetX = (geo.size.width - renderedSize.width) / 2
            let offsetY = (geo.size.height - renderedSize.height) / 2

            let artwork = BodyMapArtwork.rendered(baseName: variant.baseImageName)

            ZStack {
                // White inside the figure. Clear pixels let the card surface show around it.
                if let artwork {
                    Image(uiImage: artwork.fill)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: renderedSize.width, height: renderedSize.height)
                        .allowsHitTesting(false)
                }

                // Translucent pastel tints over the active muscle groups.
                maskedMuscleLayers(in: renderedSize)

                if let artwork {
                    Image(uiImage: artwork.stroke)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: renderedSize.width, height: renderedSize.height)
                        .allowsHitTesting(false)
                } else {
                    Image(variant.linesImageName)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: renderedSize.width, height: renderedSize.height)
                        .allowsHitTesting(false)
                }

                cardioHeartOverlay(in: renderedSize)

                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: renderedSize.width, height: renderedSize.height)
                    .onTapGesture { location in
                        let heartCenter = CGPoint(
                            x: renderedSize.width * variant.heartPosition.x,
                            y: renderedSize.height * variant.heartPosition.y
                        )
                        let heartRadius = max(renderedSize.height * 0.045, 12) * 1.5
                        let dx = location.x - heartCenter.x
                        let dy = location.y - heartCenter.y
                        if sqrt(dx * dx + dy * dy) < heartRadius {
                            handleMuscleGroupTap(.cardio)
                            return
                        }

                        if let group = hitTestMuscleGroup(at: location, in: renderedSize) {
                            handleMuscleGroupTap(group)
                        }
                    }
            }
            .frame(width: renderedSize.width, height: renderedSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .offset(x: offsetX, y: offsetY)
        }
        .aspectRatio(variant.imageAspect, contentMode: .fit)
        .overlay(cardioAura)
        .scaleEffect(1.0 + (breathingAnimation ? 0.015 : 0.0))
        .shadow(color: Color.blue.opacity(overallGlow * 0.3), radius: overallGlow * 8, x: 0, y: 0)
        .onAppear {
            initializeAnimations()
            prepareHapticFeedback()
            startBreathingAnimation()
        }
        .onChange(of: muscleGroupProgress) { _, newProgress in
            updateAnimations(for: newProgress)
            updateOverallGlow()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Body progress map showing muscle group training levels")
    }

    // MARK: - Image Sizing

    private func fittedImageSize(in container: CGSize) -> CGSize {
        let containerAspect = container.width / container.height
        if containerAspect > variant.imageAspect {
            let h = container.height
            return CGSize(width: h * variant.imageAspect, height: h)
        } else {
            let w = container.width
            return CGSize(width: w, height: w / variant.imageAspect)
        }
    }

    // MARK: - Mask-Based Muscle Layers

    private func maskedMuscleLayers(in size: CGSize) -> some View {
        ZStack {
            ForEach(Self.maskedGroups, id: \.self) { group in
                Rectangle()
                    .fill(getProgressColor(for: group))
                    .mask(
                        Image(variant.maskImageName(for: group))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    )
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityLabel("\(group.displayName) muscle group")
                    .accessibilityValue(getProgressTier(for: group).accessibilityDescription)
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Pixel Hit Testing

    private func hitTestMuscleGroup(at point: CGPoint, in size: CGSize) -> MuscleGroup? {
        let nx = point.x / size.width
        let ny = point.y / size.height

        for group in Self.maskedGroups {
            guard let uiImage = UIImage(named: variant.maskImageName(for: group)),
                  let cgImage = uiImage.cgImage else { continue }

            let px = Int(nx * CGFloat(cgImage.width))
            let py = Int(ny * CGFloat(cgImage.height))

            guard px >= 0, px < cgImage.width, py >= 0, py < cgImage.height else { continue }

            if pixelAlpha(in: cgImage, x: px, y: py) > 128 {
                return group
            }
        }
        return nil
    }

    private func pixelAlpha(in cgImage: CGImage, x: Int, y: Int) -> UInt8 {
        guard let provider = cgImage.dataProvider,
              let data = provider.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }

        let bpp = cgImage.bitsPerPixel / 8
        let offset = cgImage.bytesPerRow * y + bpp * x
        let alphaIndex = (cgImage.alphaInfo == .premultipliedFirst || cgImage.alphaInfo == .first) ? 0 : bpp - 1
        return ptr[offset + alphaIndex]
    }

    // MARK: - Cardio Heart Overlay

    private func cardioHeartOverlay(in size: CGSize) -> some View {
        let tier = getProgressTier(for: .cardio)
        return Image(systemName: "heart.fill")
            .font(.system(size: max(size.height * 0.045, 12)))
            .foregroundColor(tier == .dormant ? .clear : getProgressColor(for: .cardio))
            .scaleEffect(breathingAnimation && tier != .dormant ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: breathingAnimation)
            .position(x: size.width * variant.heartPosition.x, y: size.height * variant.heartPosition.y)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel("Cardio")
            .accessibilityValue(tier.accessibilityDescription)
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Cardio Aura

    @ViewBuilder
    private var cardioAura: some View {
        let cardioTier = getProgressTier(for: .cardio)
        if cardioTier != .dormant {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    getProgressColor(for: .cardio),
                    lineWidth: 2
                )
                .blur(radius: 3)
                .opacity(breathingAnimation ? 0.7 : 0.3)
        }
    }

    // MARK: - Helper Methods

    private func getProgressTier(for muscleGroup: MuscleGroup) -> ProgressTier {
        if showTestColors {
            return getTestProgressTier(for: muscleGroup)
        }
        return muscleGroupProgress[muscleGroup] ?? .dormant
    }

    private func getTestProgressTier(for muscleGroup: MuscleGroup) -> ProgressTier {
        switch muscleGroup {
        case .chest: return .beginnerSpark
        case .back: return .gettingTraction
        case .shoulders: return .solidIntermediate
        case .arms: return .advanced
        case .core: return .athleteTier
        case .quads: return .solidIntermediate
        case .posteriorChain: return .gettingTraction
        case .cardio: return .advanced
        }
    }

    private func getProgressColor(for muscleGroup: MuscleGroup) -> Color {
        let tier = getProgressTier(for: muscleGroup)

        // Dormant groups aren't tinted — the grey base illustration shows
        // through as the default look.
        guard tier != .dormant else { return .clear }

        let decay = muscleGroupOpacity[muscleGroup] ?? 0.3
        let animationValue = animationValues[muscleGroup] ?? 1.0
        let pulseValue = pulseAnimations[muscleGroup] ?? false
        let glowValue = glowAnimations[muscleGroup] ?? false

        let baseColor = tier.color

        // Map the decay range (0.3...1.0) onto a strong-but-translucent tint
        // so pastel colours read clearly over the grey artwork while its thin
        // outlines and shading stay visible underneath.
        var finalOpacity = 0.5 + 0.42 * decay

        if animationValue != 1.0 {
            finalOpacity *= animationValue
        }
        if pulseValue || glowValue {
            finalOpacity = min(1.0, finalOpacity * 1.15)
        }

        return baseColor.opacity(min(finalOpacity, 0.92))
    }

    private func handleMuscleGroupTap(_ muscleGroup: MuscleGroup) {
        hapticFeedback.impactOccurred()

        withAnimation(.easeOut(duration: 0.1)) {
            scaleAnimations[muscleGroup] = 0.95
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                scaleAnimations[muscleGroup] = 1.0
                pulseAnimations[muscleGroup] = true
                glowAnimations[muscleGroup] = true
            }
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            rotationAnimations[muscleGroup] = 2.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.3)) {
                pulseAnimations[muscleGroup] = false
                glowAnimations[muscleGroup] = false
                rotationAnimations[muscleGroup] = 0.0
            }
        }

        let tier = getProgressTier(for: muscleGroup)
        let opacity = muscleGroupOpacity[muscleGroup] ?? 0.3
        onMuscleGroupTap?(muscleGroup, tier, opacity)
    }

    // MARK: - Animation Methods

    private func initializeAnimations() {
        for muscleGroup in MuscleGroup.allCases {
            animationValues[muscleGroup] = 1.0
            revealAnimations[muscleGroup] = false
            pulseAnimations[muscleGroup] = false
            glowAnimations[muscleGroup] = false
            scaleAnimations[muscleGroup] = 1.0
            rotationAnimations[muscleGroup] = 0.0
            particleEffects[muscleGroup] = false
        }
    }

    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathingAnimation = true
        }
    }

    private func updateOverallGlow() {
        let activeGroups = muscleGroupProgress.values.filter { $0 != .dormant }.count
        let maxGroups = MuscleGroup.allCases.count
        let glowIntensity = Double(activeGroups) / Double(maxGroups)

        withAnimation(.easeInOut(duration: 1.0)) {
            overallGlow = glowIntensity
        }
    }

    private func prepareHapticFeedback() {
        hapticFeedback.prepare()
    }

    private func updateAnimations(for newProgress: [MuscleGroup: ProgressTier]) {
        for (muscleGroup, newTier) in newProgress {
            let oldTier = muscleGroupProgress[muscleGroup] ?? .dormant
            if newTier.rawValue != oldTier.rawValue {
                triggerRevealAnimation(for: muscleGroup)
            }
        }
    }

    private func triggerRevealAnimation(for muscleGroup: MuscleGroup) {
        withAnimation(.easeOut(duration: 0.2)) {
            animationValues[muscleGroup] = 0.7
            scaleAnimations[muscleGroup] = 0.9
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                animationValues[muscleGroup] = 1.2
                scaleAnimations[muscleGroup] = 1.05
                revealAnimations[muscleGroup] = true
                glowAnimations[muscleGroup] = true
                particleEffects[muscleGroup] = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.4)) {
                animationValues[muscleGroup] = 1.0
                scaleAnimations[muscleGroup] = 1.0
                particleEffects[muscleGroup] = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                revealAnimations[muscleGroup] = false
                glowAnimations[muscleGroup] = false
            }
        }

        let progressFeedback = UIImpactFeedbackGenerator(style: .heavy)
        progressFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let secondaryFeedback = UIImpactFeedbackGenerator(style: .medium)
            secondaryFeedback.impactOccurred()
        }
    }
}

// MARK: - Progress Tier System

enum ProgressTier: String, CaseIterable {
    case dormant = "dormant"
    case beginnerSpark = "beginnerSpark"
    case gettingTraction = "gettingTraction"
    case solidIntermediate = "solidIntermediate"
    case advanced = "advanced"
    case athleteTier = "athleteTier"

    var displayName: String {
        switch self {
        case .dormant: return "Dormant"
        case .beginnerSpark: return "Beginner Spark"
        case .gettingTraction: return "Getting Traction"
        case .solidIntermediate: return "Solid Intermediate"
        case .advanced: return "Advanced"
        case .athleteTier: return "Athlete Tier"
        }
    }

    var color: Color {
        switch self {
        case .dormant: return .progressDormant
        case .beginnerSpark: return .progressBeginnerSpark
        case .gettingTraction: return .progressGettingTraction
        case .solidIntermediate: return .progressSolidIntermediate
        case .advanced: return .progressAdvanced
        case .athleteTier: return .progressAthleteTier
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .dormant: return "No recent activity"
        case .beginnerSpark: return "Just getting started"
        case .gettingTraction: return "Building consistency"
        case .solidIntermediate: return "Regular training established"
        case .advanced: return "Advanced training level"
        case .athleteTier: return "Elite athlete level"
        }
    }

    var colorBlindDescription: String {
        switch self {
        case .dormant: return "Grey - Inactive"
        case .beginnerSpark: return "Amber - Beginner"
        case .gettingTraction: return "Green - Building"
        case .solidIntermediate: return "Blue - Consistent"
        case .advanced: return "Indigo - Advanced"
        case .athleteTier: return "Purple - Elite"
        }
    }

    var description: String {
        switch self {
        case .dormant: return "No recent activity"
        case .beginnerSpark: return "Just getting started"
        case .gettingTraction: return "Building consistency"
        case .solidIntermediate: return "Strong foundation"
        case .advanced: return "Impressive progress"
        case .athleteTier: return "Elite performance"
        }
    }
}

// MARK: - Smooth body artwork

/// White figure with a clear surround and a smooth, even outline.
/// The backdrop is whatever near-white is connected to the image edge, so the card surface shows through.
@MainActor
private enum BodyMapArtwork {
    struct Images {
        let fill: UIImage
        let stroke: UIImage
    }

    private struct VertexKey: Hashable {
        let x: Int
        let y: Int
    }

    private static var cache: [String: Images] = [:]

    static func rendered(baseName: String) -> Images? {
        if let cached = cache[baseName] { return cached }
        guard let images = make(baseName: baseName) else { return nil }
        cache[baseName] = images
        return images
    }

    private static func make(baseName: String) -> Images? {
        guard let source = UIImage(named: baseName)?.cgImage else { return nil }
        let width = source.width
        let height = source.height
        guard width > 2, height > 2 else { return nil }
        guard let interior = interiorMask(from: source, width: width, height: height) else { return nil }

        let field = gaussianBlur(interior, width: width, height: height, sigma: 0.95)
        let loops = marchingSquares(field, width: width, height: height, level: 0.5)
            .filter { $0.count >= 12 && abs(signedArea($0)) > 50 }
            .map { chaikin(rdpClosed($0, epsilon: 0.9), iterations: 2) }
            .filter { $0.count >= 6 && abs(signedArea($0)) > 50 }
        guard !loops.isEmpty else { return nil }

        let path = CGMutablePath()
        for loop in loops {
            guard let first = loop.first else { continue }
            path.move(to: CGPoint(x: first.x + 0.5, y: first.y + 0.5))
            for point in loop.dropFirst() {
                path.addLine(to: CGPoint(x: point.x + 0.5, y: point.y + 0.5))
            }
            path.closeSubpath()
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
        let ink = UIColor(red: 28.0 / 255.0, green: 30.0 / 255.0, blue: 34.0 / 255.0, alpha: 1)

        let fill = renderer.image { context in
            let ctx = context.cgContext
            ctx.setAllowsAntialiasing(true)
            ctx.setShouldAntialias(true)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.addPath(path)
            ctx.fillPath(using: .evenOdd)
        }

        // Stroke is clipped to the figure so the whole line sits on the white interior.
        let stroke = renderer.image { context in
            let ctx = context.cgContext
            ctx.setAllowsAntialiasing(true)
            ctx.setShouldAntialias(true)
            ctx.addPath(path)
            ctx.clip(using: .evenOdd)
            ctx.setStrokeColor(ink.cgColor)
            ctx.setLineWidth(5.6)
            ctx.setLineJoin(.round)
            ctx.setLineCap(.round)
            ctx.addPath(path)
            ctx.strokePath()
        }

        return Images(fill: fill, stroke: stroke)
    }

    private static func interiorMask(from source: CGImage, width: Int, height: Int) -> [Float]? {
        let count = width * height
        var bytes = [UInt8](repeating: 0, count: count * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let drew = bytes.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { return nil }

        func isBackdrop(_ index: Int) -> Bool {
            let offset = index * 4
            return bytes[offset] >= 245 && bytes[offset + 1] >= 245 && bytes[offset + 2] >= 245
        }

        var exterior = [Bool](repeating: false, count: count)
        var queue = [Int]()
        queue.reserveCapacity(width * 2)

        func mark(_ index: Int) {
            guard exterior[index] == false, isBackdrop(index) else { return }
            exterior[index] = true
            queue.append(index)
        }

        for x in 0..<width {
            mark(x)
            mark((height - 1) * width + x)
        }
        if height > 2 {
            for y in 1..<(height - 1) {
                mark(y * width)
                mark(y * width + width - 1)
            }
        }

        var head = 0
        while head < queue.count {
            let index = queue[head]
            head += 1
            let x = index % width
            let y = index / width
            if x > 0 { mark(index - 1) }
            if x + 1 < width { mark(index + 1) }
            if y > 0 { mark(index - width) }
            if y + 1 < height { mark(index + width) }
        }

        var mask = [Float](repeating: 0, count: count)
        for index in 0..<count where exterior[index] == false {
            mask[index] = 1
        }
        return mask
    }

    private static func gaussianBlur(_ source: [Float], width: Int, height: Int, sigma: Float) -> [Float] {
        let radius = max(1, Int(ceil(sigma * 3)))
        var kernel = [Float](repeating: 0, count: radius * 2 + 1)
        var weight: Float = 0
        for offset in -radius...radius {
            let value = exp(-Float(offset * offset) / (2 * sigma * sigma))
            kernel[offset + radius] = value
            weight += value
        }
        for index in kernel.indices {
            kernel[index] /= weight
        }

        var horizontal = [Float](repeating: 0, count: width * height)
        var blurred = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                var sum: Float = 0
                for offset in -radius...radius {
                    let sampleX = min(width - 1, max(0, x + offset))
                    sum += source[y * width + sampleX] * kernel[offset + radius]
                }
                horizontal[y * width + x] = sum
            }
        }
        for y in 0..<height {
            for x in 0..<width {
                var sum: Float = 0
                for offset in -radius...radius {
                    let sampleY = min(height - 1, max(0, y + offset))
                    sum += horizontal[sampleY * width + x] * kernel[offset + radius]
                }
                blurred[y * width + x] = sum
            }
        }
        return blurred
    }

    private static func marchingSquares(_ field: [Float], width: Int, height: Int, level: Float) -> [[CGPoint]] {
        func lerp(_ ax: Float, _ ay: Float, _ bx: Float, _ by: Float, _ a: Float, _ b: Float) -> CGPoint {
            let t: Float
            if abs(b - a) < 0.0000001 {
                t = 0.5
            } else {
                t = min(1, max(0, (level - a) / (b - a)))
            }
            return CGPoint(
                x: CGFloat(ax + (bx - ax) * t),
                y: CGFloat(ay + (by - ay) * t)
            )
        }

        func key(_ point: CGPoint) -> VertexKey {
            VertexKey(x: Int((point.x * 10000).rounded()), y: Int((point.y * 10000).rounded()))
        }

        var segments: [(CGPoint, CGPoint)] = []
        segments.reserveCapacity(width)
        for y in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let tl = field[y * width + x]
                let tr = field[y * width + x + 1]
                let bl = field[(y + 1) * width + x]
                let br = field[(y + 1) * width + x + 1]
                var index = 0
                if tl >= level { index |= 1 }
                if tr >= level { index |= 2 }
                if br >= level { index |= 4 }
                if bl >= level { index |= 8 }
                if index == 0 || index == 15 { continue }

                let fx = Float(x)
                let fy = Float(y)
                let top = lerp(fx, fy, fx + 1, fy, tl, tr)
                let right = lerp(fx + 1, fy, fx + 1, fy + 1, tr, br)
                let bottom = lerp(fx, fy + 1, fx + 1, fy + 1, bl, br)
                let left = lerp(fx, fy, fx, fy + 1, tl, bl)
                let center = (tl + tr + bl + br) / 4

                switch index {
                case 1: segments.append((left, top))
                case 2: segments.append((top, right))
                case 3: segments.append((left, right))
                case 4: segments.append((right, bottom))
                case 5:
                    if center >= level {
                        segments.append((left, bottom))
                        segments.append((top, right))
                    } else {
                        segments.append((left, top))
                        segments.append((bottom, right))
                    }
                case 6: segments.append((top, bottom))
                case 7: segments.append((left, bottom))
                case 8: segments.append((bottom, left))
                case 9: segments.append((top, bottom))
                case 10:
                    if center >= level {
                        segments.append((left, top))
                        segments.append((bottom, right))
                    } else {
                        segments.append((left, bottom))
                        segments.append((top, right))
                    }
                case 11: segments.append((bottom, right))
                case 12: segments.append((right, left))
                case 13: segments.append((top, right))
                case 14: segments.append((left, top))
                default: break
                }
            }
        }

        var adjacency: [VertexKey: [Int]] = [:]
        for (index, segment) in segments.enumerated() {
            adjacency[key(segment.0), default: []].append(index)
            adjacency[key(segment.1), default: []].append(index)
        }

        var used = [Bool](repeating: false, count: segments.count)
        var loops: [[CGPoint]] = []
        for startIndex in segments.indices where used[startIndex] == false {
            used[startIndex] = true
            let start = segments[startIndex].0
            var loop = [start]
            var current = segments[startIndex].1
            let startKey = key(start)
            var guardCount = 0
            while guardCount <= segments.count {
                loop.append(current)
                let currentKey = key(current)
                if currentKey == startKey { break }
                guard let nextIndex = adjacency[currentKey]?.first(where: { used[$0] == false }) else { break }
                used[nextIndex] = true
                let next = segments[nextIndex]
                current = key(next.0) == currentKey ? next.1 : next.0
                guardCount += 1
            }
            if loop.count > 8, key(loop[0]) == key(loop[loop.count - 1]) {
                loop.removeLast()
                loops.append(loop)
            }
        }
        return loops
    }

    private static func signedArea(_ points: [CGPoint]) -> CGFloat {
        var sum: CGFloat = 0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            sum += a.x * b.y - b.x * a.y
        }
        return sum * 0.5
    }

    private static func rdpClosed(_ points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count >= 8 else { return points }
        var farIndex = 0
        var farDistance: CGFloat = -1
        let origin = points[0]
        for index in 1..<points.count {
            let distance = hypot(points[index].x - origin.x, points[index].y - origin.y)
            if distance > farDistance {
                farDistance = distance
                farIndex = index
            }
        }
        if farIndex < 2 || farIndex > points.count - 3 {
            farIndex = points.count / 2
        }
        let left = rdpOpen(Array(points[0...farIndex]), epsilon: epsilon)
        var rightPoints = Array(points[farIndex...])
        rightPoints.append(points[0])
        let right = rdpOpen(rightPoints, epsilon: epsilon)
        var result = left
        if !result.isEmpty { result.removeLast() }
        if !right.isEmpty { result.append(contentsOf: right.dropLast()) }
        return result
    }

    private static func rdpOpen(_ points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        let count = points.count
        guard count >= 3 else { return points }
        var keep = [Bool](repeating: false, count: count)
        keep[0] = true
        keep[count - 1] = true
        var stack = [(Int, Int)]()
        stack.append((0, count - 1))
        while let (start, end) = stack.popLast() {
            guard end > start + 1 else { continue }
            let a = points[start]
            let b = points[end]
            let abx = b.x - a.x
            let aby = b.y - a.y
            let length = hypot(abx, aby)
            var maxDistance: CGFloat = 0
            var maxIndex = -1
            for index in (start + 1)..<end {
                let distance: CGFloat
                if length < 0.0001 {
                    distance = hypot(points[index].x - a.x, points[index].y - a.y)
                } else {
                    distance = abs((points[index].x - a.x) * aby - (points[index].y - a.y) * abx) / length
                }
                if distance > maxDistance {
                    maxDistance = distance
                    maxIndex = index
                }
            }
            if maxIndex >= 0, maxDistance > epsilon {
                keep[maxIndex] = true
                stack.append((start, maxIndex))
                stack.append((maxIndex, end))
            }
        }
        return points.enumerated().compactMap { keep[$0.offset] ? $0.element : nil }
    }

    private static func chaikin(_ points: [CGPoint], iterations: Int) -> [CGPoint] {
        guard points.count >= 3 else { return points }
        var current = points
        for _ in 0..<iterations {
            var next: [CGPoint] = []
            next.reserveCapacity(current.count * 2)
            for index in current.indices {
                let a = current[index]
                let b = current[(index + 1) % current.count]
                next.append(CGPoint(x: 0.75 * a.x + 0.25 * b.x, y: 0.75 * a.y + 0.25 * b.y))
                next.append(CGPoint(x: 0.25 * a.x + 0.75 * b.x, y: 0.25 * a.y + 0.75 * b.y))
            }
            current = next
        }
        return current
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Body Map - Male")
            .font(.headline)
        BodyMapView(showTestColors: true)
            .frame(height: 280)
            .padding(.horizontal)

        Text("Body Map - Female")
            .font(.headline)
        BodyMapView(showTestColors: true, variant: .female)
            .frame(height: 280)
            .padding(.horizontal)
    }
    .padding()
}
