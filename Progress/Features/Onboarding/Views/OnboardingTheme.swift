//
//  OnboardingTheme.swift
//  Progress
//
//  Shared visual language for the onboarding flow, based on the
//  "Progress — Onboarding Prototype" design: soft neutral background with
//  blue radial tints, ink pill buttons, chat-bubble questions, emoji option
//  rows, note pills and body-map silhouettes. Accents use the brand blue.
//

import SwiftUI

// MARK: - Palette

enum OnboardingPalette {

    /// Near-black ink used for headlines and primary buttons (inverts in dark mode).
    static let ink = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)   // #F2F3F7
            : UIColor(red: 0.07, green: 0.075, blue: 0.10, alpha: 1.0)  // #12131A
    })

    /// Text drawn on top of ink-filled surfaces (e.g. primary button labels).
    static let onInk = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.075, blue: 0.10, alpha: 1.0)
            : UIColor.white
    })

    /// Muted body copy (#7B7F8C).
    static let muted = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.63, blue: 0.69, alpha: 1.0)
            : UIColor(red: 0.48, green: 0.50, blue: 0.55, alpha: 1.0)
    })

    /// Page background (#EEF0F4).
    static let background = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.06, blue: 0.08, alpha: 1.0)
            : UIColor(red: 0.933, green: 0.941, blue: 0.957, alpha: 1.0)
    })

    /// White card surface (#FFFFFF).
    static let surface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0)
            : UIColor.white
    })

    /// Soft grey option-row / card fill (#F6F6F9).
    static let optionFill = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.125, blue: 0.16, alpha: 1.0)
            : UIColor(red: 0.965, green: 0.965, blue: 0.976, alpha: 1.0)
    })

    /// Soft blue tint for selected options and note pills (blue version of accent-soft).
    static let accentSoft = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.16, blue: 0.27, alpha: 1.0)
            : UIColor(red: 0.89, green: 0.925, blue: 0.98, alpha: 1.0)  // #E3ECFA
    })

    /// Hairline borders (#E7E8EE).
    static let line = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor(red: 0.906, green: 0.910, blue: 0.933, alpha: 1.0)
    })

    /// Lighter companion to the brand blue, used in ring/accent gradients.
    static let brandLight = Color(hex: "6E9BE6")

    /// Blue accent gradient (replaces the prototype's indigo→orange).
    static let accentGradient = LinearGradient(
        colors: [Color.brand, brandLight],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Background

/// Neutral background with soft blue radial tints in the top corners.
struct OnboardingBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            OnboardingPalette.background

            RadialGradient(
                colors: [
                    Color.brand.opacity(colorScheme == .dark ? 0.16 : 0.14),
                    Color.clear
                ],
                center: UnitPoint(x: 0.12, y: -0.05),
                startRadius: 0,
                endRadius: 480
            )

            RadialGradient(
                colors: [
                    OnboardingPalette.brandLight.opacity(colorScheme == .dark ? 0.10 : 0.16),
                    Color.clear
                ],
                center: UnitPoint(x: 0.95, y: 0.05),
                startRadius: 0,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Progress Bar & Dots

/// Slim rounded progress bar with a blue fill.
struct OnboardingProgressBar: View {
    let current: Int // 1-based
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(OnboardingPalette.line)

                Capsule()
                    .fill(OnboardingPalette.accentGradient)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(max(total, 1)))
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: current)
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current) of \(total)")
    }
}

/// Page dots for the feature carousel — active dot stretches into a pill.
struct OnboardingPageDots: View {
    let total: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == index ? OnboardingPalette.ink : OnboardingPalette.line)
                    .frame(width: i == index ? 16 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: index)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(index + 1) of \(total)")
    }
}

// MARK: - Buttons

