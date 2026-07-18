//
//  BodyMapView.swift
//  Progress
//
//  Created by Progress Team
//

import SwiftUI

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

            ZStack {
                Color.white

                maskedMuscleLayers(in: renderedSize)

                Image(variant.linesImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: renderedSize.width, height: renderedSize.height)
                    .allowsHitTesting(false)

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
        let opacity = muscleGroupOpacity[muscleGroup] ?? 0.3
        let animationValue = animationValues[muscleGroup] ?? 1.0
        let pulseValue = pulseAnimations[muscleGroup] ?? false
        let glowValue = glowAnimations[muscleGroup] ?? false

        var baseColor = tier.color
        var finalOpacity = opacity

        if animationValue != 1.0 {
            finalOpacity *= animationValue
        }
        if pulseValue {
            finalOpacity = min(1.0, finalOpacity * 1.4)
        }
        if glowValue {
            finalOpacity = min(1.0, finalOpacity * 1.2)
            baseColor = baseColor.opacity(0.9)
        }
        if tier == .advanced || tier == .athleteTier {
            finalOpacity = min(1.0, finalOpacity * 1.1)
        }

        return baseColor.opacity(finalOpacity)
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
        case .beginnerSpark: return "White - Beginner"
        case .gettingTraction: return "Light - Building"
        case .solidIntermediate: return "Medium - Consistent"
        case .advanced: return "Dark - Advanced"
        case .athleteTier: return "Bright - Elite"
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
