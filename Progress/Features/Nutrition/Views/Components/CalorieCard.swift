//
//  CalorieCard.swift
//  Progress
//

import SwiftUI

// MARK: - Calorie Card Component

struct CalorieCard: View {
    let consumed: Double
    let target: Double

    private static let remainingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private var remaining: Double {
        max(0, target - consumed)
    }

    private var progress: Double {
        target > 0 ? min(consumed / target, 1.0) : 0
    }

    private var remainingText: String {
        Self.remainingFormatter.string(from: NSNumber(value: Int(remaining))) ?? "\(Int(remaining))"
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(remainingText)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(AppPalette.ink)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("Calories left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.muted)
                    .lineLimit(1)

                Text("🍽 \(Int(consumed)) eaten")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppPalette.ink.opacity(0.75))
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppPalette.optionFill))
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .stroke(AppPalette.accentSoft, lineWidth: 8)
                    .frame(width: 78, height: 78)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Color.brand, AppPalette.brandLight, Color.brand],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 78, height: 78)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: consumed)

                Circle()
                    .fill(AppPalette.surface)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Text("🔥")
                            .font(.system(size: 24))
                    }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Calorie progress")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(height: NutritionCardMetrics.height)
        .appCard(cornerRadius: 24, padding: 0)
    }
}
