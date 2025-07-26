#!/bin/bash

# Progress iOS App - Design Tokens Check
# Ensures design tokens are used instead of hardcoded colors and fonts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "🎨 Checking design tokens compliance..."

# Check if design token files exist
if [ ! -f "Progress/Resources/DesignTokens/Colours.swift" ]; then
    print_warning "Colours.swift not found. Creating placeholder..."
    mkdir -p "Progress/Resources/DesignTokens"
    cat > "Progress/Resources/DesignTokens/Colours.swift" << 'EOF'
import SwiftUI

extension Color {
    // Design tokens will be defined here
    // Example: static let primaryBackground = Color("primaryBackground")
}
EOF
fi

if [ ! -f "Progress/Resources/DesignTokens/Typography.swift" ]; then
    print_warning "Typography.swift not found. Creating placeholder..."
    mkdir -p "Progress/Resources/DesignTokens"
    cat > "Progress/Resources/DesignTokens/Typography.swift" << 'EOF'
import SwiftUI

extension Font {
    // Design tokens will be defined here
    // Example: static let heading1 = Font.custom("SF Pro Display", size: 28).weight(.bold)
}
EOF
fi

# Check for hardcoded color values
print_status "Checking for hardcoded color values..."

# Check for RGB/hex color values
rgb_colors=$(grep -r -E 'Color\(red:|Color\(hue:|#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8}' Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -v '// design-tokens:ignore' || true)

if [ -n "$rgb_colors" ]; then
    print_error "Found hardcoded RGB/hex colors. Use design tokens from Colours.swift instead:"
    echo "$rgb_colors"
    echo ""
    echo "Examples of correct usage:"
    echo "  ❌ Color(red: 0.2, green: 0.4, blue: 0.8)"
    echo "  ❌ Color(#FF0000)"
    echo "  ✅ Color.primaryBlue (defined in Colours.swift)"
    echo ""
    echo "To ignore a specific line, add: // design-tokens:ignore"
    exit 1
fi

# Check for system color usage outside design tokens
system_colors=$(grep -r -E 'Color\.(red|blue|green|black|white|gray|orange|purple|pink|yellow|clear|primary|secondary|accentColor)' Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -v '// design-tokens:ignore' || true)

if [ -n "$system_colors" ]; then
    print_error "Found hardcoded system colors. Use design tokens from Colours.swift instead:"
    echo "$system_colors"
    echo ""
    echo "Examples of correct usage:"
    echo "  ❌ Color.blue"
    echo "  ✅ Color.primaryBlue (defined in Colours.swift)"
    exit 1
fi

# Check for UIColor usage (should not exist due to SwiftUI-only rule)
ui_colors=$(grep -r 'UIColor' Progress/ --include="*.swift" | grep -v "DesignTokens" || true)

if [ -n "$ui_colors" ]; then
    print_error "Found UIColor usage. Use SwiftUI Color with design tokens instead:"
    echo "$ui_colors"
    exit 1
fi

# Check for hardcoded font values
print_status "Checking for hardcoded font values..."

# Check for system font usage outside design tokens
system_fonts=$(grep -r -E 'Font\.(largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)' Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -v '// design-tokens:ignore' || true)

if [ -n "$system_fonts" ]; then
    print_error "Found hardcoded system fonts. Use design tokens from Typography.swift instead:"
    echo "$system_fonts"
    echo ""
    echo "Examples of correct usage:"
    echo "  ❌ Font.headline"
    echo "  ✅ Font.heading1 (defined in Typography.swift)"
    exit 1
fi

# Check for custom font usage outside design tokens
custom_fonts=$(grep -r -E 'Font\.custom\(|Font\.system\(' Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -v '// design-tokens:ignore' || true)

if [ -n "$custom_fonts" ]; then
    print_error "Found hardcoded custom fonts. Use design tokens from Typography.swift instead:"
    echo "$custom_fonts"
    exit 1
fi

# Check for hardcoded font sizes
font_sizes=$(grep -r -E '\.font\(\.system\(size:|\.fontWeight\(' Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -v '// design-tokens:ignore' || true)

if [ -n "$font_sizes" ]; then
    print_error "Found hardcoded font sizes/weights. Use design tokens from Typography.swift instead:"
    echo "$font_sizes"
    exit 1
fi

# Check for spacing values (optional - can be enabled later)
# print_status "Checking for hardcoded spacing values..."
# hardcoded_spacing=$(grep -r -E '\.padding\([0-9]+\)|\.frame\(.*[0-9]+.*\)|\.offset\(.*[0-9]+.*\)' Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -v '// design-tokens:ignore' || true)

# Verify design token files are imported where needed
print_status "Verifying design token imports..."

# Find Swift files that use Color or Font extensions
files_using_colors=$(grep -l -r 'Color\.' Progress/ --include="*.swift" | grep -v "DesignTokens" || true)
files_using_fonts=$(grep -l -r 'Font\.' Progress/ --include="*.swift" | grep -v "DesignTokens" || true)

# Check if these files import the design tokens (this is a simplified check)
for file in $files_using_colors $files_using_fonts; do
    if [ -f "$file" ]; then
        # Check if file has any custom color/font usage that might need design tokens
        if grep -q -E 'Color\.|Font\.' "$file" && ! grep -q "DesignTokens" "$file"; then
            # This is informational - we don't fail the build for this
            print_warning "File $file uses Color/Font but may not import design tokens"
        fi
    fi
done

print_status "Design tokens compliance check passed! 🎨" 