import SwiftUI

/// Design tokens for consistent color usage throughout the Progress app
/// Provides semantic colors that adapt to light/dark mode automatically
public extension Color {
    
    // MARK: - Primary Colors
    
    /// Primary brand color - used for main actions and branding
    static let primary = Color.blue
    
    /// Secondary accent color for highlights and emphasis
    static let accent = Color.green
    
    // MARK: - Background Colors & Gradients
    
    /// Primary gradient background - main app background with directional gradient
    /// Adapts automatically for light/dark mode
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                // Top-left gradient stop
                .init(color: Color.backgroundGradientTopLeft, location: 0.0),
                // Top-right gradient stop
                .init(color: Color.backgroundGradientTopRight, location: 0.25),
                // Center gradient stop
                .init(color: Color.backgroundGradientCenter, location: 0.5),
                // Bottom gradient stop
                .init(color: Color.backgroundGradientBottom, location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Progress page gradient background - subtle colored gradients fading to base
    /// Adapts automatically for light/dark mode
    static var progressBackgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                // Top blend: Subtle color mix
                .init(color: Color.progressGradientTop, location: 0.0),
                // Upper middle: Softer blend
                .init(color: Color.progressGradientMiddle, location: 0.3),
                // Center: Very subtle
                .init(color: Color.progressGradientCenter, location: 0.6),
                // Bottom: Base background
                .init(color: Color.progressGradientBottom, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Primary background color - adapts to light/dark mode
    static let background = Color(UIColor.systemBackground)
    
    /// Secondary background color - cards and elevated surfaces
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    
    /// Tertiary background color - input fields and inactive states
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Adaptive Gradient Colors
    
    /// Background gradient colors that adapt to light/dark mode
    private static let backgroundGradientTopLeft = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)  // Dark blue-grey
            : UIColor(red: 0.90, green: 0.91, blue: 0.92, alpha: 1.0)  // Light grey
    })
    
    private static let backgroundGradientTopRight = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.10, blue: 0.15, alpha: 1.0)  // Dark purple-grey
            : UIColor(red: 0.87, green: 0.91, blue: 0.96, alpha: 1.0)  // Soft pale blue
    })
    
    private static let backgroundGradientCenter = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)  // Dark grey
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)     // White
    })
    
    private static let backgroundGradientBottom = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0)  // Very dark grey
            : UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)  // Very light grey
    })
    
    // MARK: - Progress Gradient Colors
    
    private static let progressGradientTop = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.10, blue: 0.18, alpha: 1.0)  // Dark purple
            : UIColor(red: 0.94, green: 0.91, blue: 0.97, alpha: 1.0)  // Light red-blue mix
    })
    
    private static let progressGradientMiddle = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.11, blue: 0.15, alpha: 1.0)  // Dark blend
            : UIColor(red: 0.96, green: 0.95, blue: 1.0, alpha: 1.0)   // Softer blend
    })
    
    private static let progressGradientCenter = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)  // Dark
            : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)  // Very light
    })
    
    private static let progressGradientBottom = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0)  // Very dark
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)     // Pure white
    })
    
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
    
    /// Card shadow color - adapts to light/dark mode
    static let cardShadow = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.3)  // Stronger shadow for dark mode
            : UIColor.black.withAlphaComponent(0.1)  // Subtle shadow for light mode
    })
    
    /// Card border color - subtle outline for dark mode cards
    static let cardBorder = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)  // Subtle white border for dark mode
            : UIColor.clear                           // No border for light mode
    })
    
    /// Elevated surface color - for raised components like modals
    static let surfaceElevated = Color(UIColor.tertiarySystemBackground)
    
    /// Pure white surface - solid white background for cards in light mode, pure black in dark mode
    static let surfaceWhite = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.black  // Pure black (#000000) for dark mode
            : UIColor.white  // Pure white (#FFFFFF) for light mode
    })
}

// MARK: - Custom Background Views

/// Light mode background with specific gradient for workout, progress, and nutrition screens
struct LightModeBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                // Top left: #E6E8EB (solid light grey)
                .init(color: Color(hex: "E6E8EB"), location: 0.0),
                // Top right: #DDE9F6 (soft pale blue)
                .init(color: Color(hex: "DDE9F6"), location: 0.25),
                // Centre: #FFFFFF (pure white)
                .init(color: Color(hex: "FFFFFF"), location: 0.5),
                // Bottom edges: #F3F3F3 (very light grey)
                .init(color: Color(hex: "F3F3F3"), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
}

/// Dark mode background with specific gradient for workout, progress, and nutrition screens
struct DarkModeBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                // Top left: #1E1E20 (deep charcoal grey)
                .init(color: Color(hex: "1E1E20"), location: 0.0),
                // Top right: #2C2328 (muted burgundy/purple tint)
                .init(color: Color(hex: "2C2328"), location: 0.25),
                // Centre: #121214 (near black base tone)
                .init(color: Color(hex: "121214"), location: 0.5),
                // Bottom edges: #18171A (very dark grey with a warm hint)
                .init(color: Color(hex: "18171A"), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
}