/// Ink pill primary CTA, like the prototype's btn-primary.
struct OnboardingPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(OnboardingPalette.onInk)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(OnboardingPalette.ink)
                    .opacity(isEnabled ? 1 : 0.35)
            )
            .shadow(color: Color.black.opacity(isEnabled ? 0.28 : 0), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// White outlined pill secondary button.
struct OnboardingOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15.5, weight: .bold))
            .foregroundColor(OnboardingPalette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(OnboardingPalette.surface))
            .overlay(Capsule().strokeBorder(OnboardingPalette.line, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Circular soft-grey back button.
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(OnboardingPalette.ink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(OnboardingPalette.optionFill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Go back to previous step")
    }
}

// MARK: - Step Header

/// Bold headline + muted subhead, left-aligned by default like the prototype.
struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String
    var alignment: TextAlignment = .leading

    private var horizontalAlignment: HorizontalAlignment {
        alignment == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        alignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(OnboardingPalette.ink)
                .multilineTextAlignment(alignment)
                .lineSpacing(1)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(OnboardingPalette.muted)
                .multilineTextAlignment(alignment)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .padding(.horizontal, 24)
    }
}

// MARK: - Chat Bubble Question

/// Avatar ring + speech bubble, used to ask questionnaire questions.
struct OnboardingChatBubble: View {
    let question: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [Color.brand, OnboardingPalette.brandLight, Color.brand],
                            center: .center,
                            angle: .degrees(-90)
                        )
                    )
                    .frame(width: 38, height: 38)
                Circle()
                    .fill(OnboardingPalette.surface)
                    .frame(width: 24, height: 24)
            }
            .padding(.top, 2)
            .accessibilityHidden(true)

            Text(question)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(OnboardingPalette.ink)
                .lineSpacing(2)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 4,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                    .fill(OnboardingPalette.optionFill)
                )
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Option Row

/// Emoji + label + radio row with a blue-tinted selected state.
struct OnboardingOptionRow: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundColor(OnboardingPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(OnboardingPalette.muted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.brand : OnboardingPalette.line,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 12, height: 12)
                    }
                }
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? OnboardingPalette.accentSoft : OnboardingPalette.optionFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Note Pill

/// Soft blue informational pill, e.g. "💡 Reminders help people stay consistent".
struct OnboardingNotePill: View {
    let emoji: String
    let text: String
    var boldText: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji)
                .font(.system(size: 15))
                .accessibilityHidden(true)

            (boldTextView + Text(text))
                .font(.system(size: 13))
                .foregroundColor(OnboardingPalette.ink.opacity(0.75))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OnboardingPalette.accentSoft)
        )
    }

    private var boldTextView: Text {
        guard let boldText else { return Text("") }
        return Text(boldText).font(.system(size: 13, weight: .bold)).foregroundColor(OnboardingPalette.ink) + Text(" ")
    }
}

// MARK: - Body Silhouette

/// Decorative body-map silhouette used in onboarding marketing screens.
struct OnboardingSilhouette: View {
    var height: CGFloat = 210
    var lit: Bool = true
    var variant: BodyMapVariant = .male

    private static let maskedGroups: [MuscleGroup] = [
        .chest, .back, .shoulders, .arms, .core, .quads, .posteriorChain
    ]

    private static let demoColors: [MuscleGroup: Color] = [
        .chest: Color(hex: "FF6B6B").opacity(0.55),
        .back: Color(hex: "4ECDC4").opacity(0.4),
        .shoulders: Color(hex: "45B7D1").opacity(0.55),
        .arms: Color(hex: "96CEB4").opacity(0.45),
        .core: Color(hex: "FFEAA7").opacity(0.5),
        .quads: Color(hex: "DDA0DD").opacity(0.55),
        .posteriorChain: Color(hex: "F39C12").opacity(0.4)
    ]

    var body: some View {
        GeometryReader { geo in
            let size = fittedImageSize(in: geo.size)
            ZStack {
                Image(variant.baseImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(lit ? 0.85 : 0.45)

                if lit {
                    ForEach(Self.maskedGroups, id: \.self) { group in
                        Rectangle()
                            .fill(Self.demoColors[group] ?? Color.brand.opacity(0.4))
                            .mask(
                                Image(variant.maskImageName(for: group))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            )
                    }
                }

                Image(variant.linesImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(lit ? 1 : 0.7)
            }
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: height)
        .aspectRatio(variant.imageAspect, contentMode: .fit)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func fittedImageSize(in container: CGSize) -> CGSize {
        let containerAspect = container.width / max(container.height, 1)
        if containerAspect > variant.imageAspect {
            let h = container.height
            return CGSize(width: h * variant.imageAspect, height: h)
        } else {
            let w = container.width
            return CGSize(width: w, height: w / variant.imageAspect)
        }
    }
}

/// Compact silhouette thumbnail for cards and collage layouts.
struct OnboardingSilhouetteThumb: View {
    var size: CGFloat = 44

    var body: some View {
        Image("bodymap_base")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .opacity(0.7)
            .accessibilityHidden(true)
    }
}

// MARK: - Cards

/// Soft grey grouped card (prototype's `.card`, #F6F6F9, radius 24).
struct OnboardingGroupCard: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(OnboardingPalette.optionFill)
            )
    }
}

