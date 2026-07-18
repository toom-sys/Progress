//
//  PlanBlockRegenerationPopup.swift
//  Progress
//

import SwiftUI

struct PlanBlockRegenerationPopup: View {
    let workoutName: String
    let options: BlockRegenerationOptions
    let units: UnitSystem
    let onConfirm: (_ levelUp: Bool) -> Void
    let onDecline: () -> Void

    @State private var isLevelUpSelected: Bool

    init(
        workoutName: String,
        options: BlockRegenerationOptions,
        units: UnitSystem,
        onConfirm: @escaping (_ levelUp: Bool) -> Void,
        onDecline: @escaping () -> Void
    ) {
        self.workoutName = workoutName
        self.options = options
        self.units = units
        self.onConfirm = onConfirm
        self.onDecline = onDecline
        _isLevelUpSelected = State(initialValue: options.recommendsLevelUp)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDecline() }

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 44))
                        .foregroundColor(.brand)

                    Text("Start your next block?")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Nice work — start the next block of \(workoutName) from your new numbers?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                ScrollView {
                    VStack(spacing: 12) {
                        optionCard(
                            title: "Level up",
                            subtitle: options.recommendsLevelUp
                                ? "You hit all your targets — push a step further."
                                : "Push a step further next block.",
                            isRecommended: options.recommendsLevelUp,
                            isSelected: isLevelUpSelected,
                            baselines: options.levelUpBaselines
                        ) {
                            isLevelUpSelected = true
                        }

                        optionCard(
                            title: "Keep my numbers",
                            subtitle: "Repeat the block from your current level.",
                            isRecommended: false,
                            isSelected: !isLevelUpSelected,
                            baselines: options.keepBaselines
                        ) {
                            isLevelUpSelected = false
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: 340)

                HStack(spacing: 12) {
                    Button("Not yet") {
                        HapticFeedback.workoutButtonTap()
                        onDecline()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Start block") {
                        HapticFeedback.workoutButtonTap()
                        onConfirm(isLevelUpSelected)
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 28)
        }
    }

    private func optionCard(
        title: String,
        subtitle: String,
        isRecommended: Bool,
        isSelected: Bool,
        baselines: [ExerciseBaseline],
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            HapticFeedback.workoutButtonTap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .foregroundColor(isSelected ? .brand : .secondary)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    if isRecommended {
                        Text("Recommended")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.brand)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.brand.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(baselines.indices, id: \.self) { index in
                        let baseline = baselines[index]
                        HStack(alignment: .top, spacing: 12) {
                            Text(baseline.exerciseName)
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(ProgressionEngine.formattedTargetLine(for: baseline, units: units))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.brand.opacity(0.08) : Color.secondary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.brand : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
