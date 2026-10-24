//
//  PrivacyPolicyView.swift
//  Progress
//

import SwiftUI

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentView(
            lastUpdated: "24 October 2026",
            intro: "Progress is a workout and nutrition app. This policy explains what information the app handles, where it goes, and the choices you have. We do not sell your personal information.",
            sections: Self.sections
        )
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }

    private static let sections: [LegalSection] = [
        LegalSection(
            title: "Information you add",
            paragraphs: [
                "You can save a display name, age, biological sex, height, weight, activity level, fitness goal, and fitness level. You can also log workouts, exercises and sets, meals, water, body weight, and a training plan.",
                "A profile may include an email address for display. Progress does not use that address to sign you in, and the app does not create a separate Progress account for your training log."
            ]
        ),
        LegalSection(
            title: "On your device",
            paragraphs: [
                "Progress is local-first. Your profile, workouts, nutrition, water, body weight, meal photos you save, and training plan are stored on your device. We do not run a separate server that holds your training log."
            ]
        ),
        LegalSection(
            title: "Apple Health",
            paragraphs: [
                "If you allow it, Progress reads your step count from Apple Health so it can show progress toward your daily step goal. The app requests read access only and does not write workouts or nutrition back to Health.",
                "Step counts are read on your device to display your progress. They are not uploaded to our servers."
            ]
        ),
        LegalSection(
            title: "Camera, photos, and barcodes",
            paragraphs: [
                "The camera is used to photograph meals and scan food barcodes. You can also pick a meal photo from your library. A photo you keep with a logged meal is stored with that entry on your device.",
                "Meal photos can be recognised on your device. If you use a feature that identifies food with a cloud model, the photo is sent so the app can suggest foods and nutrition values. That is described under AI features.",
                "When you scan a barcode, the barcode number is sent to Open Food Facts to look up the public product record. Open Food Facts returns the product name and nutrition information shown in the app."
            ]
        ),
        LegalSection(
            title: "AI features",
            paragraphs: [
                "Personalised training plans and AI workout suggestions send the details needed to generate a result. That can include your age, biological sex, height, weight, activity level, fitness goal and level, training environment or equipment, and the answers you give while setting up a plan or describing a workout.",
                "Those requests are sent to OpenAI. In the released app they go through our server and are authorised with an anonymous Firebase sign-in, so the service can confirm the app is allowed to make the request. That sign-in is not a profile you manage and is not tied to your name.",
                "We use the response to show you a plan, workout, or food estimate. AI output is an estimate. It is not medical, dietary, or coaching advice."
            ]
        ),
        LegalSection(
            title: "Subscriptions",
            paragraphs: [
                "Progress Pro is an auto-renewing subscription sold by Apple. Apple processes the payment. We never receive your card number or full payment details.",
                "We use RevenueCat to tell whether this installation has an active Progress Pro entitlement, including after you restore purchases or redeem an offer code. RevenueCat receives a subscriber identifier and subscription status. It does not receive your payment card details."
            ]
        ),
        LegalSection(
            title: "Analytics and crash reports",
            paragraphs: [
                "We use Firebase Analytics to understand the setup flow: which onboarding screens you see, and the choices you make there, such as training environment or how often you want to work out.",
                "We use Firebase Crashlytics to diagnose crashes. These tools may receive device and app information such as device model, operating system version, and a crash trace. They are not used to build an advertising profile, and we do not show third-party ads in Progress."
            ]
        ),
        LegalSection(
            title: "Notifications",
            paragraphs: [
                "If you allow notifications, Progress schedules them on your device, for example when a rest timer finishes. They are local notifications. We do not run a remote notification service that stores your training data."
            ]
        ),
        LegalSection(
            title: "How we use information",
            paragraphs: [
                "We use information to provide workout tracking, nutrition logging, progress charts, and training plans; to personalise goals and suggestions; to run subscriptions and restore purchases; to keep the app reliable; and to reply if you contact us.",
                "We do not sell your personal information."
            ]
        ),
        LegalSection(
            title: "Who else processes it",
            paragraphs: [
                "Apple, for Health, the App Store, and on-device notifications. OpenAI, for AI generation. Google Firebase, for anonymous authentication of AI requests, onboarding analytics, and crash reports. RevenueCat, for subscription status. Open Food Facts, for barcode lookups.",
                "Some of these providers are outside the United Kingdom. Where information is transferred, it is handled under their terms and the safeguards they offer for international transfers."
            ]
        ),
        LegalSection(
            title: "Your choices",
            paragraphs: [
                "You can edit your profile in Settings. From Profile you can clear your workouts, nutrition, and profile on this device. That cannot be undone.",
                "You can turn Health, Camera, Photos, and Notifications access off in iOS Settings. You can cancel a subscription in your Apple ID subscription settings. Deleting the app does not cancel the subscription."
            ]
        ),
        LegalSection(
            title: "Children",
            paragraphs: [
                "Progress is not directed at children under 13, and we do not knowingly collect personal information from them. If you believe a child has provided information in the app, contact us and we will help you remove what is stored on the device."
            ]
        ),
        LegalSection(
            title: "Changes",
            paragraphs: [
                "If this policy changes, the updated version will appear on the public policy page and in the app. The date at the top is the latest version."
            ]
        )
    ]
}
