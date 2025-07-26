import SwiftUI

/// Design tokens for consistent color usage throughout the Progress app
/// Provides semantic colors that adapt to light/dark mode automatically
public extension Color {
    
    // MARK: - Primary Colors
    
    /// Primary brand color - used for main actions and branding
    static let primary = Color(
        light: Color(red: 0.0, green: 0.48, blue: 1.0),     // #007AFF (iOS Blue)
        dark: Color(red: 0.04, green: 0.52, blue: 1.0)      // #0A84FF (iOS Blue Dark)
    )
    
    /// Secondary accent color for highlights and emphasis
    static let accent = Color(
        light: Color(red: 0.2, green: 0.78, blue: 0.35),    // #32C759 (iOS Green)
        dark: Color(red: 0.19, green: 0.82, blue: 0.35)     // #30D158 (iOS Green Dark)
    )
    
    // MARK: - Background Colors
    
    /// Primary background color - main app background
    static let background = Color(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),      // #FFFFFF (White)
        dark: Color(red: 0.0, green: 0.0, blue: 0.0)        // #000000 (Black)
    )
    
    /// Secondary background color - cards and elevated surfaces
    static let backgroundSecondary = Color(
        light: Color(red: 0.95, green: 0.95, blue: 0.97),   // #F2F2F7 (iOS Gray 6)
        dark: Color(red: 0.11, green: 0.11, blue: 0.12)     // #1C1C1E (iOS Gray 6 Dark)
    )
    
    /// Tertiary background color - input fields and inactive states
    static let backgroundTertiary = Color(
        light: Color(red: 0.98, green: 0.98, blue: 0.98),   // #FAFAFA (iOS Gray 7)
        dark: Color(red: 0.17, green: 0.17, blue: 0.18)     // #2C2C2E (iOS Gray 5 Dark)
    )
    
    // MARK: - Text Colors
    
    /// Primary text color - main content
    static let textPrimary = Color(
        light: Color(red: 0.0, green: 0.0, blue: 0.0),      // #000000 (Black)
        dark: Color(red: 1.0, green: 1.0, blue: 1.0)        // #FFFFFF (White)
    )
    
    /// Secondary text color - supporting content
    static let textSecondary = Color(
        light: Color(red: 0.24, green: 0.24, blue: 0.26),   // #3C3C43 (iOS Gray)
        dark: Color(red: 0.92, green: 0.92, blue: 0.96)     // #EBEBF5 (iOS Gray Dark)
    )
    
    /// Tertiary text color - subtle content and placeholders
    static let textTertiary = Color(
        light: Color(red: 0.46, green: 0.46, blue: 0.50),   // #767680 (iOS Gray 2)
        dark: Color(red: 0.54, green: 0.54, blue: 0.56)     // #8A8A8E (iOS Gray 2 Dark)
    )
    
    // MARK: - Semantic Colors
    
    /// Success states and positive feedback
    static let success = Color(
        light: Color(red: 0.2, green: 0.78, blue: 0.35),    // #32C759 (iOS Green)
        dark: Color(red: 0.19, green: 0.82, blue: 0.35)     // #30D158 (iOS Green Dark)
    )
    
    /// Warning states and caution indicators
    static let warning = Color(
        light: Color(red: 1.0, green: 0.58, blue: 0.0),     // #FF9500 (iOS Orange)
        dark: Color(red: 1.0, green: 0.62, blue: 0.04)      // #FF9F0A (iOS Orange Dark)
    )
    
    /// Error states and destructive actions
    static let error = Color(
        light: Color(red: 1.0, green: 0.23, blue: 0.19),    // #FF3B30 (iOS Red)
        dark: Color(red: 1.0, green: 0.27, blue: 0.23)      // #FF453A (iOS Red Dark)
    )
    
    // MARK: - Component-Specific Colors
    
    /// Border and separator color
    static let border = Color(
        light: Color(red: 0.78, green: 0.78, blue: 0.78),   // #C7C7CC (iOS Separator)
        dark: Color(red: 0.33, green: 0.33, blue: 0.35)     // #545458 (iOS Separator Dark)
    )
    
    /// Surface color for cards and elevated components
    static let surface = Color(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),      // #FFFFFF (White)
        dark: Color(red: 0.11, green: 0.11, blue: 0.12)     // #1C1C1E (iOS Gray 6 Dark)
    )
}

// MARK: - Color Factory

private extension Color {
    /// Creates a color that adapts to light/dark mode
    /// - Parameters:
    ///   - light: Color for light mode
    ///   - dark: Color for dark mode
    init(light: Color, dark: Color) {
        self = Color(
            .init(
                colorScheme: .light,
                color: .init(light)
            ),
            darkAppearance: .init(
                colorScheme: .dark,
                color: .init(dark)
            )
        )
    }
}

// MARK: - Preview

#Preview("Progress Colors") {
    ScrollView {
        VStack(spacing: 24) {
            // Primary Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Primary Colors")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 16) {
                    ColorSwatch(color: .primary, name: "Primary")
                    ColorSwatch(color: .accent, name: "Accent")
                }
            }
            
            // Background Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Background Colors")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 12) {
                    ColorSwatch(color: .background, name: "Background")
                    ColorSwatch(color: .backgroundSecondary, name: "Background Secondary")
                    ColorSwatch(color: .backgroundTertiary, name: "Background Tertiary")
                }
            }
            
            // Text Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Text Colors")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 12) {
                    ColorSwatch(color: .textPrimary, name: "Text Primary")
                    ColorSwatch(color: .textSecondary, name: "Text Secondary")
                    ColorSwatch(color: .textTertiary, name: "Text Tertiary")
                }
            }
            
            // Semantic Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Semantic Colors")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 16) {
                    ColorSwatch(color: .success, name: "Success")
                    ColorSwatch(color: .warning, name: "Warning")
                    ColorSwatch(color: .error, name: "Error")
                }
            }
            
            // Usage Examples
            VStack(alignment: .leading, spacing: 16) {
                Text("Usage Examples")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                VStack(spacing: 12) {
                    // Card Example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Card")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Text("This is a sample card using our design tokens")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                        
                        Button("Primary Action") {
                            // Action
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        }
        .padding(20)
    }
    .background(.background)
}

// MARK: - Helper Views

private struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.border, lineWidth: 1)
                )
            
            Text(name)
                .font(.body)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
} 