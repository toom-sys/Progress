# Secrets Management for Progress iOS

This document explains how to set up and manage sensitive configuration data for the Progress iOS app using environment variables and automated injection.

## Overview

The Progress iOS app uses RevenueCat for subscriptions and Firebase for analytics/crashlytics. Both services require API keys and configuration data that should not be committed to version control.

Our solution uses:
- **Placeholder plist files** with environment variable references
- **Automated injection script** that replaces placeholders with actual values
- **Fastlane integration** for CI/CD workflows
- **Backup/restore mechanism** for safe development

## Configuration Files

### RevenueCat.plist
Contains RevenueCat SDK configuration:
```xml
<key>PUBLIC_SDK_KEY_IOS</key>
<string>${REVENUECAT_PUBLIC_SDK_KEY_IOS}</string>
```

### GoogleService-Info.plist
Contains Firebase project configuration:
```xml
<key>API_KEY</key>
<string>${FIREBASE_API_KEY}</string>
```

## Required Environment Variables

### RevenueCat
```bash
export REVENUECAT_API_KEY="your_api_key"
export REVENUECAT_PUBLIC_SDK_KEY_IOS="your_public_sdk_key"
export REVENUECAT_ENVIRONMENT="sandbox"  # or "production"
```

### Firebase
```bash
export FIREBASE_CLIENT_ID="your_client_id"
export FIREBASE_REVERSED_CLIENT_ID="your_reversed_client_id"
export FIREBASE_API_KEY="your_api_key"
export FIREBASE_GCM_SENDER_ID="your_sender_id"
export FIREBASE_PROJECT_ID="your_project_id"
export FIREBASE_STORAGE_BUCKET="your_bucket"
export FIREBASE_GOOGLE_APP_ID="your_app_id"
export FIREBASE_DATABASE_URL="your_database_url"
```

## Local Development Setup

### 1. Create Environment File
Create a `.env` file in your project root (this file is gitignored):

```bash
# .env
REVENUECAT_API_KEY=your_dev_api_key
REVENUECAT_PUBLIC_SDK_KEY_IOS=your_dev_public_key
REVENUECAT_ENVIRONMENT=sandbox

FIREBASE_CLIENT_ID=your_dev_client_id
FIREBASE_REVERSED_CLIENT_ID=com.googleusercontent.apps.your_reversed_id
FIREBASE_API_KEY=your_dev_api_key
FIREBASE_GCM_SENDER_ID=123456789
FIREBASE_PROJECT_ID=your-dev-project
FIREBASE_STORAGE_BUCKET=your-dev-project.appspot.com
FIREBASE_GOOGLE_APP_ID=1:123456789:ios:abcdef123456
FIREBASE_DATABASE_URL=https://your-dev-project.firebaseio.com
```

### 2. Load Environment Variables
```bash
# Load variables from .env file
export $(cat .env | xargs)

# Or use direnv (recommended)
echo "source .env" > .envrc
direnv allow
```

### 3. Inject Secrets
```bash
# Inject secrets into plist files
./Scripts/inject-secrets.sh inject

# Build your app in Xcode
# The AppDelegate will now find valid configuration files
```

### 4. Restore Original Files
```bash
# Restore placeholder files (important before committing)
./Scripts/inject-secrets.sh restore
```

## CI/CD Setup

### GitHub Actions
Add these secrets to your GitHub repository:

1. Go to Repository Settings → Secrets and variables → Actions
2. Add each environment variable as a secret:
   - `REVENUECAT_API_KEY`
   - `REVENUECAT_PUBLIC_SDK_KEY_IOS`
   - `REVENUECAT_ENVIRONMENT`
   - `FIREBASE_CLIENT_ID`
   - `FIREBASE_REVERSED_CLIENT_ID`
   - `FIREBASE_API_KEY`
   - `FIREBASE_GCM_SENDER_ID`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_STORAGE_BUCKET`
   - `FIREBASE_GOOGLE_APP_ID`
   - `FIREBASE_DATABASE_URL`

### Fastlane Integration
The injection is automatically handled by Fastlane:

```bash
# For beta builds
bundle exec fastlane beta

# For testing
bundle exec fastlane lint

# Manual injection
bundle exec fastlane inject_secrets

# Restore placeholders
bundle exec fastlane restore_configs
```

## Script Usage

### Basic Commands
```bash
./Scripts/inject-secrets.sh inject    # Inject environment variables (default)
./Scripts/inject-secrets.sh restore   # Restore original placeholder files
./Scripts/inject-secrets.sh cleanup   # Remove backup files
./Scripts/inject-secrets.sh help      # Show help information
```

### Development Workflow
```bash
# 1. Start development session
./Scripts/inject-secrets.sh inject

# 2. Build and test your app
# ...

# 3. Before committing changes
./Scripts/inject-secrets.sh restore
git add .
git commit -m "Your changes"
```

## Security Best Practices

### ✅ Do's
- Use different API keys for development/staging/production
- Store secrets in environment variables or secure secret management
- Always restore placeholder files before committing
- Use `.env` files for local development (gitignored)
- Regularly rotate API keys

### ❌ Don'ts
- Never commit actual API keys to version control
- Don't share production keys in development environments
- Don't skip the restore step before committing
- Don't store secrets in plain text files that could be committed

## Troubleshooting

### Missing Environment Variables
If you see warnings about missing environment variables:
```bash
⚠️ Warning: Environment variable 'FIREBASE_API_KEY' is not set
```

1. Check your environment variable names match exactly
2. Ensure variables are exported: `export VARIABLE_NAME=value`
3. Verify `.env` file is loaded if using one

### Build Failures
If builds fail with configuration errors:
```bash
⚠️ RevenueCat config not found or invalid
```

1. Run `./Scripts/inject-secrets.sh inject` before building
2. Check that environment variables are set correctly
3. Verify plist files exist in the Progress/ directory

### Git Issues
If you accidentally commit injected files:
```bash
# Restore placeholder files
./Scripts/inject-secrets.sh restore

# Update the commit
git add Progress/*.plist
git commit --amend --no-edit
```

## Integration Testing

To verify the setup works correctly:

```bash
# 1. Set test environment variables
export REVENUECAT_API_KEY="test_key"
export FIREBASE_API_KEY="test_firebase_key"

# 2. Inject secrets
./Scripts/inject-secrets.sh inject

# 3. Check injection worked
grep "test_key" Progress/RevenueCat.plist
grep "test_firebase_key" Progress/GoogleService-Info.plist

# 4. Restore
./Scripts/inject-secrets.sh restore

# 5. Verify restoration
grep "\${REVENUECAT_API_KEY}" Progress/RevenueCat.plist
```

## Support

For issues with secrets management:
1. Check this documentation
2. Verify environment variables are set correctly  
3. Ensure script has execute permissions: `chmod +x Scripts/inject-secrets.sh`
4. Test the injection manually before running builds 