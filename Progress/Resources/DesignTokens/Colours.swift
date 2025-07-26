import SwiftUI

/// Design tokens for consistent color usage throughout the Progress app
/// Provides semantic colors that adapt to light/dark mode automatically
public extension Color {
    
    // MARK: - Primary Colors
    
    /// Primary brand color - used for main actions and branding
    static let primary = Color.blue
    
    /// Secondary accent color for highlights and emphasis
    static let accent = Color.green
    
    // MARK: - Background Colors
    
    /// Primary background color - main app background
    static let background = Color(UIColor.systemBackground)
    
    /// Secondary background color - cards and elevated surfaces
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    
    /// Tertiary background color - input fields and inactive states
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Text Colors
    
    /// Primary text color - main content
    static let textPrimary = Color(UIColor.label)
    
    /// Secondary text color - supporting content
    static let textSecondary = Color(UIColor.secondaryLabel)
    
    /// Tertiary text color - subtle content and placeholders
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // MARK: - Semantic Colors
    
    /// Success states and positive feedback
    static let success = Color.green
    
    /// Warning states and caution indicators
    static let warning = Color.orange
    
    /// Error states and destructive actions
    static let error = Color.red
    
    // MARK: - Component-Specific Colors
    
    /// Border and separator color
    static let border = Color(UIColor.separator)
    
    /// Surface color for cards and elevated components
    static let surface = Color(UIColor.secondarySystemBackground)
}

// MARK: - Preview

#Preview("Progress Colors") {
    ScrollView {
        VStack(spacing: 24) {
            // Primary Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Primary Colors")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                HStack(spacing: 16) {
                    ColorSwatch(color: Color.primary, name: "Primary")
                    ColorSwatch(color: Color.accent, name: "Accent")
                }
            }
            
            // Background Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Background Colors")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                VStack(spacing: 12) {
                    ColorSwatch(color: Color.background, name: "Background")
                    ColorSwatch(color: Color.backgroundSecondary, name: "Background Secondary")
                    ColorSwatch(color: Color.backgroundTertiary, name: "Background Tertiary")
                }
            }
            
            // Text Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Text Colors")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                VStack(spacing: 12) {
                    ColorSwatch(color: Color.textPrimary, name: "Text Primary")
                    ColorSwatch(color: Color.textSecondary, name: "Text Secondary")
                    ColorSwatch(color: Color.textTertiary, name: "Text Tertiary")
                }
            }
            
            // Semantic Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Semantic Colors")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                HStack(spacing: 16) {
                    ColorSwatch(color: Color.success, name: "Success")
                    ColorSwatch(color: Color.warning, name: "Warning")
                    ColorSwatch(color: Color.error, name: "Error")
                }
            }
            
            // Usage Examples
            VStack(alignment: .leading, spacing: 16) {
                Text("Usage Examples")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                VStack(spacing: 12) {
                    // Card Example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Card")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("This is a sample card using our design tokens")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                        
                        Button("Primary Action") {
                            // Action
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(16)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
    }
    .background(Color.background)
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
                        .stroke(Color.border, lineWidth: 1)
                )
            
            Text(name)
                .font(.body)
                .foregroundColor(Color.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
} 