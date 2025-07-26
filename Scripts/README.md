# Progress iOS - CI/CD Scripts

This directory contains scripts for maintaining code quality and enforcing the project requirements defined in the PRD.

## Setup

### Prerequisites

Install the required tools:

```bash
# SwiftLint for code linting
brew install swiftlint

# SwiftGen for type-safe resource access
brew install swiftgen

# Optional: xcov for code coverage reporting
gem install xcov
```

### Git Hooks Setup

To automatically run these scripts on commit/push, set up Git hooks:

```bash
# Make scripts executable (already done)
chmod +x Scripts/ci/*.sh

# Set up pre-commit hook
ln -sf ../../Scripts/ci/pre-commit.sh .git/hooks/pre-commit

# Set up pre-push hook  
echo '#!/bin/bash\nScripts/ci/run-full-tests.sh' > .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

## Scripts

### `pre-commit.sh`
Runs before each commit to enforce code quality:
- ✅ SwiftLint with strict mode
- ✅ No UIKit imports (SwiftUI only)
- ✅ No hardcoded colors/fonts (use design tokens)
- ✅ SwiftGen localization compliance
- ✅ Unit tests

### `check-localization.sh`
Verifies all UI strings use SwiftGen localization:
- Detects hardcoded strings in `Text()`, `Button()`, alerts
- Ensures `L10n` keys are used instead
- Generates SwiftGen files if needed

### `check-design-tokens.sh`
Enforces design token usage:
- Blocks hardcoded RGB/hex colors
- Blocks system color usage outside design tokens
- Blocks hardcoded font usage
- Ensures `Colours.swift` and `Typography.swift` are used

### `run-full-tests.sh`
Comprehensive test suite for pre-push:
- 🏗️ Clean build
- 🧪 Unit tests with coverage
- 🖥️ UI tests
- 📊 Code coverage analysis
- 🔍 SwiftLint analysis
- ⚠️ TODO/FIXME detection

## Bypassing Checks

For emergency commits, you can bypass pre-commit hooks:

```bash
git commit --no-verify -m "Emergency fix"
```

To ignore specific lines, use comments:

```swift
// swiftgen:ignore
Text("Debug only string")

// design-tokens:ignore  
Color.red // For debugging
```

## Configuration Files

- `.cursor/project.json` - Cursor IDE project configuration
- `.swiftlint.yml` - SwiftLint rules and custom checks
- `swiftgen.yml` - SwiftGen asset generation config

## Troubleshooting

### SwiftLint Errors
```bash
# Run SwiftLint manually to see detailed errors
swiftlint lint --strict

# Auto-fix certain issues
swiftlint autocorrect
```

### Localization Issues
```bash
# Generate SwiftGen files manually
swiftgen

# Check for missing localizations
Scripts/ci/check-localization.sh
```

### Design Token Issues
```bash
# Find hardcoded values
Scripts/ci/check-design-tokens.sh

# View design token files
open Progress/Resources/DesignTokens/
```

## Performance Targets (PRD Requirements)

- 🚀 App launch: ≤ 500ms
- 🧪 Test coverage: ≥ 80%
- 💥 Crash-free sessions: ≥ 99.5%
- ✨ Clean commit rate: ≥ 85% 