/// White floating card with hairline border and soft shadow.
struct OnboardingSurfaceCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(OnboardingPalette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 13, x: 0, y: 7)
    }
}

extension View {
    func onboardingGroupCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(OnboardingGroupCard(cornerRadius: cornerRadius))
    }

    func onboardingSurfaceCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(OnboardingSurfaceCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Horizontal Ruler Slider

/// Horizontal "tape measure" slider used for age, height and weight.
/// Drag left or right to change the value — the tick marks scroll under a
/// fixed centre indicator with haptic feedback on every step.
struct OnboardingRulerSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var majorTickInterval: Double = 5
    var labelInterval: Double = 10
    var label: (Double) -> String = { "\(Int($0))" }

    @State private var dragStartValue: Double?

    private let tickSpacing: CGFloat = 9

    var body: some View {
        ZStack {
            Canvas { context, size in
                drawTicks(in: context, size: size)
            }

            // Fixed centre indicator
            Capsule()
                .fill(Color.brand)
                .frame(width: 4, height: 40)
                .frame(maxHeight: .infinity, alignment: .top)
                .shadow(color: Color.brand.opacity(0.35), radius: 4, x: 0, y: 2)
        }
        .frame(height: 64)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .mask(edgeFade)
        .accessibilityElement()
        .accessibilityValue(label(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if dragStartValue == nil {
                    dragStartValue = value
                }
                let start = dragStartValue ?? value
                let rawValue = start - Double(gesture.translation.width / tickSpacing) * step
                let snapped = (rawValue / step).rounded() * step
                let clamped = min(max(snapped, range.lowerBound), range.upperBound)
                if clamped != value {
                    value = clamped
                    HapticFeedback.selectionChanged()
                }
            }
            .onEnded { _ in
                dragStartValue = nil
            }
    }

    private func drawTicks(in context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let totalTicks = Int(((range.upperBound - range.lowerBound) / step).rounded())
        let currentSteps = (value - range.lowerBound) / step
        let visibleHalf = Int(size.width / (2 * tickSpacing)) + 1
        let firstIndex = max(0, Int(currentSteps.rounded()) - visibleHalf)
        let lastIndex = min(totalTicks, Int(currentSteps.rounded()) + visibleHalf)
        guard firstIndex <= lastIndex else { return }

        for index in firstIndex...lastIndex {
            let tickValue = range.lowerBound + Double(index) * step
            let x = centerX + CGFloat(Double(index) - currentSteps) * tickSpacing
            let isMajor = isMultiple(tickValue, of: majorTickInterval)

            var path = Path()
            path.move(to: CGPoint(x: x, y: isMajor ? 6 : 13))
            path.addLine(to: CGPoint(x: x, y: isMajor ? 36 : 29))
            context.stroke(
                path,
                with: .color(isMajor ? OnboardingPalette.muted : OnboardingPalette.line),
                style: StrokeStyle(lineWidth: isMajor ? 2 : 1.5, lineCap: .round)
            )

            if isMultiple(tickValue, of: labelInterval) {
                context.draw(
                    Text(label(tickValue))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(OnboardingPalette.muted),
                    at: CGPoint(x: x, y: 52)
                )
            }
        }
    }

    private func isMultiple(_ value: Double, of interval: Double) -> Bool {
        guard interval > 0 else { return false }
        let ratio = value / interval
        return abs(ratio - ratio.rounded()) < 0.001
    }

    private var edgeFade: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.1),
                .init(color: .black, location: 0.9),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Stat Chip

/// Small floating white chip with a bold value over a muted label.
struct OnboardingStatChip: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(OnboardingPalette.ink)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(OnboardingPalette.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OnboardingPalette.surface)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 9, x: 0, y: 5)
    }
}

// MARK: - Workout Row (feature mock)

/// Mock workout row used on the feature carousel: emoji tile, name, detail, checkmark.
struct OnboardingWorkoutRow: View {
    let emoji: String
    let title: String
    let detail: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(OnboardingPalette.accentSoft)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(OnboardingPalette.ink)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(OnboardingPalette.muted)
            }

            Spacer()

            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.green)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.green.opacity(0.15)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OnboardingPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(OnboardingPalette.line, lineWidth: 1)
        )
    }
}

// MARK: - Momentum Chart

