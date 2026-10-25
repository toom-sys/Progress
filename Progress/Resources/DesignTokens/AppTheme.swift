//
//  AppTheme.swift
//  Progress
//
//  Shared visual language for the main tabs, adopted from onboarding.
//  Tokens and components only — screens keep their current look until they opt in.
//

import SwiftUI

// MARK: - Aliases

typealias AppPalette = OnboardingPalette
typealias AppBackground = OnboardingBackground

// MARK: - Palette

extension OnboardingPalette {

    static let protein = Color(hex: "FF6B6B")
    static let carbs = Color(hex: "F39C12")
    static let fat = Color(hex: "45B7D1")

    /// "In progress" green.
    static let live = Color(hex: "34C759")

    /// Label colour on a live tint. Light #1C6B33, dark #7EE29A.
    static let liveText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 126.0 / 255.0, green: 226.0 / 255.0, blue: 154.0 / 255.0, alpha: 1.0)
            : UIColor(red: 28.0 / 255.0, green: 107.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
    })

    /// Soft tile or chip fill. Stays legible in dark mode.
    static func tint(_ hue: Color) -> Color {
        hue.opacity(0.14)
    }
}

// MARK: - Typography

extension Font {
    /// Screen title. Apply `.tracking(-0.5)` at the call site.
    static let appScreenTitle = Font.system(size: 34, weight: .heavy, design: .rounded)

    static let appSectionTitle = Font.system(size: 22, weight: .heavy, design: .rounded)

    static let appCardTitle = Font.system(size: 16, weight: .heavy)

    /// Big metric. Apply `.monospacedDigit()` at the call site.
    static let appBigNumber = Font.system(size: 32, weight: .heavy, design: .rounded)

    /// Eyebrow label. Apply `.tracking(1)` and uppercase at the call site.
    static let appEyebrow = Font.system(size: 11, weight: .heavy)

    /// Secondary line. Colour with `AppPalette.muted`.
    static let appSubtitle = Font.system(size: 13, weight: .semibold)
}

// MARK: - Cards

extension View {

    func appCard(cornerRadius: CGFloat = 22, padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppPalette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }

    func appGroupRow(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppPalette.optionFill)
            )
    }

    /// Small surface chip that floats over content.
    func appFloatingChip() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppPalette.surface)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Emoji Tile

struct EmojiTile: View {
    let emoji: String
    var size: CGFloat = 46
    var background: Color = AppPalette.accentSoft

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.52))
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(background)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Circle Icon Button

struct CircleIconButton: View {
    enum Style {
        case plain
        case ink
    }

    let systemName: String
    var style: Style = .plain
    var size: CGFloat = 40
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(style == .ink ? AppPalette.onInk : AppPalette.ink)
                .frame(width: size, height: size)
                .background(backgroundCircle)
                .modifier(InkCircleShadow(isEnabled: style == .ink))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var backgroundCircle: some View {
        switch style {
        case .plain:
            Circle()
                .fill(AppPalette.surface)
                .overlay(Circle().strokeBorder(AppPalette.line, lineWidth: 1))
        case .ink:
            Circle()
                .fill(AppPalette.ink)
        }
    }
}

/// Shadow for ink circles only. A clear shadow on the plain style would still be a modifier, so the two styles stay one view type.
private struct InkCircleShadow: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content.shadow(
            color: isEnabled ? Color.black.opacity(0.22) : .clear,
            radius: isEnabled ? 8 : 0,
            x: 0,
            y: isEnabled ? 6 : 0
        )
    }
}

// MARK: - Chevron Toggle

struct ChevronToggleButton: View {
    let isExpanded: Bool
    var size: CGFloat = 30
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.down")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(AppPalette.ink)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .frame(width: size, height: size)
                .background(Circle().fill(AppPalette.optionFill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }
}

// MARK: - Progress Bar

struct AppProgressBar: View {
    let progress: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppPalette.line)

                Capsule()
                    .fill(AppPalette.accentGradient)
                    .frame(width: geo.size.width * clampedProgress)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: clampedProgress)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(percentComplete) percent")
    }

    private var clampedProgress: CGFloat {
        guard progress.isFinite else { return 0 }
        return CGFloat(min(max(progress, 0), 1))
    }

    private var percentComplete: Int {
        Int((Double(clampedProgress) * 100).rounded())
    }
}

// MARK: - Pill Button

struct AppPillButtonStyle: ButtonStyle {
    enum Kind {
        case ink
        case outline
        case inverse
    }

    enum Size {
        case large
        case compact
    }

    var kind: Kind
    var size: Size

    init(_ kind: Kind, _ size: Size) {
        self.kind = kind
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        styled(configuration.label, isPressed: configuration.isPressed)
    }

