//
//  SplashView.swift
//  Progress
//

import SwiftUI

struct SplashView: View {

    @EnvironmentObject private var subscriptionService: SubscriptionService
    var onComplete: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            AdaptiveGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("app_icon_display")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Text("Progress")
                    .font(.titleXL)
                    .foregroundColor(.textPrimary)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                textOpacity = 1.0
            }
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await subscriptionService.loadOfferings()
                    await subscriptionService.checkSubscriptionStatus()
                }
                group.addTask {
                    try? await Task.sleep(for: .seconds(1.5))
                }
                group.addTask {
                    await ExerciseDatabase.warmUp()
                }
                await group.waitForAll()
            }
            onComplete()
        }
    }
}

#Preview {
    SplashView(onComplete: {})
        .environmentObject(SubscriptionService())
}
