# Progress iOS App

A minimalist iOS app that helps everyday athletes in the UK track workouts, log nutrition, and visualise progress in one seamless experience.

## 🎯 Vision

Progress closes the behaviour loop—*Activity → Nutrition → Insight*—so users understand exactly how actions drive results. Built for iOS 18+ with SwiftUI and modern Swift practices.

## ✨ Features

### Core Features
- **Workout Planning & Tracking** - Plan workouts, track sets live with rest timer
- **Nutrition Logging** - Search foods, scan barcodes, AI-powered camera logging (AI tier)
- **Progress Visualization** - Daily snapshots, weekly charts, streak tracking
- **Dual-Tier Subscriptions** - Standard (£1/mo) and AI Native (£3/mo)
- **Referral System** - One-month free via referral invites

### Technical Features
- **Local-First Storage** with CloudKit sync
- **Offline Support** - Every action works without internet
- **Design System** - Consistent colors and typography tokens
- **Accessibility** - WCAG AA compliance
- **Performance** - Sub-500ms launch times

## 🛠 Technical Stack

- **UI Framework**: SwiftUI (iOS 18+)
- **Language**: Swift 6.0
- **Data & Persistence**: SwiftData, CloudKit
- **Charts**: Swift Charts
- **AI Services**: OpenAI API, Vision + Core ML
- **Subscriptions**: RevenueCat
- **Analytics**: Firebase Crashlytics
- **Dependencies**: Swift Package Manager only

## 📁 Project Structure

```
Progress/
├─ Progress/                    # Main app target
│  ├─ Resources/
│  │  ├─ Assets.xcassets       # App icons, images
│  │  └─ DesignTokens/         # Color and typography tokens
│  │     ├─ Colours.swift
│  │     └─ Typography.swift
│  ├─ Features/                # Feature-based organization
│  │  ├─ Onboarding/
│  │  ├─ Workouts/
│  │  │  ├─ Planner/
│  │  │  ├─ LiveTracker/
│  │  │  ├─ RestTimer/
│  │  │  └─ History/
│  │  ├─ Nutrition/
│  │  │  ├─ Search/
│  │  │  ├─ Barcode/
│  │  │  ├─ CameraAI/
│  │  │  └─ MacroGoals/
│  │  ├─ ProgressDashboard/
│  │  ├─ Engagement/
│  │  ├─ Paywall/
│  │  └─ Settings/
│  ├─ Extensions/
│  └─ Utilities/
├─ ProgressTests/              # Unit tests
├─ ProgressUITests/            # UI tests
└─ docs/                       # Documentation
```

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0+
- iOS 18.0+ Simulator or Device
- Apple Developer Account (for device testing)

### Setup
1. Clone the repository
2. Open `Progress.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run on simulator or device

### Environment Variables
Set `GIT_REMOTE` environment variable for automated deployment:
```bash
export GIT_REMOTE="https://github.com/your-username/progress-ios.git"
```

## 🎨 Design System

The app uses a comprehensive design token system for consistency:

### Colors
- **Brand Colors**: Primary blue, secondary blue, accent green
- **Semantic Colors**: Success, warning, error, info
- **Text Colors**: Primary, secondary, tertiary, placeholder
- **Background/Surface Colors**: Multiple levels for depth
- **Component Colors**: Specialized for timers, macros, charts

### Typography
- **Display Styles**: Hero sections and large headers
- **Headlines**: Page and section titles
- **Body Text**: Primary content in multiple sizes
- **Labels**: UI elements and captions
- **Specialized**: Numbers (rounded), code (monospace), timers

## 📊 Key Metrics & Goals

| Metric | Target | Description |
|--------|--------|-------------|
| Seamless Capture | ≥85% | Sessions logged without edit errors |
| Fast Entry | ≤15s | Median meal-logging time |
| Retention | ≥40% | Day-7 user retention |
| Performance | ≤500ms | Cold launch time |
| Reliability | ≥99.5% | Crash-free sessions |

## 🏗 Development Guidelines

### Code Organization
- One feature = one folder under `Features/`
- MVVM architecture with SwiftUI
- Protocol-oriented programming
- Value types preferred over classes

### Design Rules
- Use design tokens only (no hard-coded colors/fonts)
- All strings must be localized
- Support dark mode and dynamic type
- UIKit imports rejected via pre-commit hook

### Performance
- Offline-first: every action succeeds without internet
- Background sync throttled during Low Power Mode
- Lazy loading for views and images
- Proper state management

## 🧪 Testing

- **Unit Tests**: Core business logic and data models
- **UI Tests**: Critical user flows and accessibility
- **Performance Tests**: Launch time and memory usage
- **Snapshot Tests**: UI consistency across devices

Run tests:
```bash
# Unit tests
xcodebuild test -project Progress.xcodeproj -scheme Progress -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -project Progress.xcodeproj -scheme Progress -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ProgressUITests
```

## 📱 Subscription Tiers

### Standard (£1/month)
- Workout planning and tracking
- Basic nutrition logging
- Progress charts and snapshots
- Rest timer functionality

### AI Native (£3/month)
- Everything in Standard
- AI workout generation
- Camera-based food logging
- Personalised insights and recommendations

## 🔒 Privacy & Security

- HealthKit integration with proper permissions
- Local-first data with optional cloud sync
- GDPR compliant data export/deletion
- Secure authentication with Apple Sign-In

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and code of conduct before submitting PRs.

### Development Process
1. Create feature branch from `main`
2. Implement changes with tests
3. Run linting and tests
4. Submit PR with clear description

## 📞 Support

For support, feature requests, or bug reports:
- Create an issue in this repository
- Email: support@progressapp.com
- Website: https://progressapp.com

---

**Built with ❤️ for everyday athletes** 