/// Adaptive background that switches between light and dark mode gradients
struct AdaptiveGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if colorScheme == .dark {
                DarkModeBackground()
            } else {
                LightModeBackground()
            }
        }
    }
}

/// Progress background with adaptive colored gradients for light/dark mode
struct ProgressBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base background adapts to system
            Color.background
            
            // Warm gradient from top-left (red-tinted)
            LinearGradient(
                stops: [
                    .init(color: warmAccentColor.opacity(colorScheme == .dark ? 0.3 : 0.6), location: 0.0),
                    .init(color: Color.clear, location: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Cool gradient from top-right (blue-tinted)
            LinearGradient(
                stops: [
                    .init(color: coolAccentColor.opacity(colorScheme == .dark ? 0.25 : 0.5), location: 0.0),
                    .init(color: Color.clear, location: 0.7)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            
            // Base color fade from bottom
            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color.background.opacity(0.3), location: 0.5),
                    .init(color: Color.background.opacity(0.8), location: 0.8),
                    .init(color: Color.background, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var warmAccentColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.2, blue: 0.2, alpha: 1.0)  // Dark red
                : UIColor(red: 1.0, green: 0.92, blue: 0.92, alpha: 1.0) // Light red
        })
    }
    
    private var coolAccentColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.25, blue: 0.4, alpha: 1.0)  // Dark blue
                : UIColor(red: 0.89, green: 0.95, blue: 0.99, alpha: 1.0) // Light blue
        })
    }
}

// MARK: - Color Extensions

public extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Card Styling

public extension View {
    /// Applies consistent card styling with proper dark mode support
    func cardStyle(
        cornerRadius: CGFloat = 12,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: Color.cardShadow,
                radius: 8,
                x: 0,
                y: 2
            )
    }
    
    /// Applies elevated card styling for modal content
    func elevatedCardStyle(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20
    ) -> some View {
        self
            .padding(padding)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: Color.cardShadow,
                radius: 16,
                x: 0,
                y: 4
            )
    }
    
    /// Applies white card styling with pure white background in light mode, pure black in dark mode
    func whiteCardStyle(
        cornerRadius: CGFloat = 12,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(Color.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: Color.cardShadow,
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Preview

#Preview("Progress Colors - Light") {
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
                    AdaptiveBackgroundSwatch(name: "Adaptive Background")
                    LightModeBackgroundSwatch(name: "Light Mode Background")
                    DarkModeBackgroundSwatch(name: "Dark Mode Background")
                    GradientSwatch(gradient: Color.backgroundGradient, name: "Background Gradient")
                    ProgressBackgroundSwatch(name: "Progress Background")
                    GradientSwatch(gradient: Color.progressBackgroundGradient, name: "Progress Gradient Fallback")
                    ColorSwatch(color: Color.background, name: "Background Fallback")
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
                    // Card Examples
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Standard Card")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("This card uses our new cardStyle() modifier with dark mode support")
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
                    .cardStyle()
                    
                    // Elevated Card Example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Elevated Card")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("This card uses elevatedCardStyle() for modal content")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                    }
                    .elevatedCardStyle()
                }
            }
        }
        .padding(20)
    }
    .background(AdaptiveGradientBackground())
    .preferredColorScheme(.light)
}

#Preview("Progress Colors - Dark") {
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
                Text("Dark Mode Backgrounds")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                VStack(spacing: 12) {
                    GradientSwatch(gradient: Color.backgroundGradient, name: "Background Gradient")
                    ProgressBackgroundSwatch(name: "Progress Background")
                    ColorSwatch(color: Color.background, name: "Background")
                    ColorSwatch(color: Color.backgroundSecondary, name: "Background Secondary")
                    ColorSwatch(color: Color.surface, name: "Surface")
                }
            }
            
            // Card Examples
            VStack(alignment: .leading, spacing: 16) {
                Text("Dark Mode Cards")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Standard Card")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Dark mode card with subtle border and enhanced shadow")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                    }
                    .cardStyle()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Elevated Card")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Elevated styling for modal and overlay content")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                    }
                    .elevatedCardStyle()
                }
            }
        }
        .padding(20)
    }
    .background(AdaptiveGradientBackground())
    .preferredColorScheme(.dark)
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

private struct GradientSwatch: View {
    let gradient: LinearGradient
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(gradient)
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

private struct AdaptiveBackgroundSwatch: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 40, height: 40)
                .background(AdaptiveGradientBackground())
                .clipShape(RoundedRectangle(cornerRadius: 8))
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

private struct LightModeBackgroundSwatch: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 40, height: 40)
                .background(LightModeBackground())
                .clipShape(RoundedRectangle(cornerRadius: 8))
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

private struct DarkModeBackgroundSwatch: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 40, height: 40)
                .background(DarkModeBackground())
                .clipShape(RoundedRectangle(cornerRadius: 8))
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

private struct ProgressBackgroundSwatch: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 40, height: 40)
                .background(ProgressBackgroundView())
                .clipShape(RoundedRectangle(cornerRadius: 8))
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