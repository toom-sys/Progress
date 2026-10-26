//
//  ProgressLegendView.swift
//  Progress
//

import SwiftUI

/// Legend view explaining the progress tiers and color coding.
struct ProgressLegendView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 10) {
                    Text("Legend")
                        .font(.appSectionTitle)
                        .foregroundStyle(AppPalette.ink)
                        .accessibilityAddTraits(.isHeader)

                    Spacer(minLength: 8)

                    CircleIconButton(
                        systemName: "xmark",
                        style: .plain,
                        size: 36,
                        accessibilityLabel: "Close",
                        action: { dismiss() }
                    )
                }

                Text("How the body map colours show your recent training.")
                    .font(.appSubtitle)
                    .foregroundStyle(AppPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 8) {
                    ForEach(ProgressTier.allCases, id: \.self) { tier in
                        ProgressTierRow(tier: tier)
                    }
                }

                infoCard(
                    title: "How progress is calculated",
                    points: [
                        "Progress is based on workout frequency and consistency",
                        "Each muscle group advances independently",
                        "More recent workouts have greater impact",
                        "Progress gradually fades without regular training"
                    ]
                )

                infoCard(
                    title: "Tips",
                    points: [
                        "Train each muscle group 2–3 times per week",
                        "Focus on consistency over intensity",
                        "Tap a muscle group to see its detail",
                        "Balance all muscle groups for the best result"
                    ]
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(AppBackground())
    }

    private func infoCard(title: String, points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.appCardTitle)
                .foregroundStyle(AppPalette.ink)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(AppPalette.muted)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                            .accessibilityHidden(true)

                        Text(point)
                            .font(.appSubtitle)
                            .foregroundStyle(AppPalette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: 22, padding: 16)
    }
}

// MARK: - Tier row

struct ProgressTierRow: View {
    let tier: ProgressTier

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tier.color)
                .frame(width: 14, height: 14)
                .overlay(Circle().strokeBorder(AppPalette.line, lineWidth: 1))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(tier.displayName)
                    .font(.appCardTitle)
                    .foregroundStyle(AppPalette.ink)

                Text(tier.accessibilityDescription)
                    .font(.appSubtitle)
                    .foregroundStyle(AppPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .appGroupRow(cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tier.displayName). \(tier.accessibilityDescription)")
    }
}

#Preview("Light") {
    ProgressLegendView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProgressLegendView()
        .preferredColorScheme(.dark)
}
