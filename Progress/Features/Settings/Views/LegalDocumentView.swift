//
//  LegalDocumentView.swift
//  Progress
//

import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .privacy:
            PrivacyPolicyView()
        case .terms:
            TermsOfServiceView()
        }
    }
}

struct LegalSection: Identifiable {
    let title: String
    let paragraphs: [String]

    var id: String { title }
}

/// Scrollable legal copy shared by the privacy policy and terms of service.
struct LegalDocumentView: View {
    let lastUpdated: String
    let intro: String
    let sections: [LegalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last updated \(lastUpdated)")
                        .font(.appSubtitle)
                        .foregroundColor(AppPalette.muted)

                    Text(intro)
                        .font(.system(size: 16))
                        .foregroundColor(AppPalette.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.appCardTitle)
                            .foregroundColor(AppPalette.ink)

                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(.system(size: 16))
                                .foregroundColor(AppPalette.muted)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact")
                        .font(.appCardTitle)
                        .foregroundColor(AppPalette.ink)

                    Text("Questions about these terms or your information:")
                        .font(.system(size: 16))
                        .foregroundColor(AppPalette.muted)

                    Link(destination: URL(string: "mailto:Tom.progressapp.support@gmail.com")!) {
                        Text("Tom.progressapp.support@gmail.com")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.brand)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppBackground())
    }
}
