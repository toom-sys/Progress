# RevenueCat Setup Guide for Progress iOS

This guide configures RevenueCat for Progress’s single membership.

## 1. RevenueCat Dashboard Setup

### Create Account & Project
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Create account and new project
3. Set project name: **Progress iOS**
4. Select platform: **iOS**

### Configure Products
Create these product IDs. Each one unlocks the same app.

#### Weekly
- **Product ID**: `com.tom.progress.member.weekly`
- **Type**: Auto-renewable subscription
- **Duration**: 1 week
- **Price**: £4.99/week
- **Display Name**: "Progress Weekly"

#### Monthly
- **Product ID**: `com.tom.progress.member.monthly`
- **Type**: Auto-renewable subscription
- **Duration**: 1 month
- **Price**: £9.99/month
- **Display Name**: "Progress Monthly"

#### Yearly
- **Product ID**: `com.tom.progress.member.yearly`
- **Type**: Auto-renewable subscription
- **Duration**: 1 year
- **Price**: £49.99/year
- **Display Name**: "Progress Yearly"

### Create Offerings
1. Go to **Offerings** in RevenueCat dashboard
2. Create one current offering: **"Membership"**
3. Add three packages:
   - Weekly: `com.tom.progress.member.weekly`
   - Monthly: `com.tom.progress.member.monthly`
   - Annual: `com.tom.progress.member.yearly`

### Configure Entitlements
Create one entitlement:

1. **"member"**
   - Products: all three membership product IDs above
   - Attach the same entitlement to weekly, monthly, and yearly

## 2. App Store Connect Setup

### Create In-App Purchases
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Monetization** → **Subscriptions**
3. Create one subscription group, **Progress Membership**, with three durations:

| Reference name | Product ID | Duration | UK price |
| --- | --- | --- | --- |
| Progress Membership Weekly | `com.tom.progress.member.weekly` | 1 week | £4.99 |
| Progress Membership Monthly | `com.tom.progress.member.monthly` | 1 month | £9.99 |
| Progress Membership Yearly | `com.tom.progress.member.yearly` | 1 year | £49.99 |

Rank yearly highest so a switch from week or month to year is an upgrade. `Progress/Configuration.storekit` carries the same three products for local StoreKit testing.

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
3. Test weekly, monthly, and yearly purchases. All three grant the `member` entitlement.
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
- Mix of weekly, monthly, and yearly purchases

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