/// "Long game" comparison chart: a steady blue Progress curve versus a
/// dashed quick-fixes curve that spikes early and fades.
struct OnboardingMomentumChart: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                Text("Momentum")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(OnboardingPalette.muted)

                Text("Time")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(OnboardingPalette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                // Quick fixes: spikes early, then declines
                Path { p in
                    p.move(to: CGPoint(x: 0.03 * w, y: 0.63 * h))
                    p.addCurve(
                        to: CGPoint(x: 0.26 * w, y: 0.15 * h),
                        control1: CGPoint(x: 0.12 * w, y: 0.30 * h),
                        control2: CGPoint(x: 0.18 * w, y: 0.10 * h)
                    )
                    p.addCurve(
                        to: CGPoint(x: 0.48 * w, y: 0.53 * h),
                        control1: CGPoint(x: 0.36 * w, y: 0.20 * h),
                        control2: CGPoint(x: 0.41 * w, y: 0.37 * h)
                    )
                    p.addCurve(
                        to: CGPoint(x: 0.96 * w, y: 0.90 * h),
                        control1: CGPoint(x: 0.58 * w, y: 0.74 * h),
                        control2: CGPoint(x: 0.73 * w, y: 0.86 * h)
                    )
                }
                .stroke(
                    OnboardingPalette.muted.opacity(0.55),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 6])
                )

                // Progress: steady compounding rise
                Path { p in
                    p.move(to: CGPoint(x: 0.03 * w, y: 0.70 * h))
                    p.addCurve(
                        to: CGPoint(x: 0.45 * w, y: 0.45 * h),
                        control1: CGPoint(x: 0.18 * w, y: 0.67 * h),
                        control2: CGPoint(x: 0.32 * w, y: 0.58 * h)
                    )
                    p.addCurve(
                        to: CGPoint(x: 0.96 * w, y: 0.10 * h),
                        control1: CGPoint(x: 0.58 * w, y: 0.32 * h),
                        control2: CGPoint(x: 0.73 * w, y: 0.17 * h)
                    )
                }
                .stroke(Color.brand, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

                // End dots
                Circle()
                    .fill(Color.brand)
                    .frame(width: 10, height: 10)
                    .position(x: 0.96 * w, y: 0.10 * h)
                Circle()
                    .fill(OnboardingPalette.muted.opacity(0.7))
                    .frame(width: 10, height: 10)
                    .position(x: 0.96 * w, y: 0.90 * h)

                // Curve labels
                Text("Progress")
                    .font(.system(size: 10.5, weight: .heavy))
                    .foregroundColor(Color.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(OnboardingPalette.accentSoft))
                    .position(x: 0.75 * w, y: 0.07 * h)

                Text("Random workouts")
                    .font(.system(size: 10.5, weight: .heavy))
                    .foregroundColor(OnboardingPalette.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(OnboardingPalette.optionFill))
                    .position(x: 0.70 * w, y: 0.80 * h)
            }
        }
    }
}

// MARK: - Testimonial Card

/// Quote card with an avatar initial, name and stat line.
struct OnboardingTestimonialCard: View {
    let initial: String
    let name: String
    let stat: String
    let quote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(initial)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.brand))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14.5, weight: .heavy))
                        .foregroundColor(OnboardingPalette.ink)
                    Text(stat)
                        .font(.system(size: 12))
                        .foregroundColor(OnboardingPalette.muted)
                }
            }

            Text("\u{201C}\(quote)\u{201D}")
                .font(.system(size: 13.5))
                .foregroundColor(OnboardingPalette.ink.opacity(0.8))
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onboardingGroupCard(cornerRadius: 22)
    }
}

// MARK: - Preview

#Preview("Onboarding Theme") {
    ZStack {
        OnboardingBackground()

        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    OnboardingBackButton(action: {})
                    OnboardingProgressBar(current: 2, total: 5)
                }
                .padding(.horizontal, 24)

                OnboardingChatBubble(question: "What's your main goal?")
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    OnboardingOptionRow(emoji: "🔥", title: "Lose weight", isSelected: true, onTap: {})
                    OnboardingOptionRow(emoji: "💪", title: "Build muscle", subtitle: "Add size and definition", isSelected: false, onTap: {})
                }
                .padding(.horizontal, 24)

                OnboardingNotePill(
                    emoji: "💡",
                    text: "is the only app where your plan and your own logs live side by side.",
                    boldText: "Progress"
                )
                .padding(.horizontal, 24)

                OnboardingSilhouette(height: 170)

                Button("Get Started") {}
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                    .padding(.horizontal, 24)

                Button("I already have an account") {}
                    .buttonStyle(OnboardingOutlineButtonStyle())
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 30)
        }
    }
}
