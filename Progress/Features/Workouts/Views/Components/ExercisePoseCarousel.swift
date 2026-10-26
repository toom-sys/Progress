//
//  ExercisePoseCarousel.swift
//  Progress
//
//  Single-pose exercise preview — tap to cycle through images with crossfade.
//

import SwiftUI

/// Shows one instructional pose at a time. Tap anywhere to advance; wraps at the end.
struct ExercisePoseCarousel: View {
    let frames: [UIImage]

    @State private var poseIndex = 0

    var body: some View {
        Button {
            advancePose()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppPalette.optionFill)

                if frames.isEmpty {
                    EmptyView()
                } else {
                    ZStack {
                        ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                            Image(uiImage: frame)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .opacity(index == poseIndex ? 1 : 0)
                        }
                    }
                    .animation(.easeInOut(duration: 0.28), value: poseIndex)

                    VStack {
                        Spacer()
                        pageDots
                            .padding(.bottom, 8)
                    }
                }
            }
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppPalette.line, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(frames.count < 2)
        .accessibilityLabel("Exercise pose")
        .accessibilityHint(frames.count > 1 ? "Tap to show next pose" : "")
        .accessibilityValue("Pose \(poseIndex + 1) of \(max(frames.count, 1))")
        .onAppear {
            poseIndex = 0
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(frames.indices, id: \.self) { index in
                Circle()
                    .fill(index == poseIndex ? AppPalette.ink : AppPalette.muted.opacity(0.45))
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: poseIndex)
        .accessibilityHidden(true)
    }

    private func advancePose() {
        guard frames.count > 1 else { return }
        HapticFeedback.workoutButtonTap()
        poseIndex = (poseIndex + 1) % frames.count
    }
}
