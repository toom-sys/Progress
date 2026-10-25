import SwiftUI

/// Encouraging empty state for new users who haven't completed any workouts yet
struct BodyMapEmptyState: View {
    var variant: BodyMapVariant = .male

    var body: some View {
        VStack(spacing: 12) {
            bodyImage
            
            // Encouraging message
            VStack(spacing: 6) {
                Text("Light Up Your Progress")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Complete a workout to light up your body map.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    private var bodyImage: some View {
        Image(variant.baseImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 140)
            .opacity(0.5)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    BodyMapEmptyState()
        .padding()
        .background(Color(.systemGray6))
}
