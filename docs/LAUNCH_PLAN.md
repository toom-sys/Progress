# Progress — plan to launch

Version 1.1 of this plan. It starts from the code on `main`, not from the README feature list.

Launch means an App Store release of a paid iPhone app (UK, iOS 18.2+) with one membership. A member can log a workout, log a meal, and see that day on a progress screen, offline, with data that survives relaunch and syncs when iCloud is available. Someone who is not a member does not get a reduced app. They get the paywall.

## Where the app actually is

The shell is real. The behaviour loop is not closed, and nothing in the paywall can be sold yet.

| Area | In the build today | Still missing for a store release |
| --- | --- | --- |
| Navigation | Floating tabs for Workouts, Nutrition, Progress (`MainTabView`) | Deep links, scroll-hide is partial |
| Workouts | List, search, sort, create, exercise types, detail, rest-timer UI | Finish workout, add set, templates, reorder, undo, unsaved-changes prompt, share |
| Nutrition | Dashboard, USDA search, Open Food Facts barcode, macro display prefs | Real food API credentials, quick-add, favourites UI, macro targets, reminders, camera AI |
| Progress | Empty state in `ProgressDashboardView` | Daily snapshot, weekly chart, streak |
| Identity | `User` model only | Onboarding, Sign in with Apple, profile setup |
| Money | Paywall UI, RevenueCat client, StoreKit config file | Live products, one subscription service, entitlement gate, restore that sticks, legal copy |
| Data | SwiftData models; container asks for CloudKit | CloudKit entitlement, export, account deletion, conflict behaviour |
| Quality | Design tokens, CI and Fastlane skeletons, placeholder tests | A CI job that can compile iOS 18.2, tests that assert behaviour |
| Store | Bundle id `com.tom.progress`, version 1.0 (1), camera purpose string | Privacy manifest, privacy policy, terms, subscription review notes, honest metadata |

Concrete defects that block every later phase:

- `Progress.entitlements` has the app sandbox only. `ProgressApp` sets `cloudKitDatabase: .automatic`, so sync is declared in code and absent in signing.
- Fastlane and Match use `com.myname.Progress`. The Xcode target uses `com.tom.progress`. A TestFlight upload with the current Fastfile will not match the app.
- CI selects Xcode 15 on `macos-13`. The deployment target is iOS 18.2, which that image cannot build.
- `PaywallView` constructs its own `SubscriptionService`. `MainTabView` constructs another. A purchase in the sheet does not update the rest of the app.
- `SubscriptionService.isSandboxMode` starts as `true`, and the simulator path never calls RevenueCat.
- Food search ships with `apiKey = "DEMO_KEY"`.
- `ModelContainer` failure calls `fatalError`.
- Settings destinations for profile, units, notifications, export, privacy, and terms render “Coming Soon”.
- `ProgressTests` and `NutritionDashboardViewTests` do not assert product behaviour. The Fastlane lint lane still requires 80% coverage.
- `project.json` points at `Progress/PrivacyInfo.xcprivacy`. That file is not in the repo.
- The paywall advertises AI workout generation, camera food logging, and a personalised insights engine. None of those screens exist. App Review treats that as a misleading subscription.

`ContentView` is an unused “Coming Soon” screen. `ProgressApp` already opens `MainTabView`.

## What 1.0 sells

One membership. Same access on every duration. The PRD’s Standard (£1) and AI Native (£3) tiers are dropped. `SubscriptionService` still models `standard` and `plusAI`; that split goes away with the paywall rewrite.