    private func styled(_ label: Configuration.Label, isPressed: Bool) -> some View {
        framed(label.font(labelFont).foregroundColor(labelColor))
            .background(backgroundShape)
            .compositingGroup()
            .shadow(
                color: kind == .ink ? Color.black.opacity(0.25) : .clear,
                radius: kind == .ink ? 9 : 0,
                x: 0,
                y: kind == .ink ? 6 : 0
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    @ViewBuilder
    private func framed(_ label: some View) -> some View {
        if size == .large {
            label
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        } else {
            label
                .padding(.horizontal, 16)
                .frame(height: 38)
        }
    }

    private var labelFont: Font {
        switch size {
        case .large:
            .system(size: 16, weight: .bold)
        case .compact:
            .system(size: 14, weight: .bold)
        }
    }

    private var labelColor: Color {
        switch kind {
        case .ink:
            AppPalette.onInk
        case .outline, .inverse:
            AppPalette.ink
        }
    }

    private var fillColor: Color {
        switch kind {
        case .ink:
            AppPalette.ink
        case .outline:
            AppPalette.surface
        case .inverse:
            AppPalette.onInk
        }
    }

    private var backgroundShape: some View {
        Capsule()
            .fill(fillColor)
            .overlay {
                if kind == .outline {
                    Capsule().strokeBorder(AppPalette.line, lineWidth: 1.5)
                }
            }
    }
}

// MARK: - Session Dots

/// Five-session block indicator. `current` is the 1-based session index:
/// dots `1...current` are filled, and the last dot is the deload session.
struct SessionDots: View {
    let current: Int
    var total: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            if total >= 1 {
                ForEach(1...total, id: \.self) { index in
                    SessionDot(
                        isFilled: index <= current,
                        isDeload: index == total
                    )
                    .accessibilityLabel(dotAccessibilityLabel(for: index))
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Same per-dot labels as `PlanSessionDotStrip` in TrainingPlanCard.
    private func dotAccessibilityLabel(for index: Int) -> String {
        let phase = ProgressionEngine.phase(forSessionIndex: index).displayName
        if index <= current {
            return "Session \(index), \(phase), completed or current"
        }
        return "Session \(index), \(phase), upcoming"
    }
}

private struct SessionDot: View {
    let isFilled: Bool
    let isDeload: Bool

    var body: some View {
        Circle()
            .fill(fillColor)
            .overlay {
                if showsStroke {
                    Circle().strokeBorder(strokeColor, lineWidth: 1.5)
                }
            }
            .frame(width: 8, height: 8)
    }

    private var showsStroke: Bool {
        isDeload || !isFilled
    }

    private var fillColor: Color {
        guard isFilled else { return .clear }
        return isDeload ? .orange : .brand
    }

    private var strokeColor: Color {
        isDeload ? .orange : Color.brand.opacity(0.45)
    }
}

// MARK: - Previews

private extension View {
    func themePreview(_ scheme: ColorScheme) -> some View {
        ScrollView {
            self
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppBackground())
        .preferredColorScheme(scheme)
    }
}

#Preview("Cards — Light") {
    CardsPreview().themePreview(.light)
}

#Preview("Cards — Dark") {
    CardsPreview().themePreview(.dark)
}

#Preview("Emoji Tile — Light") {
    EmojiTilePreview().themePreview(.light)
}

#Preview("Emoji Tile — Dark") {
    EmojiTilePreview().themePreview(.dark)
}

#Preview("Circle Icon Button — Light") {
    CircleIconButtonPreview().themePreview(.light)
}

#Preview("Circle Icon Button — Dark") {
    CircleIconButtonPreview().themePreview(.dark)
}

#Preview("Chevron Toggle — Light") {
    ChevronTogglePreview().themePreview(.light)
}

#Preview("Chevron Toggle — Dark") {
    ChevronTogglePreview().themePreview(.dark)
}

#Preview("Progress Bar — Light") {
    ProgressBarPreview().themePreview(.light)
}

#Preview("Progress Bar — Dark") {
    ProgressBarPreview().themePreview(.dark)
}

#Preview("Pill Button — Light") {
    PillButtonPreview().themePreview(.light)
}

#Preview("Pill Button — Dark") {
    PillButtonPreview().themePreview(.dark)
}

#Preview("Session Dots — Light") {
    SessionDotsPreview().themePreview(.light)
}

#Preview("Session Dots — Dark") {
    SessionDotsPreview().themePreview(.dark)
}

