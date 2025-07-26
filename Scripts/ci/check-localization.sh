#!/bin/bash

# Progress iOS App - Localization Check
# Ensures all UI strings use SwiftGen localized keys

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

echo "🔍 Checking SwiftGen localization compliance..."

# Check if SwiftGen is installed
if ! command -v swiftgen &> /dev/null; then
    print_warning "SwiftGen not found. Skipping localization checks."
    exit 0
fi

# Generate SwiftGen files if config exists
if [ -f "swiftgen.yml" ]; then
    print_status "Generating SwiftGen localization files..."
    swiftgen
fi

# Check for hardcoded strings in Text() views
print_status "Checking for hardcoded strings in Text views..."
hardcoded_strings=$(grep -r 'Text("' Progress/ --include="*.swift" | grep -v 'L10n\.' | grep -v '\.localized' | grep -v '// swiftgen:ignore' || true)

if [ -n "$hardcoded_strings" ]; then
    print_error "Found hardcoded strings in Text views. Use SwiftGen L10n keys instead:"
    echo "$hardcoded_strings"
    echo ""
    echo "Examples of correct usage:"
    echo "  ❌ Text(\"Hello World\")"
    echo "  ✅ Text(L10n.welcome.title)"
    echo ""
    echo "To ignore a specific line, add: // swiftgen:ignore"
    exit 1
fi

# Check for hardcoded strings in alert/sheet titles
print_status "Checking for hardcoded strings in alerts and sheets..."
alert_strings=$(grep -r -E '\.alert\(|\.sheet\(|\.confirmationDialog\(' Progress/ --include="*.swift" | grep '".*"' | grep -v 'L10n\.' | grep -v '\.localized' | grep -v '// swiftgen:ignore' || true)

if [ -n "$alert_strings" ]; then
    print_error "Found hardcoded strings in alerts/sheets. Use SwiftGen L10n keys instead:"
    echo "$alert_strings"
    exit 1
fi

# Check for Button titles
print_status "Checking for hardcoded Button titles..."
button_strings=$(grep -r 'Button("' Progress/ --include="*.swift" | grep -v 'L10n\.' | grep -v '\.localized' | grep -v '// swiftgen:ignore' || true)

if [ -n "$button_strings" ]; then
    print_error "Found hardcoded Button titles. Use SwiftGen L10n keys instead:"
    echo "$button_strings"
    exit 1
fi

# Check if Localizable.strings file exists
if [ ! -f "Progress/Resources/Localization/en.lproj/Localizable.strings" ]; then
    print_warning "Localizable.strings file not found. Creating directory structure..."
    mkdir -p "Progress/Resources/Localization/en.lproj"
    touch "Progress/Resources/Localization/en.lproj/Localizable.strings"
fi

# Verify SwiftGen generated files exist
if [ ! -f "Progress/Resources/Generated/Strings.swift" ] && [ ! -f "Progress/Generated/Strings.swift" ]; then
    print_warning "SwiftGen Strings.swift not found. Make sure to run 'swiftgen' to generate localization files."
fi

print_status "Localization compliance check passed! ✨" 