import SwiftUI

/// Design tokens for consistent color usage throughout the Progress app
public struct ProgressColors {
    
    // MARK: - Brand Colors
    
    /// Primary brand color - used for main actions and branding
    public static let primaryBlue = Color("PrimaryBlue")
    
    /// Secondary brand color - used for supporting elements
    public static let secondaryBlue = Color("SecondaryBlue")
    
    /// Accent color for highlights and emphasis
    public static let accentGreen = Color("AccentGreen")
    
    // MARK: - Semantic Colors
    
    /// Success states and positive actions
    public static let success = Color("Success")
    
    /// Warning states and caution indicators  
    public static let warning = Color("Warning")
    
    /// Error states and destructive actions
    public static let error = Color("Error")
    
    /// Information and neutral states
    public static let info = Color("Info")
    
    // MARK: - Text Colors
    
    /// Primary text color - adapts to light/dark mode
    public static let textPrimary = Color("TextPrimary")
    
    /// Secondary text color - lower emphasis
    public static let textSecondary = Color("TextSecondary")
    
    /// Tertiary text color - lowest emphasis
    public static let textTertiary = Color("TextTertiary")
    
    /// Placeholder text color
    public static let textPlaceholder = Color("TextPlaceholder")
    
    // MARK: - Background Colors
    
    /// Primary background color
    public static let backgroundPrimary = Color("BackgroundPrimary")
    
    /// Secondary background color - cards, sections
    public static let backgroundSecondary = Color("BackgroundSecondary")
    
    /// Tertiary background color - inputs, inactive states
    public static let backgroundTertiary = Color("BackgroundTertiary")
    
    // MARK: - Surface Colors
    
    /// Card and elevated surface color
    public static let surfaceCard = Color("SurfaceCard")
    
    /// Sheet and modal surface color
    public static let surfaceSheet = Color("SurfaceSheet")
    
    /// Popover and tooltip surface color
    public static let surfacePopover = Color("SurfacePopover")
    
    // MARK: - Border Colors
    
    /// Primary border color
    public static let borderPrimary = Color("BorderPrimary")
    
    /// Secondary border color - subtle dividers
    public static let borderSecondary = Color("BorderSecondary")
    
    /// Input border color
    public static let borderInput = Color("BorderInput")
    
    // MARK: - Component-Specific Colors
    
    /// Rest timer progress color
    public static let timerProgress = Color("TimerProgress")
    
    /// Workout completion indicator
    public static let workoutComplete = Color("WorkoutComplete")
    
    /// Macro ring colors
    public static let macroProtein = Color("MacroProtein")
    public static let macroCarbs = Color("MacroCarbs")
    public static let macroFat = Color("MacroFat")
    
    /// Chart colors for progress visualization
    public static let chartPrimary = Color("ChartPrimary")
    public static let chartSecondary = Color("ChartSecondary")
    public static let chartTertiary = Color("ChartTertiary")
}

// MARK: - Color Extensions

extension Color {
    /// Creates a color from hex string
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    public init(hex: String) {
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

// MARK: - Accessibility Support

extension ProgressColors {
    /// Returns high contrast version of a color if accessibility settings require it
    public static func accessibleColor(_ color: Color, highContrast: Color) -> Color {
        // In a real implementation, this would check accessibility settings
        return color
    }
} 