private struct CardsPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Workouts")
                .font(.appScreenTitle)
                .tracking(-0.5)
                .foregroundColor(AppPalette.ink)

            VStack(alignment: .leading, spacing: 8) {
                Text("Your plan")
                    .font(.appEyebrow)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(AppPalette.muted)
                Text("Upper / Lower")
                    .font(.appSectionTitle)
                    .foregroundColor(AppPalette.ink)
                Text("Card subtitle")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
                Text("12")
                    .font(.appBigNumber)
                    .monospacedDigit()
                    .foregroundColor(AppPalette.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(cornerRadius: 26, padding: 18)

            HStack {
                Text("Group row")
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                Spacer()
            }
            .appGroupRow()

            Text("Floating chip")
                .font(.appCardTitle)
                .foregroundColor(AppPalette.ink)
                .appFloatingChip()

            HStack(spacing: 8) {
                Text("In progress")
                    .font(.appEyebrow)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(AppPalette.liveText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppPalette.tint(AppPalette.live)))

            HStack(spacing: 10) {
                PaletteSwatch(color: AppPalette.protein, name: "Protein")
                PaletteSwatch(color: AppPalette.carbs, name: "Carbs")
                PaletteSwatch(color: AppPalette.fat, name: "Fat")
                PaletteSwatch(color: AppPalette.live, name: "Live")
                PaletteSwatch(color: AppPalette.liveText, name: "Live text")
            }
        }
    }
}

private struct PaletteSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppPalette.line, lineWidth: 1)
                )
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppPalette.muted)
        }
    }
}

private struct EmojiTilePreview: View {
    var body: some View {
        HStack(spacing: 12) {
            EmojiTile(emoji: "💪")
            EmojiTile(emoji: "🥩", background: AppPalette.tint(AppPalette.protein))
            EmojiTile(emoji: "🍞", background: AppPalette.tint(AppPalette.carbs))
            EmojiTile(emoji: "🥑", background: AppPalette.tint(AppPalette.fat))
            EmojiTile(emoji: "🍽️", size: 56, background: AppPalette.tint(.green))
        }
    }
}

private struct CircleIconButtonPreview: View {
    var body: some View {
        HStack(spacing: 12) {
            CircleIconButton(
                systemName: "chart.line.uptrend.xyaxis",
                accessibilityLabel: "Progress history",
                action: {}
            )
            CircleIconButton(
                systemName: "arrow.up.arrow.down",
                accessibilityLabel: "Sort workouts",
                action: {}
            )
            CircleIconButton(
                systemName: "plus",
                style: .ink,
                accessibilityLabel: "New workout",
                action: {}
            )
            CircleIconButton(
                systemName: "gearshape",
                size: 38,
                accessibilityLabel: "Settings",
                action: {}
            )
        }
    }
}

private struct ChevronTogglePreview: View {
    @State private var isExpanded = true

    var body: some View {
        HStack(spacing: 12) {
            ChevronToggleButton(
                isExpanded: isExpanded,
                size: 34,
                accessibilityLabel: isExpanded ? "Collapse plan" : "Expand plan"
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            }
            Text(isExpanded ? "Expanded" : "Collapsed")
                .font(.appCardTitle)
                .foregroundColor(AppPalette.ink)
        }
    }
}

private struct ProgressBarPreview: View {
    @State private var progress = 1.0 / 15.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppProgressBar(progress: progress)
            Text("\(Int((progress * 15).rounded())) of 15 sessions done")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
            HStack(spacing: 8) {
                Button("1 of 15") { progress = 1.0 / 15.0 }
                    .buttonStyle(AppPillButtonStyle(.outline, .compact))
                Button("Half") { progress = 0.5 }
                    .buttonStyle(AppPillButtonStyle(.outline, .compact))
                Button("Full") { progress = 1 }
                    .buttonStyle(AppPillButtonStyle(.outline, .compact))
            }
        }
    }
}

private struct PillButtonPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
            } label: {
                HStack(spacing: 8) {
                    Text("Start workout")
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(AppPillButtonStyle(.ink, .large))

            Button("Outline") {}
                .buttonStyle(AppPillButtonStyle(.outline, .large))

            VStack(spacing: 10) {
                Button {
                } label: {
                    HStack(spacing: 8) {
                        Text("Resume workout")
                        Image(systemName: "arrow.right")
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(AppPillButtonStyle(.inverse, .large))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppPalette.ink)
            )

            HStack(spacing: 8) {
                Button("Start") {}
                    .buttonStyle(AppPillButtonStyle(.outline, .compact))
                Button("Resume") {}
                    .buttonStyle(AppPillButtonStyle(.ink, .compact))
            }
        }
    }
}

private struct SessionDotsPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sessionRow(current: 1)
            sessionRow(current: 2)
            sessionRow(current: 5)
        }
    }

    private func sessionRow(current: Int) -> some View {
        HStack(spacing: 8) {
            Text("Session \(current) of 5")
                .font(.appSubtitle)
                .foregroundColor(AppPalette.muted)
            SessionDots(current: current)
        }
    }
}
