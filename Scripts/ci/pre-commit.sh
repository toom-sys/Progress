#!/bin/bash

# Progress iOS App - Pre-commit Hook
# Enforces code quality standards defined in PRD.md

set -e

echo "🚀 Running Progress iOS pre-commit checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    print_error "SwiftLint not found. Install with: brew install swiftlint"
    exit 1
fi

# Check if SwiftGen is installed
if ! command -v swiftgen &> /dev/null; then
    print_warning "SwiftGen not found. Install with: brew install swiftgen"
fi

# 1. Run SwiftLint
print_status "Running SwiftLint..."
if ! swiftlint lint --strict; then
    print_error "SwiftLint failed. Fix issues before committing."
    exit 1
fi

# 2. Check for UIKit imports
print_status "Checking for prohibited UIKit imports..."
if grep -r "import UIKit" Progress/ --include="*.swift" 2>/dev/null; then
    print_error "UIKit imports found. Use SwiftUI only per PRD requirements."
    exit 1
fi

# 3. Check for hardcoded colors
print_status "Checking for hardcoded colors..."
if grep -r "UIColor\|Color\." Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -E "\.(red|blue|green|black|white|gray|orange|purple|pink|yellow)" 2>/dev/null; then
    print_error "Hardcoded colors found. Use design tokens from Colours.swift"
    exit 1
fi

# 4. Check for hardcoded fonts
print_status "Checking for hardcoded fonts..."
if grep -r "Font\." Progress/ --include="*.swift" | grep -v "DesignTokens" | grep -E "\.(system|custom|largeTitle|title|headline|body|caption)" 2>/dev/null; then
    print_error "Hardcoded fonts found. Use design tokens from Typography.swift"
    exit 1
fi

# 5. Check localization (if SwiftGen is available)
if command -v swiftgen &> /dev/null; then
    print_status "Checking localization compliance..."
    if ! Scripts/ci/check-localization.sh; then
        print_error "Localization check failed."
        exit 1
    fi
fi

# 6. Check design tokens usage
print_status "Verifying design tokens usage..."
if ! Scripts/ci/check-design-tokens.sh; then
    print_error "Design tokens check failed."
    exit 1
fi

# 7. Run unit tests
print_status "Running unit tests..."
if ! xcodebuild test -scheme Progress -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet; then
    print_error "Unit tests failed."
    exit 1
fi

print_status "All pre-commit checks passed! 🎉" 