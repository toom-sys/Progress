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
                        .font(.caption)
                        .foregroundColor(.textTertiary)

                    Text(intro)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)

                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact")
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)

                    Text("Questions about these terms or your information:")
                        .font(.body)
                        .foregroundColor(.textSecondary)

                    Link(destination: URL(string: "mailto:Tom.progressapp.support@gmail.com")!) {
                        Text("Tom.progressapp.support@gmail.com")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.background)
    }
}
