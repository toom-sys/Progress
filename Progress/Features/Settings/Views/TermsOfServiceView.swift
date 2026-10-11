//
//  TermsOfServiceView.swift
//  Progress
//

import SwiftUI

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentView(
            lastUpdated: "11 October 2026",
            intro: "These terms are an agreement between you and Progress for the Progress iOS app. By using the app you agree to them and to the Privacy Policy. If you do not agree, do not use the app.",
            sections: Self.sections
        )
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.large)
    }

    private static let sections: [LegalSection] = [
        LegalSection(
            title: "The service",
            paragraphs: [
                "Progress helps you log workouts, nutrition, water, and body weight, see your progress, and build a training plan. Some features, including AI workout and meal tools, require an active Progress Pro subscription.",
                "Logging on your device is designed to work without an internet connection. iCloud sync, barcode lookup, subscriptions, and AI features need a connection and can be unavailable or delayed."
            ]
        ),
        LegalSection(
            title: "Who can use Progress",
            paragraphs: [
                "You need to be able to form a contract where you live, and you must be at least 13. Progress is a personal fitness tool. It is not for clinical, commercial coaching, or emergency use."
            ]
        ),
        LegalSection(
            title: "Your logs",
            paragraphs: [
                "You keep ownership of the workouts, meals, photos, and other content you add. You allow Progress to store that content on your device, sync it with iCloud when you use iCloud, and send the portions described in the Privacy Policy to the services that power barcode lookup and AI features.",
                "You are responsible for what you enter. Progress does not check that a workout or meal log is accurate."
            ]
        ),
        LegalSection(
            title: "Progress Pro",
            paragraphs: [
                "Progress Pro is an auto-renewing subscription sold through the Apple App Store. The app offers yearly, monthly, and weekly billing. The price for the plan you select is shown on the purchase screen before you confirm, and it can differ by country.",
                "The yearly plan may include a free trial. The length of any trial is shown before you confirm. Monthly and weekly plans do not include a trial unless the purchase screen says they do.",
                "Payment is charged to your Apple ID when you confirm the purchase. The subscription renews automatically unless you cancel at least 24 hours before the end of the current period. Your account is charged for renewal within 24 hours before that period ends. After a free trial, the plan renews at the price shown for that plan unless you cancel before the trial ends.",
                "You can manage or cancel in your Apple ID subscription settings (Settings, then your name, then Subscriptions). Deleting Progress does not cancel the subscription. Where Apple's rules say so, any unused part of a free trial ends if you purchase a subscription.",
                "Restore Purchases puts an existing Progress Pro entitlement back on this device. Offer codes, including annual codes, are redeemed through Apple. We do not take payment ourselves and we do not issue refunds. Billing questions and refund requests go to Apple."
            ]
        ),
        LegalSection(
            title: "Health and safety",
            paragraphs: [
                "Progress is a general fitness and nutrition log. It is not a medical device and it does not provide medical, dietary, or personal-training advice. Calorie targets, macro goals, step goals, and generated plans are estimates based on what you enter. They are not a diagnosis or a prescription.",
                "Talk to a doctor before you start or change exercise or eating habits, especially if you are pregnant, injured, or managing a health condition. You are responsible for how you train. Stop if you feel pain, dizziness, or distress."
            ]
        ),
        LegalSection(
            title: "AI features",
            paragraphs: [
                "AI workouts, training plans, and food recognition can be wrong, incomplete, or unsuitable for you. Check food labels and use your own judgment before you rely on a suggestion. Do not treat AI output as professional advice."
            ]
        ),
        LegalSection(
            title: "Acceptable use",
            paragraphs: [
                "Use Progress for your own training. Do not misuse the app, interfere with it, try to bypass subscription checks, or use it to break the law. Do not add photos or other content you do not have the right to use."
            ]
        ),
        LegalSection(
            title: "The app itself",
            paragraphs: [
                "The app, its design, and its built-in exercise content belong to Progress or its licensors. These terms give you a personal, non-transferable licence to use Progress on Apple devices you own or control, as allowed by the App Store rules. They do not transfer ownership of the app to you."
            ]
        ),
        LegalSection(
            title: "Apple",
            paragraphs: [
                "These terms are between you and Progress, not Apple. Apple is not responsible for Progress or its content, and Apple has no obligation to provide support for the app.",
                "If Progress fails to conform to an applicable warranty, you may notify Apple, and Apple may refund the purchase price of the app where the App Store rules require it. To the maximum extent permitted by law, Apple has no other warranty obligation for the app.",
                "Apple and its subsidiaries are third-party beneficiaries of these terms as they relate to your licence from the App Store, and they may enforce those terms."
            ]
        ),
        LegalSection(
            title: "Liability",
            paragraphs: [
                "Nothing in these terms limits liability that cannot legally be limited, including liability for death or personal injury caused by negligence, fraud, or your statutory rights as a consumer.",
                "The app is provided as available. We do not guarantee that it will be uninterrupted or error-free, or that a plan, calorie estimate, or food recognition will be right for you. To the extent the law allows, we are not liable for lost logs, lost profits, or indirect or consequential loss arising from your use of Progress."
            ]
        ),
        LegalSection(
            title: "Stopping or changing the service",
            paragraphs: [
                "You can stop using Progress at any time and delete the app. Cancel any subscription separately through Apple. We may change or stop offering the app or a feature. These terms still cover use up to that point.",
                "We may update these terms. The date at the top is the current version, and the new version is shown in the app. If you keep using Progress after an update, you accept the new terms. If you do not, stop using the app and cancel your subscription."
            ]
        ),
        LegalSection(
            title: "Law",
            paragraphs: [
                "These terms are governed by the laws of England and Wales. If you are a consumer, you keep the mandatory protections of the country where you live, and you may bring a claim in the courts of that country where the law gives you that right."
            ]
        )
    ]
}