Price it the way [Cal AI](https://apps.apple.com/gb/app/cal-ai-calorie-tracker/id6480417616) prices Unlimited. Apple’s UK catalog, checked 7 October 2026, has one product at two durations:

| Duration | Cal AI Unlimited (UK) | Progress membership |
| --- | --- | --- |
| Month | £9.99 | £9.99 |
| Year | £19.99 | £19.99 |

The year is two months of the monthly price (£119.88 if someone pays monthly all year). That is the offer. Annual is preselected on the paywall. Weekly and the other Unlimited prices on Cal AI’s listing (£2.99, £5.99, £24.95, £29.99) are experiments, not the launch pair. A £0.99 streak restore is also out of scope.

Cal AI’s paywall shape, copied:

- A short onboarding (goal, ability, age) and then the paywall. The tabs stay behind the membership.
- One card for the product. Monthly and yearly are billing choices, not feature tiers. No comparison table.
- Copy lists only what this build does. Camera logging, generated workouts, and written insights join the same membership when they exist. They do not create a second price.
- Restore sits on the paywall.

Referral stays a single-use App Store offer code for one free month of the same membership. The inviter graph is the release after launch.

HealthKit import, workout share links, email-and-password accounts, push reminders, Rive, and Lottie stay off the 1.0 list. The README currently claims several of these. Store screenshots and the App Store description must describe the build that ships.

## Phase 0 — Make the project releasable

Nothing in later phases is trustworthy until the toolchain and the identifiers agree.

1. Pick `com.tom.progress` as the only bundle id. Update `fastlane/Fastfile` and `fastlane/Matchfile` to match the Xcode target. Point Match at the real certificates repo, Apple ID, and team id.
2. Move CI to an image with Xcode 16 or newer. Build and test for an iOS 18.2 simulator. Drop the 80% coverage gate until Phase 4 replaces the placeholder tests; a failing gate on empty tests hides real regressions.
3. Add `PrivacyInfo.xcprivacy` for the required-reason APIs already in use (`UserDefaults`).
4. Move the USDA key, RevenueCat public SDK key, and Firebase plist values behind `Scripts/inject-secrets.sh`. Delete `DEMO_KEY` from `FoodSearchService`.
5. Remove the unused `ContentView` launch path so there is one app entry.

**Exit:** `xcodebuild` of the `Progress` scheme succeeds on the CI image. Fastlane `lint` runs the test action without a coverage failure caused by an empty suite. No food or payment secret is committed.

## Phase 1 — Close the loop on one device

This phase is the product. It does not need an account or a network.

### Workouts

- Add, edit, and tick sets on an exercise. `ExerciseDetailView` still has the add-set action empty.
- Finish a workout from the detail menu: set `status` to completed and set `completedAt`. That action is an empty closure in `WorkoutDetailView`.
- Keep plans separate from sessions. Starting a workout duplicates the plan into an in-progress session so the template is still there tomorrow.
- Rest timer: pause, resume, and reset, with a haptic on completion. The control already exists in `NewProgressBarWithTimer`; wire it to the session rather than view-local state only.
- Swipe to delete an exercise or a plan, with undo for a few seconds.
- Seed a few labelled templates from the profile goal (strength, run, recovery) once onboarding exists. Until then, seed them on first launch.

### Nutrition

- Use Open Food Facts for search as well as barcodes. The app is for UK athletes; USDA FoodData Central is a poor default, and the barcode path already talks to Open Food Facts.
- Confirm portion, then save a `NutritionEntry`. Barcode already saves; search should use the same confirmation step.
- Quick-add: parse a short string such as `200g chicken breast` into a name and a gram weight, then look up or accept manual macros. Target the PRD’s accuracy bar with a fixture list, not a model.
- Store macro targets on the user profile. The rings in the nutrition dashboard read those targets.
- Pin a food. `NutritionEntry.isFavorite` exists; the dashboard needs a one-tap list.

### Progress

Replace the empty state in `ProgressDashboardView`.

- Daily snapshot: workouts completed today, minutes, and calories logged.
- One weekly Swift Chart: calories in against workload (sets or minutes).
- A 7-day streak. A day counts when the user finishes a workout or logs a meal. Missing a day resets the count.

**Exit:** with the network off, a user can create a workout, log sets, finish it, log a meal by search and by a typed quick-add, force-quit, relaunch, and see that day on the progress tab.

## Phase 2 — Identity, payment, and legal

Paid-only means the main tabs stay behind an entitlement.

1. Onboarding, in order: Sign in with Apple, age / goal / ability (writes `User`), then the paywall. Email-and-password auth is not required for 1.0. Sign in with Apple is the identity App Review expects, and iCloud already identifies the device for sync.
2. One `SubscriptionService`, created in `ProgressApp` and passed in the environment. Delete the second instance inside `PaywallView`. Collapse `SubscriptionTier` to a single `member` state.
3. `isSandboxMode` is true only in debug simulator builds. Release calls RevenueCat.
4. Two App Store Connect subscriptions, one RevenueCat entitlement named `member`: `com.tom.progress.member.monthly` at £9.99 and `com.tom.progress.member.yearly` at £19.99. The paywall reads the localized price from StoreKit. There is no £1 or £3 product.
5. Gate the three tabs on `member`. Restore purchases is on the paywall and in Settings, and it updates the same service.
6. Offer-code field on the paywall for a one-month introductory offer. Single use, enforced by App Store offer codes rather than a custom code server. The code grants `member`, not a separate tier.
7. Replace the privacy and terms stubs with the real documents, and link to the hosted URLs from the paywall footer (those buttons are empty closures today).
8. Export writes a JSON file of workouts and nutrition entries to the share sheet. Delete account wipes the SwiftData store, signs out, and tells the user how to cancel the subscription (Apple requires the cancellation to happen through the App Store).

**Exit:** a sandbox account can buy the yearly membership, kill the app, relaunch into the tabs, restore onto a second install, redeem an offer code, export a file, and delete local data. The reviewer notes describe that path.

## Phase 3 — Sync and production services

1. Add the iCloud and CloudKit entitlements and a container id. Deploy the SwiftData schema to the development CloudKit environment, then to production before the store build.
2. If the container cannot be created, show a blocking error with a retry. Do not call `fatalError`.
3. Sync when the app becomes active, and skip background sync while Low Power Mode is on.
4. SwiftData plus CloudKit does not give a rich manual merge UI. For 1.0, last writer wins, and export is the safety net. Record that as a known limit. A per-record “keep mine / keep the other copy” screen is the follow-up if TestFlight actually produces conflicts.
5. Turn Firebase Crashlytics on in the Release configuration and confirm a test crash from a TestFlight build arrives in the console. `AppDelegate` already calls `FirebaseApp.configure()` when the plist exists.
6. Log four analytics events: first open, workout completed, meal logged, purchase completed.

**Exit:** two devices on the same iCloud account show the same workout after a sync. A TestFlight crash appears in Crashlytics.

## Phase 4 — Make the binary match the claims

1. Tests that protect the loop: finishing a workout sets `completedAt`; a day’s macro totals add up; the quick-add parser covers the fixture list; the entitlement gate hides the tabs; the streak resets after a missed day.
2. One UI test that creates a workout, logs a food, and sees the snapshot.
3. Accessibility on the three main flows: Dynamic Type, VoiceOver labels on the timer and the rings, and the existing colour tokens checked against WCAG AA.
4. Localise the strings on those screens through the existing `Localizable.strings` and SwiftGen. The file already has onboarding and auth keys; the views do not use them.
5. Replace hard-coded fonts on the workout detail screen with the tokens in `Typography.swift`.
6. Measure cold launch on a device in the iPhone 12 class. The PRD bar is 500 ms. If the measurement is over that, the first place to look is SDK startup in `AppDelegate` (Firebase and RevenueCat on the launch path).
7. App Store metadata for one membership. Screenshots of the workout logger, the meal logger, and the progress snapshot. Privacy nutrition labels that match the SDK list (RevenueCat, Firebase, CloudKit, camera, Open Food Facts). Subscription review notes and a sandbox account.

**Exit:** CI is green on the Xcode 16 image, including the new tests. A teammate can complete the reviewer path on TestFlight without a “Coming Soon” screen and without a feature the build does not contain.

## Phase 5 — Ship

1. Internal TestFlight from the Fastlane `beta` lane, after Match is pointed at the real team.
2. A short external TestFlight with people who match the three personas: a lifter, a runner, and someone who wants charts. Watch for meal-log time and for sessions that need an edit after finish (the PRD targets are 15 seconds and 85% clean logs).
3. Fix crashes and data-loss bugs from that group before submission. Copy bugs can wait.
4. Submit with a phased release. Watch crash-free sessions (target 99.5%) for the first days before opening the release fully.

## The release after launch

In this order:

1. **Camera logging and insights, inside the same membership.** A confidence badge and an edit step on a meal photo, then one weekly written insight on the progress tab. No second product and no upgrade prompt.
2. **Referral graph.** A personal invite link, a single redemption, and a notice to the inviter. Keep the offer-code path from 1.0 as the fallback.
3. **HealthKit.** Import workouts (runs in particular) so the runner persona does not type them in. This needs usage strings and a privacy-label update, which is why it is not in the first review.
4. **Reminders and share links.** A local notification if nothing is logged by late afternoon. A workout link that opens the app or the App Store.
5. **Polish.** Email auth only if Sign in with Apple proves insufficient. Remote paywall copy experiments. Motion.

## Mapping back to the PRD

| PRD item | 1.0 | Later |
| --- | --- | --- |
| 1.0 Plan selection, 1.4 profile | Profile yes. Plan selection is month vs year of one membership | |
| 1.1 Referral redemption | Offer code | Personal invite link and inviter notice |
| 1.2 Email auth | No | If required |
| 1.3 Sign in with Apple | Yes | |
| 2.1 Floating navigation | Already in the build | Hide-on-scroll polish |
| 2.2 Deep links | No | With share links and pushes |
| 3.0–3.4 Templates, planner, types, live log, rest timer | Yes | |
| 3.5–3.7 Reorder, undo, unsaved prompt | Undo yes; reorder and unsaved prompt if they fall out of the finish flow | Otherwise the next release |
| 3.8 Finish workout | Yes | Share summary with the share-link work |
| 3.9 Workout sharing | No | |
| 3.10 AI exercises | No | Same membership, after launch |
| 4.1–4.2 Search and barcode | Yes, Open Food Facts | |
| 4.3 Camera AI | No | Same membership, first feature after launch |
| 4.4–4.6 Quick-add, favourites, macro targets | Yes | |
| 4.7 Intake reminder | No | With other notifications |
| 5.1–5.3 Snapshot, weekly chart, streak | Yes | |
| 5.4 Personalised insights | No | Same membership, after camera logging |
| 6.1–6.3 Offline store, CloudKit, export and delete | Yes | |
| 6.4 Manual conflict resolution | Last writer wins, documented | Chooser if conflicts show up |
| 7.x Motion, Lottie, shared elements | Tokens only | |
| 8.1, 8.3–8.5 Pushes, units, theme, rating prompt | System theme only | The rest |
| 8.2 Referral generation | No | Second item after launch |
| 9.x Launch time, low-power sync, Crashlytics | Yes | |
| 10.1–10.3 Dual paywall, purchase, restore | One membership, £9.99/month or £19.99/year, restore yes | |
| 10.4–10.5 Remote paywall, promo codes | Offer codes yes | Remote copy experiments |
