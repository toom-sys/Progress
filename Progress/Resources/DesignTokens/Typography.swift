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

#Preview("Progress Typography") {
    ScrollView {
        VStack(spacing: 32) {
            // Title Styles Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Title Styles")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    TypographySample(
                        text: "Title XL - Hero Header",
                        font: .titleXL,
                        description: "34pt Bold"
                    )
                    
                    TypographySample(
                        text: "Title Large - Page Header",
                        font: .titleLarge,
                        description: "28pt Bold"
                    )
                    
                    TypographySample(
                        text: "Title Medium - Section Header",
                        font: .titleMedium,
                        description: "22pt Semibold"
                    )
                    
                    TypographySample(
                        text: "Title Small - Card Header",
                        font: .titleSmall,
                        description: "20pt Semibold"
                    )
                }
            }
            
            // Body Styles Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Body Styles")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    TypographySample(
                        text: "Body Large - Primary content for important information",
                        font: .bodyLarge,
                        description: "17pt Regular"
                    )
                    
                    TypographySample(
                        text: "Body - Standard content for most text in the app",
                        font: .body,
                        description: "16pt Regular"
                    )
                    
                    TypographySample(
                        text: "Body Small - Secondary content and supporting text",
                        font: .bodySmall,
                        description: "14pt Regular"
                    )
                }
            }
            
            // Supporting Styles Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Supporting Styles")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    TypographySample(
                        text: "Subheadline - Supporting headers",
                        font: .subheadline,
                        description: "15pt Medium"
                    )
                    
                    TypographySample(
                        text: "Label - Buttons and form labels",
                        font: .label,
                        description: "14pt Medium"
                    )
                    
                    TypographySample(
                        text: "Caption - Hints and metadata",
                        font: .caption,
                        description: "12pt Regular"
                    )
                }
            }
            
            // Number Styles Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Number Styles")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    TypographySample(
                        text: "12:34",
                        font: .timerDisplay,
                        description: "Timer Display - 48pt Bold Rounded"
                    )
                    
                    TypographySample(
                        text: "1,234",
                        font: .numberLarge,
                        description: "Number Large - 32pt Bold Rounded"
                    )
                    
                    TypographySample(
                        text: "567",
                        font: .numberMedium,
                        description: "Number Medium - 20pt Semibold Rounded"
                    )
                    
                    TypographySample(
                        text: "89",
                        font: .numberSmall,
                        description: "Number Small - 16pt Medium Rounded"
                    )
                }
            }
            
            // Interactive Examples Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Interactive Examples")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 16) {
                    // Button Examples
                    HStack(spacing: 16) {
                        Button("Primary Button") {}
                            .primaryButtonStyle()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Secondary Button") {}
                            .secondaryButtonStyle()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.primary, lineWidth: 1)
                            )
                    }
                    
                    // Status Examples
                    HStack(spacing: 20) {
                        Text("Success message")
                            .successStyle()
                        
                        Text("Error message")
                            .errorStyle()
                    }
                    
                    // Timer Example
                    Text("02:45")
                        .timerStyle()
                        .padding(20)
                        .background(.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Usage Sample Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample Workout Card")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Push Day")
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                    
                    Text("Upper body workout focusing on pushing movements")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                    
                    HStack {
                        Label("45 min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                        
                        Spacer()
                        
                        Text("1,250")
                            .numberStyle(.numberSmall)
                        
                        Text("calories")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                }
                .padding(16)
                .background(.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.border, lineWidth: 1)
                )
            }
        }
        .padding(20)
    }
    .background(.background)
}

// MARK: - Helper Views

private struct TypographySample: View {
    let text: String
    let font: Font
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(font)
                .foregroundColor(.textPrimary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
} 