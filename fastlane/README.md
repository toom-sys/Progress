# Fastlane Configuration for Progress iOS

This directory contains the Fastlane configuration for automating the build, test, and deployment process of the Progress iOS app.

## Setup

### Prerequisites

1. **Ruby**: Install Ruby 3.1+ (recommended via rbenv or RVM)
2. **Fastlane**: Install via gem or Homebrew
3. **Xcode**: Version 15+ installed
4. **SwiftLint**: Install via Homebrew (`brew install swiftlint`)

### Installation

```bash
# Install dependencies
bundle install

# Install SwiftLint if not already installed
brew install swiftlint

# Optional: Install xcov for coverage reports
gem install xcov
```

### Initial Setup

1. **Configure Matchfile**: Update the following values in `Matchfile`:
   - `git_url`: Your certificates repository URL
   - `username`: Your Apple Developer account email
   - `team_id`: Your Apple Developer Team ID

2. **Setup certificates** (first time only):
   ```bash
   bundle exec fastlane certificates
   ```

## Available Lanes

### 🧪 Lint Lane
Runs comprehensive code quality checks and tests:

```bash
bundle exec fastlane lint
```

**What it does:**
- ✅ SwiftLint analysis with JSON output
- ✅ Unit tests with code coverage
- ✅ Design token compliance checks
- ✅ Localization compliance checks
- ✅ Code coverage report generation (if xcov installed)
- ✅ TODO/FIXME comment scanning

### 🚀 Beta Lane
Builds and uploads to TestFlight:

```bash
bundle exec fastlane beta
```

**What it does:**
- ✅ Git status verification
- ✅ Automatic build number increment
- ✅ Code signing with Match
- ✅ Release build generation
- ✅ TestFlight upload
- ✅ Build artifacts cleanup
- ✅ Success notification

### 🔧 Helper Lanes

#### Setup Certificates
```bash
bundle exec fastlane certificates
```

#### Refresh Provisioning Profiles
```bash
bundle exec fastlane refresh_profiles
```

#### Clean Build Environment
```bash
bundle exec fastlane clean
```

## Configuration Details

### Constants
- **Scheme**: `Progress`
- **Project**: `Progress.xcodeproj`
- **Bundle ID**: `com.myname.Progress`
- **Coverage Threshold**: 80%

### Output Files
- `test-results.xml` - JUnit test results
- `test-results.html` - HTML test report
- `swiftlint-results.json` - SwiftLint analysis
- `coverage_reports/` - Code coverage reports

## CI/CD Integration

### GitHub Actions
The repository includes a comprehensive CI workflow (`.github/workflows/ci.yml`) that:

- Runs on macOS 13 with Xcode 15
- Executes the `lint` lane on every PR
- Uploads test results and coverage reports
- Posts coverage summaries to PR comments
- Includes security and PRD compliance checks

### Environment Variables
Set these in your CI environment:

```bash
CI=true                          # Enables CI-specific behavior
FASTLANE_SKIP_UPDATE_CHECK=true  # Skips update prompts
FASTLANE_HIDE_CHANGELOG=true     # Hides changelogs
FASTLANE_DISABLE_ANIMATION=true  # Disables animations
```

## Code Signing with Match

Match stores certificates and provisioning profiles in a git repository for team sharing.

### First Time Setup
1. Create a private git repository for certificates
2. Update `git_url` in `Matchfile`
3. Run `bundle exec fastlane certificates`

### Adding New Devices
```bash
bundle exec fastlane refresh_profiles
```

## Troubleshooting

### Common Issues

1. **Build failures**: Ensure Xcode 15+ is installed and selected
2. **Code signing**: Verify Apple Developer account access and team membership
3. **SwiftLint errors**: Run `swiftlint autocorrect` to fix auto-correctable issues
4. **Coverage below threshold**: Add more unit tests to reach 80% coverage

### Debug Mode
Enable verbose output:
```bash
DEBUG=true bundle exec fastlane lint
```

### Clean Reset
If builds are failing unexpectedly:
```bash
bundle exec fastlane clean
```

## PRD Compliance

The fastlane configuration enforces several PRD requirements:

- ✅ No UIKit imports (SwiftUI only)
- ✅ Design token usage validation
- ✅ Localization completeness
- ✅ Code coverage minimum (80%)
- ✅ Build performance monitoring

## Support

For issues with the fastlane configuration, check:
1. [Fastlane Documentation](https://docs.fastlane.tools/)
2. [Match Documentation](https://docs.fastlane.tools/actions/match/)
3. Project-specific scripts in `Scripts/ci/` 