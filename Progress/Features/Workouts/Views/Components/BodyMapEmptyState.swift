import SwiftUI

/// Encouraging empty state for new users who haven't completed any workouts yet
struct BodyMapEmptyState: View {
    var variant: BodyMapVariant = .male

    var body: some View {
        VStack(spacing: 20) {
            bodyImage
            
            // Encouraging message
            VStack(spacing: 12) {
                Text("Light Up Your Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Complete your first workout to see your body map come alive with color. Each muscle group you train will glow brighter as you build consistency.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
    }
    
    private var bodyImage: some View {
        Image(variant.baseImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 180)
            .opacity(0.5)
    }
}

// MARK: - Preview

#Preview {
    BodyMapEmptyState()
        .padding()
        .background(Color(.systemGray6))
}
