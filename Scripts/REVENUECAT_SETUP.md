# RevenueCat Setup Guide for Progress iOS

This guide walks through configuring RevenueCat for the **Progress Pro** subscription, which is
offered as two billing plans (annual and monthly) sharing a single `pro` entitlement.

## 1. RevenueCat Dashboard Setup

### Create Account & Project
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Create account and new project
3. Set project name: **Progress iOS**
4. Select platform: **iOS**

### Configure Products
Create two products to match the app:

#### Progress Pro (Annual)
- **Product ID**: `com.tom.progress.pro.annual`
- **Type**: Auto-renewable subscription
- **Duration**: 1 year
- **Price**: £35.00/year (sale price; £49.00 is shown struck-through in-app as the reference price)
- **Display Name**: "Progress Pro (Annual)"
- **Introductory Offer**: 3-day free trial (Free Trial type, P3D period)

#### Progress Pro (Monthly)
- **Product ID**: `com.tom.progress.pro.monthly`
- **Type**: Auto-renewable subscription
- **Duration**: 1 month
- **Price**: £4.99/month
- **Display Name**: "Progress Pro (Monthly)"
- **Introductory Offer**: none

### Create Offering
1. Go to **Offerings** in RevenueCat dashboard
2. Create offering: **"Pro"** (set as the default/current offering)
   - Add package `com.tom.progress.pro.annual` as the **Annual** package
   - Add package `com.tom.progress.pro.monthly` as the **Monthly** package

### Configure Entitlement
Create one entitlement to control feature access:

1. **"pro"** entitlement
   - Grant access to: All Progress Pro features
   - Products: `com.tom.progress.pro.annual`, `com.tom.progress.pro.monthly`

## 2. App Store Connect Setup

### Create In-App Purchases
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Monetization** → **In-App Purchases**
3. Create two auto-renewable subscriptions in the same group:

#### Progress Pro Annual
- **Reference Name**: Progress Pro Annual
- **Product ID**: `com.tom.progress.pro.annual`
- **Subscription Group**: Progress Subscriptions
- **Duration**: 1 year
- **Price**: £35.00

#### Progress Pro Monthly
- **Reference Name**: Progress Pro Monthly
- **Product ID**: `com.tom.progress.pro.monthly`
- **Subscription Group**: Progress Subscriptions
- **Duration**: 1 month
- **Price**: £4.99

### Introductory Offer
Configure a free trial on the **annual** product:
- **Type**: Free Trial
- **Duration**: 3 days
- **Eligible customers**: New subscribers only

> Note: because both products live in the same subscription group, a customer is only eligible
> for the free trial once across the group.

### StoreKit Configuration
The local `Configuration.storekit` file already mirrors this setup: an annual product with a
3-day free trial and a monthly product with no trial.

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
1. Create a sandbox test user in App Store Connect
2. Sign in with the sandbox account on device
3. Test the Progress Pro subscription and free trial
4. Verify the trial converts to paid after 7 days

### RevenueCat Testing
1. In RevenueCat dashboard, check the **Customer** section
2. Verify test purchases appear
3. Confirm the **"pro"** entitlement is granted correctly

## 5. Enable RevenueCat in App

Once products are configured, enable RevenueCat in the app:

### Step 1: Inject Environment Variables
```bash
export REVENUECAT_PUBLIC_SDK_KEY_IOS="your_actual_key"
export REVENUECAT_ENVIRONMENT="sandbox"
./Scripts/inject-secrets.sh inject
```

### Step 2: Verify Configuration
In `AppDelegate.swift`, ensure RevenueCat is configured:
```swift
import RevenueCat

// In initializeRevenueCat():
Purchases.logLevel = .debug
Purchases.configure(withAPIKey: apiKey)
```

### Step 3: Test Integration
1. Build and run the app
2. Complete onboarding to reach the subscription step
3. Verify the Pro offering loads from RevenueCat
4. Test the free trial purchase flow with the sandbox account

## 6. Production Deployment

### Pre-Launch Checklist
- [ ] Product approved in App Store Connect
- [ ] Free trial introductory offer approved
- [ ] RevenueCat webhooks configured (if using server)
- [ ] Set environment to "production"
- [ ] Test with production API keys in staging
- [ ] Confirm `"pro"` entitlement works end-to-end

### Monitor Key Metrics
Track these in the RevenueCat dashboard:
- Free trial start rate
- Trial-to-paid conversion rate
- Monthly churn rate
- Revenue per user

## 7. Troubleshooting

### Common Issues

#### "No offering found"
- Check the product ID matches exactly: `com.tom.progress.pro.monthly`
- Verify the product is approved in App Store Connect
- Ensure the "Pro" offering is set as current/default in RevenueCat

#### "Purchase failed"
- Verify sandbox account setup
- Check App Store Connect agreement status
- Ensure the correct product ID is used

#### "Entitlement not granted"
- Check the **"pro"** entitlement is mapped to `com.tom.progress.pro.monthly`
- Verify webhook delivery if using a server
- Check RevenueCat customer info for active entitlements

### Debug Tools
```swift
// Enable debug logging
Purchases.logLevel = .debug

// Check customer info
Purchases.shared.getCustomerInfo { customerInfo, error in
    print("Active entitlements: \(customerInfo?.entitlements.active ?? [:])")
}
```

## 8. Support Resources

- [RevenueCat Documentation](https://docs.revenuecat.com)
- [iOS SDK Guide](https://docs.revenuecat.com/docs/ios)
- [Free Trial Setup](https://docs.revenuecat.com/docs/introductory-offers)
- [Testing Guide](https://docs.revenuecat.com/docs/sandbox)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
