import SwiftUI

/// Design tokens for consistent typography usage throughout the Progress app
/// Provides semantic font styles that scale with Dynamic Type
public extension Font {
    
    // MARK: - Display Typography
    
    /// Extra large title - hero sections and main headers
    static let titleXL = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Large title - page titles and section headers
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Medium title - subsection headers
    static let titleMedium = Font.system(size: 22, weight: .semibold, design: .default)
    
    /// Small title - card headers and labels
    static let titleSmall = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body Typography
    
    /// Large body text - primary content
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Standard body text - default content
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Small body text - secondary content
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    // MARK: - Supporting Typography
    
    /// Caption text - hints and metadata
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Label text - buttons and form labels
    static let label = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Subheadline text - supporting headers
    static let subheadline = Font.system(size: 15, weight: .medium, design: .default)
    
    // MARK: - Specialized Typography
    
    /// Numbers and metrics - monospaced for alignment
    static let numberLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        .monospacedDigit()
    
    static let numberMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        .monospacedDigit()
    
    static let numberSmall = Font.system(size: 16, weight: .medium, design: .rounded)
        .monospacedDigit()
    
    /// Timer display - large, prominent numbers
    static let timerDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
        .monospacedDigit()
    
    /// Button text styles
    static let buttonPrimary = Font.system(size: 16, weight: .semibold, design: .default)
    static let buttonSecondary = Font.system(size: 14, weight: .medium, design: .default)
}

// MARK: - Text Style Extensions

public extension Text {
    /// Applies primary button styling
    func primaryButtonStyle() -> some View {
        self
            .font(.buttonPrimary)
            .foregroundColor(.white)
    }
    
    /// Applies secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .font(.buttonSecondary)
            .foregroundColor(.primary)
    }
    
    /// Applies number formatting for metrics
    func numberStyle(_ font: Font = .numberMedium) -> some View {
        self
            .font(font)
            .monospacedDigit()
            .foregroundColor(.textPrimary)
    }
    
    /// Applies timer display formatting
    func timerStyle() -> some View {
        self
            .font(.timerDisplay)
            .foregroundColor(.primary)
    }
    
    /// Applies error text styling
    func errorStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.error)
    }
    
    /// Applies success text styling
    func successStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.success)
    }
}

// MARK: - Button Style Extensions

public extension Button {
    /// Applies primary button styling
    func primaryButtonStyle() -> some View {
        self
            .font(.buttonPrimary)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    /// Applies secondary button styling  
    func secondaryButtonStyle() -> some View {
        self
            .font(.buttonSecondary)
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.primary, lineWidth: 1)
            )
    }
}

// MARK: - Layout Extensions

public extension View {
    /// Standard horizontal layout
    var horizontal: some View {
        HStack { self }
    }
    
    /// Standard vertical layout
    var vertical: some View {
        VStack { self }
    }
}

// MARK: - Typography Helpers

public struct ProgressTypography {
    /// Standard line height multiplier for body text
    public static let lineHeightMultiplier: CGFloat = 1.25
    
    /// Letter spacing values
    public static let letterSpacingTight: CGFloat = -0.5
    public static let letterSpacingNormal: CGFloat = 0
    public static let letterSpacingWide: CGFloat = 0.5
    
    /// Paragraph spacing values
    public static let paragraphSpacing: CGFloat = 16
}

// MARK: - Preview

#Preview("Typography Samples") {
    VStack(spacing: 16) {
        Text("Title XL - Hero Header")
            .font(.titleXL)
        
        Text("Title Large - Page Header")
            .font(.titleLarge)
        
        Text("Body Large - Primary content")
            .font(.bodyLarge)
        
        Text("Body - Standard content")
            .font(.body)
        
        Button("Primary Button") {}
            .primaryButtonStyle()
        
        Text("02:45")
            .timerStyle()
    }
    .padding()
            .background(Color.backgroundGradient)
}

 