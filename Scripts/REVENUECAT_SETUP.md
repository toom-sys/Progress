# RevenueCat Setup Guide for Progress iOS

This guide will help you configure RevenueCat for the Progress iOS app's dual-tier subscription model.

## 1. RevenueCat Dashboard Setup

### Create Account & Project
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Create account and new project
3. Set project name: **Progress iOS**
4. Select platform: **iOS**

### Configure Products
Create these exact product IDs to match the app:

#### Standard Tier
- **Product ID**: `com.tom.progress.standard.monthly`
- **Type**: Auto-renewable subscription
- **Duration**: 1 month
- **Price**: £0.99/month
- **Display Name**: "Progress Standard"

#### Plus AI Tier  
- **Product ID**: `com.tom.progress.plus_ai.monthly`
- **Type**: Auto-renewable subscription
- **Duration**: 1 month
- **Price**: £2.99/month
- **Display Name**: "Progress Plus AI"

### Create Offerings
1. Go to **Offerings** in RevenueCat dashboard
2. Create offering: **"Standard"** 
   - Add package: `com.tom.progress.standard.monthly`
   - Set as monthly package
3. Create offering: **"Plus AI"**
   - Add package: `com.tom.progress.plus_ai.monthly` 
   - Set as monthly package

### Configure Entitlements
Create these entitlements to control feature access:

1. **"standard"** entitlement
   - Grant access to: Standard tier features
   - Products: `com.tom.progress.standard.monthly`

2. **"plus_ai"** entitlement  
   - Grant access to: Plus AI tier features
   - Products: `com.tom.progress.plus_ai.monthly`

## 2. App Store Connect Setup

### Create In-App Purchases
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Monetization** → **In-App Purchases**
3. Create two auto-renewable subscriptions:

#### Standard Subscription
- **Reference Name**: Progress Standard Monthly
- **Product ID**: `com.tom.progress.standard.monthly`
- **Subscription Group**: Progress Subscriptions
- **Duration**: 1 month
- **Price**: £0.99 (Tier 2)

#### Plus AI Subscription  
- **Reference Name**: Progress Plus AI Monthly
- **Product ID**: `com.tom.progress.plus_ai.monthly`
- **Subscription Group**: Progress Subscriptions  
- **Duration**: 1 month
- **Price**: £2.99 (Tier 5)

### Subscription Group Settings
- **Reference Name**: Progress Subscriptions
- **Rank products**: Progress Plus AI (higher rank), Standard (lower rank)
- This allows users to upgrade from Standard to AI Native

## 3. Get API Keys

### RevenueCat API Keys
1. In RevenueCat dashboard, go to **Project Settings** → **API Keys**
2. Copy these values:
   - **Public SDK Key** (for iOS)
   - **Secret API Key** (for server-side if needed)

### Environment Variables
Set these in your environment:

```bash
# RevenueCat Configuration
export REVENUECAT_PUBLIC_SDK_KEY_IOS="your_public_sdk_key_here"
export REVENUECAT_API_KEY="your_secret_api_key_here"  
export REVENUECAT_ENVIRONMENT="sandbox"  # or "production"
```

## 4. Test Configuration

### Sandbox Testing
1. Create sandbox test user in App Store Connect
2. Sign in with sandbox account on device
3. Test both subscription tiers
4. Verify purchase flow works correctly

### RevenueCat Testing
1. In RevenueCat dashboard, check **Customer** section
2. Verify test purchases appear
3. Check entitlements are granted correctly

## 5. Enable RevenueCat in App

Once products are configured, enable RevenueCat in the app:

### Step 1: Inject Environment Variables
```bash
# Set your actual API keys
export REVENUECAT_PUBLIC_SDK_KEY_IOS="your_actual_key"
export REVENUECAT_ENVIRONMENT="sandbox"

# Inject into plist files
./Scripts/inject-secrets.sh inject
```

### Step 2: Uncomment RevenueCat Code
In `AppDelegate.swift`, uncomment:
```swift
import RevenueCat

// In initializeRevenueCat():
Purchases.logLevel = .debug
Purchases.configure(withAPIKey: apiKey)
// ... rest of configuration
```

In `SubscriptionService.swift`, uncomment:
```swift
import RevenueCat

// All the actual RevenueCat API calls
```

### Step 3: Test Integration
1. Build and run app
2. Tap "View Subscription Plans"
3. Verify offerings load from RevenueCat
4. Test purchase flow with sandbox account

## 6. Production Deployment

### Pre-Launch Checklist
- [ ] Products approved in App Store Connect
- [ ] RevenueCat webhooks configured (if using server)
- [ ] Set environment to "production"
- [ ] Test with production API keys in staging
- [ ] Set up analytics/tracking for subscription events

### Environment Settings
```bash
# Production environment
export REVENUECAT_ENVIRONMENT="production"
export REVENUECAT_PUBLIC_SDK_KEY_IOS="your_production_key"
```

### Monitor Key Metrics
Track these in RevenueCat dashboard:
- Conversion rate (free trial → paid)
- Churn rate
- Revenue per user
- Upgrade rate (Standard → AI Native)

## 7. Troubleshooting

### Common Issues

#### "No offerings found"
- Check product IDs match exactly
- Verify products are approved in App Store Connect
- Ensure offering is configured in RevenueCat

#### "Purchase failed" 
- Verify sandbox account setup
- Check App Store Connect agreement status
- Ensure correct product IDs

#### "Entitlements not granted"
- Check entitlement configuration in RevenueCat
- Verify product mapping to entitlements
- Check webhook delivery if using server

### Debug Tools
```swift
// Enable debug logging
Purchases.logLevel = .debug

// Check customer info
Purchases.shared.getCustomerInfo { customerInfo, error in
    print("Customer Info: \(customerInfo)")
    print("Active entitlements: \(customerInfo?.entitlements.active)")
}
```

## 8. Support Resources

- [RevenueCat Documentation](https://docs.revenuecat.com)
- [iOS SDK Guide](https://docs.revenuecat.com/docs/ios)
- [Testing Guide](https://docs.revenuecat.com/docs/sandbox)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

Need help? Check the RevenueCat community or support channels for assistance. 