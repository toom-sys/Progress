import SwiftUI

/// Encouraging empty state for new users who haven't completed any workouts yet
struct BodyMapEmptyState: View {
    var variant: BodyMapVariant = .male
    @State private var artworkToken = 0

    var body: some View {
        VStack(spacing: 12) {
            bodyImage

            VStack(spacing: 6) {
                Text("Light Up Your Progress")
                    .font(.appCardTitle)
                    .foregroundColor(AppPalette.ink)
                    .multilineTextAlignment(.center)

                Text("Complete a workout to light up your body map.")
                    .font(.appSubtitle)
                    .foregroundColor(AppPalette.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .task(id: variant.baseImageName) {
            let name = variant.baseImageName
            guard BodyMapArtworkLoader.cachedFill(baseName: name) == nil else { return }
            await Task.detached(priority: .utility) {
                BodyMapArtworkLoader.renderFill(baseName: name)
            }.value
            artworkToken += 1
        }
    }

    private var bodyImage: some View {
        let image = BodyMapArtworkLoader.cachedFill(baseName: variant.baseImageName)
        return Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 140)
                    .opacity(0.55)
            } else {
                Color.clear
                    .frame(height: 140)
            }
        }
        .id(artworkToken)
    }
}

// MARK: - Preview

#Preview("Light") {
    BodyMapEmptyState()
        .padding()
        .background(AppBackground())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    BodyMapEmptyState()
        .padding()
        .background(AppBackground())
        .preferredColorScheme(.dark)
}
