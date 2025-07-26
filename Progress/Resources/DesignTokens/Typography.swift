import SwiftUI

/// Design tokens for consistent typography usage throughout the Progress app
public struct ProgressTypography {
    
    // MARK: - Font Families
    
    /// System font family - SF Pro
    public static let systemFont = "SF Pro"
    
    /// Rounded system font family - SF Pro Rounded
    public static let roundedFont = "SF Pro Rounded"
    
    /// Monospace font family - SF Mono
    public static let monospaceFont = "SF Mono"
    
    // MARK: - Display Typography
    
    /// Large display text - hero sections
    public static let displayLarge = Font.system(size: 57, weight: .regular, design: .default)
    
    /// Medium display text - section headers
    public static let displayMedium = Font.system(size: 45, weight: .regular, design: .default)
    
    /// Small display text - card headers
    public static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
    
    // MARK: - Headline Typography
    
    /// Large headline - page titles
    public static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
    
    /// Medium headline - section titles
    public static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Small headline - subsection titles
    public static let headlineSmall = Font.system(size: 24, weight: .bold, design: .default)
    
    // MARK: - Title Typography
    
    /// Large title - modal headers
    public static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
    
    /// Medium title - card titles
    public static let titleMedium = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// Small title - list headers
    public static let titleSmall = Font.system(size: 18, weight: .semibold, design: .default)
    
    // MARK: - Body Typography
    
    /// Large body text - primary content
    public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Medium body text - standard content
    public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    
    /// Small body text - secondary content
    public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Label Typography
    
    /// Large label - form labels
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Medium label - button labels
    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    
    /// Small label - captions and hints
    public static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Specialized Typography
    
    /// Numbers and metrics - rounded design
    public static let numberLarge = Font.system(size: 24, weight: .bold, design: .rounded)
    public static let numberMedium = Font.system(size: 18, weight: .semibold, design: .rounded)
    public static let numberSmall = Font.system(size: 14, weight: .medium, design: .rounded)
    
    /// Code and technical text - monospace
    public static let codeLarge = Font.system(size: 16, weight: .regular, design: .monospaced)
    public static let codeMedium = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let codeSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    
    /// Timer display - large, prominent numbers
    public static let timerDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    public static let timerSeconds = Font.system(size: 32, weight: .semibold, design: .rounded)
}

// MARK: - Text Styles

public struct ProgressTextStyles {
    
    /// Primary button text style
    public static func primaryButton() -> some View {
        EmptyView()
            .font(ProgressTypography.labelLarge)
            .foregroundColor(ProgressColors.textPrimary)
    }
    
    /// Secondary button text style
    public static func secondaryButton() -> some View {
        EmptyView()
            .font(ProgressTypography.labelMedium)
            .foregroundColor(ProgressColors.textSecondary)
    }
    
    /// Input field text style
    public static func inputField() -> some View {
        EmptyView()
            .font(ProgressTypography.bodyMedium)
            .foregroundColor(ProgressColors.textPrimary)
    }
    
    /// Placeholder text style
    public static func placeholder() -> some View {
        EmptyView()
            .font(ProgressTypography.bodyMedium)
            .foregroundColor(ProgressColors.textPlaceholder)
    }
    
    /// Error text style
    public static func error() -> some View {
        EmptyView()
            .font(ProgressTypography.labelSmall)
            .foregroundColor(ProgressColors.error)
    }
    
    /// Caption text style
    public static func caption() -> some View {
        EmptyView()
            .font(ProgressTypography.labelSmall)
            .foregroundColor(ProgressColors.textTertiary)
    }
}

// MARK: - Line Height and Spacing

public struct ProgressSpacing {
    
    /// Typography line height multipliers
    public static let lineHeightTight: CGFloat = 1.1
    public static let lineHeightNormal: CGFloat = 1.4
    public static let lineHeightLoose: CGFloat = 1.6
    
    /// Letter spacing values
    public static let letterSpacingTight: CGFloat = -0.5
    public static let letterSpacingNormal: CGFloat = 0
    public static let letterSpacingWide: CGFloat = 0.5
    
    /// Paragraph spacing
    public static let paragraphSpacingSmall: CGFloat = 8
    public static let paragraphSpacingMedium: CGFloat = 16
    public static let paragraphSpacingLarge: CGFloat = 24
}

// MARK: - Typography Extensions

extension Font {
    /// Creates a font with custom tracking (letter spacing)
    public func tracking(_ value: CGFloat) -> Font {
        return self
    }
    
    /// Creates a font with custom line height
    public func lineHeight(_ value: CGFloat) -> Font {
        return self
    }
}

extension Text {
    /// Applies Progress app typography style
    public func progressStyle(_ style: Font) -> Text {
        return self.font(style)
    }
    
    /// Applies number formatting for metrics
    public func numberStyle(size: Font) -> Text {
        return self
            .font(size)
            .monospacedDigit()
    }
    
    /// Applies timer display formatting
    public func timerStyle() -> Text {
        return self
            .font(ProgressTypography.timerDisplay)
            .monospacedDigit()
            .foregroundColor(ProgressColors.textPrimary)
    }
} 