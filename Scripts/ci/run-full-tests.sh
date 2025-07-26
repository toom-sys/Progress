#!/bin/bash

# Progress iOS App - Full Test Suite
# Runs comprehensive tests before push

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "🧪 Running full Progress iOS test suite..."

# Variables
SCHEME="Progress"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
COVERAGE_THRESHOLD=80

# 1. Clean build directory
print_info "Cleaning build directory..."
xcodebuild clean -scheme $SCHEME

# 2. Build project
print_status "Building project..."
if ! xcodebuild build -scheme $SCHEME -destination "$DESTINATION" -quiet; then
    print_error "Build failed."
    exit 1
fi

# 3. Run unit tests with coverage
print_status "Running unit tests with coverage..."
if ! xcodebuild test -scheme $SCHEME -destination "$DESTINATION" -enableCodeCoverage YES -quiet; then
    print_error "Unit tests failed."
    exit 1
fi

# 4. Check code coverage (if xcov is available)
if command -v xcov &> /dev/null; then
    print_status "Checking code coverage..."
    xcov --scheme $SCHEME --minimum_coverage_percentage $COVERAGE_THRESHOLD
else
    print_warning "xcov not found. Install with: gem install xcov"
fi

# 5. Run UI tests
print_status "Running UI tests..."
if ! xcodebuild test -scheme $SCHEME -destination "$DESTINATION" -only-testing:ProgressUITests -quiet; then
    print_error "UI tests failed."
    exit 1
fi

# 6. Run SwiftLint (if not already run)
if command -v swiftlint &> /dev/null; then
    print_status "Running SwiftLint analysis..."
    swiftlint lint --reporter json > swiftlint-results.json || true
    
    # Count warnings and errors
    if [ -f swiftlint-results.json ]; then
        warnings=$(jq '[.[] | select(.severity == "warning")] | length' swiftlint-results.json 2>/dev/null || echo "0")
        errors=$(jq '[.[] | select(.severity == "error")] | length' swiftlint-results.json 2>/dev/null || echo "0")
        
        if [ "$errors" -gt 0 ]; then
            print_error "SwiftLint found $errors errors and $warnings warnings"
            exit 1
        elif [ "$warnings" -gt 0 ]; then
            print_warning "SwiftLint found $warnings warnings"
        fi
        
        rm -f swiftlint-results.json
    fi
fi

# 7. Check for TODO/FIXME comments (optional warning)
print_status "Checking for TODO/FIXME comments..."
todos=$(grep -r -E "TODO|FIXME|HACK" Progress/ --include="*.swift" || true)
if [ -n "$todos" ]; then
    todo_count=$(echo "$todos" | wc -l)
    print_warning "Found $todo_count TODO/FIXME comments. Consider addressing these before release."
fi

# 8. Verify app can be archived (optional - can be slow)
# print_status "Testing archive build..."
# if ! xcodebuild archive -scheme $SCHEME -destination generic/platform=iOS -archivePath build/Progress.xcarchive -quiet; then
#     print_error "Archive build failed."
#     exit 1
# fi

# 9. Performance test (if available)
if [ -f "ProgressPerformanceTests/ProgressPerformanceTests.swift" ]; then
    print_status "Running performance tests..."
    xcodebuild test -scheme $SCHEME -destination "$DESTINATION" -only-testing:ProgressPerformanceTests -quiet
fi

print_status "All tests passed! 🎉"
print_info "Summary:"
print_info "  ✅ Build successful"
print_info "  ✅ Unit tests passed"
print_info "  ✅ UI tests passed"
print_info "  ✅ Code quality checks passed"

# Optional: Send notification or update status
# osascript -e 'display notification "All tests passed!" with title "Progress iOS"' 